# ❓ ¿Por qué Client Registration en Spring Security?

## ⚠️ ACLARACIÓN IMPORTANTE

**`client.registration` NO es configuración de seguridad de tu API**. Es configuración para tu **cliente HTTP** (RestTemplate/WebClient) cuando llama a otras APIs.

```
❌ INCORRECTO: "client.registration protege mi API"
✅ CORRECTO: "client.registration configura cómo mi app obtiene tokens para llamar a otras APIs"
```

## 🎯 Dos Configuraciones Diferentes

Tu aplicación puede tener **DOS configuraciones diferentes**:

### 1️⃣ Seguridad de TU API (Resource Server)
**Archivo**: `SecurityConfig.java` o similar
**Propósito**: Proteger los endpoints de TU aplicación

```yaml
# application.yml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://localhost:5556/dex
```

```java
// SecurityConfig.java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) {
        http
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/api/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt());
        return http.build();
    }
}
```

**Esto protege TU API**: Las peticiones a tus endpoints necesitan un token válido.

### 2️⃣ Cliente HTTP para Llamar a OTRAS APIs (OAuth2 Client)
**Archivo**: `RestClientConfig.java` o similar  
**Propósito**: Configurar RestTemplate/WebClient para que obtenga tokens automáticamente

```yaml
# application.yml  
spring:
  security:
    oauth2:
      client:
        registration:
          dex:
            client-id: ms-data-client
            client-secret: ms-data-client-secret-change-in-production
            authorization-grant-type: client_credentials
            scope:
              - openid
              - profile
        provider:
          dex:
            token-uri: https://localhost:5556/dex/token
```

```java
// RestClientConfig.java (NO es SecurityConfig)
@Configuration
public class RestClientConfig {
    
    @Bean
    public OAuth2AuthorizedClientManager authorizedClientManager(
            ClientRegistrationRepository clientRegistrationRepository,
            OAuth2AuthorizedClientRepository authorizedClientRepository) {
        
        OAuth2AuthorizedClientProvider authorizedClientProvider =
            OAuth2AuthorizedClientProviderBuilder.builder()
                .clientCredentials()
                .build();
        
        DefaultOAuth2AuthorizedClientManager manager =
            new DefaultOAuth2AuthorizedClientManager(
                clientRegistrationRepository,
                authorizedClientRepository);
        
        manager.setAuthorizedClientProvider(authorizedClientProvider);
        return manager;
    }
    
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
```

**Esto configura tu cliente HTTP**: Cuando llames a APIs externas, obtendrá tokens automáticamente.

## 🔄 Escenarios de Uso

### Escenario A: Solo Resource Server
**Tu API solo recibe peticiones con tokens**

```yaml
# Solo esto
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://localhost:5556/dex
```

**NO necesitas** `client.registration`

### Escenario B: Solo OAuth2 Client
**Tu aplicación solo llama a otras APIs**

```yaml
# Solo esto
spring:
  security:
    oauth2:
      client:
        registration:
          dex:
            client-id: ms-data-client
            client-secret: ms-data-client-secret-change-in-production
            authorization-grant-type: client_credentials
```

**NO necesitas** `resourceserver`

### Escenario C: Ambos (Más Común en Microservicios)
**Tu API recibe peticiones Y llama a otras APIs**

```yaml
# Ambas configuraciones
spring:
  security:
    oauth2:
      # Validar tokens que recibo
      resourceserver:
        jwt:
          issuer-uri: https://localhost:5556/dex
      
      # Obtener tokens para llamar a otros servicios
      client:
        registration:
          dex:
            client-id: ms-data-client
            client-secret: ms-data-client-secret-change-in-production
            authorization-grant-type: client_credentials
```

## 📊 Comparación

| Característica | Resource Server | OAuth2 Client |
|----------------|-----------------|---------------|
| **Propósito** | Proteger TU API | Llamar a otras APIs |
| **Archivo Config** | SecurityConfig.java | RestClientConfig.java |
| **Recibe tokens** | ✅ Sí | ❌ No |
| **Envía tokens** | ❌ No | ✅ Sí |
| **Necesita Client ID/Secret** | ❌ No | ✅ Sí |
| **Valida JWT** | ✅ Sí | ❌ No |
| **Obtiene tokens** | ❌ No | ✅ Sí |
| **Es seguridad** | ✅ Sí | ❌ No (es cliente HTTP) |

