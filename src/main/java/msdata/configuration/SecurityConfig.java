package msdata.configuration;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Configuración de seguridad OAuth2 Resource Server
 * Valida tokens JWT emitidos por Dex
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    /**
     * Configuración del filtro de seguridad
     * Define qué endpoints están protegidos y cómo validar los tokens
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // Configurar autorización de peticiones
            .authorizeHttpRequests(authz -> authz
                // Endpoints públicos (sin autenticación)
                .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()

                // Todos los demás endpoints requieren autenticación
                .anyRequest().authenticated()
            )

            // Configurar OAuth2 Resource Server con JWT
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .jwtAuthenticationConverter(jwtAuthenticationConverter())
                )
            )

            // Deshabilitar CSRF (típico para APIs REST stateless)
            .csrf(csrf -> csrf.disable())

            // Configurar manejo de sesiones (stateless para APIs REST)
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            );

        return http.build();
    }

    /**
     * Conversor de JWT a Authentication
     * Extrae los authorities/roles del token JWT
     */
    @Bean
    public JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter grantedAuthoritiesConverter = new JwtGrantedAuthoritiesConverter();

        // Configurar prefijo de authorities (por defecto es "SCOPE_")
        grantedAuthoritiesConverter.setAuthorityPrefix("ROLE_");

        // Configurar de dónde extraer los authorities del JWT
        // Dex típicamente los pone en el claim "groups" o "roles"
        grantedAuthoritiesConverter.setAuthoritiesClaimName("groups");

        JwtAuthenticationConverter jwtAuthenticationConverter = new JwtAuthenticationConverter();
        jwtAuthenticationConverter.setJwtGrantedAuthoritiesConverter(grantedAuthoritiesConverter);

        return jwtAuthenticationConverter;
    }
}
