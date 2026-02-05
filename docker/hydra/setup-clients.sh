#!/bin/bash
# Script para configurar clientes OAuth2 en Ory Hydra

set -e

echo "🔐 Configurando clientes OAuth2 en Hydra..."
echo ""

# Esperar a que Hydra esté listo
echo "⏳ Esperando a que Hydra esté disponible..."
MAX_RETRIES=30
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:4445/health/ready > /dev/null 2>&1; then
        echo "   ✅ Hydra está listo"
        break
    fi
    RETRY=$((RETRY + 1))
    echo -n "."
    sleep 1
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo ""
    echo "❌ Error: Hydra no está disponible"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Creando clientes OAuth2..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Cliente 1: ms-data-client (para microservicios)
echo "1️⃣  Creando cliente: ms-data-client"
docker-compose exec -T hydra hydra create oauth2-client \
    --endpoint http://localhost:4445 \
    --name "MS Data Client" \
    --secret ms-data-client-secret-change-in-production \
    --grant-type client_credentials,authorization_code,refresh_token \
    --response-type code,id_token,token \
    --scope openid,offline,profile,email \
    --redirect-uri http://localhost:8080/callback \
    --redirect-uri http://localhost:8080/login/oauth2/code/hydra \
    --format json 2>&1 | head -10 || echo "   ⚠️  Cliente ya existe o error al crear"

echo ""

# Cliente 2: web-app-client
echo "2️⃣  Creando cliente: web-app-client"
docker-compose exec -T hydra hydra create oauth2-client \
    --endpoint http://localhost:4445 \
    --name "Web Application" \
    --secret web-app-client-secret-change-in-production \
    --grant-type client_credentials,authorization_code,refresh_token \
    --response-type code,id_token,token \
    --scope openid,offline,profile,email \
    --redirect-uri http://localhost:3000/callback \
    --format json 2>&1 | head -10 || echo "   ⚠️  Cliente ya existe o error al crear"

echo ""

# Cliente 3: test-client
echo "3️⃣  Creando cliente: test-client"
docker-compose exec -T hydra hydra create oauth2-client \
    --endpoint http://localhost:4445 \
    --name "Test Client" \
    --secret test-client-secret \
    --grant-type client_credentials,authorization_code,refresh_token \
    --response-type code,id_token,token \
    --scope openid,offline,profile,email \
    --redirect-uri http://localhost:9090/callback \
    --format json 2>&1 | head -10 || echo "   ⚠️  Cliente ya existe o error al crear"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Clientes OAuth2 configurados"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Listar clientes
echo "📋 Clientes configurados:"
docker-compose exec -T hydra hydra list clients --endpoint http://localhost:4445

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 Credenciales de Clientes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Cliente 1: ms-data-client"
echo "  Client ID:     ms-data-client"
echo "  Client Secret: ms-data-client-secret-change-in-production"
echo ""
echo "Cliente 2: web-app-client"
echo "  Client ID:     web-app-client"
echo "  Client Secret: web-app-client-secret-change-in-production"
echo ""
echo "Cliente 3: test-client"
echo "  Client ID:     test-client"
echo "  Client Secret: test-client-secret"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Test Client Credentials"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "curl -X POST http://localhost:4444/oauth2/token \\"
echo "  -H \"Content-Type: application/x-www-form-urlencoded\" \\"
echo "  -d \"grant_type=client_credentials\" \\"
echo "  -d \"client_id=ms-data-client\" \\"
echo "  -d \"client_secret=ms-data-client-secret-change-in-production\" \\"
echo "  -d \"scope=openid profile email\""
echo ""
