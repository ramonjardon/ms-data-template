# --- ETAPA 1: Construcción (Build) ---
# Actualizado a JDK 25 sobre Alpine
FROM eclipse-temurin:25-jdk-alpine AS build

WORKDIR /app

# 1. Copiamos el wrapper de Maven y el pom.xml
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
# Descargamos dependencias (aprovechando la caché de Docker)
RUN ./mvnw dependency:go-offline -B

# 2. Copiamos el código fuente y compilamos
COPY src ./src
RUN ./mvnw clean package -DskipTests -B

# --- ETAPA 2: Ejecución (Runtime) ---
# Usamos el JRE 25 para minimizar el tamaño de la imagen final
FROM eclipse-temurin:25-jre-alpine

WORKDIR /app

# 3. Soporte para Timezone Europe/Madrid
RUN apk add --no-cache tzdata
ENV TZ=Europe/Madrid

# 4. Copiamos el artefacto desde la etapa de build
COPY --from=build /app/target/*.jar app.jar

# 5. Configuración optimizada para Java 25 y Virtual Threads
# -XX:+UseZGC y -XX:+ZGenerational: Ideal para Java 25, reduce latencias de GC casi a cero
# -XX:MaxRAMPercentage=75.0: Gestión dinámica de memoria en contenedores
ENTRYPOINT ["java", \
            "-XX:+UseContainerSupport", \
            "-XX:MaxRAMPercentage=75.0", \
            "-XX:+UseZGC", \
            "-XX:+ZGenerational", \
            "-Duser.timezone=Europe/Madrid", \
            "-Djdk.virtualThreadScheduler.maxPoolSize=256", \
            "-jar", \
            "app.jar"]

# Puerto de la aplicación
EXPOSE 8080