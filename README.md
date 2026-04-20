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

## Ejecución

La base de datos se levanta mediante `docker compose up` desde la raíz.
