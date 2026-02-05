# Redis 7.4 con TLS (rediss://)

## 🔐 Configuración

- **Versión**: Redis 7.4 Alpine
- **Protocolo**: rediss:// (Redis con TLS/SSL)
- **Puerto**: 6380 (TLS)
- **Recursos**: 1GB RAM, 1 CPU
- **Persistencia**: AOF (Append Only File)
- **Timezone**: Europe/Madrid

## 🔑 Credenciales

- **Host**: localhost:6380
- **Protocolo**: rediss:// (con TLS)
- **Password**: redis_password
- **Certificados**: ./docker/redis/tls/

## 🚀 Inicio Rápido

### 1. Generar Certificados TLS

**IMPORTANTE**: Debes generar los certificados antes de iniciar Redis.

```bash
cd docker/redis
chmod +x generate-certs.sh
./generate-certs.sh
```

Esto creará:
- `tls/ca.crt` - Certificado CA
- `tls/ca.key` - Clave privada CA
- `tls/redis.crt` - Certificado Redis
- `tls/redis.key` - Clave privada Redis

### 2. Iniciar Redis

```bash
# Desde la raíz del proyecto
docker-compose up -d redis

# Ver logs
docker-compose logs -f redis
```

### 3. Verificar Estado

```bash
# Ver estado del contenedor
docker-compose ps redis

# Ver healthcheck
docker inspect ms-data-redis | grep -A 5 Health
```

## 🔌 Conexión

### Desde el Contenedor (Redis CLI)

```bash
# Conectar con TLS
docker-compose exec redis redis-cli \
  --tls \
  --cert /tls/redis.crt \
  --key /tls/redis.key \
  --cacert /tls/ca.crt \
  -p 6380 \
  -a redis_password

# Probar comandos
127.0.0.1:6380> PING
PONG
127.0.0.1:6380> SET test "Hello Redis"
OK
127.0.0.1:6380> GET test
"Hello Redis"
127.0.0.1:6380> INFO memory
```

### Desde la Aplicación (Spring Boot)

#### application.yml

```yaml
spring:
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

#### Configuración con Lettuce

```java
@Configuration
public class RedisConfig {
    
    @Bean
    public LettuceConnectionFactory redisConnectionFactory() {
        RedisStandaloneConfiguration config = new RedisStandaloneConfiguration();
        config.setHostName("localhost");
        config.setPort(6380);
        config.setPassword("redis_password");
        
        LettuceClientConfiguration clientConfig = LettuceClientConfiguration.builder()
            .useSsl()
            .build();
        
        return new LettuceConnectionFactory(config, clientConfig);
    }
}
```

### URL de Conexión

```
rediss://:redis_password@localhost:6380
```

## 📊 Configuración Actual

### Memoria

- **Max Memory**: 900MB (90% de 1GB)
- **Política de Evicción**: allkeys-lru (elimina las claves menos usadas)
- **Active Defragmentation**: Habilitado

### Persistencia

- **Método**: AOF (Append Only File)
- **Sync**: everysec (cada segundo)
- **Auto-rewrite**: Al 100% de crecimiento o 64MB mínimo

### CPU

- **IO Threads**: 2 (optimizado para 1 CPU)
- **IO Reads**: Habilitado

### Seguridad

- **Comandos deshabilitados**: FLUSHDB, FLUSHALL, CONFIG
- **TLS**: Obligatorio (puerto 0 = sin TLS deshabilitado)
- **Auth**: Requerida (requirepass)

## 🔧 Comandos Útiles

### Monitoreo

```bash
# Ver uso de memoria
docker-compose exec redis redis-cli \
  --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
  -p 6380 -a redis_password \
  INFO memory

# Ver estadísticas
docker-compose exec redis redis-cli \
  --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
  -p 6380 -a redis_password \
  INFO stats

# Ver clientes conectados
docker-compose exec redis redis-cli \
  --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
  -p 6380 -a redis_password \
  CLIENT LIST
```

### Mantenimiento

```bash
# Ver tamaño de la base de datos
docker-compose exec redis redis-cli \
  --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
  -p 6380 -a redis_password \
  DBSIZE

# Guardar snapshot manual (si está habilitado)
docker-compose exec redis redis-cli \
  --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
  -p 6380 -a redis_password \
  BGSAVE

# Ver info de persistencia
docker-compose exec redis redis-cli \
  --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
  -p 6380 -a redis_password \
  INFO persistence
```

## 💾 Backup y Restore

### Backup del AOF

```bash
# El AOF se guarda automáticamente en el volumen
docker run --rm \
  -v ms-data-template_redis_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/redis-backup-$(date +%Y%m%d).tar.gz -C /data .
```

### Restore

```bash
# 1. Detener Redis
docker-compose down redis

# 2. Restaurar datos
docker run --rm \
  -v ms-data-template_redis_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/redis-backup-YYYYMMDD.tar.gz -C /data

# 3. Iniciar Redis
docker-compose up -d redis
```

## 🔐 Certificados TLS

### Regenerar Certificados

```bash
cd docker/redis
rm -rf tls/*
./generate-certs.sh
docker-compose restart redis
```

### Producción

⚠️ **Los certificados incluidos son autofirmados para desarrollo.**

Para producción:
1. Obtén certificados válidos de Let's Encrypt o una CA
2. Reemplaza los archivos en `tls/`
3. Reinicia Redis

## 📈 Optimización

### Ajustar Maxmemory

Editar `redis.conf`:
```conf
maxmemory 900mb  # Ajustar según necesites
```

### Cambiar Política de Evicción

```conf
# Opciones:
# - allkeys-lru: Elimina las menos usadas (recomendado para cache)
# - volatile-lru: Solo elimina claves con TTL
# - allkeys-lfu: Elimina las menos frecuentes
# - volatile-ttl: Elimina las que expiran antes
maxmemory-policy allkeys-lru
```

### Ajustar IO Threads

```conf
# Para 1 CPU: 2-3 threads
# Para 2+ CPU: 4-6 threads
io-threads 2
```

## 🆘 Troubleshooting

### Error de conexión TLS

**Problema**: `Error: SSL_connect returned=1 errno=0`

**Solución**:
```bash
# Verificar que los certificados existen
ls -la docker/redis/tls/

# Regenerar si es necesario
cd docker/redis && ./generate-certs.sh
```

### Redis no inicia

**Ver logs**:
```bash
docker-compose logs redis
```

**Problemas comunes**:
- Certificados no generados → ejecutar `generate-certs.sh`
- Puerto 6380 en uso → cambiar puerto en docker-compose.yml
- Memoria insuficiente → ajustar `maxmemory` en redis.conf

### Verificar Healthcheck

```bash
docker inspect ms-data-redis --format='{{json .State.Health}}' | jq
```

## 📚 Referencias

- [Redis Documentation](https://redis.io/docs/)
- [Redis TLS/SSL](https://redis.io/docs/management/security/encryption/)
- [Redis Configuration](https://redis.io/docs/management/config/)

---

**Protocolo**: `rediss://` (Redis con TLS habilitado) ✅
