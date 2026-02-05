package msdata.configuration;

import org.jspecify.annotations.NonNull;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.tomcat.TomcatProtocolHandlerCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.AsyncTaskExecutor;
import org.springframework.core.task.support.TaskExecutorAdapter;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.web.servlet.config.annotation.AsyncSupportConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.concurrent.Executors;

@EnableAsync
@Configuration
public class AsyncConfiguration {

    @Value("${spring.mvc.async.request-timeout:10000}")
    private long asyncTimeout;


    @Bean
    public TomcatProtocolHandlerCustomizer<?> protocolHandler() {
        return protocolHandler -> {
            protocolHandler.setExecutor(
                    Executors.newVirtualThreadPerTaskExecutor()
            );
        };
    }

    @Bean
    public AsyncTaskExecutor applicationTaskExecutor() {
        return new TaskExecutorAdapter(
                Executors.newVirtualThreadPerTaskExecutor()
        );
    }



    @Bean
    public WebMvcConfigurer webMvcConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void configureAsyncSupport(@NonNull AsyncSupportConfigurer configurer) {
                configurer.setTaskExecutor(applicationTaskExecutor());
                configurer.setDefaultTimeout(asyncTimeout);
            }
        };
    }
}
