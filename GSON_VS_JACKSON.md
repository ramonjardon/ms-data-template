# Gson vs Jackson en Spring Boot - ¿Excluir o No?

## 🎯 Respuesta para tu Proyecto

### ✅ Estado Actual: NO tienes Gson

```bash
./mvnw dependency:tree | grep gson
# Resultado: (vacío) ✅
```

**Conclusión**: NO necesitas excluir `GsonAutoConfiguration`

## 🤔 ¿Por Qué Preguntar por Gson?

Es una **excelente pregunta** porque:

1. **Gson puede entrar por dependencias transitivas** - Sin que te des cuenta
2. **Puede causar conflictos con Jackson** - Dos librerías JSON compitiendo
3. **Spring Boot prefiere Jackson** - Pero si Gson está, puede haber confusión

## 📊 Jackson vs Gson: Comparación

| Aspecto | Jackson | Gson |
|---------|---------|------|
| **Velocidad** | ⚡ Más rápido (~2x) | Más lento |
| **Memoria** | 💾 Menos memoria | Más memoria |
| **Features** | ✅ Más completo | Básico |
| **Java Time API** | ✅ Módulo nativo | ❌ Requiere adapters |
| **Spring Boot** | ✅ Por defecto | ⚠️ Secundario |
| **Native Image** | ✅ Mejor soporte | ⚠️ Más complejo |

## 🔍 Cuándo Gson Aparece en tu Proyecto

### Librerías que Traen Gson

```xml
<!-- Google API Client -->
<dependency>
    <groupId>com.google.api-client</groupId>
    <artifactId>google-api-client</artifactId>
    <!-- Trae Gson automáticamente -->
</dependency>

<!-- Firebase Admin SDK -->
<dependency>
    <groupId>com.google.firebase</groupId>
    <artifactId>firebase-admin</artifactId>
    <!-- Trae Gson automáticamente -->
</dependency>

<!-- Google Cloud Libraries -->
<dependency>
    <groupId>com.google.cloud</groupId>
    <artifactId>google-cloud-storage</artifactId>
    <!-- Puede traer Gson -->
</dependency>

<!-- Retrofit (versiones antiguas) -->
<dependency>
    <groupId>com.squareup.retrofit2</groupId>
    <artifactId>retrofit</artifactId>
    <version>2.x</version>
    <!-- Versiones antiguas usan Gson -->
</dependency>
```

## ⚠️ Problemas si Gson Está Presente

### 1. Conflicto de Serializadores

```java
// Puede usar Jackson o Gson dependiendo del contexto
@RestController
public class MyController {
    
    @GetMapping("/data")
    public MyDTO getData() {
        // ¿Qué usa Spring Boot para serializar?
        // - Jackson (por defecto)
        // - ¿Pero si Gson está presente?
        return new MyDTO();
    }
}
```

### 2. Inconsistencia de Formatos

```java
// Jackson con tu configuración
{
  "date": "2026-02-06T15:30:45+01:00",  // ISO-8601
  "value": "test"
  // nulls omitidos
}

// Si Gson toma control
{
  "date": "Feb 6, 2026, 3:30:45 PM",  // Formato diferente
  "value": "test",
  "nullField": null  // Nulls incluidos
}
```

### 3. Pérdida de Configuración

Tu `JacksonConfig.java` no se aplicaría si Gson toma el control:
- ❌ Zona horaria `Europe/Madrid` ignorada
- ❌ JavaTimeModule no funciona
- ❌ NON_NULL no se aplica

## ✅ Soluciones si Gson Aparece

### Solución 1: Excluir GsonAutoConfiguration (Recomendado)

```java
@SpringBootApplication(exclude = {
    org.springframework.boot.autoconfigure.gson.GsonAutoConfiguration.class
})
public class MicroserviceApp {
    static void main(String[] args) {
        SpringApplication.run(MicroserviceApp.class, args);
    }
}
```

**Ventajas**:
- ✅ Gson sigue en el classpath (otras librerías pueden usarlo)
- ✅ Spring Boot solo usa Jackson
- ✅ Simple

### Solución 2: Excluir Gson de la Dependencia

