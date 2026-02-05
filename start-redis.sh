#!/bin/bash
# Script para iniciar Redis con TLS

set -e

echo "🔐 Iniciando Redis con TLS (rediss://)..."
echo ""

# Verificar que existen los certificados TLS
if [ ! -f "docker/redis/tls/redis.crt" ]; then
    echo "⚠️  Certificados TLS no encontrados. Generando..."
    echo ""
    cd docker/redis
    chmod +x generate-certs.sh
    ./generate-certs.sh
    cd ../..
    echo ""
fi

# Iniciar Redis
echo "🚀 Iniciando Redis..."
docker-compose up -d redis

# Esperar a que Redis esté listo
echo ""
echo "⏳ Esperando a que Redis esté listo..."
sleep 3

MAX_RETRIES=30
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    if docker-compose exec -T redis redis-cli \
        --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
        -p 6380 -a redis_password ping > /dev/null 2>&1; then
        echo ""
        echo "✅ Redis está listo!"
        break
    fi

    RETRY=$((RETRY + 1))
    echo -n "."
    sleep 1
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo ""
    echo "❌ Error: Redis no está respondiendo después de ${MAX_RETRIES} segundos"
    echo ""
    echo "Ver logs con: docker-compose logs redis"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Redis iniciado correctamente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Mostrar info
echo "📊 Información de Redis:"
echo ""
docker-compose exec -T redis redis-cli \
    --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
    -p 6380 -a redis_password \
    INFO server | grep -E "redis_version|redis_mode|os|tcp_port"

echo ""
echo "💾 Uso de memoria:"
docker-compose exec -T redis redis-cli \
    --tls --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \
    -p 6380 -a redis_password \
    INFO memory | grep -E "used_memory_human|maxmemory_human|maxmemory_policy"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 Comandos útiles:"
echo ""
echo "  # Conectar a Redis CLI"
echo "  docker-compose exec redis redis-cli --tls \\"
echo "    --cert /tls/redis.crt --key /tls/redis.key --cacert /tls/ca.crt \\"
echo "    -p 6380 -a redis_password"
echo ""
echo "  # Ver logs"
echo "  docker-compose logs -f redis"
echo ""
echo "  # Ver estado"
echo "  docker-compose ps redis"
echo ""
echo "  # Detener Redis"
echo "  docker-compose down redis"
echo ""
echo "🔗 URL de conexión:"
echo "  rediss://:redis_password@localhost:6380"
echo ""
echo "📖 Documentación: docker/redis/README.md"
echo ""
