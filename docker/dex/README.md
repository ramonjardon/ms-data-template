# Dex - OpenID Connect Provider

## ⚠️ IMPORTANTE: Limitación de Client Credentials

**Dex NO soporta nativamente el flujo OAuth2 Client Credentials Grant.**

Si necesitas autenticación service-to-service (client_credentials), considera usar:
- ✅ **Keycloak** - Soporta completamente client_credentials
- ✅ **Spring Authorization Server** - Alternativa nativa de Spring
- ✅ **Auth0 / Okta** - Soluciones SaaS

**Solución temporal con Dex**: Usar **Password Grant** con usuarios estáticos (ver abajo).

📖 **Ver [DEX_CLIENT_CREDENTIALS_LIMITATION.md](./DEX_CLIENT_CREDENTIALS_LIMITATION.md)** para más detalles.

---

## 🔐 OAuth2 / OpenID Connect con Password Grant

Dex configurado para autenticación service-to-service usando OAuth2 Client Credentials Flow.

## 📋 Especificaciones

- **Versión**: Dex v2.41.1
- **Protocolo**: HTTPS (puerto 5556)
- **Issuer**: https://localhost:5556/dex
- **Métricas**: http://localhost:5558
- **Recursos**: 0.5 CPU, 512MB RAM
- **Storage**: Memoria (para desarrollo)

## 🔑 Clientes OAuth2 Configurados

### Cliente 1: MS Data Client
```yaml
Client ID: ms-data-client
Client Secret: ms-data-client-secret-change-in-production
Redirect URIs:
  - http://localhost:8080/callback
  - http://localhost:8080/login/oauth2/code/dex
Grant Types: client_credentials, authorization_code, refresh_token
```

### Cliente 2: Web App Client
```yaml
Client ID: web-app-client
Client Secret: web-app-client-secret-change-in-production
Redirect URIs:
  - http://localhost:3000/callback
Grant Types: client_credentials, authorization_code, refresh_token
```

### Cliente 3: Test Client
```yaml
Client ID: test-client
Client Secret: test-client-secret
Redirect URIs:
  - http://localhost:9090/callback
Grant Types: client_credentials, authorization_code, refresh_token
```

## 🚀 Inicio Rápido

### 1. Generar Certificados TLS

```bash
cd docker/dex
chmod +x generate-certs.sh
./generate-certs.sh
cd ../..
```

### 2. Iniciar Dex

```bash
docker-compose up -d dex

# Ver logs
docker-compose logs -f dex
```

### 3. Verificar Estado

```bash
# Healthcheck
curl http://localhost:5558/healthz

# Métricas
curl http://localhost:5558/metrics
```

## 🔌 Uso del Password Grant Flow

### Obtener Access Token

```bash
# Usando Password Grant (el que Dex SÍ soporta)
curl -X POST https://localhost:5556/dex/token \
  --insecure \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "username=admin@example.com" \
  -d "password=password" \
  -d "client_id=ms-data-client" \
  -d "client_secret=ms-data-client-secret-change-in-production" \
  -d "scope=openid profile email"
```

**Respuesta**:
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "Bearer",
  "expires_in": 86400
}
```

### Usar el Token

```bash
# Llamar a tu API con el token
curl -H "Authorization: Bearer eyJhbGc..." \
  http://localhost:8080/api/protected-resource
```

## 🔧 Integración con Spring Boot

Tu aplicación puede actuar en **DOS roles** con Dex:

### Rol 1: Resource Server (Validar Tokens) 🛡️

**Cuando**: Tu API recibe peticiones con tokens JWT

**Configuración mínima**:
```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://localhost:5556/dex
```

**Uso**:
```java
@GetMapping("/api/data")
public ResponseEntity<Data> getData(@AuthenticationPrincipal Jwt jwt) {
    // Spring valida el token automáticamente
    return ResponseEntity.ok(data);
}
```

### Rol 2: Cliente HTTP para llamar a otras APIs 🔑

**Cuando**: Tu aplicación necesita llamar a OTRAS APIs protegidas

**NO necesitas** `spring.security.oauth2.client.registration` en `application.yml`.

Puedes configurarlo todo en código Java:

```java
@Configuration
public class HttpClientConfig {
    
