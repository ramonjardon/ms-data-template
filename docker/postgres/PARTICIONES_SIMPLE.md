# Guía Simple de Particionamiento Nativo en PostgreSQL

## 🎯 Solución Simple con Imagen Oficial

Esta configuración usa **PostgreSQL 17.7 oficial** sin necesidad de extensiones adicionales como pg_partman. PostgreSQL incluye particionamiento declarativo nativo que es suficiente para la mayoría de casos de uso.

## ✨ Ventajas de Esta Solución

- ✅ **Sin dependencias**: Usa solo la imagen oficial de PostgreSQL
- ✅ **Simple**: No requiere background workers ni configuración compleja
- ✅ **Control total**: Tú decides cuándo crear o eliminar particiones
- ✅ **Funciones helper**: Scripts SQL simples para facilitar la gestión
- ✅ **Compatible**: Funciona con cualquier imagen PostgreSQL 10+

## 🚀 Inicio Rápido

### 1. Iniciar PostgreSQL

```bash
docker-compose up -d postgres
```

### 2. Crear Tabla Particionada

```sql
-- Conectar a la base de datos
docker-compose exec postgres psql -U msdata_user -d msdata

-- Crear tabla con particionamiento por mes
CREATE TABLE timeseries.metrics (
    id BIGSERIAL,
    timestamp TIMESTAMPTZ NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    tags JSONB DEFAULT '{}',
    PRIMARY KEY (timestamp, id)
) PARTITION BY RANGE (timestamp);
```

### 3. Crear Particiones

#### Opción A: Crear Una Partición Mensual

```sql
-- Crear partición para febrero 2026
SELECT timeseries.create_monthly_partition('timeseries.metrics', '2026-02-01'::DATE);
```

#### Opción B: Crear Múltiples Particiones

```sql
-- Crear 12 particiones mensuales desde febrero 2026
SELECT timeseries.create_monthly_partitions(
    'timeseries.metrics',  -- Tabla
    '2026-02-01'::DATE,    -- Fecha inicial
    12                     -- Número de meses
);
```

#### Opción C: Crear Particiones Diarias

```sql
-- Crear partición para un día específico
SELECT timeseries.create_daily_partition('timeseries.logs', '2026-02-05'::DATE);
```

### 4. Insertar y Consultar Datos

```sql
-- Insertar datos (se insertarán automáticamente en la partición correcta)
INSERT INTO timeseries.metrics (timestamp, metric_name, value, tags)
VALUES 
    (NOW(), 'cpu.usage', 45.2, '{"host": "server1"}'),
    (NOW(), 'memory.usage', 8192, '{"host": "server1"}');

-- Consultar datos (PostgreSQL usa automáticamente las particiones apropiadas)
SELECT * FROM timeseries.metrics 
WHERE timestamp >= NOW() - INTERVAL '1 day';
```

### 5. Gestionar Particiones

#### Listar Particiones

```sql
SELECT * FROM timeseries.list_partitions('timeseries.metrics');
```

#### Eliminar Particiones Antiguas

```sql
-- Eliminar particiones de más de 6 meses
SELECT timeseries.drop_old_partitions(
    'timeseries.metrics',
    '6 months'::INTERVAL
);
```

## 📋 Funciones Helper Disponibles

### `timeseries.create_monthly_partition()`
Crea una partición mensual para una fecha específica.

```sql
SELECT timeseries.create_monthly_partition(
    parent_table TEXT,      -- ej: 'timeseries.metrics'
    partition_date DATE     -- ej: '2026-03-01'::DATE
);
```

### `timeseries.create_daily_partition()`
Crea una partición diaria para una fecha específica.

```sql
SELECT timeseries.create_daily_partition(
    parent_table TEXT,      -- ej: 'timeseries.logs'
    partition_date DATE     -- ej: '2026-02-05'::DATE
);
```

### `timeseries.create_monthly_partitions()`
Crea múltiples particiones mensuales a la vez.

```sql
SELECT timeseries.create_monthly_partitions(
    parent_table TEXT,      -- ej: 'timeseries.metrics'
    start_month DATE,       -- ej: '2026-01-01'::DATE
    num_months INT          -- ej: 12 (default: 6)
);
```

### `timeseries.drop_old_partitions()`
Elimina particiones más antiguas que el intervalo especificado.

```sql
SELECT timeseries.drop_old_partitions(
    parent_table TEXT,      -- ej: 'timeseries.metrics'
    older_than INTERVAL     -- ej: '6 months'::INTERVAL (default: 6 months)
);
```

### `timeseries.list_partitions()`
Lista todas las particiones de una tabla con su tamaño y número de filas.

```sql
SELECT * FROM timeseries.list_partitions('timeseries.metrics');
```

## 🔄 Mantenimiento con Cron

Puedes automatizar la gestión de particiones con cron o un scheduler:

### Script de Mantenimiento Mensual

```bash
#!/bin/bash
# maintenance.sh - Ejecutar una vez al mes

# Crear particiones para los próximos 3 meses
docker-compose exec -T postgres psql -U msdata_user -d msdata << EOF
SELECT timeseries.create_monthly_partitions(
    'timeseries.metrics',
    CURRENT_DATE,
    3
);
EOF

# Eliminar particiones de más de 6 meses
docker-compose exec -T postgres psql -U msdata_user -d msdata << EOF
SELECT timeseries.drop_old_partitions(
    'timeseries.metrics',
    '6 months'::INTERVAL
);
EOF
```

Añadir a crontab:
```bash
# Ejecutar el primer día de cada mes a las 2 AM
0 2 1 * * /path/to/maintenance.sh
```

