# Dockerfile para PostgreSQL 17.7 con pg_partman
FROM postgres:17.7

# Información del mantenedor
LABEL maintainer="ramonjardon"
LABEL description="PostgreSQL 17.7 con pg_partman y extensiones para timeseries"

# Instalar dependencias y pg_partman
RUN apt-get update && apt-get install -y \
    postgresql-17-partman \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configuración de pg_partman en postgresql.conf
RUN echo "shared_preload_libraries = 'pg_partman_bgw'" >> /usr/share/postgresql/postgresql.conf.sample \
    && echo "pg_partman_bgw.interval = 3600" >> /usr/share/postgresql/postgresql.conf.sample \
    && echo "pg_partman_bgw.role = 'msdata_user'" >> /usr/share/postgresql/postgresql.conf.sample \
    && echo "pg_partman_bgw.dbname = 'msdata'" >> /usr/share/postgresql/postgresql.conf.sample

# El resto de la configuración se mantiene igual que la imagen base
