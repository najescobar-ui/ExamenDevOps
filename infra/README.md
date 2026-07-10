# Infraestructura (AWS)

Scripts para aprovisionar la infraestructura del proyecto en AWS con la CLI.
Toda la solución corre en **ECS Fargate** detrás de un **ALB**, con **RDS MySQL**
e imágenes en **ECR**.

## Requisitos

- `aws-cli` v2, `docker` (con buildx) y `jq`.
- Credenciales de AWS resueltas en el entorno. En el lab de AWS Academy las
  credenciales son **temporales** (rotan cada sesión). Se recomienda un perfil
  aislado, por ejemplo:

  ```bash
  export AWS_PROFILE=exm          # perfil con las credenciales del lab
  export AWS_REGION=us-east-1
  ```

## Uso

Aprovisionar todo desde cero:

```bash
cd infra
./provision.sh
```

El orden que ejecuta es:

| Paso | Script | Qué hace |
|------|--------|----------|
| 1 | `01-ecr.sh` | Crea los repos ECR (scan on push) |
| — | `push-images.sh` | Construye y publica las 3 imágenes (linux/amd64) |
| 2 | `02-network.sh` | Security groups con mínimo privilegio (ALB→ECS→RDS) |
| 3 | `03-rds.sh` | Subnet group + RDS MySQL privada + secreto de la password |
| 4 | `04-ecs-base.sh` | Service-linked roles, log group y clúster ECS |
| 5 | `05-alb.sh` | ALB + target groups + listener con routing por path |
| 6 | `06-services.sh` | Registra task-defs y crea/actualiza los 3 servicios |

Cada script es **idempotente**: si el recurso ya existe, lo reutiliza.
Los IDs/ARNs descubiertos o creados se guardan en `state.env` (ignorado por git).

## Detalle relevante

- **Sin valores hardcodeados de cuenta:** el account id, el ARN del `LabRole`, la
  VPC por defecto y las subnets se descubren en tiempo de ejecución.
- **Health checks afinados** (`05-alb.sh`): sano tras 2 chequeos de 15 s y
  `deregistration_delay` de 30 s; los servicios usan `health-check-grace-period`
  de 240 s. Esto evita el *crash-loop* de tasks durante el rollout (Spring Boot
  tarda ~50 s en arrancar).
- **Secretos:** la password de la BD vive en Secrets Manager y se inyecta a las
  tasks como variable `DB_PASSWORD`; nunca queda en el repo.
- Los despliegues del día a día los hace el pipeline (`.github/workflows/deploy.yml`);
  estos scripts son para **crear la infraestructura base** y como documentación.

## Bajar todo

Para no gastar presupuesto del lab:

```bash
./teardown.sh
```