```xml
<dependency>
    <groupId>com.google.api-client</groupId>
    <artifactId>google-api-client</artifactId>
    <exclusions>
        <exclusion>
            <groupId>com.google.code.gson</groupId>
            <artifactId>gson</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

**Ventajas**:
- ✅ Gson no está en el classpath
- ✅ Menos dependencias
- ✅ Imagen nativa más pequeña

**Desventajas**:
- ⚠️ Si la librería NECESITA Gson, fallará

### Solución 3: application.yml (No siempre funciona)

```yaml
spring:
  http:
    converters:
      preferred-json-mapper: jackson  # Preferir Jackson
```

**Limitación**: Spring Boot ya prefiere Jackson, esto no ayuda mucho.

## 🧪 Cómo Verificar Qué Librería Usa Spring Boot

### Test 1: Ver Autoconfiguraciones Activas

```bash
# Ejecutar aplicación con debug
java -jar app.jar --debug

# Buscar en logs:
# GsonAutoConfiguration matched:
#    - @ConditionalOnClass found required class 'com.google.gson.Gson'
```

### Test 2: Endpoint de Test

```java
@RestController
public class JsonTestController {
    
    @Autowired
    private HttpMessageConverters converters;
    
    @GetMapping("/test/json-library")
    public String getJsonLibrary() {
        return converters.getConverters().stream()
            .filter(c -> c instanceof MappingJackson2HttpMessageConverter ||
                        c instanceof GsonHttpMessageConverter)
            .map(c -> c.getClass().getSimpleName())
            .collect(Collectors.joining(", "));
    }
}
```

### Test 3: Verificar Formato de Fecha

```java
@RestController
public class DateTestController {
    
    @GetMapping("/test/date")
    public Map<String, Object> testDate() {
        return Map.of(
            "localDate", LocalDate.now(),
            "instant", Instant.now()
        );
    }
}

// Si usas Jackson (correcto):
// {"localDate":"2026-02-06","instant":"2026-02-06T14:30:45Z"}

// Si usa Gson (problema):
// {"localDate":"Feb 6, 2026","instant":"2026-02-06T14:30:45Z"}
```

## 📋 Checklist de Decisión

¿Debería excluir Gson?

- [ ] ✅ **Verifica si está presente**: `./mvnw dependency:tree | grep gson`
- [ ] ❌ **Si NO está** → No hacer nada
- [ ] ✅ **Si SÍ está** → ¿La librería que lo trae lo NECESITA?
  - [ ] ✅ SI → Excluir solo `GsonAutoConfiguration.class`
  - [ ] ❌ NO → Excluir la dependencia completa del pom.xml

## 🎯 Tu Caso Específico

```bash
# Tu resultado actual:
./mvnw dependency:tree | grep gson
# (vacío) ✅

# Conclusión:
@SpringBootApplication  // ✅ Sin exclusiones necesarias
```

### Si Añades Google Cloud o Firebase

```bash
# ANTES de añadir la dependencia, verifica:
./mvnw dependency:tree | grep gson

# Si Gson aparece:
@SpringBootApplication(exclude = {
    GsonAutoConfiguration.class  // Asegurar Jackson
})
```

## 📊 Impacto de Excluir Gson

### Si Gson NO está (tu caso)
```
Excluir GsonAutoConfiguration: Sin efecto
Startup time: Sin cambio
Memoria: Sin cambio
```

### Si Gson SÍ está
```
Sin excluir:
- Puede usar Gson en algunos contextos ⚠️
- Inconsistencia de formato ⚠️
- Configuración Jackson no se aplica siempre ⚠️

Con exclusión:
- Solo Jackson ✅
- Formato consistente ✅
- Configuración garantizada ✅
```

## 🎉 Conclusión Final

### Tu Situación Actual

**NO necesitas excluir Gson** porque:
1. ✅ Gson no está en tu proyecto
2. ✅ Solo usas Jackson
3. ✅ Tu configuración funciona perfectamente

### Futuro: Si Añades Librerías de Google

**SÍ considera excluir** si:
1. Añades Google Cloud SDK
2. Añades Firebase Admin
3. Añades Google API Client

**Entonces usa**:
```java
@SpringBootApplication(exclude = {
    GsonAutoConfiguration.class
})
```

### Script de Verificación

He creado `check-autoconfig.sh` que detecta automáticamente:
- ✅ Si Gson está presente
- ✅ Qué librería lo trae
- ✅ Recomendaciones específicas

```bash
./check-autoconfig.sh
```

---

**Resumen**: Muy buena pregunta. En tu caso actual NO, pero es importante saberlo para el futuro. ✅
