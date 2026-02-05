# 🔧 Corrección del Error de Volumen Docker

## ❌ Problema Original

Error al iniciar PostgreSQL:
```
failed to populate volume: error while mounting volume 
failed to mount local volume: mount ./docker/volumes/postgres
flags: 0x1000, data: size=8G: no such file or directory
```

## 🔍 Causa

El `docker-compose.yml` estaba configurado con un volumen bind mount con opciones no soportadas:

```yaml
volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind,size=8G  # ← Esta opción no es válida
      device: ./docker/volumes/postgres  # ← El directorio no existía
```

Problemas:
1. La opción `size=8G` no es soportada en volúmenes bind mount estándar
2. El directorio `./docker/volumes/postgres` no existía
3. Este tipo de configuración requiere permisos especiales

## ✅ Solución Aplicada

Cambiado a **volumen gestionado por Docker** (más simple y confiable):

```yaml
volumes:
  postgres_data:
    driver: local
    # Volumen gestionado por Docker
    # Los datos se almacenan en: /var/lib/docker/volumes/ms-data-template_postgres_data
```

## 🎯 Ventajas de la Solución

| Característica | Bind Mount (❌ anterior) | Volumen Docker (✅ actual) |
|----------------|--------------------------|---------------------------|
| Configuración | Compleja | Simple |
| Permisos | Problemático | Gestionado por Docker |
| Límite de tamaño | No soportado directamente | Se gestiona a nivel de disco |
| Portabilidad | Depende del filesystem | Portable |
| Backups | Manual | `docker volume` commands |
| Compatibilidad | Limitada | Universal |

## 📊 Gestión del Volumen

### Ver información del volumen

```bash
# Listar volúmenes
docker volume ls

# Inspeccionar el volumen de PostgreSQL
docker volume inspect ms-data-template_postgres_data

# Ver tamaño del volumen
docker system df -v
```

### Backup del volumen

```bash
# Backup
docker run --rm \
  -v ms-data-template_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-backup.tar.gz -C /data .

# Restore
docker run --rm \
  -v ms-data-template_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/postgres-backup.tar.gz -C /data
```

### Limpiar volumen (si necesitas empezar de cero)

```bash
# Detener PostgreSQL
docker-compose down

# Eliminar el volumen
docker volume rm ms-data-template_postgres_data

# Iniciar de nuevo (creará volumen limpio)
docker-compose up -d postgres
```

## 🚀 Iniciar PostgreSQL

Ahora puedes iniciar PostgreSQL sin problemas:

```bash
# Iniciar
docker-compose up -d postgres

# Ver logs
docker-compose logs -f postgres

# Verificar que está corriendo
docker-compose ps
```

## 📁 Ubicación de los Datos

Los datos de PostgreSQL se almacenan en:
```
/var/lib/docker/volumes/ms-data-template_postgres_data/_data
```

Puedes verlo con:
```bash
docker volume inspect ms-data-template_postgres_data | grep Mountpoint
```

## 💾 Límite de Almacenamiento (Opcional)

Si necesitas limitar el tamaño del volumen, hay varias opciones:

### Opción 1: A nivel de sistema de archivos
Si Docker está en una partición con límite, el volumen respetará ese límite.

### Opción 2: Docker Desktop (macOS/Windows)
Configura el límite en Docker Desktop → Preferences → Resources → Disk image size

### Opción 3: Monitoreo manual
```bash
# Ver tamaño actual
docker system df -v | grep postgres

# Script de monitoreo
#!/bin/bash
SIZE=$(docker system df -v | grep ms-data-template_postgres_data | awk '{print $3}')
echo "Tamaño actual del volumen PostgreSQL: $SIZE"
```

### Opción 4: Política de retención en PostgreSQL
La mejor práctica es gestionar el tamaño a nivel de aplicación:

```sql
-- Eliminar particiones antiguas automáticamente
SELECT timeseries.drop_old_partitions('timeseries.metrics', '6 months'::INTERVAL);
```

## 🔄 Migración desde Bind Mount (si tenías datos)

Si tenías datos en `./docker/volumes/postgres`, puedes migrarlos:

```bash
# 1. Asegúrate de que PostgreSQL está detenido
docker-compose down

# 2. Crear el nuevo volumen
docker volume create ms-data-template_postgres_data

# 3. Copiar datos (si existían)
docker run --rm \
  -v $(pwd)/docker/volumes/postgres:/source \
  -v ms-data-template_postgres_data:/dest \
  alpine sh -c "cp -a /source/. /dest/"

# 4. Iniciar PostgreSQL
docker-compose up -d postgres
```

## ✅ Verificación

Después de iniciar, verifica que todo funciona:

```bash
# 1. Ver logs
docker-compose logs postgres

# 2. Conectar a PostgreSQL
docker-compose exec postgres psql -U msdata_user -d msdata

# 3. Verificar extensiones
docker-compose exec postgres psql -U msdata_user -d msdata -c "SELECT extname FROM pg_extension;"

# 4. Verificar timezone
docker-compose exec postgres psql -U msdata_user -d msdata -c "SHOW timezone;"
```

## 📝 Resumen

✅ **Problema resuelto**: Cambiado de bind mount con opciones no soportadas a volumen Docker gestionado

✅ **Más simple**: No requiere crear directorios manualmente

✅ **Más confiable**: Docker gestiona permisos y almacenamiento

✅ **Portable**: Funciona en cualquier sistema con Docker

---

**Ahora puedes iniciar PostgreSQL con:**
```bash
docker-compose up -d postgres
```

¡Todo debería funcionar correctamente! 🎉
