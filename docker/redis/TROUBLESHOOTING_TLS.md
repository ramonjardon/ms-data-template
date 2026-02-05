# ✅ Solución: Error de Certificados TLS en Redis

## ❌ Error

```
Failed to load certificate: /tls/redis.crt: error:80000002:system library::No such file or directory
Failed to configure TLS. Check logs for more info.
```

## 🔍 Causa

Los certificados TLS no se han generado. Redis con TLS requiere certificados para funcionar.

## ✅ Solución

### Generar Certificados

```bash
# Opción 1: Usar el script automático
cd docker/redis
chmod +x generate-certs.sh
./generate-certs.sh
cd ../..

# Opción 2: Usar el script start-all.sh (genera automáticamente)
chmod +x start-all.sh
./start-all.sh

# Opción 3: Usar el script start-redis.sh
chmod +x start-redis.sh
./start-redis.sh
```

### Reiniciar Redis

```bash
docker-compose restart redis

# Verificar logs
docker-compose logs redis | tail -5
```

Deberías ver:
```
✅ Ready to accept connections tls
```

### Verificar Conexión

```bash
docker-compose exec redis redis-cli \
  --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
  -p 6380 -a redis_password ping
```

Debería responder:
```
PONG
```

## 📁 Certificados Generados

Los certificados se crean en `docker/redis/tls/`:

```
docker/redis/tls/
├── ca.crt       # Certificado CA
├── ca.key       # Clave privada CA (no compartir)
├── redis.crt    # Certificado Redis
└── redis.key    # Clave privada Redis (no compartir)
```

## 🔐 Seguridad de Certificados

Los certificados generados son **autofirmados** para desarrollo/testing.

### ⚠️ Para Producción

1. **Obtener certificados válidos** de Let's Encrypt o una CA
2. **Reemplazar** los archivos en `docker/redis/tls/`
3. **Reiniciar** Redis: `docker-compose restart redis`

### Let's Encrypt (ejemplo)

```bash
# Obtener certificados con certbot
certbot certonly --standalone -d redis.tudominio.com

# Copiar certificados
cp /etc/letsencrypt/live/redis.tudominio.com/fullchain.pem docker/redis/tls/redis.crt
cp /etc/letsencrypt/live/redis.tudominio.com/privkey.pem docker/redis/tls/redis.key
cp /etc/letsencrypt/live/redis.tudominio.com/chain.pem docker/redis/tls/ca.crt

# Reiniciar
docker-compose restart redis
```

## 🔄 Regenerar Certificados

Si necesitas nuevos certificados:

```bash
# 1. Eliminar certificados existentes
rm -rf docker/redis/tls/*.crt docker/redis/tls/*.key

# 2. Regenerar
cd docker/redis
./generate-certs.sh
cd ../..

# 3. Reiniciar Redis
docker-compose restart redis
```

## ✅ Checklist de Verificación

- [ ] Certificados generados (`ls docker/redis/tls/`)
- [ ] Redis iniciado (`docker-compose ps redis`)
- [ ] Logs sin errores (`docker-compose logs redis | tail -10`)
- [ ] Conexión exitosa (comando `ping` responde `PONG`)
- [ ] Healthcheck OK (`docker inspect ms-data-redis | grep Health`)

## 🆘 Problemas Comunes

### El script generate-certs.sh falla

**Causa**: No tienes OpenSSL instalado

**Solución**:
```bash
# macOS
brew install openssl

# Ubuntu/Debian
sudo apt-get install openssl

# Alpine
apk add openssl
```

### Permisos denegados en certificados

**Causa**: Permisos incorrectos en los archivos

**Solución**:
```bash
chmod 644 docker/redis/tls/ca.crt docker/redis/tls/redis.crt
chmod 600 docker/redis/tls/ca.key docker/redis/tls/redis.key
docker-compose restart redis
```

### Redis sigue sin iniciar con TLS

**Verificar configuración**:
```bash
# Ver configuración de Redis
docker-compose exec redis cat /usr/local/etc/redis/redis.conf | grep -E "tls-|port"

# Debería mostrar:
# tls-port 6380
# port 0
# tls-cert-file /tls/redis.crt
# tls-key-file /tls/redis.key
# tls-ca-cert-file /tls/ca.crt
```

## 📚 Referencias

- [Redis TLS Documentation](https://redis.io/docs/management/security/encryption/)
- [OpenSSL Certificates](https://www.openssl.org/docs/man1.1.1/man1/openssl-req.html)

---

**Estado Esperado**: Redis iniciado con `Ready to accept connections tls` ✅
