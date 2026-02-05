package msdata.configuration;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.json.JsonMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import java.util.Locale;
import java.util.TimeZone;

/**
 * Configuración de Jackson optimizada para GraalVM Native Image
 *
 * Esta configuración minimiza el uso de reflexión y optimiza
 * el rendimiento para entornos con recursos limitados (512MB RAM, 0.5 CPU)
 *
 * NOTA: En Spring Boot 4.0 (Spring Framework 7):
 * - Jackson2ObjectMapperBuilderCustomizer fue REMOVIDO
 * - Jackson2ObjectMapperBuilder está DEPRECADO
 * - La forma correcta es: application.yml properties + @Bean ObjectMapper cuando sea necesario
 * - Usamos @Primary para que este ObjectMapper sea el predeterminado
 */
@Configuration
public class JacksonConfig {

    /**
     * ObjectMapper personalizado para Spring Boot 4.0 (Spring Framework 7)
     *
     * POR QUÉ NO Jackson2ObjectMapperBuilderCustomizer:
     * - Removido en Spring Framework 7.0 / Spring Boot 4.0
     * - La migración requiere usar application.yml para configuración base
     * - Y @Bean ObjectMapper con @Primary para personalizaciones específicas
     *
     * Características:
     * - Soporte Java Time API (LocalDate, LocalDateTime, Instant, etc.)
     * - Fechas ISO-8601 con milisegundos: 2026-02-05T22:30:00.123+01:00
     * - Zona horaria: Europe/Madrid (CET/CEST automático)
     * - Locale: es_ES
     * - Sin valores null (ahorra ~30% payload)
     * - Flexible con campos desconocidos
     * - Optimizado para GraalVM Native Image (512MB RAM, 0.5 CPU)
     */


    @Bean
    @Primary
    public ObjectMapper objectMapper() {
        return JsonMapper.builder()
                // 1. Módulos esenciales (Sin Afterburner)
                .addModule(new JavaTimeModule())

                // 2. Zona Horaria y Locale Fijos
                .defaultTimeZone(TimeZone.getTimeZone("Europe/Madrid"))
                .defaultLocale(Locale.forLanguageTag("es-ES"))

                // 3. Serialización (Salida eficiente)
                .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)       // ISO-8601
                .disable(SerializationFeature.WRITE_DATE_TIMESTAMPS_AS_NANOSECONDS) // Ahorra bytes
                .disable(SerializationFeature.FAIL_ON_EMPTY_BEANS)             // Robustez
                .disable(SerializationFeature.FAIL_ON_SELF_REFERENCES)         // JPA Safety
                .disable(SerializationFeature.FAIL_ON_UNWRAPPED_TYPE_IDENTIFIERS)

                // 4. Deserialización (Entrada tolerante)
                .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)    // Tolerancia a cambios API
                .disable(DeserializationFeature.READ_DATE_TIMESTAMPS_AS_NANOSECONDS)
                .disable(DeserializationFeature.ADJUST_DATES_TO_CONTEXT_TIME_ZONE) // Respetar la hora que viene

                // 5. Optimización de Payload (Solo NON_NULL - Reduce ~30% payload)
                .defaultPropertyInclusion(JsonInclude.Value.construct(JsonInclude.Include.NON_NULL, JsonInclude.Include.ALWAYS))

                .build();
    }
}
