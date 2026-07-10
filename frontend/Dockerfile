# syntax=docker/dockerfile:1

### Build stage: genera los estaticos con Vite ###
FROM node:20-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

### Runtime stage: nginx minimo sirviendo la SPA ###
FROM nginx:1.27-alpine AS runtime

# Plantilla de nginx: los upstream de las APIs se inyectan por variables de
# entorno al arrancar (envsubst lo procesa el entrypoint oficial de nginx).
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
