#!/usr/bin/env bash
# Elimina toda la infraestructura para no gastar presupuesto del lab.
# Orden inverso a la creacion. Ignora recursos que ya no existan.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require; discover_network; state_load

log "Borrando servicios ECS..."
for svc in "${PROJECT}-ventas" "${PROJECT}-despachos" "${PROJECT}-frontend"; do
  aws ecs update-service --cluster "$CLUSTER" --service "$svc" --desired-count 0 >/dev/null 2>&1 || true
  aws ecs delete-service --cluster "$CLUSTER" --service "$svc" --force >/dev/null 2>&1 || true
done

log "Borrando ALB, listener y target groups..."
ALB_ARN="$(aws elbv2 describe-load-balancers --names "${PROJECT}-alb" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null | grep -v '^None$' || true)"
[ -n "$ALB_ARN" ] && aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" >/dev/null 2>&1 || true
sleep 5
for tg in "${PROJECT}-tg-frontend" "${PROJECT}-tg-ventas" "${PROJECT}-tg-despachos"; do
  arn="$(aws elbv2 describe-target-groups --names "$tg" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null | grep -v '^None$' || true)"
  [ -n "$arn" ] && aws elbv2 delete-target-group --target-group-arn "$arn" >/dev/null 2>&1 || true
done

log "Borrando cluster ECS..."
aws ecs delete-cluster --cluster "$CLUSTER" >/dev/null 2>&1 || true

log "Borrando RDS..."
aws rds delete-db-instance --db-instance-identifier "${PROJECT}-mysql" --skip-final-snapshot >/dev/null 2>&1 || true
aws rds wait db-instance-deleted --db-instance-identifier "${PROJECT}-mysql" 2>/dev/null || true
aws rds delete-db-subnet-group --db-subnet-group-name "${PROJECT}-db-subnets" >/dev/null 2>&1 || true

log "Borrando secreto..."
aws secretsmanager delete-secret --secret-id "${PROJECT}-db-password" --force-delete-without-recovery >/dev/null 2>&1 || true

log "Borrando security groups..."
for sg in "${PROJECT}-rds-sg" "${PROJECT}-ecs-sg" "${PROJECT}-alb-sg"; do
  id="$(sg_id "$sg")"; [ -n "$id" ] && aws ec2 delete-security-group --group-id "$id" >/dev/null 2>&1 || true
done

log "Borrando repos ECR y log group..."
for svc in ventas despachos frontend; do
  aws ecr delete-repository --repository-name "${ECR_NAMESPACE}/${svc}" --force >/dev/null 2>&1 || true
done
aws logs delete-log-group --log-group-name "$LOG_GROUP" >/dev/null 2>&1 || true

rm -f "$STATE"
log "Teardown completo."
