#!/usr/bin/env bash
# Prepara la base de ECS: service-linked roles, log group de CloudWatch y cluster.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require

# Service-linked roles (ignorar si ya existen)
aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com >/dev/null 2>&1 || true
aws iam create-service-linked-role --aws-service-name elasticloadbalancing.amazonaws.com >/dev/null 2>&1 || true

# Log group
if ! aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" \
     --query 'logGroups[?logGroupName==`'"$LOG_GROUP"'`]' --output text | grep -q .; then
  aws logs create-log-group --log-group-name "$LOG_GROUP"
  aws logs put-retention-policy --log-group-name "$LOG_GROUP" --retention-in-days 7
  log "log group $LOG_GROUP creado"
fi

# Cluster
if aws ecs describe-clusters --clusters "$CLUSTER" --query 'clusters[?status==`ACTIVE`]' --output text | grep -q .; then
  log "cluster $CLUSTER ya activo"
else
  aws ecs create-cluster --cluster-name "$CLUSTER" --capacity-providers FARGATE \
    --query 'cluster.clusterName' --output text
  log "cluster $CLUSTER creado"
fi
