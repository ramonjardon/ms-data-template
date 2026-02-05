#!/bin/bash
# Script para iniciar todos los servicios (PostgreSQL + Redis)

set -e

echo "════════════════════════════════════════════════════════"
echo "  🚀 Iniciando Servicios de Datos"
echo "  PostgreSQL 17.7 + Redis 7.4 (TLS) + Dex OAuth2"
echo "════════════════════════════════════════════════════════"
echo ""

# 1. Verificar certificados TLS de Redis
if [ ! -f "docker/redis/tls/redis.crt" ] || [ ! -f "docker/redis/tls/redis.key" ] || [ ! -f "docker/redis/tls/ca.crt" ]; then
    echo "🔐 Generando certificados TLS para Redis..."
    echo ""

    # Asegurar que el directorio existe
    mkdir -p docker/redis/tls

    # Generar certificados
    cd docker/redis
    chmod +x generate-certs.sh
    ./generate-certs.sh
    cd ../..
    echo ""

    # Verificar que se generaron correctamente
    if [ ! -f "docker/redis/tls/redis.crt" ]; then
        echo "❌ Error: No se pudieron generar los certificados TLS"
        echo "   Verifica el archivo docker/redis/generate-certs.sh"
        exit 1
    fi

    echo "✅ Certificados TLS generados correctamente"
    echo ""
else
    echo "✅ Certificados TLS de Redis ya existen"
    echo ""
fi

# 2. Verificar certificados TLS de Dex
if [ ! -f "docker/dex/tls/dex.crt" ] || [ ! -f "docker/dex/tls/dex.key" ] || [ ! -f "docker/dex/tls/ca.crt" ]; then
    echo "🔐 Generando certificados TLS para Dex..."
    echo ""

    # Asegurar que el directorio existe
    mkdir -p docker/dex/tls

    # Generar certificados
    cd docker/dex
    chmod +x generate-certs.sh
    ./generate-certs.sh
    cd ../..
    echo ""

    # Verificar que se generaron correctamente
    if [ ! -f "docker/dex/tls/dex.crt" ]; then
        echo "❌ Error: No se pudieron generar los certificados TLS de Dex"
        echo "   Verifica el archivo docker/dex/generate-certs.sh"
        exit 1
    fi

    echo "✅ Certificados TLS de Dex generados correctamente"
    echo ""
else
    echo "✅ Certificados TLS de Dex ya existen"
    echo ""
fi

# 3. Iniciar todos los servicios
echo "🚀 Iniciando PostgreSQL, Redis y Dex..."
docker-compose up -d postgres redis dex

echo ""
echo "⏳ Esperando a que los servicios estén listos..."
sleep 5

# 3. Verificar PostgreSQL
echo ""
echo "📊 Verificando PostgreSQL..."
MAX_RETRIES=30
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    if docker-compose exec -T postgres pg_isready -U msdata_user -d msdata > /dev/null 2>&1; then
        echo "   ✅ PostgreSQL listo"
        break
    fi
    RETRY=$((RETRY + 1))
    sleep 1
done

# 4. Verificar Redis
echo ""
echo "🔐 Verificando Redis..."
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    if docker-compose exec -T redis redis-cli \
        --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
        -p 6380 -a redis_password ping > /dev/null 2>&1; then
        echo "   ✅ Redis listo"
        break
    fi
    RETRY=$((RETRY + 1))
    sleep 1
done

# 5. Verificar Dex
echo ""
echo "🔐 Verificando Dex..."
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:5558/healthz > /dev/null 2>&1; then
        echo "   ✅ Dex listo"
        break
    fi
    RETRY=$((RETRY + 1))
    sleep 1
done

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Servicios iniciados correctamente"
echo "════════════════════════════════════════════════════════"
echo ""

# Mostrar estado
echo "📊 Estado de los servicios:"
docker-compose ps

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 POSTGRESQL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  🔗 Conexión:"
echo "     Host: localhost:5432"
echo "     User: msdata_user"
echo "     Pass: msdata_password"
echo "     DB:   msdata"
echo ""
echo "  📦 Conectar:"
echo "     docker-compose exec postgres psql -U msdata_user -d msdata"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 REDIS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  🔗 Conexión:"
echo "     Protocol: rediss:// (TLS)"
echo "     Host:     localhost:6380"
echo "     Pass:     redis_password"
echo "     URL:      rediss://:redis_password@localhost:6380"
echo ""
echo "  📦 Conectar:"
echo "     docker-compose exec redis redis-cli \\"
echo "       --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \\"
echo "       -p 6380 -a redis_password"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 DEX (OAuth2/OIDC)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  🔗 Endpoints:"
echo "     Issuer:   https://localhost:5556/dex"
echo "     Token:    https://localhost:5556/dex/token"
echo "     Health:   http://localhost:5558/healthz"
echo "     Metrics:  http://localhost:5558/metrics"
echo ""
echo "  🔑 Cliente Principal:"
echo "     Client ID:     ms-data-client"
echo "     Client Secret: ms-data-client-secret-change-in-production"
echo ""
echo "  📦 Obtener Token:"
echo "     curl -X POST https://localhost:5556/dex/token --insecure \\"
echo "       -H \"Content-Type: application/x-www-form-urlencoded\" \\"
echo "       -d \"grant_type=client_credentials\" \\"
echo "       -d \"client_id=ms-data-client\" \\"
echo "       -d \"client_secret=ms-data-client-secret-change-in-production\" \\"
echo "       -d \"scope=openid profile email\""
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛠️  COMANDOS ÚTILES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  # Ver logs de todos los servicios"
echo "  docker-compose logs -f"
echo ""
echo "  # Ver logs de un servicio específico"
echo "  docker-compose logs -f postgres"
echo "  docker-compose logs -f redis"
echo ""
echo "  # Detener todos los servicios"
echo "  docker-compose down"
echo ""
echo "  # Monitorear storage de PostgreSQL"
echo "  ./monitor-storage.sh"
echo ""
echo "════════════════════════════════════════════════════════"