## 💡 Ejemplos Prácticos

### Caso 1: Métricas con Particiones Mensuales

```sql
-- Crear tabla
CREATE TABLE timeseries.server_metrics (
    id BIGSERIAL,
    timestamp TIMESTAMPTZ NOT NULL,
    server_id VARCHAR(50) NOT NULL,
    cpu_usage DOUBLE PRECISION,
    memory_usage BIGINT,
    PRIMARY KEY (timestamp, id)
) PARTITION BY RANGE (timestamp);

-- Crear índices (se heredan en todas las particiones)
CREATE INDEX idx_server_metrics_timestamp ON timeseries.server_metrics USING BRIN (timestamp);
CREATE INDEX idx_server_metrics_server ON timeseries.server_metrics (server_id, timestamp DESC);

-- Crear 12 particiones mensuales
SELECT timeseries.create_monthly_partitions('timeseries.server_metrics', CURRENT_DATE, 12);
```

### Caso 2: Logs con Particiones Diarias

```sql
-- Crear tabla
CREATE TABLE logs.application (
    id BIGSERIAL,
    timestamp TIMESTAMPTZ NOT NULL,
    level VARCHAR(20) NOT NULL,
    message TEXT,
    metadata JSONB,
    PRIMARY KEY (timestamp, id)
) PARTITION BY RANGE (timestamp);

-- Crear índice para búsquedas
CREATE INDEX idx_logs_level ON logs.application (level, timestamp DESC);
CREATE INDEX idx_logs_metadata ON logs.application USING GIN (metadata);

-- Crear particiones para los próximos 30 días
DO $$
BEGIN
    FOR i IN 0..29 LOOP
        PERFORM timeseries.create_daily_partition(
            'logs.application',
            (CURRENT_DATE + (i || ' days')::INTERVAL)::DATE
        );
    END LOOP;
END $$;

-- Política de retención: eliminar logs de más de 7 días
SELECT timeseries.drop_old_partitions('logs.application', '7 days'::INTERVAL);
```

### Caso 3: Eventos con Particiones Semanales

```sql
-- Crear tabla
CREATE TABLE events.user_activity (
    id BIGSERIAL,
    timestamp TIMESTAMPTZ NOT NULL,
    user_id UUID NOT NULL,
    event_type VARCHAR(50),
    data JSONB,
    PRIMARY KEY (timestamp, id)
) PARTITION BY RANGE (timestamp);

-- Para particiones semanales, crear manualmente
CREATE TABLE events.user_activity_2026_w06 
PARTITION OF events.user_activity
FOR VALUES FROM ('2026-02-02') TO ('2026-02-09');

CREATE TABLE events.user_activity_2026_w07 
PARTITION OF events.user_activity
FOR VALUES FROM ('2026-02-09') TO ('2026-02-16');
```

## 📊 Monitoreo y Estadísticas

### Ver Todas las Particiones

```sql
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    (SELECT count(*) FROM only schemaname.tablename) as rows
FROM pg_tables
WHERE schemaname = 'timeseries'
    AND tablename LIKE 'metrics_%'
ORDER BY tablename DESC;
```

### Ver Uso de Índices

```sql
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as scans,
    pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_stat_user_indexes
WHERE schemaname = 'timeseries'
ORDER BY idx_scan DESC;
```

### Plan de Ejecución

```sql
-- Ver cómo PostgreSQL usa las particiones
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM timeseries.metrics
WHERE timestamp >= '2026-02-01' 
  AND timestamp < '2026-03-01';
```

## 🎨 Alternativa: Bitnami PostgreSQL

Si prefieres usar Bitnami, simplemente cambia la imagen en docker-compose.yml:

```yaml
services:
  postgres:
    image: bitnami/postgresql:17
    container_name: ms-data-postgres
    restart: unless-stopped
    
    environment:
      - POSTGRESQL_USERNAME=msdata_user
      - POSTGRESQL_PASSWORD=msdata_password
      - POSTGRESQL_DATABASE=msdata
      - TZ=Europe/Madrid
    
    ports:
      - "5432:5432"
    
    volumes:
      - postgres_data:/bitnami/postgresql
      - ./docker/postgres/init:/docker-entrypoint-initdb.d
```

Las funciones helper funcionarán exactamente igual con Bitnami.

## 🔧 Mejores Prácticas

1. **Pre-crear particiones**: Crea particiones futuras con anticipación (3-6 meses)
2. **Índices en la tabla padre**: Los índices se heredan automáticamente
3. **BRIN para timestamps**: Muy eficiente en espacio para columnas ordenadas
4. **Monitoreo**: Verifica regularmente que las particiones existen para las fechas actuales
5. **Automatización**: Usa cron o scheduler para crear/eliminar particiones automáticamente

## ❓ FAQ

**¿Qué pasa si inserto datos y no existe la partición?**
PostgreSQL dará un error. Debes asegurarte de que las particiones existen antes de insertar.

**¿Puedo usar particionamiento en tablas existentes?**
Sí, pero requiere migración. Es mejor diseñar con particiones desde el inicio.

**¿Cuántas particiones puedo tener?**
PostgreSQL maneja miles de particiones eficientemente, pero 100-500 es un rango típico.

**¿Necesito pg_partman?**
No, para la mayoría de casos estas funciones simples son suficientes. pg_partman es útil si necesitas gestión totalmente automática.

---

**Esta solución simple es perfecta para proyectos que necesitan particionamiento sin complejidad adicional.** 🎉
