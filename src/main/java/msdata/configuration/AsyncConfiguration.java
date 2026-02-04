package msdata.configuration;

import org.springframework.boot.tomcat.TomcatProtocolHandlerCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.AsyncTaskExecutor;
import org.springframework.core.task.support.TaskExecutorAdapter;
import org.springframework.scheduling.annotation.EnableAsync;

import java.util.concurrent.Executors;

@EnableAsync
@Configuration
public class AsyncConfiguration {
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
}
