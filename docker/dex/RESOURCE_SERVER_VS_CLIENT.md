# 📊 Resumen Visual: Resource Server vs OAuth2 Client

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TU APLICACIÓN SPRING BOOT                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────┐    ┌──────────────────────────┐     │
│  │   RESOURCE SERVER        │    │   OAUTH2 CLIENT          │     │
│  │   (Seguridad)            │    │   (Cliente HTTP)         │     │
│  └──────────────────────────┘    └──────────────────────────┘     │
│                                                                     │
│  ┌──────────────────────────┐    ┌──────────────────────────┐     │
│  │ SecurityConfig.java      │    │ HttpClientConfig.java    │     │
│  │                          │    │                          │     │
│  │ @EnableWebSecurity       │    │ @Configuration           │     │
│  │ SecurityFilterChain      │    │ RestTemplate/RestClient  │     │
│  │                          │    │ + OAuth2 Interceptor     │     │
│  └──────────────────────────┘    └──────────────────────────┘     │
│             ▲                                   │                  │
│             │                                   │                  │
│             │                                   ▼                  │
│  ┌──────────────────────────┐    ┌──────────────────────────┐     │
│  │ Recibe tokens de         │    │ Envía tokens a           │     │
│  │ clientes externos        │    │ APIs externas            │     │
│  └──────────────────────────┘    └──────────────────────────┘     │
│             ▲                                   │                  │
└─────────────│───────────────────────────────────│──────────────────┘
              │                                   │
              │                                   │
    ┌─────────┴────────┐                ┌────────▼─────────┐
    │  Cliente Externo │                │  API Externa     │
    │  (Mobile, Web)   │                │  (Otro μservice) │
    │                  │                │                  │
    │  GET /api/data   │                │  GET /users/{id} │
    │  Authorization:  │                │  Authorization:  │
    │  Bearer <token>  │                │  Bearer <token>  │
    └──────────────────┘                └──────────────────┘
```

## 🔑 Claves para Entender

### Resource Server (RECIBE tokens)
```yaml
# application.yml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://localhost:5556/dex
```

**Qué hace**: Valida tokens que TU API recibe
**Archivo**: SecurityConfig.java
**Es**: Configuración de SEGURIDAD

### OAuth2 Client (ENVÍA tokens)
```yaml
# application.yml - Solo credenciales
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

**Qué hace**: Configura las credenciales OAuth2
**Archivo Java**: HttpClientConfig.java (configura RestTemplate/RestClient)
**Es**: Configuración de CREDENCIALES + CLIENTE HTTP (no seguridad)

## 📋 Ejemplos de Código

### Resource Server (SecurityConfig.java)
```java
@Configuration
@EnableWebSecurity  // ← Esto es SEGURIDAD
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) {
        http
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/api/public/**").permitAll()
                .anyRequest().authenticated()  // ← Protege TUS endpoints
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt());
        return http.build();
    }
}
```

### OAuth2 Client (HttpClientConfig.java)
```java
@Configuration
public class HttpClientConfig {
    
    @Bean
    public RestTemplate restTemplate(RestTemplateBuilder builder,
                                     OAuth2AuthorizedClientManager clientManager) {
        
        // Configurar interceptor OAuth2 en RestTemplate
        return builder
            .requestFactory(() -> new HttpComponentsClientHttpRequestFactory())
            .interceptors(new OAuth2ClientHttpRequestInterceptor(clientManager))
            .build();
    }
    
    // O mejor aún, usar RestClient (Spring 6+)
    @Bean
    public RestClient restClient(RestClient.Builder builder,
                                 OAuth2AuthorizedClientManager clientManager) {
        
        return builder
            .requestInterceptor((request, body, execution) -> {
                // Obtener token automáticamente
                OAuth2AuthorizeRequest authorizeRequest = 
                    OAuth2AuthorizeRequest.withClientRegistrationId("dex")
                        .principal("ms-data-client")
                        .build();
                
                OAuth2AuthorizedClient client = clientManager.authorize(authorizeRequest);
                if (client != null) {
                    request.getHeaders().setBearerAuth(
                        client.getAccessToken().getTokenValue()
                    );
                }
                
                return execution.execute(request, body);
            })
            .build();
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

## 🎯 Casos de Uso

### Caso 1: API pública que no llama a nadie
```yaml
spring:
  security:
    oauth2:
      resourceserver:  # ← Solo esto
        jwt:
          issuer-uri: https://localhost:5556/dex
