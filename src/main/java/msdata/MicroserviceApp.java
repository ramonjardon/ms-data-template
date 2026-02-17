package msdata;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Microservicio optimizado para GraalVM Native Image
 *
 * Configuración:
 * - Sin base de datos (Stateless REST API)
 * - OAuth2 Resource Server (validación JWT)
 * - Virtual Threads (Java 25)
 * - 512MB RAM, 0.5 CPU
 *
 * EXCLUSIONES ACTUALES:
 * - Ninguna (Spring Boot solo carga autoconfiguraciones si las dependencias están presentes)
 * - No tenemos JPA/Hibernate en el pom.xml → No se autoconfigura
 * - No tenemos Thymeleaf → No se autoconfigura
 * - Spring Boot es inteligente: sin dependencia = sin autoconfiguración
 *
 * SI AÑADES JPA EN EL FUTURO:
 * - NO excluyas DataSourceAutoConfiguration ni HibernateJpaAutoConfiguration
 * - Las necesitas para que JPA funcione
 * - Solo excluye autoconfiguraciones que NO quieres usar
 */
@SpringBootApplication
public class MicroserviceApp {

    private MicroserviceApp() {
        // Constructor privado para evitar instanciación
    }
    static void main(String[] args) {
        SpringApplication.run(MicroserviceApp.class, args);
    }
}
