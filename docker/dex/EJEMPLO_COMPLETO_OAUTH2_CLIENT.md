# ✅ Configuración Correcta: OAuth2 Client con RestTemplate

## 🎯 Configuración Estándar de Spring Boot

### ✅ Forma Correcta (Recomendada)
Configurar las credenciales OAuth2 en **`application.yml`** usando `spring.security.oauth2.client.registration`.

Esta es la forma estándar y recomendada en Spring Boot.

## 📋 Separación de Responsabilidades

```
application.yml
├─ resourceserver → Para validar tokens que TU API recibe
└─ client.registration → Credenciales OAuth2 para llamar a otras APIs

SecurityConfig.java
└─ Proteger TU API (si es necesario)

HttpClientConfig.java  
├─ Configura RestTemplate/RestClient/WebClient
├─ Añade interceptor OAuth2
└─ Usa las credenciales de application.yml
```

## 💻 Configuración Estándar (Recomendada)

### 1. application.yml (Credenciales OAuth2)

```yaml
spring:
  security:
    oauth2:
      # Para VALIDAR tokens que TU API recibe (opcional)
      resourceserver:
        jwt:
          issuer-uri: https://localhost:5556/dex
      
      # CREDENCIALES para obtener tokens al llamar a otras APIs
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
        provider:
          dex:
            token-uri: https://localhost:5556/dex/token
            jwk-set-uri: https://localhost:5556/dex/keys
```

### 2. HttpClientConfig.java (Cliente HTTP con OAuth2)

```java
package com.example.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.client.*;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.client.web.OAuth2AuthorizedClientRepository;
import org.springframework.web.client.RestTemplate;

@Configuration
public class HttpClientConfig {
    
    /**
     * RestTemplate con interceptor OAuth2
     * Usa las credenciales configuradas en application.yml
     */
    @Bean
    public RestTemplate restTemplate(OAuth2AuthorizedClientManager clientManager) {
        RestTemplate restTemplate = new RestTemplate();
        
        // Añadir interceptor que inyecta el token automáticamente
        restTemplate.getInterceptors().add((request, body, execution) -> {
            
            // Solicitar token usando el client registration "dex"
            OAuth2AuthorizeRequest authorizeRequest = 
                OAuth2AuthorizeRequest
                    .withClientRegistrationId("dex")  // ID del client.registration
                    .principal("ms-data-client")      // Principal (puede ser cualquier string)
                    .build();
            
            // Obtener o renovar el token automáticamente
            OAuth2AuthorizedClient authorizedClient = 
                clientManager.authorize(authorizeRequest);
            
            if (authorizedClient != null) {
                String token = authorizedClient.getAccessToken().getTokenValue();
                
                // Añadir el token al header Authorization
                request.getHeaders().setBearerAuth(token);
            }
            
            return execution.execute(request, body);
        });
        
        return restTemplate;
    }
    
    /**
     * Manager que gestiona la obtención y renovación de tokens
     * Lee las credenciales de application.yml automáticamente
     */
    @Bean
    public OAuth2AuthorizedClientManager authorizedClientManager(
            ClientRegistrationRepository clientRegistrationRepository,
            OAuth2AuthorizedClientRepository authorizedClientRepository) {
        
        // Provider que implementa el flujo Client Credentials
        OAuth2AuthorizedClientProvider authorizedClientProvider =
            OAuth2AuthorizedClientProviderBuilder.builder()
                .clientCredentials()  // Habilitar Client Credentials Grant
                .build();
        
        // Manager que coordina la obtención de tokens
        DefaultOAuth2AuthorizedClientManager authorizedClientManager =
            new DefaultOAuth2AuthorizedClientManager(
                clientRegistrationRepository,
                authorizedClientRepository
            );
        
        authorizedClientManager.setAuthorizedClientProvider(authorizedClientProvider);
        
        return authorizedClientManager;
    }
}
```

### 3. SecurityConfig.java (Solo si proteges TU API)

**Nota**: Solo necesitas esto si TU API recibe tokens para validar.

```java
package com.example.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/actuator/health").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt());
        
        return http.build();
    }
}
```

## 💡 Alternativa: Todo en Código Java (No recomendado)

Si prefieres NO usar `application.yml` y configurar todo en código Java:

```java
package com.example.service;

import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.beans.factory.annotation.Autowired;

@Service
public class UserServiceClient {
    
    @Autowired
    private RestTemplate restTemplate;  // ← Ya tiene el interceptor OAuth2
    
    /**
     * Llamar a otra API
     * El token se inyecta automáticamente gracias al interceptor
     */
    public UserDto getUser(String userId) {
        String url = "https://user-service/api/users/" + userId;
        
        // ¡No necesitas añadir el token manualmente!
        // El interceptor lo hace automáticamente
        return restTemplate.getForObject(url, UserDto.class);
    }
    
    public void createUser(UserDto user) {
        String url = "https://user-service/api/users";
        
        // El token se añade automáticamente
        restTemplate.postForObject(url, user, UserDto.class);
    }
}
```

