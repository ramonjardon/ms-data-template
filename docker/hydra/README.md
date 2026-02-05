# Ory Hydra - OAuth2 & OpenID Connect Server

## ✅ OAuth2 Client Credentials Grant Soportado

Ory Hydra **SÍ soporta completamente** el flujo OAuth2 Client Credentials Grant, perfecto para autenticación service-to-service.

## 📋 Especificaciones

- **Versión**: Ory Hydra v2.2.0
- **Puerto Público**: 4444 (OAuth2/OIDC endpoints)
- **Puerto Admin**: 4445 (API de administración)
- **Database**: PostgreSQL (hydra database)
- **Recursos**: 0.5 CPU, 512MB RAM
- **Grant Types**: client_credentials, authorization_code, refresh_token, implicit

## 🔑 Clientes OAuth2 Configurados

### Cliente 1: MS Data Client
```yaml
Client ID: ms-data-client
Client Secret: ms-data-client-secret-change-in-production
Grant Types: client_credentials, authorization_code, refresh_token
Scopes: openid, offline, profile, email
```

### Cliente 2: Web App Client
```yaml
Client ID: web-app-client
Client Secret: web-app-client-secret-change-in-production
Grant Types: client_credentials, authorization_code, refresh_token
Scopes: openid, offline, profile, email
```

### Cliente 3: Test Client
```yaml
Client ID: test-client
Client Secret: test-client-secret
Grant Types: client_credentials, authorization_code, refresh_token
Scopes: openid, offline, profile, email
```

## 🚀 Inicio Rápido

### 1. Iniciar Hydra

```bash
# Iniciar PostgreSQL primero
docker-compose up -d postgres

# Esperar a que esté listo
sleep 10

# Iniciar Hydra (migrará la DB automáticamente)
docker-compose up -d hydra

# Ver logs
docker-compose logs -f hydra
```

### 2. Configurar Clientes OAuth2

```bash
cd docker/hydra
chmod +x setup-clients.sh
./setup-clients.sh
```

### 3. Verificar Estado

```bash
# Healthcheck
curl http://localhost:4445/health/ready

# Listar clientes
docker-compose exec hydra hydra list clients --endpoint http://localhost:4445
```

## 🔐 Client Credentials Flow

### Obtener Access Token

```bash
curl -X POST http://localhost:4444/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=ms-data-client" \
  -d "client_secret=ms-data-client-secret-change-in-production" \
  -d "scope=openid profile email"
```

**Respuesta**:
```json
{
  "access_token": "ory_at_...",
  "expires_in": 3599,
  "scope": "openid profile email",
  "token_type": "bearer"
}
```

### Usar el Token

```bash
# Llamar a tu API con el token
TOKEN="ory_at_..."

curl http://localhost:8080/api/protected/data \
  -H "Authorization: Bearer $TOKEN"
```

## 🔌 Integración con Spring Boot

### application.yml (Resource Server)

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://localhost:4444
          jwk-set-uri: http://localhost:4444/.well-known/jwks.json
```

### application.yml (OAuth2 Client)

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          hydra:
            client-id: ms-data-client
            client-secret: ms-data-client-secret-change-in-production
            authorization-grant-type: client_credentials
            scope:
              - openid
              - profile
              - email
        provider:
          hydra:
            token-uri: http://localhost:4444/oauth2/token
            authorization-uri: http://localhost:4444/oauth2/auth
            jwk-set-uri: http://localhost:4444/.well-known/jwks.json
```

### Java Code (Obtener Token)

```java
@Configuration
public class HttpClientConfig {
    
    @Bean
    public RestTemplate restTemplate(OAuth2AuthorizedClientManager clientManager) {
        RestTemplate restTemplate = new RestTemplate();
        
        restTemplate.getInterceptors().add((request, body, execution) -> {
            OAuth2AuthorizeRequest authorizeRequest = 
                OAuth2AuthorizeRequest
                    .withClientRegistrationId("hydra")
                    .principal("ms-data-client")
                    .build();
            
            OAuth2AuthorizedClient client = clientManager.authorize(authorizeRequest);
            
            if (client != null) {
                request.getHeaders().setBearerAuth(
                    client.getAccessToken().getTokenValue()
                );
            }
            
            return execution.execute(request, body);
        });
        
        return restTemplate;
    }
    
    @Bean
    public OAuth2AuthorizedClientManager authorizedClientManager(
            ClientRegistrationRepository clientRepo,
            OAuth2AuthorizedClientRepository authorizedClientRepo) {
        
        OAuth2AuthorizedClientProvider provider =
            OAuth2AuthorizedClientProviderBuilder.builder()
                .clientCredentials()
                .build();
        
        DefaultOAuth2AuthorizedClientManager manager =
            new DefaultOAuth2AuthorizedClientManager(clientRepo, authorizedClientRepo);
        manager.setAuthorizedClientProvider(provider);
        
        return manager;
    }
}
```

