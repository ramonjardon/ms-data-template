# ⚠️ Limitación de Dex: Client Credentials Grant

## 🔍 Problema

Dex **NO soporta nativamente** el flujo OAuth2 Client Credentials Grant de forma estándar.

Error recibido:
```json
{
  "level": "ERROR",
  "msg": "unsupported grant type",
  "grant_type": "client_credentials"
}
```

## 🎯 Soluciones

### Opción 1: Usar Password Grant (Recomendado con Dex)

Dex soporta el Password Grant usando usuarios estáticos.

#### Obtener Token

```bash
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

#### Configuración en Spring Boot

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          dex:
            client-id: ms-data-client
            client-secret: ms-data-client-secret-change-in-production
            authorization-grant-type: password
            scope:
              - openid
              - profile
              - email
        provider:
          dex:
            token-uri: https://localhost:5556/dex/token
```

**Limitación**: Necesitas usuario y contraseña, no es puro client_credentials.

### Opción 2: Usar Authorization Code Flow

El flujo principal que Dex soporta bien:

```bash
# 1. Redirigir al usuario a Dex para login
https://localhost:5556/dex/auth?client_id=ms-data-client&redirect_uri=http://localhost:8080/callback&response_type=code&scope=openid+profile+email

# 2. Dex redirige con el código
http://localhost:8080/callback?code=abc123...

# 3. Intercambiar código por token
curl -X POST https://localhost:5556/dex/token \
  --insecure \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=abc123..." \
  -d "client_id=ms-data-client" \
  -d "client_secret=ms-data-client-secret-change-in-production" \
  -d "redirect_uri=http://localhost:8080/callback"
```

**Limitación**: Requiere interacción del usuario.

### Opción 3: Cambiar a Keycloak (Recomendado para Client Credentials)

Keycloak SÍ soporta completamente Client Credentials Grant.

#### docker-compose.yml

```yaml
services:
  keycloak:
    image: quay.io/keycloak/keycloak:26.0
    container_name: ms-data-keycloak
    restart: unless-stopped
    
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      KC_HTTP_PORT: 8180
      KC_HOSTNAME_STRICT: false
      KC_HOSTNAME_STRICT_HTTPS: false
      KC_HTTP_ENABLED: true
    
    command:
      - start-dev
    
    ports:
      - "8180:8180"
    
    networks:
      - ms-data-network
```

#### Configuración Keycloak

1. Acceder a http://localhost:8180
2. Crear realm: `ms-data`
3. Crear client: `ms-data-client`
   - Client authentication: ON
   - Service accounts roles: ON
   - Standard flow: OFF
   - Direct access grants: OFF
4. Copiar client secret

#### Obtener Token

```bash
curl -X POST http://localhost:8180/realms/ms-data/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=ms-data-client" \
  -d "client_secret=<client-secret>"
```

✅ **Funciona perfectamente con client_credentials!**

### Opción 4: Usar Spring Authorization Server

Spring Authorization Server es la alternativa oficial de Spring para OAuth2.

#### pom.xml

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-authorization-server</artifactId>
</dependency>
```

#### AuthorizationServerConfig.java

```java
@Configuration
public class AuthorizationServerConfig {
    
    @Bean
    public RegisteredClientRepository registeredClientRepository() {
        RegisteredClient client = RegisteredClient.withId(UUID.randomUUID().toString())
            .clientId("ms-data-client")
            .clientSecret("{noop}ms-data-client-secret")
            .clientAuthenticationMethod(ClientAuthenticationMethod.CLIENT_SECRET_BASIC)
            .authorizationGrantType(AuthorizationGrantType.CLIENT_CREDENTIALS)
            .scope("read")
            .scope("write")
            .build();
        
        return new InMemoryRegisteredClientRepository(client);
    }
    
    @Bean
    public JWKSource<SecurityContext> jwkSource() {
        KeyPair keyPair = generateRsaKey();
        RSAPublicKey publicKey = (RSAPublicKey) keyPair.getPublic();
        RSAPrivateKey privateKey = (RSAPrivateKey) keyPair.getPrivate();
        
        RSAKey rsaKey = new RSAKey.Builder(publicKey)
            .privateKey(privateKey)
            .keyID(UUID.randomUUID().toString())
            .build();
        
        JWKSet jwkSet = new JWKSet(rsaKey);
        return new ImmutableJWKSet<>(jwkSet);
    }
    
    private static KeyPair generateRsaKey() {
        KeyPair keyPair;
        try {
            KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
            keyPairGenerator.initialize(2048);
            keyPair = keyPairGenerator.generateKeyPair();
        } catch (Exception ex) {
            throw new IllegalStateException(ex);
        }
        return keyPair;
    }
}
```

✅ **Soporta client_credentials nativamente!**

## 📋 Comparación

| Servidor | Client Credentials | Complejidad | Recomendado |
|----------|-------------------|-------------|-------------|
| **Dex** | ❌ No nativo | Baja | ⚠️ Solo para auth de usuarios |
| **Keycloak** | ✅ Completo | Media | ✅ Producción |
| **Spring AS** | ✅ Completo | Alta | ✅ Si ya usas Spring |
| **Auth0** | ✅ Completo | Baja | ✅ SaaS |
| **Okta** | ✅ Completo | Baja | ✅ SaaS |

## 🎯 Recomendación

### Para Desarrollo/Testing
Usar **Password Grant con Dex** (ya configurado):
```bash
curl -X POST https://localhost:5556/dex/token --insecure \
  -d "grant_type=password" \
  -d "username=admin@example.com" \
  -d "password=password" \
  -d "client_id=ms-data-client" \
  -d "client_secret=ms-data-client-secret-change-in-production"
```

### Para Producción
Cambiar a **Keycloak** o **Spring Authorization Server** si necesitas client_credentials real.

## 🔄 Migración a Keycloak

Si decides cambiar a Keycloak, he preparado una configuración lista:

**[MIGRACION_KEYCLOAK.md](MIGRACION_KEYCLOAK.md)** (próximamente)

---

**Conclusión**: Dex está diseñado para federar identidades de usuarios, no para autenticación service-to-service con client_credentials. Para ese caso, Keycloak o Spring Authorization Server son mejores opciones. ✅