    @Bean
    public RestTemplate restTemplate() {
        RestTemplate restTemplate = new RestTemplate();
        
        // Interceptor que obtiene token de Dex automáticamente
        restTemplate.getInterceptors().add(new OAuth2ClientCredentialsInterceptor(
            "https://localhost:5556/dex/token",
            "ms-data-client",
            "ms-data-client-secret-change-in-production"
        ));
        
        return restTemplate;
    }
}
```

**O si prefieres externalizar las credenciales** (opcional):

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          dex:
            client-id: ms-data-client
            client-secret: ms-data-client-secret-change-in-production
            authorization-grant-type: client_credentials
        provider:
          dex:
            token-uri: https://localhost:5556/dex/token
```

```java
@Configuration
public class HttpClientConfig {
    
    @Bean
    public RestTemplate restTemplate(OAuth2AuthorizedClientManager clientManager) {
        RestTemplate restTemplate = new RestTemplate();
        restTemplate.getInterceptors().add(oauth2Interceptor(clientManager));
        return restTemplate;
    }
    
    @Bean
    public OAuth2AuthorizedClientManager authorizedClientManager(...) {
        // Configuración del manager
    }
}
```

**📖 Ver [EJEMPLO_COMPLETO_OAUTH2_CLIENT.md](./EJEMPLO_COMPLETO_OAUTH2_CLIENT.md) para ejemplos completos**

---

## 🔧 Ejemplo Rápido (Sin client.registration)

### SecurityConfig.java (Resource Server)

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/api/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .jwtAuthenticationConverter(jwtAuthenticationConverter())
                )
            );
        
        return http.build();
    }
    
    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setJwtGrantedAuthoritiesConverter(new JwtGrantedAuthoritiesConverter());
        return converter;
    }
}
```

### Obtener Token desde Java

```java
@Service
public class DexTokenService {
    
    private final RestTemplate restTemplate;
    
    public String getAccessToken() {
        String tokenUrl = "https://localhost:5556/dex/token";
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        
        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("grant_type", "client_credentials");
        body.add("client_id", "ms-data-client");
        body.add("client_secret", "ms-data-client-secret-change-in-production");
        body.add("scope", "openid profile email");
        
        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(body, headers);
        
        TokenResponse response = restTemplate.postForObject(
            tokenUrl, 
            request, 
            TokenResponse.class
        );
        
        return response.getAccessToken();
    }
    
    @Data
    static class TokenResponse {
        @JsonProperty("access_token")
        private String accessToken;
        
        @JsonProperty("token_type")
        private String tokenType;
        
        @JsonProperty("expires_in")
        private Long expiresIn;
    }
}
```

## 📊 Endpoints de Dex

### OpenID Discovery
```bash
curl https://localhost:5556/dex/.well-known/openid-configuration --insecure
```

### JWK Keys (para validar tokens)
```bash
curl https://localhost:5556/dex/keys --insecure
```

### Token Endpoint
```
POST https://localhost:5556/dex/token
```

### Authorization Endpoint
```
GET https://localhost:5556/dex/auth
```

### UserInfo Endpoint
```
GET https://localhost:5556/dex/userinfo
```

## 👥 Usuarios Estáticos Configurados

Para testing con Authorization Code Flow:

```yaml
Email: admin@example.com
Password: password
UserID: 08a8684b-db88-4b73-90a9-3cd1661f5466

Email: user@example.com
Password: password
UserID: 41331323-6f44-45e6-b3b9-2c4b60c02be5
```

## 🔐 Cambiar Passwords

Para generar un nuevo hash de password:

```bash
# Instalar bcrypt
go install github.com/dexidp/dex/cmd/dexctl@latest

