#!/usr/bin/env bash
# Crea los repositorios ECR (uno por servicio) con escaneo de vulnerabilidades.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require; discover_account

for svc in ventas despachos frontend; do
  repo="${ECR_NAMESPACE}/${svc}"
  if aws ecr describe-repositories --repository-names "$repo" >/dev/null 2>&1; then
    log "ECR $repo ya existe"
  else
    aws ecr create-repository \
      --repository-name "$repo" \
      --image-scanning-configuration scanOnPush=true \
      --image-tag-mutability MUTABLE \
      --query 'repository.repositoryUri' --output text
    log "ECR $repo creado"
  fi
done
