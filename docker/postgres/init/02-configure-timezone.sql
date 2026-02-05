-- Configuración permanente del timezone para PostgreSQL
-- Este script establece Europe/Madrid como timezone por defecto

ALTER DATABASE msdata SET timezone TO 'Europe/Madrid';

-- Verificar que el timezone está configurado correctamente
DO $$
DECLARE
    current_tz TEXT;
BEGIN
    SELECT current_setting('timezone') INTO current_tz;
    RAISE NOTICE 'Timezone configurado: %', current_tz;
END $$;
