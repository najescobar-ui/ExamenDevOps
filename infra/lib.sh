#!/usr/bin/env bash
# Funciones y variables comunes a los scripts de infraestructura.
# Se espera que las credenciales de AWS ya esten resueltas en el entorno
# (por ejemplo: export AWS_PROFILE=exm) y que exista jq.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="$HERE/state.env"

# Cargar parametros
# shellcheck source=/dev/null
source "$HERE/config.env"
export AWS_DEFAULT_REGION="$AWS_REGION"

# --- estado persistente (IDs/ARNs descubiertos o creados) ---
state_set() {
  local key="$1" val="$2"
  touch "$STATE"
  grep -v "^${key}=" "$STATE" > "$STATE.tmp" 2>/dev/null || true
  mv "$STATE.tmp" "$STATE"
  echo "${key}=${val}" >> "$STATE"
}
state_load() { [ -f "$STATE" ] && source "$STATE" || true; }

log()  { printf '\033[1;34m[infra]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

require() {
  command -v aws >/dev/null || die "falta aws-cli"
  command -v jq  >/dev/null || die "falta jq"
  aws sts get-caller-identity >/dev/null 2>&1 || die "credenciales AWS no validas (revisa AWS_PROFILE / el token del lab)"
}

# Datos de cuenta y red (se descubren dinamicamente, no se hardcodean)
discover_account() {
  ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
  ECR_REGISTRY="${ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"
  LABROLE="$(aws iam get-role --role-name LabRole --query 'Role.Arn' --output text)"
  state_set ACCOUNT "$ACCOUNT"
  state_set LABROLE "$LABROLE"
}

discover_network() {
  VPC="$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)"
  # Una subnet publica por AZ (sort -u por AZ) y tomamos dos AZ distintas.
  local rows
  rows="$(aws ec2 describe-subnets \
    --filters Name=vpc-id,Values="$VPC" Name=map-public-ip-on-launch,Values=true \
    --query 'Subnets[].[AvailabilityZone,SubnetId]' --output text | sort -u -k1,1)"
  SUBNET_A="$(echo "$rows" | awk 'NR==1{print $2}')"
  SUBNET_B="$(echo "$rows" | awk 'NR==2{print $2}')"
  [ -n "$SUBNET_A" ] && [ -n "$SUBNET_B" ] || die "no se encontraron 2 subnets publicas en AZ distintas"
  state_set VPC "$VPC"
  state_set SUBNET_A "$SUBNET_A"
  state_set SUBNET_B "$SUBNET_B"
}

# Devuelve el GroupId de un SG por nombre (vacio si no existe)
sg_id() {
  aws ec2 describe-security-groups \
    --filters Name=group-name,Values="$1" Name=vpc-id,Values="$VPC" \
    --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null | grep -v '^None$' || true
}
