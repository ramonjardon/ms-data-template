package msdata.configuration;


import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.util.TimeZone;

@Component
public class TimeZoneConfiguration {
    @EventListener(ApplicationReadyEvent.class)
    public void setTimeZone() {
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/Madrid"));
    }
}
