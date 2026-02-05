# Límite de Storage de 8GB para PostgreSQL

## 🎯 Opciones para Limitar el Storage a 8GB

### Opción 1: A Nivel de PostgreSQL (RECOMENDADO)

La forma más práctica es gestionar el tamaño desde PostgreSQL usando políticas de retención automática.

#### Configuración en PostgreSQL

```sql
-- 1. Crear función para monitorear tamaño de la base de datos
CREATE OR REPLACE FUNCTION public.check_database_size()
RETURNS TABLE(
    database_name TEXT,
    size_bytes BIGINT,
    size_pretty TEXT,
    limit_gb NUMERIC,
    percent_used NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        current_database()::TEXT,
        pg_database_size(current_database()),
        pg_size_pretty(pg_database_size(current_database())),
        8.0 as limit_gb,
        ROUND((pg_database_size(current_database()) / (8.0 * 1024 * 1024 * 1024) * 100)::NUMERIC, 2)
    ;
END;
$$ LANGUAGE plpgsql;

-- 2. Ver uso actual
SELECT * FROM public.check_database_size();

-- 3. Configurar retención automática de particiones (6 meses)
SELECT timeseries.drop_old_partitions('timeseries.metrics', '6 months'::INTERVAL);

-- 4. VACUUM para liberar espacio
VACUUM FULL ANALYZE;
```

#### Script de Mantenimiento Automático

```bash
#!/bin/bash
# maintenance-storage.sh

echo "🗑️ Limpiando particiones antiguas..."

docker-compose exec -T postgres psql -U msdata_user -d msdata << 'EOF'
-- Eliminar particiones antiguas
SELECT timeseries.drop_old_partitions('timeseries.metrics', '6 months'::INTERVAL);
SELECT timeseries.drop_old_partitions('logs.application', '7 days'::INTERVAL);

-- Liberar espacio
VACUUM FULL ANALYZE;

-- Mostrar tamaño actual
SELECT * FROM public.check_database_size();
EOF

echo "✅ Mantenimiento completado"
```

**Cron**: Ejecutar semanalmente
```bash
0 3 * * 0 /path/to/maintenance-storage.sh
```

---

### Opción 2: Docker Volume con Límite (Linux con device mapper)

**⚠️ Solo funciona en Linux con device mapper**

#### docker-compose.yml

```yaml
volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: size=8G
      device: tmpfs
```

**Limitación**: Esto usa tmpfs (memoria RAM), no es persistente.

---

### Opción 3: Loop Device con Límite (Linux Avanzado)

Crear un archivo de 8GB como dispositivo de loop:

```bash
# 1. Crear archivo de 8GB
sudo dd if=/dev/zero of=/var/lib/postgres-volume.img bs=1M count=8192

# 2. Formatear como ext4
sudo mkfs.ext4 /var/lib/postgres-volume.img

# 3. Montar
sudo mkdir -p /mnt/postgres-volume
sudo mount -o loop /var/lib/postgres-volume.img /mnt/postgres-volume
sudo chown -R 999:999 /mnt/postgres-volume  # Usuario postgres en Docker

# 4. Usar en docker-compose
```

```yaml
volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /mnt/postgres-volume
```

**Inconveniente**: Requiere permisos de root y configuración manual.

---

### Opción 4: Docker Desktop (macOS/Windows)

#### Configuración Global

1. Abrir Docker Desktop
2. Settings → Resources → Advanced
3. Disk image maximum size: configurar según necesites
4. Apply & Restart

**Limitación**: Es global para todos los contenedores.

---

### Opción 5: Monitoring + Alertas (RECOMENDADO para Producción)

Implementar monitoreo y alertas cuando se acerque al límite.

#### Script de Monitoreo

```bash
#!/bin/bash
# monitor-storage.sh

LIMIT_BYTES=$((8 * 1024 * 1024 * 1024))  # 8GB en bytes
THRESHOLD=85  # Alerta al 85%

SIZE_BYTES=$(docker-compose exec -T postgres psql -U msdata_user -d msdata -t -c "SELECT pg_database_size(current_database());" | tr -d ' ')

PERCENT=$((SIZE_BYTES * 100 / LIMIT_BYTES))

echo "📊 Uso de almacenamiento PostgreSQL:"
echo "   Tamaño actual: $(numfmt --to=iec-i --suffix=B $SIZE_BYTES)"
echo "   Límite: 8GB"
echo "   Porcentaje: ${PERCENT}%"

if [ $PERCENT -ge $THRESHOLD ]; then
    echo "⚠️  ALERTA: Uso de almacenamiento superior al ${THRESHOLD}%"
    echo "   Ejecutando limpieza automática..."
    
    # Ejecutar limpieza
    docker-compose exec -T postgres psql -U msdata_user -d msdata << 'EOF'
SELECT timeseries.drop_old_partitions('timeseries.metrics', '3 months'::INTERVAL);
VACUUM FULL ANALYZE;
EOF
    
    echo "✅ Limpieza completada"
fi
```

