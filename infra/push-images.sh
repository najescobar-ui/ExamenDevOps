#!/usr/bin/env bash
# Construye y publica las 3 imagenes en ECR (para bootstrap local, sin pipeline).
# Las imagenes se construyen para linux/amd64 (Fargate x86_64).
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require; discover_account
ROOT="$(cd "$HERE/.." && pwd)"

aws ecr get-login-password | docker login --username AWS --password-stdin "$ECR_REGISTRY"

build_push() { # $1=servicio $2=contexto
  local repo="${ECR_REGISTRY}/${ECR_NAMESPACE}/$1"
  docker buildx build --platform linux/amd64 \
    -t "${repo}:${IMAGE_TAG}" --push "$ROOT/$2"
  log "imagen $1 publicada en $repo:${IMAGE_TAG}"
}

build_push ventas    backend/ventas
build_push despachos backend/despachos
build_push frontend  frontend
