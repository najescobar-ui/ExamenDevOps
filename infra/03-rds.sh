#!/usr/bin/env bash
# Crea el subnet group + la instancia RDS MySQL (privada) y guarda la password
# en Secrets Manager. Espera a que quede disponible.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require; discover_account; discover_network; state_load
: "${SG_RDS:?corre 02-network.sh primero}"

SUBNET_GROUP="${PROJECT}-db-subnets"
DB_ID="${PROJECT}-mysql"

# Subnet group
if ! aws rds describe-db-subnet-groups --db-subnet-group-name "$SUBNET_GROUP" >/dev/null 2>&1; then
  aws rds create-db-subnet-group --db-subnet-group-name "$SUBNET_GROUP" \
    --db-subnet-group-description "Subnets RDS $PROJECT" \
    --subnet-ids "$SUBNET_A" "$SUBNET_B" --query 'DBSubnetGroup.DBSubnetGroupName' --output text
  log "subnet group $SUBNET_GROUP creado"
fi

# Instancia RDS
if aws rds describe-db-instances --db-instance-identifier "$DB_ID" >/dev/null 2>&1; then
  log "RDS $DB_ID ya existe"
else
  DB_PASS="$(openssl rand -hex 16)"
  aws rds create-db-instance \
    --db-instance-identifier "$DB_ID" \
    --db-instance-class "$DB_INSTANCE_CLASS" \
    --engine mysql --engine-version "$DB_ENGINE_VERSION" \
    --allocated-storage "$DB_ALLOCATED_STORAGE" \
    --master-username "$DB_MASTER_USER" --master-user-password "$DB_PASS" \
    --db-name "$DB_NAME" \
    --vpc-security-group-ids "$SG_RDS" --db-subnet-group-name "$SUBNET_GROUP" \
    --no-publicly-accessible --backup-retention-period 0 --no-multi-az \
    --query 'DBInstance.DBInstanceStatus' --output text
  log "RDS $DB_ID lanzada, guardando password en Secrets Manager..."
  if aws secretsmanager describe-secret --secret-id "${PROJECT}-db-password" >/dev/null 2>&1; then
    aws secretsmanager put-secret-value --secret-id "${PROJECT}-db-password" --secret-string "$DB_PASS" >/dev/null
  else
    aws secretsmanager create-secret --name "${PROJECT}-db-password" --secret-string "$DB_PASS" >/dev/null
  fi
fi

log "Esperando a que RDS quede disponible (puede tardar varios minutos)..."
aws rds wait db-instance-available --db-instance-identifier "$DB_ID"

RDS_ENDPOINT="$(aws rds describe-db-instances --db-instance-identifier "$DB_ID" \
  --query 'DBInstances[0].Endpoint.Address' --output text)"
SECRET_PW_ARN="$(aws secretsmanager describe-secret --secret-id "${PROJECT}-db-password" --query ARN --output text)"
state_set RDS_ENDPOINT "$RDS_ENDPOINT"
state_set SECRET_PW_ARN "$SECRET_PW_ARN"
log "RDS disponible en $RDS_ENDPOINT"
