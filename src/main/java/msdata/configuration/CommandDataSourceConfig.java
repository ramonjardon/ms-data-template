package msdata.configuration;

import com.zaxxer.hikari.HikariDataSource;
import jakarta.persistence.EntityManagerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.sql.DataSource;
import java.util.HashMap;
import java.util.Map;

/**
 * Configuración de DataSource y EntityManager para COMMANDS (Escrituras)
 *
 * Patrón CQRS:
 * - Este EntityManager maneja todas las operaciones de escritura
 * - Optimizado para transacciones y consistencia
 * - Pool pequeño pero con control transaccional completo
 *
 * Preparado para escalar:
 * - Actualmente apunta a la misma DB que Query
 * - Fácil cambiar a DB separada modificando variables de entorno
 *
 * Compatible con GraalVM Native Image
 */
@Configuration
@EnableTransactionManagement
@EnableJpaRepositories(
    basePackages = "msdata.repository.command",        // Repositories de escritura
    entityManagerFactoryRef = "commandEntityManagerFactory",
    transactionManagerRef = "commandTransactionManager"
)
public class CommandDataSourceConfig {

    /**
     * Properties del DataSource de Commands desde application.yml
     * spring.datasource.command.*
     */
    @Bean
    @Primary
    @ConfigurationProperties("spring.datasource.command")
    public DataSourceProperties commandDataSourceProperties() {
        return new DataSourceProperties();
    }

    /**
     * DataSource para Commands (Escrituras)
     *
     * Características:
     * - Pool pequeño (5 conexiones max)
     * - Auto-commit deshabilitado
     * - Control transaccional manual
     * - Optimizado para escrituras consistentes
     */
    @Bean
    @Primary
    @ConfigurationProperties("spring.datasource.command.hikari")
    public DataSource commandDataSource(
            @Qualifier("commandDataSourceProperties") DataSourceProperties properties) {
        return properties.initializeDataSourceBuilder()
                .type(HikariDataSource.class)
                .build();
    }

    /**
     * EntityManagerFactory para Commands
     *
     * Escanea entities en: msdata.domain.command
     * Usa configuración JPA de application.yml
     */
    @Bean
    @Primary
    public LocalContainerEntityManagerFactoryBean commandEntityManagerFactory(
            EntityManagerFactoryBuilder builder,
            @Qualifier("commandDataSource") DataSource dataSource) {

        Map<String, Object> properties = new HashMap<>();
        properties.put("hibernate.physical_naming_strategy",
                "org.hibernate.boot.model.naming.CamelCaseToUnderscoresNamingStrategy");
        properties.put("hibernate.implicit_naming_strategy",
                "org.springframework.boot.orm.jpa.hibernate.SpringImplicitNamingStrategy");

        // DDL: En producción usar 'validate' o Flyway/Liquibase
        properties.put("hibernate.hbm2ddl.auto", "validate");

        return builder
                .dataSource(dataSource)
                .packages("msdata.domain.command")    // Entities de escritura
                .persistenceUnit("command")
                .properties(properties)
                .build();
    }

    /**
     * TransactionManager para Commands
     *
     * Gestiona transacciones de escritura:
     * - ACID garantizado
     * - Rollback automático en errores
     * - Integrado con @Transactional
     */
    @Bean
    @Primary
    public PlatformTransactionManager commandTransactionManager(
            @Qualifier("commandEntityManagerFactory") EntityManagerFactory entityManagerFactory) {
        return new JpaTransactionManager(entityManagerFactory);
    }
}
