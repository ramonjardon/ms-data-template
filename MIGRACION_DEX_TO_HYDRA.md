# ✅ Migración Completada: Dex → Ory Hydra

## 🎯 Cambios Realizados

### 1. Docker Compose
- ❌ **Eliminado**: Dex (no soporta client_credentials)
- ✅ **Añadido**: Ory Hydra v2.2.0 (soporte completo de OAuth2)

### 2. Configuración

#### docker-compose.yml
```yaml
hydra:
  image: oryd/hydra:v2.2.0
  ports:
    - "4444:4444"  # Puerto público OAuth2
    - "4445:4445"  # Puerto admin
  environment:
    URLS_SELF_ISSUER: http://localhost:4444
    DSN: postgres://msdata_user:msdata_password@ms-data-postgres:5432/hydra
```

#### application.yml (ms-data)
```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: ${OAUTH2_ISSUER_URI:http://localhost:4444}
          jwk-set-uri: ${OAUTH2_JWK_SET_URI:http://localhost:4444/.well-known/jwks.json}
```

### 3. Base de Datos
- ✅ Creado: `05-hydra-db.sql` (crea DB hydra)
- ✅ Hydra migrará automáticamente las tablas al iniciar

### 4. Scripts
- ✅ `setup-clients.sh`: Configura los 3 clientes OAuth2

## 🚀 Pasos Siguientes

### 1. Iniciar Servicios

```bash
# 1. Iniciar PostgreSQL
docker-compose up -d postgres

# 2. Esperar unos segundos
sleep 10

# 3. Iniciar Hydra
docker-compose up -d hydra

# 4. Ver logs
docker-compose logs -f hydra
```

### 2. Configurar Clientes OAuth2

```bash
# Una vez Hydra esté listo (después de ~30 segundos)
cd docker/hydra
chmod +x setup-clients.sh
./setup-clients.sh
```

### 3. Probar Client Credentials

```bash
# Obtener token
curl -X POST http://localhost:4444/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=ms-data-client" \
  -d "client_secret=ms-data-client-secret-change-in-production" \
  -d "scope=openid profile email"
```

**Respuesta esperada**:
```json
{
  "access_token": "ory_at_...",
  "expires_in": 3599,
  "scope": "openid profile email",
  "token_type": "bearer"
}
```

### 4. Iniciar Microservicio

```bash
# Iniciar el microservicio ms-data
docker-compose up -d ms-data

# O localmente
./mvnw spring-boot:run
```

### 5. Probar API Protegida

```bash
# Obtener token
TOKEN=$(curl -s -X POST http://localhost:4444/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=ms-data-client" \
  -d "client_secret=ms-data-client-secret-change-in-production" \
  -d "scope=openid" | jq -r '.access_token')

# Llamar a API protegida
curl http://localhost:8080/api/protected/data \
  -H "Authorization: Bearer $TOKEN"
```

## 📊 Comparativa

| Característica | Dex | Hydra |
|----------------|-----|-------|
| **Client Credentials** | ❌ No | ✅ Sí |
| **Authorization Code** | ✅ Sí | ✅ Sí |
| **Implicit** | ✅ Sí | ✅ Sí |
| **Password Grant** | ✅ Sí | ✅ Sí |
| **Refresh Token** | ✅ Sí | ✅ Sí |
| **Token Introspection** | ❌ No | ✅ Sí |
| **Token Revocation** | ❌ No | ✅ Sí |
| **Admin API** | ❌ No | ✅ Sí |
| **Database Support** | Limitado | ✅ PostgreSQL, MySQL |
| **Producción Ready** | ⚠️ Limitado | ✅ Sí |

## 📁 Archivos Nuevos

```
docker/
├── hydra/
│   ├── README.md              # Documentación completa
│   └── setup-clients.sh       # Script de configuración
├── postgres/
│   └── init/
│       └── 05-hydra-db.sql    # Crear DB hydra
```

## 📁 Archivos Actualizados

```
docker-compose.yml             # Dex → Hydra
application.yml                # URLs de Hydra
```

## 🔑 Clientes OAuth2 Configurados

| Cliente | Client ID | Grant Types |
|---------|-----------|-------------|
| **MS Data** | ms-data-client | client_credentials, authorization_code, refresh_token |
| **Web App** | web-app-client | client_credentials, authorization_code, refresh_token |
| **Test** | test-client | client_credentials, authorization_code, refresh_token |

## ✅ Ventajas de Hydra

1. ✅ **Soporte completo de Client Credentials** - Autenticación service-to-service
2. ✅ **API de Admin** - Gestión programática de clientes
3. ✅ **Token Introspection** - Validar tokens
4. ✅ **Token Revocation** - Invalidar tokens
5. ✅ **Production Ready** - Usado por empresas grandes
6. ✅ **Database Persistence** - PostgreSQL, MySQL
7. ✅ **Escalable** - Diseñado para alta disponibilidad
8. ✅ **Open Source** - Apache 2.0 License

## 📚 Documentación

- **[docker/hydra/README.md](docker/hydra/README.md)** - Guía completa de Hydra
- **[OAUTH2_RESOURCE_SERVER.md](OAUTH2_RESOURCE_SERVER.md)** - Configuración del Resource Server

---

**¡Migración completada! Ahora tienes soporte completo de OAuth2 Client Credentials Grant!** 🎉
