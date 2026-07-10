#!/usr/bin/env bash
# Crea el ALB, los 3 target groups (con health checks afinados) y el listener
# con enrutamiento por path.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require; discover_network; state_load
: "${SG_ALB:?corre 02-network.sh primero}"

# ALB
ALB_ARN="$(aws elbv2 describe-load-balancers --names "${PROJECT}-alb" \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null | grep -v '^None$' || true)"
if [ -z "$ALB_ARN" ]; then
  ALB_ARN="$(aws elbv2 create-load-balancer --name "${PROJECT}-alb" \
    --subnets "$SUBNET_A" "$SUBNET_B" --security-groups "$SG_ALB" \
    --scheme internet-facing --type application \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)"
  log "ALB creado"
fi
ALB_DNS="$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" \
  --query 'LoadBalancers[0].DNSName' --output text)"
state_set ALB_ARN "$ALB_ARN"; state_set ALB_DNS "$ALB_DNS"

# Target group (idempotente). $1=nombre $2=puerto $3=health-path
ensure_tg() {
  local arn
  arn="$(aws elbv2 describe-target-groups --names "$1" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null | grep -v '^None$' || true)"
  if [ -z "$arn" ]; then
    arn="$(aws elbv2 create-target-group --name "$1" --protocol HTTP --port "$2" \
      --vpc-id "$VPC" --target-type ip --health-check-path "$3" \
      --query 'TargetGroups[0].TargetGroupArn' --output text)"
  fi
  # Health check rapido: sano tras 2 chequeos de 15s (evita crash-loop en el rollout)
  aws elbv2 modify-target-group --target-group-arn "$arn" \
    --health-check-interval-seconds 15 --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 >/dev/null
  aws elbv2 modify-target-group-attributes --target-group-arn "$arn" \
    --attributes Key=deregistration_delay.timeout_seconds,Value=30 >/dev/null
  echo "$arn"
}

TG_FRONT="$(ensure_tg "${PROJECT}-tg-frontend" 80  /healthz)"
TG_VENTAS="$(ensure_tg "${PROJECT}-tg-ventas"   8080 /actuator/health)"
TG_DESP="$(ensure_tg "${PROJECT}-tg-despachos"  8081 /actuator/health)"
state_set TG_FRONT "$TG_FRONT"; state_set TG_VENTAS "$TG_VENTAS"; state_set TG_DESP "$TG_DESP"

# Listener :80 -> default al frontend
LISTENER="$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" \
  --query 'Listeners[0].ListenerArn' --output text 2>/dev/null | grep -v '^None$' || true)"
if [ -z "$LISTENER" ]; then
  LISTENER="$(aws elbv2 create-listener --load-balancer-arn "$ALB_ARN" --protocol HTTP --port 80 \
    --default-actions Type=forward,TargetGroupArn="$TG_FRONT" \
    --query 'Listeners[0].ListenerArn' --output text)"
fi
state_set LISTENER "$LISTENER"

# Reglas de path (crear solo si no existen esas prioridades)
ensure_rule() { # $1=prioridad $2=path $3=tg
  if ! aws elbv2 describe-rules --listener-arn "$LISTENER" \
       --query 'Rules[?Priority==`'"$1"'`]' --output text | grep -q .; then
    aws elbv2 create-rule --listener-arn "$LISTENER" --priority "$1" \
      --conditions Field=path-pattern,Values="$2" \
      --actions Type=forward,TargetGroupArn="$3" >/dev/null
  fi
}
ensure_rule 10 '/api/v1/ventas*'    "$TG_VENTAS"
ensure_rule 20 '/api/v1/despachos*' "$TG_DESP"

log "ALB listo en http://$ALB_DNS"
