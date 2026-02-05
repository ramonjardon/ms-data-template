# ✅ Solución: Error de Locale "es_ES.UTF-8"

## ❌ Problema

```
initdb: error: invalid locale name "es_ES.UTF-8"
initdb: hint: If the locale name is specific to ICU, use --icu-locale.
```

## 🔍 Causa

La imagen oficial de PostgreSQL usa una imagen base mínima (Debian slim) que **no incluye todos los locales por defecto**. El locale `es_ES.UTF-8` no está disponible sin instalación adicional.

## ✅ Solución Aplicada

Cambiado de `es_ES.UTF-8` a `C.UTF-8` que está **siempre disponible** en todas las imágenes de PostgreSQL.

### Cambio en docker-compose.yml

```yaml
# ❌ ANTES (no funciona)
POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --lc-collate=es_ES.UTF-8 --lc-ctype=es_ES.UTF-8"

# ✅ AHORA (funciona)
POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --locale=C.UTF-8"
```

### ¿Qué es C.UTF-8?

- **C.UTF-8** es un locale UTF-8 neutral disponible en todos los sistemas
- Soporta caracteres Unicode (incluyendo español, emojis, etc.)
- Ordenación simple byte a byte (más rápida que locales específicos)
- **Recomendado para aplicaciones modernas**

### ¿Afecta al español?

**No**, puedes seguir usando caracteres españoles (ñ, á, é, etc.):
- ✅ Almacenamiento de texto: Perfecto (UTF-8)
- ✅ Búsquedas: Funciona normal
- ⚠️ Ordenación: Usa orden Unicode (no específico español)
  - Ejemplo: "año" podría ordenarse después de "azo"
  - En práctica, raramente es un problema

### Timezone sigue siendo Europe/Madrid

```yaml
TZ: Europe/Madrid  # ✅ Esto sigue funcionando perfectamente
```

El timezone **no depende del locale** y se maneja por separado.

## 🚀 Reiniciar PostgreSQL

### Opción 1: Script automático

```bash
chmod +x fix-locale.sh
./fix-locale.sh
```

### Opción 2: Comandos manuales

```bash
# 1. Detener y eliminar volumen con error
docker-compose down
docker volume rm ms-data-template_postgres_data

# 2. Iniciar con locale corregido
docker-compose up -d postgres

# 3. Verificar
docker-compose logs -f postgres
```

## 🔍 Verificar Configuración

```bash
# Conectar a PostgreSQL
docker-compose exec postgres psql -U msdata_user -d msdata

# Ver locale actual
SHOW lc_collate;
SHOW lc_ctype;

# Ver timezone
SHOW timezone;
```

Deberías ver:
```
lc_collate  | C.UTF-8
lc_ctype    | C.UTF-8
timezone    | Europe/Madrid
```

## 🎨 Alternativa: Usar Locale Español con Imagen Personalizada

Si **realmente necesitas** ordenación en español, puedes crear un Dockerfile personalizado:

### docker/postgres/Dockerfile

```dockerfile
FROM postgres:17.7

# Instalar locales
RUN apt-get update && \
    apt-get install -y locales && \
    sed -i '/es_ES.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen es_ES.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV LANG es_ES.UTF-8
ENV LANGUAGE es_ES:es
ENV LC_ALL es_ES.UTF-8
```

### docker-compose.yml

```yaml
services:
  postgres:
    build:
      context: ./docker/postgres
      dockerfile: Dockerfile
    image: ms-data-postgres:17.7-es
    # ... resto igual
    environment:
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --locale=es_ES.UTF-8"
```

**Inconvenientes**:
- ⚠️ Requiere build personalizado (más lento)
- ⚠️ Imagen más grande (~50MB extra)
- ⚠️ Ordenación más lenta que C.UTF-8

**Para la mayoría de aplicaciones, C.UTF-8 es la mejor opción.**

## 📊 Comparativa de Locales

| Característica | C.UTF-8 | es_ES.UTF-8 |
|----------------|---------|-------------|
| Disponibilidad | ✅ Siempre | ⚠️ Requiere instalación |
| Velocidad | ✅ Rápido | ⚠️ Más lento |
| Ordenación | Byte a byte | Alfabético español |
| Tamaño imagen | ✅ Mínimo | ⚠️ +50MB |
| Caracteres UTF-8 | ✅ Soporta todos | ✅ Soporta todos |
| Recomendado | ✅ Para apps modernas | ⚠️ Solo si necesitas orden español |

## ✅ Resumen

1. **Cambiado locale** de `es_ES.UTF-8` a `C.UTF-8`
2. **Timezone** sigue siendo `Europe/Madrid`
3. **UTF-8** soporta todos los caracteres españoles
4. **Más simple** y **más rápido**
5. **Funciona** en todas las imágenes PostgreSQL

## 🔧 Ejecutar Ahora

```bash
# Usar el script de corrección
chmod +x fix-locale.sh
./fix-locale.sh
```

o

```bash
# Manual
docker-compose down
docker volume rm ms-data-template_postgres_data
docker-compose up -d postgres
```

¡PostgreSQL debería iniciar correctamente ahora! ✅
