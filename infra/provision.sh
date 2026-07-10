#!/usr/bin/env bash
# Aprovisiona toda la infraestructura desde cero, en orden.
# Requisitos: aws-cli con credenciales validas (export AWS_PROFILE=exm), docker y jq.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">> 1/6  ECR"           && bash "$HERE/01-ecr.sh"
echo ">> ..   Imagenes"      && bash "$HERE/push-images.sh"
echo ">> 2/6  Red (SGs)"     && bash "$HERE/02-network.sh"
echo ">> 3/6  RDS MySQL"     && bash "$HERE/03-rds.sh"
echo ">> 4/6  ECS base"      && bash "$HERE/04-ecs-base.sh"
echo ">> 5/6  ALB"           && bash "$HERE/05-alb.sh"
echo ">> 6/6  Servicios"     && bash "$HERE/06-services.sh"

echo
echo "Listo. La app queda disponible en el DNS del ALB (ver infra/state.env)."
