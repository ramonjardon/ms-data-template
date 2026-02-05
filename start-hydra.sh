#!/bin/bash
# Script para inicializar Hydra - ejecuta migraciones y luego inicia el servidor

set -e

echo "🔐 Iniciando Ory Hydra..."
echo ""

# 1. Verificar que PostgreSQL de Hydra está disponible
echo "⏳ Esperando a que PostgreSQL de Hydra esté disponible..."
docker-compose up -d postgres-hydra

MAX_RETRIES=30
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    if docker-compose exec -T postgres-hydra pg_isready -U hydra_user -d hydra > /dev/null 2>&1; then
        echo "   ✅ PostgreSQL de Hydra está listo"
        break
    fi
    RETRY=$((RETRY + 1))
    echo -n "."
    sleep 1
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo ""
    echo "❌ Error: PostgreSQL de Hydra no está disponible"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Ejecutando migraciones de base de datos..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 2. Ejecutar migraciones (sin iniciar el servidor)
docker-compose run --rm hydra migrate sql -e --yes

echo ""
echo "✅ Migraciones completadas"
echo ""

# 3. Iniciar Hydra
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Iniciando servidor Hydra..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker-compose up -d hydra

# 4. Esperar a que Hydra esté listo
echo "⏳ Esperando a que Hydra esté disponible..."
sleep 5

RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:4445/health/ready > /dev/null 2>&1; then
        echo ""
        echo "✅ Hydra está listo!"
        break
    fi
    RETRY=$((RETRY + 1))
    echo -n "."
    sleep 1
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo ""
    echo "❌ Error: Hydra no está respondiendo"
    echo ""
    echo "Ver logs con: docker-compose logs hydra"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Hydra iniciado correctamente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Mostrar información
echo "📊 Información de Hydra:"
echo ""
echo "  🔗 Puerto Público: http://localhost:4444"
echo "  🔧 Puerto Admin:   http://localhost:4445"
echo ""
echo "  📋 Healthcheck:"
curl -s http://localhost:4445/health/ready | head -5
echo ""
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 Próximos pasos"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Configurar clientes OAuth2:"
echo "   cd docker/hydra && ./setup-clients.sh"
echo ""
echo "2. Ver logs:"
echo "   docker-compose logs -f hydra"
echo ""
echo "3. Probar token:"
echo "   curl -X POST http://localhost:4444/oauth2/token \\"
echo "     -d \"grant_type=client_credentials\" \\"
echo "     -d \"client_id=ms-data-client\" \\"
echo "     -d \"client_secret=ms-data-client-secret-change-in-production\""
echo ""