## 💡 ¿Cuál Necesito?

### Si tu aplicación...
- ✅ **Solo expone una API REST** → Solo Resource Server
- ✅ **Solo consume APIs externas** → Solo OAuth2 Client  
- ✅ **Expone API Y consume otras APIs** → Ambos

## 🔧 Ejemplos Prácticos

### Ejemplo 1: API Simple (Solo Resource Server)

**application.yml**
```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://localhost:5556/dex
```

**SecurityConfig.java**
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
            .oauth2ResourceServer(oauth2 -> oauth2.jwt());
        
        return http.build();
    }
}
```

**Controller.java**
```java
@RestController
@RequestMapping("/api")
public class DataController {
    
    @GetMapping("/data")
    public ResponseEntity<String> getData(@AuthenticationPrincipal Jwt jwt) {
        // Spring valida el token automáticamente
        String userId = jwt.getSubject();
        return ResponseEntity.ok("Data for user: " + userId);
    }
}
```

### Ejemplo 2: Cliente que Llama a Otras APIs (Solo Client)

**application.yml**
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
            scope:
              - openid
              - profile
        provider:
          dex:
            token-uri: https://localhost:5556/dex/token
```

**ExternalApiClient.java**
```java
@Service
public class ExternalApiClient {
    
    @Autowired
    private RestTemplate restTemplate;
    
    @Autowired
    private OAuth2AuthorizedClientManager authorizedClientManager;
    
    public String callExternalApi() {
        OAuth2AuthorizeRequest authorizeRequest = 
            OAuth2AuthorizeRequest
                .withClientRegistrationId("dex")
                .principal("ms-data-client")
                .build();
        
        OAuth2AuthorizedClient client = 
            authorizedClientManager.authorize(authorizeRequest);
        
        String token = client.getAccessToken().getTokenValue();
        
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        
        return restTemplate.exchange(
            "https://external-api.com/data",
            HttpMethod.GET,
            new HttpEntity<>(headers),
            String.class
        ).getBody();
    }
}
```

**Configuration.java**
```java
@Configuration
public class OAuth2ClientConfig {
    
    @Bean
    public OAuth2AuthorizedClientManager authorizedClientManager(
            ClientRegistrationRepository clientRegistrationRepository,
            OAuth2AuthorizedClientRepository authorizedClientRepository) {
        
        OAuth2AuthorizedClientProvider authorizedClientProvider =
            OAuth2AuthorizedClientProviderBuilder.builder()
                .clientCredentials()
                .build();
        
        DefaultOAuth2AuthorizedClientManager authorizedClientManager =
            new DefaultOAuth2AuthorizedClientManager(
                clientRegistrationRepository,
                authorizedClientRepository);
        
        authorizedClientManager.setAuthorizedClientProvider(
            authorizedClientProvider);
        
        return authorizedClientManager;
    }
}
```

### Ejemplo 3: Microservicio Completo (Ambos)

**application.yml**
```yaml
spring:
  security:
    oauth2:
      # Validar tokens de peticiones entrantes
      resourceserver:
        jwt:
          issuer-uri: https://localhost:5556/dex
      
      # Obtener tokens para llamar a otros microservicios
      client:
        registration:
          dex:
            client-id: ms-data-client
            client-secret: ms-data-client-secret-change-in-production
            authorization-grant-type: client_credentials
            scope:
              - openid
              - profile
        provider:
          dex:
            token-uri: https://localhost:5556/dex/token
```