```
✅ Solo SecurityConfig.java

### Caso 2: Worker/Job que solo llama a APIs
```yaml
# application.yml - Solo credenciales
spring:
  security:
    oauth2:
      client:
        registration:
          dex:
            client-id: worker-client
            client-secret: worker-secret
            authorization-grant-type: client_credentials
        provider:
          dex:
            token-uri: https://localhost:5556/dex/token
```

```java
// HttpClientConfig.java - Configurar RestTemplate con OAuth2
@Configuration
public class HttpClientConfig {
    
    @Bean
    public RestTemplate restTemplate(OAuth2AuthorizedClientManager clientManager) {
        RestTemplate restTemplate = new RestTemplate();
        restTemplate.getInterceptors().add(new OAuth2ClientHttpRequestInterceptor(clientManager));
        return restTemplate;
    }
    
    @Bean
    public OAuth2AuthorizedClientManager authorizedClientManager(...) {
        // Configuración del manager
    }
}
```
✅ HttpClientConfig.java (sin SecurityConfig porque no expone API)

### Caso 3: Microservicio que hace ambas
```yaml
# application.yml
spring:
  security:
    oauth2:
      resourceserver:  # ← Para validar tokens entrantes
        jwt:
          issuer-uri: https://localhost:5556/dex
      client:  # ← Credenciales para obtener tokens salientes
        registration:
          dex:
            client-id: ms-data-client
            client-secret: ms-data-client-secret
            authorization-grant-type: client_credentials
        provider:
          dex:
            token-uri: https://localhost:5556/dex/token
```

```java
// SecurityConfig.java - Proteger TU API
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) {
        http.oauth2ResourceServer(oauth2 -> oauth2.jwt());
        return http.build();
    }
}

// HttpClientConfig.java - Configurar cliente para llamar a otras APIs
@Configuration
public class HttpClientConfig {
    @Bean
    public RestTemplate restTemplate(OAuth2AuthorizedClientManager clientManager) {
        RestTemplate restTemplate = new RestTemplate();
        restTemplate.getInterceptors().add(new OAuth2ClientHttpRequestInterceptor(clientManager));
        return restTemplate;
    }
    
    @Bean
    public OAuth2AuthorizedClientManager authorizedClientManager(...) {
        // Manager que usa las credenciales de application.yml
    }
}
```
✅ SecurityConfig.java + HttpClientConfig.java

## ⚠️ Error Común

```java
// ❌ INCORRECTO: Mezclar seguridad con cliente HTTP
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) {
        // Configurar seguridad...
    }
    
    @Bean
    public OAuth2AuthorizedClientManager authorizedClientManager(...) {
        // ← Esto NO debería estar en SecurityConfig
        // Debería estar en RestClientConfig
    }
}
```

```java
// ✅ CORRECTO: Separar responsabilidades

// 1. application.yml - Solo credenciales OAuth2
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
            client-secret: ms-data-client-secret
            authorization-grant-type: client_credentials
        provider:
          dex:
            token-uri: https://localhost:5556/dex/token

// 2. SecurityConfig.java - Solo seguridad de TU API
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

// 3. HttpClientConfig.java - Configurar RestTemplate/RestClient con OAuth2
@Configuration
public class HttpClientConfig {
    
    @Bean
    public RestTemplate restTemplate(OAuth2AuthorizedClientManager clientManager) {
        RestTemplate restTemplate = new RestTemplate();
        
        // Añadir interceptor que inyecta el token automáticamente
        restTemplate.getInterceptors().add((request, body, execution) -> {
            OAuth2AuthorizeRequest authorizeRequest = 
                OAuth2AuthorizeRequest.withClientRegistrationId("dex")
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

## 📚 Analogía del Mundo Real

### Resource Server = Portero del Club
- **Recibe** la identificación (token) de las personas que ENTRAN
- **Valida** que la identificación sea válida
- **Decide** si puede pasar o no

### OAuth2 Client = Mensajero con Credenciales
- **Obtiene** credenciales (token) del sistema de seguridad (Dex)
- **Lleva** las credenciales cuando va a OTRAS ubicaciones
- **Presenta** las credenciales para acceder a otros lugares

---

**En resumen**: Son dos configuraciones independientes para dos propósitos diferentes. Una protege TU API (seguridad), la otra configura cómo TU APP llama a otras APIs (cliente HTTP). ✅
