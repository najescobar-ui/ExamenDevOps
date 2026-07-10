#!/usr/bin/env bash
# Crea los security groups con minimo privilegio:
#   alb-sg : 80 desde internet
#   ecs-sg : 80/8080/8081 solo desde alb-sg
#   rds-sg : 3306 solo desde ecs-sg
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require; discover_account; discover_network

ensure_sg() { # $1=nombre $2=descripcion -> imprime GroupId
  local id; id="$(sg_id "$1")"
  if [ -z "$id" ]; then
    id="$(aws ec2 create-security-group --group-name "$1" --description "$2" \
      --vpc-id "$VPC" --query GroupId --output text)"
  fi
  echo "$id"
}

# Autoriza una regla ignorando el error si ya existe
authorize() { aws ec2 authorize-security-group-ingress "$@" >/dev/null 2>&1 || true; }

SG_ALB="$(ensure_sg "${PROJECT}-alb-sg" "ALB publico")"
SG_ECS="$(ensure_sg "${PROJECT}-ecs-sg" "ECS tasks")"
SG_RDS="$(ensure_sg "${PROJECT}-rds-sg" "RDS MySQL")"

authorize --group-id "$SG_ALB" --protocol tcp --port 80   --cidr 0.0.0.0/0
for p in 80 8080 8081; do
  authorize --group-id "$SG_ECS" --protocol tcp --port "$p" --source-group "$SG_ALB"
done
authorize --group-id "$SG_RDS" --protocol tcp --port 3306 --source-group "$SG_ECS"

state_set SG_ALB "$SG_ALB"; state_set SG_ECS "$SG_ECS"; state_set SG_RDS "$SG_RDS"
log "Security groups listos: alb=$SG_ALB ecs=$SG_ECS rds=$SG_RDS"
