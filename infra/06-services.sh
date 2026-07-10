#!/usr/bin/env bash
# Renderiza y registra los task-defs iniciales y crea (o actualiza) los 3
# servicios ECS Fargate enganchados a sus target groups.
# Nota: los despliegues posteriores los hace el pipeline (deploy.yml). Este
# script deja la primera version corriendo.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require; discover_account; discover_network; state_load
: "${RDS_ENDPOINT:?corre 03-rds.sh primero}"
: "${TG_VENTAS:?corre 05-alb.sh primero}"

# Exportar todo lo que usan las plantillas
export PROJECT AWS_REGION LOG_GROUP DB_NAME DB_MASTER_USER ECR_NAMESPACE IMAGE_TAG \
       BACKEND_CPU BACKEND_MEM FRONTEND_CPU FRONTEND_MEM \
       ECR_REGISTRY LABROLE RDS_ENDPOINT ALB_DNS SECRET_PW_ARN

NET="awsvpcConfiguration={subnets=[$SUBNET_A,$SUBNET_B],securityGroups=[$SG_ECS],assignPublicIp=ENABLED}"

deploy_service() { # $1=servicio $2=tg $3=puerto
  local svc="$1" tg="$2" port="$3" family="${PROJECT}-$1" rendered="$HERE/task-defs/$1.json"
  envsubst < "$HERE/task-defs/$1.json.tpl" > "$rendered"
  aws ecs register-task-definition --cli-input-json "file://$rendered" \
    --query 'taskDefinition.taskDefinitionArn' --output text >/dev/null
  log "task-def $family registrada"

  if aws ecs describe-services --cluster "$CLUSTER" --services "$family" \
       --query 'services[?status==`ACTIVE`]' --output text | grep -q .; then
    aws ecs update-service --cluster "$CLUSTER" --service "$family" \
      --task-definition "$family" --health-check-grace-period-seconds 240 >/dev/null
    log "servicio $family actualizado"
  else
    aws ecs create-service --cluster "$CLUSTER" --service-name "$family" \
      --task-definition "$family" --desired-count 1 --launch-type FARGATE \
      --network-configuration "$NET" \
      --load-balancers "targetGroupArn=$tg,containerName=$svc,containerPort=$port" \
      --health-check-grace-period-seconds 240 \
      --query 'service.serviceName' --output text >/dev/null
    log "servicio $family creado"
  fi
}

deploy_service ventas    "$TG_VENTAS" 8080
deploy_service despachos "$TG_DESP"   8081
deploy_service frontend  "$TG_FRONT"  80

log "Servicios desplegados. Front: http://$ALB_DNS"