## 📊 Endpoints de Hydra

### Endpoints Públicos (Puerto 4444)

| Endpoint | Descripción |
|----------|-------------|
| `/oauth2/auth` | Authorization endpoint |
| `/oauth2/token` | Token endpoint |
| `/oauth2/revoke` | Token revocation |
| `/oauth2/introspect` | Token introspection |
| `/userinfo` | UserInfo endpoint |
| `/.well-known/openid-configuration` | OpenID Discovery |
| `/.well-known/jwks.json` | JSON Web Key Set |

### Endpoints Admin (Puerto 4445)

| Endpoint | Descripción |
|----------|-------------|
| `/admin/clients` | Gestión de clientes |
| `/health/ready` | Healthcheck |
| `/health/alive` | Liveness check |

## 🔧 Gestión de Clientes

### Crear Cliente

```bash
docker-compose exec hydra hydra create client \
  --endpoint http://localhost:4445 \
  --id my-client \
  --secret my-secret \
  --grant-types client_credentials \
  --scope openid,profile,email
```

### Listar Clientes

```bash
docker-compose exec hydra hydra list clients \
  --endpoint http://localhost:4445
```

### Obtener Cliente

```bash
docker-compose exec hydra hydra get client my-client \
  --endpoint http://localhost:4445
```

### Eliminar Cliente

```bash
docker-compose exec hydra hydra delete client my-client \
  --endpoint http://localhost:4445
```

## 🔐 Introspección de Tokens

```bash
# Verificar si un token es válido
curl -X POST http://localhost:4445/admin/oauth2/introspect \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=ory_at_..."
```

Respuesta:
```json
{
  "active": true,
  "client_id": "ms-data-client",
  "scope": "openid profile email",
  "exp": 1709673600,
  "iat": 1709670000
}
```

## 🔄 Authorization Code Flow

Para aplicaciones web con usuario:

### 1. Redirigir al usuario

```
http://localhost:4444/oauth2/auth?client_id=ms-data-client&redirect_uri=http://localhost:8080/callback&response_type=code&scope=openid+profile+email&state=random-state
```

### 2. Hydra redirige con código

```
http://localhost:8080/callback?code=ory_ac_...&state=random-state
```

### 3. Intercambiar código por token

```bash
curl -X POST http://localhost:4444/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=ory_ac_..." \
  -d "client_id=ms-data-client" \
  -d "client_secret=ms-data-client-secret-change-in-production" \
  -d "redirect_uri=http://localhost:8080/callback"
```

## 📈 Configuración de Producción

### Variables de Entorno Importantes

```yaml
environment:
  # URLs
  URLS_SELF_ISSUER: https://auth.example.com
  
  # Database
  DSN: postgres://user:pass@host:5432/hydra?sslmode=require
  
  # Secrets (CAMBIAR EN PRODUCCIÓN)
  SECRETS_SYSTEM: <random-32-char-string>
  OIDC_SUBJECT_IDENTIFIERS_PAIRWISE_SALT: <random-32-char-string>
  
  # TTL
  TTL_ACCESS_TOKEN: 1h
  TTL_REFRESH_TOKEN: 720h
  
  # Estrategia (jwt u opaque)
  STRATEGIES_ACCESS_TOKEN: jwt
```

### Generar Secrets Seguros

```bash
# Generar secret aleatorio
openssl rand -hex 32
```

## 🆘 Troubleshooting

### Error: "Client authentication failed"

**Causa**: Client ID o Secret incorrectos

**Solución**: Verificar credenciales
```bash
docker-compose exec hydra hydra get client ms-data-client \
  --endpoint http://localhost:4445
```

### Error: "Database not ready"

**Causa**: PostgreSQL no está disponible

**Solución**:
```bash
# Verificar PostgreSQL
docker-compose ps postgres

# Verificar que la DB hydra existe
docker-compose exec postgres psql -U msdata_user -l | grep hydra
```

### Error: "Token invalid"

**Causa**: Token expirado o inválido

**Solución**: Obtener nuevo token
```bash
curl -X POST http://localhost:4445/admin/oauth2/introspect \
  -d "token=<your-token>"
```

## 📚 Referencias

- [Ory Hydra Documentation](https://www.ory.sh/docs/hydra)
- [OAuth 2.0 Client Credentials](https://www.rfc-editor.org/rfc/rfc6749#section-4.4)
- [OpenID Connect](https://openid.net/connect/)

---

**Estado**: ✅ Hydra con soporte completo de Client Credentials Grant
