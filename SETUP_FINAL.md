# ✅ Redis con TLS (rediss://) - Configuración Completada

## 🎉 Estado Actual

Ambos servicios están corriendo exitosamente:

```
✅ PostgreSQL 17.7  - Puerto 5432 (healthy)
✅ Redis 7.4 TLS    - Puerto 6380 (healthy)
```

## 🔐 Redis con TLS Configurado

El error de certificados TLS se ha resuelto. Redis ahora está funcionando correctamente con el protocolo `rediss://`.

### Logs de Redis

```
✅ Ready to accept connections tls
```

### Test de Conexión

```bash
$ docker-compose exec redis redis-cli --tls \
    --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
    -p 6380 -a redis_password ping

PONG  ✅
```

## 📋 Servicios Disponibles

### PostgreSQL 17.7

```yaml
Host: localhost:5432
User: msdata_user
Pass: msdata_password
DB:   msdata
```

**Conexión**:
```bash
docker-compose exec postgres psql -U msdata_user -d msdata
```

### Redis 7.4 con TLS

```yaml
Protocol: rediss://
Host:     localhost:6380
Pass:     redis_password
URL:      rediss://:redis_password@localhost:6380
```

**Conexión**:
```bash
docker-compose exec redis redis-cli \
  --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
  -p 6380 -a redis_password
```

## 🚀 Scripts Disponibles

### Iniciar Todo
```bash
chmod +x start-all.sh
./start-all.sh
```
- ✅ Verifica certificados TLS (genera si no existen)
- ✅ Inicia PostgreSQL y Redis
- ✅ Verifica que ambos estén healthy
- ✅ Muestra información de conexión

### Iniciar Solo PostgreSQL
```bash
chmod +x start-postgres.sh
./start-postgres.sh
```

### Iniciar Solo Redis
```bash
chmod +x start-redis.sh
./start-redis.sh
```
- ✅ Genera certificados TLS si no existen
- ✅ Inicia Redis
- ✅ Verifica conexión

### Monitorear Storage PostgreSQL
```bash
chmod +x monitor-storage.sh
./monitor-storage.sh
```

## 📁 Estructura de Archivos

```
ms-data-template/
├── docker-compose.yml          # Configuración de servicios
├── start-all.sh               # ⭐ Inicia todo
├── start-postgres.sh          # Inicia PostgreSQL
├── start-redis.sh             # Inicia Redis
├── monitor-storage.sh         # Monitor storage PostgreSQL
├── fix-locale.sh              # Fix locale PostgreSQL
│
├── docker/
│   ├── postgres/
│   │   ├── README.md          # Guía PostgreSQL
│   │   ├── PARTICIONES_SIMPLE.md
│   │   ├── LIMITAR_STORAGE_8GB.md
│   │   ├── SOLUCION_LOCALE.md
│   │   └── init/
│   │       ├── 01-init.sql
│   │       ├── 02-configure-timezone.sql
│   │       ├── 03-partition-helpers.sql
│   │       └── 04-storage-monitoring.sql
│   │
│   └── redis/
│       ├── README.md           # Guía Redis
│       ├── TROUBLESHOOTING_TLS.md  # ⭐ Solución errores TLS
│       ├── redis.conf          # Configuración Redis
│       ├── generate-certs.sh   # Genera certificados TLS
│       └── tls/
│           ├── ca.crt          # Certificado CA
│           ├── ca.key          # Clave CA
│           ├── redis.crt       # Certificado Redis
│           └── redis.key       # Clave Redis
│
└── README.md                   # Documentación principal
```

## 🔧 Recursos Configurados

### PostgreSQL
- CPU: 0.5-1 core
- RAM: 512MB-1GB
- Storage: Gestionado con límite de 8GB
- Timezone: Europe/Madrid
- Locale: C.UTF-8

### Redis
- CPU: 0.5-1 core
- RAM: 512MB-1GB
- Max Memory: 900MB (allkeys-lru)
- Persistencia: AOF (everysec)
- Timezone: Europe/Madrid
- TLS: Obligatorio (puerto 6380)

## 📊 Comandos Útiles

### Ver Estado
```bash
docker-compose ps
```

### Ver Logs
```bash
# Todos los servicios
docker-compose logs -f

# Solo PostgreSQL
docker-compose logs -f postgres

# Solo Redis
docker-compose logs -f redis
```

### Detener Servicios
```bash
# Detener todos
docker-compose down

# Detener solo uno
docker-compose stop postgres
docker-compose stop redis
```

### Reiniciar Servicios
```bash
# Reiniciar todos
docker-compose restart

# Reiniciar solo uno
docker-compose restart postgres
docker-compose restart redis
```

## 🔐 Certificados TLS

### Ubicación
```
docker/redis/tls/
├── ca.crt       # Certificado CA
├── ca.key       # Clave privada CA
├── redis.crt    # Certificado Redis
└── redis.key    # Clave privada Redis
```

### Regenerar
```bash
cd docker/redis
./generate-certs.sh
docker-compose restart redis
```

### ⚠️ Producción
Los certificados actuales son **autofirmados** para desarrollo.

Para producción:
1. Obtén certificados válidos (Let's Encrypt, etc.)
2. Reemplaza los archivos en `docker/redis/tls/`
3. Reinicia Redis

## 🔗 Integración en Spring Boot

### application.yml

```yaml
spring:
  # PostgreSQL
  datasource:
    url: jdbc:postgresql://localhost:5432/msdata
    username: msdata_user
    password: msdata_password
    driver-class-name: org.postgresql.Driver
  
  # Redis con TLS
  data:
    redis:
      host: localhost
      port: 6380
      password: redis_password
      ssl:
        enabled: true
      timeout: 2000ms
      lettuce:
        pool:
          max-active: 8
          max-idle: 8
          min-idle: 2
```

### Dependencies (pom.xml)

```xml
<!-- PostgreSQL -->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
</dependency>

<!-- Redis -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>

<!-- Lettuce (cliente Redis) -->
<dependency>
    <groupId>io.lettuce</groupId>
    <artifactId>lettuce-core</artifactId>
</dependency>
```

## 📚 Documentación

### Principal
- **[README.md](../../README.md)** - Inicio rápido

### PostgreSQL
- **[docker/postgres/README.md](../postgres/README.md)**
- **[docker/postgres/PARTICIONES_SIMPLE.md](../postgres/PARTICIONES_SIMPLE.md)**
- **[docker/postgres/LIMITAR_STORAGE_8GB.md](../postgres/LIMITAR_STORAGE_8GB.md)**

### Redis
- **[docker/redis/README.md](README.md)**
- **[docker/redis/TROUBLESHOOTING_TLS.md](TROUBLESHOOTING_TLS.md)** ⭐

## ✅ Checklist Final

- [x] PostgreSQL 17.7 corriendo (puerto 5432)
- [x] Redis 7.4 con TLS corriendo (puerto 6380)
- [x] Certificados TLS generados
- [x] Healthchecks OK en ambos servicios
- [x] Conexiones verificadas (PostgreSQL y Redis)
- [x] Scripts de inicio disponibles
- [x] Documentación completa

## 🎉 ¡Todo Listo!

Los servicios están correctamente configurados y funcionando:

```bash
# Iniciar todo
./start-all.sh

# Ver estado
docker-compose ps

# Conectar a PostgreSQL
docker-compose exec postgres psql -U msdata_user -d msdata

# Conectar a Redis
docker-compose exec redis redis-cli \
  --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
  -p 6380 -a redis_password
```

**¡Disfruta de tu stack de datos!** 🚀
