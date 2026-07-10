# ExamenDevOps

Evaluación Final Transversal — **ISY1101 Introducción a Herramientas DevOps**.

Automatización del ciclo **CI/CD** de una plataforma compuesta por **frontend + backend + base de datos relacional**, contenerizada con Docker, con pipeline en **GitHub Actions** y despliegue orquestado en la nube (ECS/EKS).

## Arquitectura (resumen)

- **Frontend:** _por definir_
- **Backend:** _por definir_
- **Base de datos:** relacional (_por definir_)
- **Contenedores:** Docker (multietapa, imágenes minimalistas) + `docker-compose` para entorno local
- **CI/CD:** GitHub Actions (build → test → push de imagen → deploy)
- **Registro de imágenes:** Amazon ECR / Docker Hub
- **Nube:** AWS (VPC, ECS/EKS, IAM, CloudWatch)

## Estrategia de ramas

Flujo de 3 niveles vía Pull Request:

```
feature/*  →  dev  (integración)  →  main  (estable / entregable)
```

- Todo cambio entra por una rama de trabajo y sube vía **Pull Request**. Nunca se commitea directo a `main`.
- **feature → dev:** cuando la unidad de trabajo está completa y verificada.
- **dev → main:** promoción de release, solo cuando `dev` está estable y con CI en verde. `main` siempre debe quedar desplegable.

## Estructura del repositorio

```
.
├── frontend/          # aplicación de frontend
├── backend/           # aplicación de backend (API)
├── docker-compose.yml # orquestación local
├── .github/workflows/ # pipelines de CI/CD
└── docs/              # informe, diagramas y evidencias
```

## Equipo

- Najeeb Escobar Pérez
- _compañero/a de dupla_
