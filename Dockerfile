# Dockerfile optimizado para Leapcell con GraalVM Native Image
# Usando Maven Wrapper (mvnw) - no requiere instalar Maven

FROM ghcr.io/graalvm/native-image-community:25-ol9 AS builder

WORKDIR /build

# Copiar Maven Wrapper y POM
COPY .mvn .mvn
COPY mvnw pom.xml ./

# Dar permisos de ejecución al wrapper
RUN chmod +x mvnw

# Descargar dependencias (se cachea si pom.xml no cambia)
RUN ./mvnw dependency:go-offline -B

# Copiar el código fuente
COPY src ./src

# Construir la imagen nativa
RUN ./mvnw -Pnative native:compile -DskipTests \
    -Dspring-boot.build-image.skip=true \
    -Dspring.native.remove-unused-autoconfig=true

# ============================================
# Stage 2: Runtime - Debian Slim (más ligera)
# ============================================
FROM debian:12-slim

# Instalar solo lo esencial + curl para health checks
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libstdc++6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && groupadd -r -g 1001 appuser \
    && useradd -r -u 1001 -g appuser -m -s /sbin/nologin appuser

WORKDIR /app

# Copiar ejecutable nativo
COPY --from=builder --chown=appuser:appuser /build/target/ms-data-template /app/application

# Cambiar a usuario no-root
USER appuser

# Variables de entorno
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s \
            --timeout=3s \
            --start-period=5s \
            --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health/liveness || exit 1

ENTRYPOINT ["/app/application", \
    "-XX:MaximumHeapSizePercent=75", \
    "-XX:MaximumYoungGenerationSizePercent=25", \
    "-Djdk.virtualThreadScheduler.maxQueueSize=10000"]