## 🔄 Alternativa: RestClient (Spring 6+)

Si usas Spring 6 o superior, puedes usar `RestClient`:

```java
@Configuration
public class HttpClientConfig {
    
    @Bean
    public RestClient restClient(
            RestClient.Builder builder,
            OAuth2AuthorizedClientManager clientManager) {
        
        return builder
            .requestInterceptor((request, body, execution) -> {
                OAuth2AuthorizeRequest authorizeRequest = 
                    OAuth2AuthorizeRequest
                        .withClientRegistrationId("dex")
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

## 🔄 Alternativa: WebClient (Reactive)

Para aplicaciones reactivas:

```java
@Configuration
public class HttpClientConfig {
    
    @Bean
    public WebClient webClient(
            WebClient.Builder builder,
            ReactiveOAuth2AuthorizedClientManager clientManager) {
        
        ServerOAuth2AuthorizedClientExchangeFilterFunction oauth2 =
            new ServerOAuth2AuthorizedClientExchangeFilterFunction(clientManager);
        
        // Configurar para usar client_credentials por defecto
        oauth2.setDefaultClientRegistrationId("dex");
        
        return builder
            .filter(oauth2)
            .build();
    }
    
    @Bean
    public ReactiveOAuth2AuthorizedClientManager authorizedClientManager(
            ReactiveClientRegistrationRepository clientRepo,
            ServerOAuth2AuthorizedClientRepository authorizedClientRepo) {
        
        ReactiveOAuth2AuthorizedClientProvider provider =
            ReactiveOAuth2AuthorizedClientProviderBuilder.builder()
                .clientCredentials()
                .build();
        
        AuthorizedClientServiceReactiveOAuth2AuthorizedClientManager manager =
            new AuthorizedClientServiceReactiveOAuth2AuthorizedClientManager(
                clientRepo, authorizedClientService
            );
        manager.setAuthorizedClientProvider(provider);
        
        return manager;
    }
}
```

## 📊 Flujo Completo

```
1. Tu App necesita llamar a otra API
   ↓
2. RestTemplate.getForObject(url, ...)
   ↓
3. Interceptor OAuth2 detecta la petición
   ↓
4. OAuth2AuthorizedClientManager verifica si hay token válido
   ↓
5. Si NO hay token o está expirado:
   - Llama a Dex: POST /dex/token
   - Con client_id y client_secret de application.yml
   - Guarda el token
   ↓
6. Interceptor añade: Authorization: Bearer <token>
   ↓
7. Ejecuta la petición HTTP
```

## ✅ Checklist de Configuración

### Configuración Estándar (Recomendada)
- [ ] `application.yml` tiene `client.registration.dex` con credenciales OAuth2
- [ ] `application.yml` tiene `client.provider.dex` con token-uri
- [ ] `HttpClientConfig.java` configura RestTemplate con interceptor OAuth2
- [ ] `HttpClientConfig.java` define `OAuth2AuthorizedClientManager`
- [ ] Services usan RestTemplate sin añadir tokens manualmente

### Solo si proteges TU API
- [ ] `application.yml` tiene `resourceserver.jwt.issuer-uri` configurado
- [ ] `SecurityConfig.java` protege TU API con `oauth2ResourceServer()`

## 🎯 Resumen Final

```
┌─────────────────────────────────────────────────────────────┐
│        Configuración Estándar (Recomendada) ✅              │
│                                                             │
│  application.yml                                            │
│  ├─ resourceserver (opcional, para proteger TU API)        │
│  └─ client.registration (credenciales OAuth2)              │
│         ├─ client-id                                       │
│         ├─ client-secret                                   │
│         └─ authorization-grant-type: client_credentials    │
│                                                             │
│  HttpClientConfig.java                                      │
│  ├─ RestTemplate con interceptor OAuth2                    │
│  ├─ OAuth2AuthorizedClientManager                          │
│  └─ Lee credenciales de application.yml automáticamente    │
│                                                             │
│  SecurityConfig.java (opcional)                             │
│  └─ Solo si necesitas proteger TU API                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 📋 Ventajas de la Configuración Estándar

| Ventaja | Descripción |
|---------|-------------|
| **Estándar Spring Boot** | Usa las convenciones de Spring |
| **Externalización** | Credenciales fuera del código |
| **Menos código** | Spring maneja la complejidad |
| **Renovación automática** | Spring renueva tokens automáticamente |
| **Soporte oficial** | Documentado por Spring |
| **Múltiples clientes** | Fácil configurar varios clientes OAuth2 |

### ✅ Recomendación

**Usa la configuración estándar con `application.yml`** - Es la forma recomendada por Spring Boot y la más mantenible.
