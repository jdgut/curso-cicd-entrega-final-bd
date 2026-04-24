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
- `workflow_dispatch` (ejecucion manual desde la pestaña Actions)

### Variables y secretos requeridos

- Variable `DOCKERHUB_USERNAME`
- Variable `SONAR_HOST_URL`
- Variable `TF_STATE_BUCKET`
- Variable `LAB_ROLE_ARN`
- Variable `VPC_ID`
- Variable `SUBNET_IDS` (formato CSV: `subnet-aaa,subnet-bbb`)
- Variable `POSTGRES_DB`
- Variable `POSTGRES_USER`
- Secreto `DOCKERHUB_TOKEN`
- Secreto `SONAR_TOKEN`
- Secreto `AWS_ACCESS_KEY_ID`
- Secreto `AWS_SECRET_ACCESS_KEY`
- Secreto `AWS_SESSION_TOKEN`
- Secreto `POSTGRES_PASSWORD`

### Credenciales de base de datos usadas en laboratorio

En la configuracion local de Terraform para staging (`infra/staging.tfvars`) se usan estos valores:

- `postgres_db = "movilidad"`
- `postgres_user = "postgres"`
- `postgres_password = "postgres"`

Importante para CI/CD:

- El workflow de GitHub Actions no toma `postgres_password` desde `infra/staging.tfvars`.
- El workflow usa el secreto de repositorio `POSTGRES_PASSWORD`.
- `POSTGRES_PASSWORD` debe existir y tener un valor no vacio, o el deploy falla durante el arranque de PostgreSQL.

### Tags de imagen esperados

- `development` -> `dev`
- `main` -> `latest`
- Los pull requests solo ejecutan validación y no publican imágenes

### Flujo de despliegue configurado (solo base de datos)

El flujo en `.github/workflows/ci-cd.yml` implementa la secuencia:

`build-test-publish`
-> `deploy-tf-staging`
-> `update-service-staging`
-> `test-staging`
-> `deploy-tf-prod`
-> `update-service-prod`
-> `smoke-test-prod`

Comportamiento por rama:

- `development`: ejecuta build, validaciones y publicación de imagen `:dev`.
- `main`: ejecuta build, validaciones, publicación `:latest`, despliegue a staging, pruebas en staging, despliegue a producción y smoke test final.
- `pull_request` hacia `main`: solo validación, sin publicación ni despliegues.

### Que hace cada etapa de despliegue

- `deploy-tf-staging` y `deploy-tf-prod`:
	- Ejecutan `terraform init` con estado remoto en S3.
	- Ejecutan `terraform apply` para actualizar ECS/NLB/EFS y fijar la imagen de Docker publicada.
	- Publican outputs de Terraform (`database_endpoint`, `ecs_cluster_name`, `ecs_service_name`) para jobs posteriores.

- `update-service-staging` y `update-service-prod`:
	- Fuerzan un nuevo deployment del servicio ECS (`aws ecs update-service --force-new-deployment`).
	- Esperan estabilidad del servicio (`aws ecs wait services-stable`).

- `test-staging` y `smoke-test-prod`:
	- Verifican que `runningCount == desiredCount`.
	- Verifican que la task definition desplegada use la imagen esperada.
	- Verifican al menos un target saludable en el target group del NLB.

Nota: el NLB de la base de datos es interno (privado). Por eso las verificaciones en CI se hacen por plano de control de AWS (ECS/ELBv2) y no con conexion TCP directa desde el runner de GitHub.

### Limpieza manual del entorno (reset con Terraform Destroy)

Se configuro un job manual en `.github/workflows/ci-cd.yml` llamado `Manual Cleanup (Terraform Destroy)` para reiniciar entornos bajo demanda.

Como ejecutarlo:

1. Ir a **Actions** en GitHub.
2. Seleccionar el workflow **Database CI/CD**.
3. Click en **Run workflow**.
4. Elegir `target_environment`:
	- `staging`
	- `production`
	- `all` (destruye ambos)
5. Escribir `DESTROY` en `confirm_destroy`.
6. Ejecutar el workflow.

Comportamiento de seguridad:

- Si `confirm_destroy` es distinto de `DESTROY`, el job falla sin destruir recursos.
- Si es correcto, ejecuta `terraform destroy -auto-approve` contra el estado remoto del entorno seleccionado.
- Para `all`, ejecuta destroy secuencialmente en `staging` y luego `production`.

## Ejecución

La base de datos se levanta mediante `docker compose up` desde la raíz.