**SecurityConfig.java**
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
            // Validar tokens entrantes
            .oauth2ResourceServer(oauth2 -> oauth2.jwt());
        
        return http.build();
    }
    
    @Bean
    public OAuth2AuthorizedClientManager authorizedClientManager(
            ClientRegistrationRepository clientRegistrationRepository,
            OAuth2AuthorizedClientRepository authorizedClientRepository) {
        
        // Para obtener tokens al llamar a otros servicios
        OAuth2AuthorizedClientProvider authorizedClientProvider =
            OAuth2AuthorizedClientProviderBuilder.builder()
                .clientCredentials()
                .build();
        
        DefaultOAuth2AuthorizedClientManager authorizedClientManager =
            new DefaultOAuth2AuthorizedClientManager(
                clientRegistrationRepository,
                authorizedClientRepository);
        
        authorizedClientManager.setAuthorizedClientProvider(
            authorizedClientProvider);
        
        return authorizedClientManager;
    }
}
```

**MicroserviceController.java**
```java
@RestController
@RequestMapping("/api")
public class MicroserviceController {
    
    @Autowired
    private UserServiceClient userServiceClient;
    
    // Endpoint que RECIBE un token
    @GetMapping("/user-data")
    public ResponseEntity<UserData> getUserData(@AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getSubject();
        
        // Llamar a otro microservicio (usa OAuth2 Client para obtener token)
        UserInfo userInfo = userServiceClient.getUserInfo(userId);
        
        return ResponseEntity.ok(new UserData(userId, userInfo));
    }
}

@Service
class UserServiceClient {
    
    @Autowired
    private RestTemplate restTemplate;
    
    @Autowired
    private OAuth2AuthorizedClientManager authorizedClientManager;
    
    public UserInfo getUserInfo(String userId) {
        // Obtener token para llamar al servicio de usuarios
        OAuth2AuthorizeRequest authorizeRequest = 
            OAuth2AuthorizeRequest
                .withClientRegistrationId("dex")
                .principal("ms-data-client")
                .build();
        
        OAuth2AuthorizedClient client = 
            authorizedClientManager.authorize(authorizeRequest);
        
        String token = client.getAccessToken().getTokenValue();
        
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        
        return restTemplate.exchange(
            "https://user-service/api/users/" + userId,
            HttpMethod.GET,
            new HttpEntity<>(headers),
            UserInfo.class
        ).getBody();
    }
}
```

## 🎯 Resumen

### ¿Por qué Client Registration?

**Respuesta corta**: Para configurar tu **cliente HTTP (RestTemplate/WebClient)** para que obtenga tokens automáticamente cuando llame a otras APIs protegidas.

**⚠️ NO ES SEGURIDAD**: `client.registration` no protege tu API, solo configura cómo tu app obtiene tokens para llamar a otras APIs.

**Sin client registration**:
```java
// Tendrías que hacer esto manualmente cada vez
String token = manuallyCallDexToGetToken(); // 😓 Tedioso
HttpHeaders headers = new HttpHeaders();
headers.setBearerAuth(token);
restTemplate.exchange(url, method, new HttpEntity<>(headers), ...);
```

**Con client registration**:
```java
// Spring lo hace automáticamente
OAuth2AuthorizedClient client = authorizedClientManager.authorize(...);
String token = client.getAccessToken().getTokenValue(); // 😊 Fácil
```

### Regla de Oro

```
🔑 client.registration = Configurar CLIENTE HTTP (RestTemplate/WebClient)
🛡️ resourceserver = Configurar SEGURIDAD de tu API
```

### Dónde va cada configuración

```java
// SecurityConfig.java - Para PROTEGER tu API
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) {
        // Aquí configuras QUÉ endpoints proteger
        // Usa: spring.security.oauth2.resourceserver
    }
}

// RestClientConfig.java - Para LLAMAR a otras APIs  
@Configuration
public class RestClientConfig {
    @Bean
    public OAuth2AuthorizedClientManager authorizedClientManager(...) {
        // Aquí configuras CÓMO obtener tokens para llamadas salientes
        // Usa: spring.security.oauth2.client.registration
    }
}
```

## 📚 Referencias

- [Spring Security OAuth2 Client](https://docs.spring.io/spring-security/reference/servlet/oauth2/client/index.html)
- [Spring Security OAuth2 Resource Server](https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/index.html)
- [OAuth2 Client Credentials Grant](https://www.rfc-editor.org/rfc/rfc6749#section-4.4)

---

**TL;DR**: Si tu microservicio llama a otras APIs, necesitas `client.registration`. Si solo expone su propia API, solo necesitas `resourceserver`. Si hace ambas cosas, necesitas ambas configuraciones. ✅
