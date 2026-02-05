# ms-data-template
Ejemplo de microservicio para capa de acceso a datos

## 🐘 PostgreSQL 17.7

Este proyecto incluye PostgreSQL 17.7 configurado con:
- ✅ Timezone: Europe/Madrid
- ✅ Extensiones para particionamiento y timeseries
- ✅ Funciones helper para gestión simple de particiones
- ✅ Healthcheck automático
- ✅ Recursos limitados (512MB-1GB RAM, 0.5-1 CPU)

### Inicio Rápido

```bash
# Iniciar PostgreSQL
docker-compose up -d postgres

# O usar el script helper
chmod +x start-postgres.sh
./start-postgres.sh

# Conectar
docker-compose exec postgres psql -U msdata_user -d msdata

# Ver logs
docker-compose logs -f postgres
```

### Credenciales

- **Host**: localhost:5432
- **Database**: msdata
- **Usuario**: msdata_user
- **Contraseña**: msdata_password

### Documentación

- **[docker/postgres/README.md](docker/postgres/README.md)** - Información general
- **[docker/postgres/PARTICIONES_SIMPLE.md](docker/postgres/PARTICIONES_SIMPLE.md)** - Guía de particionamiento (RECOMENDADO)
- **[docker/postgres/SOLUCION_VOLUMEN.md](docker/postgres/SOLUCION_VOLUMEN.md)** - Solución al error de volumen

### Ejemplo de Uso con Particiones

```sql
-- Crear tabla particionada
CREATE TABLE timeseries.metrics (
    id BIGSERIAL,
    timestamp TIMESTAMPTZ NOT NULL,
    metric_name VARCHAR(100),
    value DOUBLE PRECISION,
    PRIMARY KEY (timestamp, id)
) PARTITION BY RANGE (timestamp);

-- Crear 6 particiones mensuales
SELECT timeseries.create_monthly_partitions('timeseries.metrics', CURRENT_DATE, 6);

-- Insertar datos
INSERT INTO timeseries.metrics (timestamp, metric_name, value)
VALUES (NOW(), 'cpu.usage', 75.5);

-- Consultar
SELECT * FROM timeseries.metrics 
WHERE timestamp >= NOW() - INTERVAL '1 day';
```

Consulta la [documentación completa](docker/postgres/PARTICIONES_SIMPLE.md) para más ejemplos.

## 🔐 Redis 7.4 con TLS (rediss://)

Este proyecto incluye Redis 7.4 configurado con:
- ✅ Protocolo: rediss:// (Redis con TLS/SSL)
- ✅ Puerto: 6380 (TLS)
- ✅ Recursos: 1GB RAM, 1 CPU
- ✅ Persistencia: AOF (Append Only File)
- ✅ Política de evicción: allkeys-lru
- ✅ Timezone: Europe/Madrid

### Inicio Rápido

```bash
# 1. Generar certificados TLS (primera vez)
cd docker/redis
chmod +x generate-certs.sh
./generate-certs.sh
cd ../..

# 2. Iniciar Redis
docker-compose up -d redis

# O usar el script helper
chmod +x start-redis.sh
./start-redis.sh

# 3. Conectar
docker-compose exec redis redis-cli \
  --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
  -p 6380 -a redis_password
```

### Credenciales

- **Host**: localhost:6380
- **Protocolo**: rediss:// (con TLS)
- **Password**: redis_password
- **URL**: `rediss://:redis_password@localhost:6380`

### Documentación

- **[docker/redis/README.md](docker/redis/README.md)** - Configuración completa y comandos útiles

### Ejemplo de Uso en Spring Boot

```yaml
spring:
  data:
    redis:
      host: localhost
      port: 6380
      password: redis_password
      ssl:
        enabled: true
```

## 🔐 Dex - OAuth2 / OpenID Connect

Este proyecto incluye Dex configurado para autenticación OAuth2 Client Credentials:
- ✅ Protocolo: OAuth2 / OpenID Connect
- ✅ Puerto: 5556 (HTTPS)
- ✅ Client Credentials Flow
- ✅ Recursos: 0.5 CPU, 512MB RAM
- ✅ 3 clientes OAuth2 preconfigurados

### Inicio Rápido

```bash
# 1. Generar certificados TLS (primera vez)
cd docker/dex
chmod +x generate-certs.sh
./generate-certs.sh
cd ../..

# 2. Iniciar Dex
docker-compose up -d dex

# O usar el script helper
chmod +x start-dex.sh
./start-dex.sh
```

### Clientes OAuth2 Configurados

**Cliente 1: MS Data Client**
```
Client ID: ms-data-client
Client Secret: ms-data-client-secret-change-in-production
```

**Cliente 2: Web App Client**
```
Client ID: web-app-client  
Client Secret: web-app-client-secret-change-in-production
```

**Cliente 3: Test Client**
```
Client ID: test-client
Client Secret: test-client-secret
```

### Obtener Access Token

```bash
curl -X POST https://localhost:5556/dex/token \
  --insecure \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=ms-data-client" \
  -d "client_secret=ms-data-client-secret-change-in-production" \
  -d "scope=openid profile email"
```

### Documentación

- **[docker/dex/README.md](docker/dex/README.md)** - Configuración completa, integración con Spring Boot

### Ejemplo en Spring Boot

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://localhost:5556/dex
      client:
        registration:
          dex:
            client-id: ms-data-client
            client-secret: ms-data-client-secret-change-in-production
            authorization-grant-type: client_credentials
            scope:
              - openid
              - profile
              - email
```

