-- Script de inicialización para PostgreSQL 17.7
-- Este script se ejecuta automáticamente al crear el contenedor

-- Crear extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Extensiones para particiones (nativas de PostgreSQL)
CREATE EXTENSION IF NOT EXISTS "btree_gist";  -- Índices avanzados para rangos y particiones

-- Extensiones para timeseries
CREATE EXTENSION IF NOT EXISTS "btree_gin";   -- Índices optimizados para consultas de tiempo
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";  -- Estadísticas de consultas

-- Configuración de timezone
SET timezone = 'Europe/Madrid';

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE 'Base de datos msdata inicializada correctamente';
    RAISE NOTICE 'Extensiones instaladas: uuid-ossp, pgcrypto, btree_gist, btree_gin, pg_stat_statements';
    RAISE NOTICE 'PostgreSQL 17.7 incluye soporte nativo para particionamiento declarativo';
END $$;
