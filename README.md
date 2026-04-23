# Base de Datos - PostgreSQL

Contenedor dedicado para persistencia histórica de desplazamientos y auditoría.

## Características

- PostgreSQL 16
- Volumen persistente `pgdata`
- Script de inicialización simple en `init/01-init.sql`
- Sin migraciones gestionadas

## Variables de entorno

- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`

## CI/CD

El repositorio incluye un flujo de GitHub Actions para validar la imagen de PostgreSQL y publicar artefactos Docker según la rama.

### Triggers

- `push` en `development`
- `push` en `main`
- `pull_request` hacia `main`

### Variables y secretos requeridos

- Variable `DOCKERHUB_USERNAME`
- Variable `SONAR_HOST_URL`
- Secreto `DOCKERHUB_TOKEN`
- Secreto `SONAR_TOKEN`

### Tags de imagen esperados

- `development` -> `dev`
- `main` -> `latest`
- Los pull requests solo ejecutan validación y no publican imágenes

## Ejecución

La base de datos se levanta mediante `docker compose up` desde la raíz.
