-- Funciones helper para gestión simple de particiones nativas
-- PostgreSQL 17.7 incluye particionamiento declarativo nativo

-- Función para crear partición mensual
CREATE OR REPLACE FUNCTION timeseries.create_monthly_partition(
    parent_table TEXT,
    partition_date DATE
) RETURNS TEXT AS $$
DECLARE
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    partition_name := parent_table || '_' || to_char(partition_date, 'YYYY_MM');
    start_date := date_trunc('month', partition_date);
    end_date := start_date + INTERVAL '1 month';

    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
        partition_name, parent_table, start_date, end_date
    );

    RAISE NOTICE 'Partición creada: % (% a %)', partition_name, start_date, end_date;
    RETURN partition_name;
END;
$$ LANGUAGE plpgsql;

-- Función para crear partición diaria
CREATE OR REPLACE FUNCTION timeseries.create_daily_partition(
    parent_table TEXT,
    partition_date DATE
) RETURNS TEXT AS $$
DECLARE
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    partition_name := parent_table || '_' || to_char(partition_date, 'YYYY_MM_DD');
    start_date := date_trunc('day', partition_date);
    end_date := start_date + INTERVAL '1 day';

    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
        partition_name, parent_table, start_date, end_date
    );

    RAISE NOTICE 'Partición creada: % (% a %)', partition_name, start_date, end_date;
    RETURN partition_name;
END;
$$ LANGUAGE plpgsql;

-- Función para crear múltiples particiones mensuales
CREATE OR REPLACE FUNCTION timeseries.create_monthly_partitions(
    parent_table TEXT,
    start_month DATE,
    num_months INT DEFAULT 6
) RETURNS TABLE(partition_name TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT timeseries.create_monthly_partition(
        parent_table,
        (start_month + (i || ' months')::INTERVAL)::DATE
    )
    FROM generate_series(0, num_months - 1) i;
END;
$$ LANGUAGE plpgsql;

-- Función para eliminar particiones antiguas
CREATE OR REPLACE FUNCTION timeseries.drop_old_partitions(
    parent_table TEXT,
    older_than INTERVAL DEFAULT '6 months'
) RETURNS TABLE(dropped_partition TEXT) AS $$
DECLARE
    partition_rec RECORD;
    cutoff_date DATE;
BEGIN
    cutoff_date := CURRENT_DATE - older_than;

    FOR partition_rec IN
        SELECT
            c.relname,
            pg_get_expr(c.relpartbound, c.oid) as partition_bound
        FROM pg_class c
        JOIN pg_inherits i ON i.inhrelid = c.oid
        JOIN pg_class parent ON i.inhparent = parent.oid
        WHERE parent.relname = split_part(parent_table, '.', 2)
            AND c.relkind = 'r'
    LOOP
        -- Extraer fecha de la partición del nombre
        BEGIN
            DECLARE
                date_part TEXT;
                part_date DATE;
            BEGIN
                date_part := substring(partition_rec.relname from '\d{4}_\d{2}(_\d{2})?$');

                IF date_part IS NOT NULL THEN
                    IF length(date_part) = 7 THEN
                        part_date := to_date(date_part, 'YYYY_MM');
                    ELSIF length(date_part) = 10 THEN
                        part_date := to_date(date_part, 'YYYY_MM_DD');
                    END IF;

                    IF part_date < cutoff_date THEN
                        EXECUTE format('DROP TABLE IF EXISTS %I.%I',
                            split_part(parent_table, '.', 1),
                            partition_rec.relname);
                        dropped_partition := partition_rec.relname;
                        RAISE NOTICE 'Partición eliminada: %', dropped_partition;
                        RETURN NEXT;
                    END IF;
                END IF;
            END;
        EXCEPTION WHEN OTHERS THEN
            CONTINUE;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Función para listar particiones
CREATE OR REPLACE FUNCTION timeseries.list_partitions(parent_table TEXT)
RETURNS TABLE(
    partition_name TEXT,
    partition_size TEXT,
    row_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.relname::TEXT,
        pg_size_pretty(pg_total_relation_size(c.oid)),
        c.reltuples::BIGINT
    FROM pg_class c
    JOIN pg_inherits i ON i.inhrelid = c.oid
    JOIN pg_class parent ON i.inhparent = parent.oid
    WHERE parent.relname = split_part(parent_table, '.', 2)
        AND c.relkind = 'r'
    ORDER BY c.relname;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    RAISE NOTICE '✅ Funciones de particionamiento nativo configuradas';
    RAISE NOTICE '📅 Usa timeseries.create_monthly_partition() para crear particiones mensuales';
    RAISE NOTICE '📅 Usa timeseries.create_daily_partition() para crear particiones diarias';
    RAISE NOTICE '🗑️  Usa timeseries.drop_old_partitions() para eliminar particiones antiguas';
    RAISE NOTICE '📋 Usa timeseries.list_partitions() para listar particiones';
END $$;
