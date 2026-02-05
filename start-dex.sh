#!/bin/bash
# Script para iniciar Dex OAuth2/OIDC Server

set -e

echo "🔐 Iniciando Dex (OAuth2/OIDC)..."
echo ""

# Verificar que existen los certificados TLS
if [ ! -f "docker/dex/tls/dex.crt" ]; then
    echo "⚠️  Certificados TLS no encontrados. Generando..."
    echo ""
    cd docker/dex
    chmod +x generate-certs.sh
    ./generate-certs.sh
    cd ../..
    echo ""
fi

# Iniciar Dex
echo "🚀 Iniciando Dex..."
docker-compose up -d dex

# Esperar a que Dex esté listo
echo ""
echo "⏳ Esperando a que Dex esté listo..."
sleep 3

MAX_RETRIES=30
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:5558/healthz > /dev/null 2>&1; then
        echo ""
        echo "✅ Dex está listo!"
        break
    fi

    RETRY=$((RETRY + 1))
    echo -n "."
    sleep 1
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo ""
    echo "❌ Error: Dex no está respondiendo después de ${MAX_RETRIES} segundos"
    echo ""
    echo "Ver logs con: docker-compose logs dex"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Dex iniciado correctamente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Mostrar información
echo "📊 Información de Dex:"
echo ""
echo "  🔗 Issuer: https://localhost:5556/dex"
echo "  📊 Metrics: http://localhost:5558/metrics"
echo "  💚 Health: http://localhost:5558/healthz"
echo ""

# Verificar healthcheck
HEALTH=$(curl -s http://localhost:5558/healthz)
echo "  Healthcheck: $HEALTH"
echo ""

# Mostrar clientes configurados
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 Clientes OAuth2 Configurados:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1️⃣  MS Data Client"
echo "      Client ID: ms-data-client"
echo "      Client Secret: ms-data-client-secret-change-in-production"
echo ""
echo "  2️⃣  Web App Client"
echo "      Client ID: web-app-client"
echo "      Client Secret: web-app-client-secret-change-in-production"
echo ""
echo "  3️⃣  Test Client"
echo "      Client ID: test-client"
echo "      Client Secret: test-client-secret"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 Ejemplo: Obtener Access Token"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "curl -X POST https://localhost:5556/dex/token \\"
echo "  --insecure \\"
echo "  -H \"Content-Type: application/x-www-form-urlencoded\" \\"
echo "  -d \"grant_type=client_credentials\" \\"
echo "  -d \"client_id=ms-data-client\" \\"
echo "  -d \"client_secret=ms-data-client-secret-change-in-production\" \\"
echo "  -d \"scope=openid profile email\""
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 URLs Útiles:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  # OpenID Discovery"
echo "  curl --insecure https://localhost:5556/dex/.well-known/openid-configuration | jq"
echo ""
echo "  # JWK Keys"
echo "  curl --insecure https://localhost:5556/dex/keys | jq"
echo ""
echo "  # Métricas"
echo "  curl http://localhost:5558/metrics"
echo ""
echo "  # Ver logs"
echo "  docker-compose logs -f dex"
echo ""
echo "📖 Documentación: docker/dex/README.md"
echo ""
