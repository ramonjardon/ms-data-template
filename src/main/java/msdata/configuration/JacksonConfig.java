package msdata.configuration;



import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.JsonInclude;
import org.springframework.boot.jackson.autoconfigure.JsonMapperBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import tools.jackson.databind.DeserializationFeature;
import tools.jackson.databind.SerializationFeature;
import tools.jackson.databind.cfg.ConstructorDetector;
import tools.jackson.databind.cfg.DateTimeFeature;

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





    @Bean
    @Primary
    JsonMapperBuilderCustomizer jacksonCustomizer() {
        return builder -> builder
                // Jackson 3 ya serializa fechas como ISO-8601 por defecto
                // No necesitas deshabilitar WRITE_DATES_AS_TIMESTAMPS

                .defaultTimeZone(TimeZone.getTimeZone("Europe/Madrid"))
                .defaultLocale(Locale.forLanguageTag("es-ES"))
                .disable(SerializationFeature.FAIL_ON_EMPTY_BEANS)
                .disable(SerializationFeature.FAIL_ON_SELF_REFERENCES)
                .disable(SerializationFeature.FAIL_ON_UNWRAPPED_TYPE_IDENTIFIERS)
                .disable(DateTimeFeature.WRITE_DATE_TIMESTAMPS_AS_NANOSECONDS)
                .disable(DateTimeFeature.READ_DATE_TIMESTAMPS_AS_NANOSECONDS)
                .disable(DateTimeFeature.WRITE_DATES_AS_TIMESTAMPS)
                .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
                .disable(DateTimeFeature.ADJUST_DATES_TO_CONTEXT_TIME_ZONE)
                .disable(SerializationFeature.INDENT_OUTPUT)
                .changeDefaultPropertyInclusion(incl ->
                        incl.withValueInclusion(JsonInclude.Include.NON_NULL)
                )
                .changeDefaultVisibility(vis -> vis
                        .withFieldVisibility(JsonAutoDetect.Visibility.NONE)
                        .withGetterVisibility(JsonAutoDetect.Visibility.ANY)
                        .withSetterVisibility(JsonAutoDetect.Visibility.ANY)
                        .withIsGetterVisibility(JsonAutoDetect.Visibility.ANY)
                        .withCreatorVisibility(JsonAutoDetect.Visibility.ANY)
                )
                .constructorDetector(ConstructorDetector.USE_PROPERTIES_BASED);
    }
}