# Generar hash
echo -n "mypassword" | dexctl hash bcrypt
```

O usando htpasswd:
```bash
htpasswd -bnBC 10 "" mypassword | tr -d ':\n'
```

## 📝 Configuración de Clientes

### Añadir Nuevo Cliente

Editar `docker/dex/config.yaml`:

```yaml
staticClients:
  - id: my-new-client
    redirectURIs:
      - 'http://localhost:8081/callback'
    name: 'My New Client'
    secret: my-new-client-secret
    public: false
```

Reiniciar Dex:
```bash
docker-compose restart dex
```

## 🔄 Storage en Producción

Para producción, cambia el storage a PostgreSQL:

```yaml
storage:
  type: postgres
  config:
    host: ms-data-postgres
    port: 5432
    database: dex
    user: dex_user
    password: dex_password
    ssl:
      mode: disable
```

Crear base de datos:
```sql
CREATE DATABASE dex;
CREATE USER dex_user WITH PASSWORD 'dex_password';
GRANT ALL PRIVILEGES ON DATABASE dex TO dex_user;
```

## 🔧 Connectors

### LDAP (ejemplo)

```yaml
connectors:
  - type: ldap
    id: ldap
    name: Corporate LDAP
    config:
      host: ldap.company.com:636
      insecureNoSSL: false
      insecureSkipVerify: false
      bindDN: cn=admin,dc=company,dc=com
      bindPW: admin-password
      userSearch:
        baseDN: ou=users,dc=company,dc=com
        filter: "(objectClass=person)"
        username: uid
        idAttr: uid
        emailAttr: mail
        nameAttr: cn
      groupSearch:
        baseDN: ou=groups,dc=company,dc=com
        filter: "(objectClass=groupOfNames)"
        userAttr: DN
        groupAttr: member
        nameAttr: cn
```

### Google OIDC (ejemplo)

```yaml
connectors:
  - type: oidc
    id: google
    name: Google
    config:
      issuer: https://accounts.google.com
      clientID: your-google-client-id.apps.googleusercontent.com
      clientSecret: your-google-client-secret
      redirectURI: https://dex.yourdomain.com/callback
      scopes:
        - openid
        - profile
        - email
```

## 📈 Métricas y Monitoreo

```bash
# Healthcheck
curl http://localhost:5558/healthz

# Métricas Prometheus
curl http://localhost:5558/metrics
```

**Métricas disponibles**:
- `dex_http_requests_total`
- `dex_http_request_duration_seconds`
- `dex_storage_*`

## 🆘 Troubleshooting

### Error: Cannot load certificate

**Solución**: Generar certificados TLS
```bash
cd docker/dex && ./generate-certs.sh
docker-compose restart dex
```

### Error: Invalid client_id or client_secret

**Verificar configuración**:
```bash
cat docker/dex/config.yaml | grep -A 5 staticClients
```

### Deshabilitar SSL en desarrollo

Para testing, puedes usar `--insecure` o `--insecure-skip-tls-verify`:
```bash
curl --insecure https://localhost:5556/dex/.well-known/openid-configuration
```

### Ver logs detallados

```bash
docker-compose logs -f dex
```

## 🔗 URLs Importantes

- **OpenID Configuration**: https://localhost:5556/dex/.well-known/openid-configuration
- **Token Endpoint**: https://localhost:5556/dex/token
- **Authorization**: https://localhost:5556/dex/auth
- **Keys (JWK)**: https://localhost:5556/dex/keys
- **Healthcheck**: http://localhost:5558/healthz
- **Metrics**: http://localhost:5558/metrics

## 📚 Referencias

- [Dex Documentation](https://dexidp.io/docs/)
- [OAuth2 Client Credentials](https://www.rfc-editor.org/rfc/rfc6749#section-4.4)
- [OpenID Connect](https://openid.net/connect/)

---

**Protocolo**: OAuth2 / OpenID Connect con Client Credentials ✅