**Cron**: Ejecutar diariamente
```bash
0 2 * * * /path/to/monitor-storage.sh
```

---

### Opción 6: ZFS/LVM Quota (Linux Avanzado)

Si usas ZFS o LVM, puedes establecer quotas:

#### ZFS
```bash
# Crear dataset con quota
sudo zfs create -o quota=8G tank/postgres
sudo zfs set compression=lz4 tank/postgres

# Montar en Docker
```

#### LVM
```bash
# Crear volumen lógico de 8GB
sudo lvcreate -L 8G -n postgres_volume vg0
sudo mkfs.ext4 /dev/vg0/postgres_volume
```

---

## 🎯 Solución RECOMENDADA para tu Caso

### Configuración Híbrida (PostgreSQL + Monitoreo)

#### 1. Actualizar docker-compose.yml (sin cambios de storage)

El actual está bien. Los límites se gestionan a nivel de aplicación.

#### 2. Crear función de monitoreo en PostgreSQL

```sql
-- Añadir a: docker/postgres/init/04-storage-monitoring.sql
```

#### 3. Script de mantenimiento automático

Ver scripts arriba: `maintenance-storage.sh` y `monitor-storage.sh`

#### 4. Política de retención agresiva

```sql
-- Para limitar a 8GB, usa retenciones cortas:

-- Métricas: 3-6 meses
SELECT timeseries.drop_old_partitions('timeseries.metrics', '3 months'::INTERVAL);

-- Logs: 7-30 días
SELECT timeseries.drop_old_partitions('logs.application', '7 days'::INTERVAL);

-- Eventos: 1-3 meses
SELECT timeseries.drop_old_partitions('events.user_activity', '1 month'::INTERVAL);
```

---

## 📊 Tabla Comparativa

| Método | Complejidad | Efectividad | Portabilidad | Recomendado |
|--------|-------------|-------------|--------------|-------------|
| PostgreSQL Retención | ⭐ Baja | ⭐⭐⭐⭐⭐ | ✅ Multiplataforma | ✅ SÍ |
| Monitoreo + Alertas | ⭐⭐ Media | ⭐⭐⭐⭐ | ✅ Multiplataforma | ✅ SÍ |
| Docker Desktop Limit | ⭐ Baja | ⭐⭐ | ⚠️ Mac/Win solo | ⚠️ Global |
| Loop Device | ⭐⭐⭐⭐ Alta | ⭐⭐⭐⭐⭐ | ❌ Solo Linux | ⚠️ Complejo |
| ZFS/LVM | ⭐⭐⭐⭐⭐ Muy Alta | ⭐⭐⭐⭐⭐ | ❌ Solo Linux | ⚠️ Avanzado |

---

## 🚀 Implementación Rápida

Voy a crear los archivos necesarios para la solución recomendada:

1. **Función de monitoreo en PostgreSQL**
2. **Scripts de mantenimiento y monitoreo**
3. **Documentación de configuración**

---

## 💡 Estimación de Datos

Para estimar cuánto tiempo de datos cabe en 8GB:

```sql
-- Ver tamaño promedio por fila
SELECT 
    schemaname || '.' || tablename as tabla,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as tamaño,
    n_live_tup as filas,
    CASE 
        WHEN n_live_tup > 0 
        THEN pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)::bigint / n_live_tup)
        ELSE '0 bytes'
    END as bytes_por_fila
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

**Ejemplo**:
- Si cada fila pesa 200 bytes
- 8GB = 8,589,934,592 bytes
- Capacidad: ~42 millones de filas
- Con 10,000 inserts/día: ~11.5 años de datos

Ajusta la retención según tu tasa de inserción.

---

## ✅ Resumen

**Para limitar PostgreSQL a 8GB de forma efectiva y portable:**

1. ✅ Usa políticas de retención en PostgreSQL (funciones `drop_old_partitions`)
2. ✅ Implementa monitoreo automático del tamaño
3. ✅ Ejecuta VACUUM FULL periódicamente
4. ✅ Configura alertas cuando llegue al 85%
5. ✅ Automatiza con cron/scheduler

**No requiere cambios en docker-compose.yml** ✨

Voy a crear los archivos necesarios ahora...
