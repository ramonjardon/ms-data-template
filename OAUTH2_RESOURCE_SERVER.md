# OAuth2 Resource Server - Configuración

## ✅ Configuración Completada

El microservicio `ms-data-template` está configurado como **OAuth2 Resource Server** para validar tokens JWT emitidos por Dex.

## 📋 Archivos Configurados

### 1. pom.xml
- ✅ `spring-boot-starter-oauth2-resource-server`
- ✅ `spring-boot-starter-security`

### 2. application.yml
```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: ${OAUTH2_ISSUER_URI:https://localhost:5556/dex}
          jwk-set-uri: ${OAUTH2_JWK_SET_URI:https://localhost:5556/dex/keys}
```

**Variables de entorno**:
- `OAUTH2_ISSUER_URI`: URL del issuer de Dex (default: https://localhost:5556/dex)
- `OAUTH2_JWK_SET_URI`: URL del JWK Set de Dex (default: https://localhost:5556/dex/keys)

### 3. docker-compose.yml
```yaml
services:
  ms-data:
    environment:
      OAUTH2_ISSUER_URI: https://ms-data-dex:5556/dex
      OAUTH2_JWK_SET_URI: https://ms-data-dex:5556/dex/keys
```

### 4. SecurityConfig.java
- ✅ Configuración de endpoints públicos y protegidos
- ✅ Validación automática de tokens JWT
- ✅ Extracción de roles/grupos del token
- ✅ Sesiones stateless (sin estado)

## 🔐 Cómo Funciona

### 1. Cliente obtiene token de Dex

```bash
curl -X POST https://localhost:5556/dex/token \
  --insecure \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=ms-data-client" \
  -d "client_secret=ms-data-client-secret-change-in-production" \
  -d "scope=openid profile email"
```

Respuesta:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 86400
}
```

### 2. Cliente llama a la API con el token

```bash
# Endpoint público (sin token)
curl http://localhost:8080/api/public/health

# Endpoint protegido (con token)
curl http://localhost:8080/api/protected/data \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIs..."
```

### 3. Spring Security valida el token automáticamente

- ✅ Verifica la firma con las claves JWK de Dex
- ✅ Valida el issuer
- ✅ Valida la expiración
- ✅ Extrae claims (sub, email, groups, etc.)

## 🛡️ Endpoints Configurados

### Públicos (sin autenticación)
- `/actuator/health`
- `/actuator/info`
- `/api/public/**`
- `/swagger-ui/**`
- `/v3/api-docs/**`

### Protegidos (requieren token JWT)
- `/api/protected/**`
- Cualquier otro endpoint no especificado como público

## 💻 Uso en Controladores

### Endpoint Protegido Básico

```java
@GetMapping("/api/protected/data")
public ResponseEntity<String> getData() {
    // Solo se ejecuta si el token es válido
    return ResponseEntity.ok("Data protegida");
}
```

### Acceder a información del JWT

```java
@GetMapping("/api/protected/userinfo")
public ResponseEntity<Map<String, Object>> userInfo(
        @AuthenticationPrincipal Jwt jwt) {
    
    return ResponseEntity.ok(Map.of(
        "sub", jwt.getSubject(),
        "email", jwt.getClaimAsString("email"),
        "name", jwt.getClaimAsString("name"),
        "groups", jwt.getClaimAsStringList("groups")
    ));
}
```

### Validar Roles/Grupos

```java
@GetMapping("/api/admin/users")
@PreAuthorize("hasRole('admin')")
public ResponseEntity<List<User>> getUsers() {
    // Solo accesible si el token tiene el grupo "admin"
    return ResponseEntity.ok(users);
}
```

Para habilitar `@PreAuthorize`, añadir a `SecurityConfig`:
```java
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {
    // ...
}
```

## 🧪 Testing

### Test con curl

```bash
# 1. Obtener token
TOKEN=$(curl -s -X POST https://localhost:5556/dex/token \
  --insecure \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=ms-data-client" \
  -d "client_secret=ms-data-client-secret-change-in-production" \
  -d "scope=openid profile email" | jq -r '.access_token')

# 2. Llamar a endpoint protegido
curl http://localhost:8080/api/protected/data \
  -H "Authorization: Bearer $TOKEN"
```

### Test con Postman

1. **Obtener token**:
   - POST `https://localhost:5556/dex/token`
   - Body (x-www-form-urlencoded):
     - `grant_type`: `client_credentials`
     - `client_id`: `ms-data-client`
     - `client_secret`: `ms-data-client-secret-change-in-production`
     - `scope`: `openid profile email`

2. **Usar token**:
   - GET `http://localhost:8080/api/protected/data`
   - Authorization: Bearer Token
   - Token: `<access_token del paso 1>`

## 🔧 Configuración Avanzada

### Variables de Entorno

Las URLs de Dex son configurables vía variables de entorno:

#### Desarrollo Local
```bash
# No es necesario configurar nada, usa los valores por defecto
./mvnw spring-boot:run
```

#### Docker
```bash
# Definidas en docker-compose.yml
docker-compose up -d ms-data
```

#### Docker manual
```bash
docker run -d \
  -p 8080:8080 \
  -e OAUTH2_ISSUER_URI=https://dex.example.com/dex \
  -e OAUTH2_JWK_SET_URI=https://dex.example.com/dex/keys \
  ms-data-template:latest
```

#### Kubernetes
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ms-data-config
data:
  OAUTH2_ISSUER_URI: "https://dex.cluster.local/dex"
  OAUTH2_JWK_SET_URI: "https://dex.cluster.local/dex/keys"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ms-data
spec:
  template:
    spec:
      containers:
      - name: ms-data
        image: ms-data-template:latest
        envFrom:
        - configMapRef:
            name: ms-data-config
```

#### Cloud (AWS, Azure, GCP)
```bash
# Variables de entorno en el servicio
OAUTH2_ISSUER_URI=https://dex.prod.example.com/dex
OAUTH2_JWK_SET_URI=https://dex.prod.example.com/dex/keys
```

### Deshabilitar validación SSL (solo desarrollo)

Si Dex usa certificados autofirmados:

```java
@Bean
public JwtDecoder jwtDecoder() {
    SSLContext sslContext = // ... configurar para aceptar certificados autofirmados
    
    NimbusJwtDecoder jwtDecoder = NimbusJwtDecoder
        .withJwkSetUri("https://localhost:5556/dex/keys")
        .restOperations(restTemplateWithSsl(sslContext))
        .build();
    
    return jwtDecoder;
}
```

### Customizar extracción de authorities

En `SecurityConfig.java`:

```java
@Bean
public JwtAuthenticationConverter jwtAuthenticationConverter() {
    JwtGrantedAuthoritiesConverter grantedAuthoritiesConverter = 
        new JwtGrantedAuthoritiesConverter();
    
    // Cambiar prefijo (por defecto "SCOPE_")
    grantedAuthoritiesConverter.setAuthorityPrefix("ROLE_");
    
    // Cambiar claim de donde extraer authorities (por defecto "scope")
    grantedAuthoritiesConverter.setAuthoritiesClaimName("groups");

    JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
    converter.setJwtGrantedAuthoritiesConverter(grantedAuthoritiesConverter);
    
    return converter;
}
```

### Añadir logging de seguridad

```yaml
logging:
  level:
    org.springframework.security: DEBUG
    org.springframework.security.oauth2: DEBUG
```

## 🐛 Troubleshooting

### Error: "An error occurred while attempting to decode the Jwt"

**Causa**: No se puede conectar a Dex o validar el JWK

**Solución**:
1. Verificar que Dex está corriendo: `docker-compose ps dex`
2. Verificar que la URL es correcta: `curl --insecure https://localhost:5556/dex/keys`
3. Revisar certificados SSL si es necesario

### Error: "Invalid token does not contain resource id (oauth2-resource)"

**Causa**: El token no tiene el audience correcto

**Solución**: Configurar validación de audience en `SecurityConfig`:
```java
@Bean
public JwtDecoder jwtDecoder() {
    NimbusJwtDecoder decoder = NimbusJwtDecoder
        .withJwkSetUri("https://localhost:5556/dex/keys")
        .build();
    
    // Opcional: validar audience
    decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
        new JwtTimestampValidator(),
        new JwtIssuerValidator("https://localhost:5556/dex")
    ));
    
    return decoder;
}
```

### Error: 401 Unauthorized en todos los endpoints

**Causa**: Token no se está enviando o es inválido

**Solución**:
1. Verificar header: `Authorization: Bearer <token>`
2. Verificar que el token no ha expirado
3. Obtener un token nuevo

### Error: 403 Forbidden

**Causa**: Token válido pero sin permisos suficientes

**Solución**: Verificar que el token tiene los roles/grupos necesarios

## 📚 Referencias

- [Spring Security OAuth2 Resource Server](https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/index.html)
- [JWT Introduction](https://jwt.io/introduction)
- [Dex Documentation](https://dexidp.io/docs/)

---

**Estado**: ✅ Configuración completa y lista para usar
