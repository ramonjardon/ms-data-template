# PostgreSQL 17.7 - Configuración Simple con Particionamiento Nativo

## 🎯 Solución Simple con Imagen Oficial

Esta configuración usa la **imagen oficial de PostgreSQL 17.7** sin modificaciones. Incluye funciones helper para facilitar la gestión de particiones nativas de PostgreSQL.

## Especificaciones

- **Versión**: PostgreSQL 17.7
- **Imagen**: postgres:17.7 (oficial)
- **Recursos**:
  - CPU: 1 core (límite), 0.5 core (reservado)
  - RAM: 1GB (límite), 512MB (reservado)
  - Storage: 8GB (volumen persistente)
- **Timezone**: Europe/Madrid

## Credenciales

- **Base de datos**: `msdata`
- **Usuario**: `msdata_user`
- **Contraseña**: `msdata_password`
- **Puerto**: `5432`

## 🚀 Inicio Rápido

```bash
# Iniciar PostgreSQL
docker-compose up -d postgres

# Ver logs
docker-compose logs -f postgres

# Conectar
docker-compose exec postgres psql -U msdata_user -d msdata
```

## 📦 Extensiones Instaladas

- **uuid-ossp** - Generación de UUIDs
- **pgcrypto** - Funciones criptográficas
- **btree_gist** - Índices avanzados para rangos y particiones
- **btree_gin** - Índices optimizados para consultas de tiempo
- **pg_stat_statements** - Estadísticas de consultas

## 📚 Documentación

### 🎯 RECOMENDADO - Particionamiento Simple
**[PARTICIONES_SIMPLE.md](./PARTICIONES_SIMPLE.md)** - Guía completa con:
- Uso de la imagen oficial (sin pg_partman)
- Funciones helper incluidas
- Ejemplos prácticos
- Alternativa con Bitnami
- Automatización con cron

### Otras Guías
- **[TIMESERIES.md](./TIMESERIES.md)** - Ejemplos de timeseries y mejores prácticas

## 🔧 Funciones Helper Incluidas

### Crear Particiones

```sql
-- Partición mensual única
SELECT timeseries.create_monthly_partition('timeseries.metrics', '2026-02-01'::DATE);

-- Múltiples particiones mensuales
SELECT timeseries.create_monthly_partitions('timeseries.metrics', CURRENT_DATE, 6);

-- Partición diaria
SELECT timeseries.create_daily_partition('timeseries.logs', CURRENT_DATE);
```

### Gestionar Particiones

```sql
-- Listar particiones
SELECT * FROM timeseries.list_partitions('timeseries.metrics');

-- Eliminar particiones antiguas (> 6 meses)
SELECT timeseries.drop_old_partitions('timeseries.metrics', '6 months'::INTERVAL);
```

### Monitoreo de Storage (Límite 8GB)

```sql
-- Ver uso actual de almacenamiento
SELECT * FROM public.storage_monitor;

-- Ver tamaño de todas las tablas
SELECT * FROM public.table_sizes();

-- Limpieza automática si supera 85%
SELECT * FROM public.auto_cleanup_storage(85);
```

**Scripts automatizados**:
```bash
# Monitorear storage
./monitor-storage.sh

# Mantenimiento semanal

```

Ver **[LIMITAR_STORAGE_8GB.md](./LIMITAR_STORAGE_8GB.md)** para configuración completa.

## 💡 Ejemplo Completo

```sql
-- 1. Crear tabla particionada
CREATE TABLE timeseries.metrics (
    id BIGSERIAL,
    timestamp TIMESTAMPTZ NOT NULL,
    metric_name VARCHAR(100),
    value DOUBLE PRECISION,
    PRIMARY KEY (timestamp, id)
) PARTITION BY RANGE (timestamp);

-- 2. Crear particiones para 6 meses
SELECT timeseries.create_monthly_partitions('timeseries.metrics', CURRENT_DATE, 6);

-- 3. Insertar datos
INSERT INTO timeseries.metrics (timestamp, metric_name, value)
VALUES (NOW(), 'cpu.usage', 75.5);

-- 4. Consultar
SELECT * FROM timeseries.metrics WHERE timestamp >= NOW() - INTERVAL '1 day';
```

## 🔄 Alternativa: Bitnami PostgreSQL

Para usar Bitnami en lugar de la imagen oficial, cambia en `docker-compose.yml`:

```yaml
services:
  postgres:
    image: bitnami/postgresql:17
    environment:
      - POSTGRESQL_USERNAME=msdata_user
      - POSTGRESQL_PASSWORD=msdata_password
      - POSTGRESQL_DATABASE=msdata
```

Las funciones helper funcionan igual en ambas imágenes.

## 🛠️ Comandos Útiles

```bash
# Backup
docker-compose exec postgres pg_dump -U msdata_user msdata > backup.sql

# Restore
cat backup.sql | docker-compose exec -T postgres psql -U msdata_user -d msdata

# Verificar extensiones
docker-compose exec postgres psql -U msdata_user -d msdata -c "SELECT extname FROM pg_extension;"

# Verificar timezone
docker-compose exec postgres psql -U msdata_user -d msdata -c "SHOW timezone;"
```

## ❓ ¿Necesitas pg_partman?

Si necesitas gestión **totalmente automática** de particiones (background worker que crea/elimina particiones automáticamente), consulta:
- **[PG_PARTMAN.md](./PG_PARTMAN.md)** - Guía de pg_partman
- **[README_PARTMAN.md](./README_PARTMAN.md)** - Configuración con Dockerfile personalizado

**Nota**: La mayoría de proyectos no necesitan pg_partman. Las funciones helper incluidas son suficientes y más simples.
