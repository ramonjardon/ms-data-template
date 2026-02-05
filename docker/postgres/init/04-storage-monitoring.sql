-- Script de monitoreo de storage para PostgreSQL
-- Límite objetivo: 8GB

-- Función para verificar tamaño de la base de datos
CREATE OR REPLACE FUNCTION public.check_database_size()
RETURNS TABLE(
    database_name TEXT,
    size_bytes BIGINT,
    size_pretty TEXT,
    limit_gb NUMERIC,
    percent_used NUMERIC,
    status TEXT
) AS $$
DECLARE
    db_size BIGINT;
    limit_bytes BIGINT := 8589934592; -- 8GB en bytes
    pct NUMERIC;
BEGIN
    db_size := pg_database_size(current_database());
    pct := ROUND((db_size::NUMERIC / limit_bytes * 100), 2);

    RETURN QUERY
    SELECT
        current_database()::TEXT,
        db_size,
        pg_size_pretty(db_size),
        8.0::NUMERIC,
        pct,
        CASE
            WHEN pct < 70 THEN '✅ OK'
            WHEN pct < 85 THEN '⚠️ WARNING'
            ELSE '🚨 CRITICAL'
        END;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener tamaño de todas las tablas
CREATE OR REPLACE FUNCTION public.table_sizes()
RETURNS TABLE(
    schema_name TEXT,
    table_name TEXT,
    total_size TEXT,
    table_size TEXT,
    indexes_size TEXT,
    row_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        schemaname::TEXT,
        tablename::TEXT,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)),
        pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)),
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)),
        n_live_tup
    FROM pg_stat_user_tables
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener tamaño por schema
CREATE OR REPLACE FUNCTION public.schema_sizes()
RETURNS TABLE(
    schema_name TEXT,
    total_size TEXT,
    table_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        schemaname::TEXT,
        pg_size_pretty(SUM(pg_total_relation_size(schemaname||'.'||tablename))),
        COUNT(*)
    FROM pg_stat_user_tables
    GROUP BY schemaname
    ORDER BY SUM(pg_total_relation_size(schemaname||'.'||tablename)) DESC;
END;
$$ LANGUAGE plpgsql;

-- Función para limpieza automática cuando se alcanza el límite
CREATE OR REPLACE FUNCTION public.auto_cleanup_storage(
    threshold_percent NUMERIC DEFAULT 85
)
RETURNS TABLE(
    action TEXT,
    details TEXT
) AS $$
DECLARE
    current_size BIGINT;
    limit_bytes BIGINT := 8589934592; -- 8GB
    pct NUMERIC;
    cleaned BOOLEAN := FALSE;
BEGIN
    current_size := pg_database_size(current_database());
    pct := ROUND((current_size::NUMERIC / limit_bytes * 100), 2);

    IF pct >= threshold_percent THEN
        -- Eliminar particiones antiguas de métricas (> 3 meses)
        BEGIN
            PERFORM timeseries.drop_old_partitions('timeseries.metrics', '3 months'::INTERVAL);
            RETURN QUERY SELECT 'CLEANUP'::TEXT, 'Eliminadas particiones antiguas de timeseries.metrics'::TEXT;
            cleaned := TRUE;
        EXCEPTION WHEN OTHERS THEN
            RETURN QUERY SELECT 'ERROR'::TEXT, ('Error limpiando timeseries.metrics: ' || SQLERRM)::TEXT;
        END;

        -- Ejecutar VACUUM
        IF cleaned THEN
            EXECUTE 'VACUUM ANALYZE';
            RETURN QUERY SELECT 'VACUUM'::TEXT, 'VACUUM ANALYZE ejecutado'::TEXT;
        END IF;

        -- Verificar nuevo tamaño
        current_size := pg_database_size(current_database());
        pct := ROUND((current_size::NUMERIC / limit_bytes * 100), 2);
        RETURN QUERY SELECT 'RESULT'::TEXT, format('Nuevo uso: %s%%', pct)::TEXT;
    ELSE
        RETURN QUERY SELECT 'INFO'::TEXT, format('No se requiere limpieza (uso actual: %s%%)', pct)::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Vista para monitoreo rápido
CREATE OR REPLACE VIEW public.storage_monitor AS
SELECT
    database_name,
    size_pretty as current_size,
    limit_gb || ' GB' as size_limit,
    percent_used || '%' as usage_percent,
    status,
    CASE
        WHEN percent_used >= 85 THEN 'Ejecutar limpieza inmediata'
        WHEN percent_used >= 70 THEN 'Planificar limpieza pronto'
        ELSE 'Todo OK'
    END as recommendation
FROM public.check_database_size();

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '✅ Funciones de monitoreo de storage creadas';
    RAISE NOTICE '📊 Usa: SELECT * FROM public.storage_monitor;';
    RAISE NOTICE '📋 Usa: SELECT * FROM public.table_sizes();';
    RAISE NOTICE '🗑️  Usa: SELECT * FROM public.auto_cleanup_storage();';
END $$;
