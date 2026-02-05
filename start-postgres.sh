#!/bin/bash
# Script para iniciar PostgreSQL de forma limpia
# Uso: ./start-postgres.sh

set -e

echo "🐘 Iniciando PostgreSQL 17.7..."
echo ""

# Verificar si Docker está corriendo
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker no está corriendo"
    echo "   Por favor, inicia Docker Desktop y vuelve a intentar"
    exit 1
fi

# Detener contenedor existente si está corriendo
if docker ps -a --format '{{.Names}}' | grep -q '^ms-data-postgres$'; then
    echo "🛑 Deteniendo contenedor existente..."
    docker-compose down
    echo ""
fi

# Iniciar PostgreSQL
echo "🚀 Iniciando PostgreSQL..."
docker-compose up -d postgres

# Esperar a que PostgreSQL esté listo
echo ""
echo "⏳ Esperando a que PostgreSQL esté listo..."
sleep 5

MAX_RETRIES=30
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    if docker-compose exec -T postgres pg_isready -U msdata_user -d msdata > /dev/null 2>&1; then
        echo ""
        echo "✅ PostgreSQL está listo!"
        break
    fi

    RETRY=$((RETRY + 1))
    echo -n "."
    sleep 1
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo ""
    echo "❌ PostgreSQL no está respondiendo después de ${MAX_RETRIES} segundos"
    echo ""
    echo "Ver logs con: docker-compose logs postgres"
    exit 1
fi

echo ""
echo "📊 Estado del contenedor:"
docker-compose ps

echo ""
echo "📦 Extensiones instaladas:"
docker-compose exec -T postgres psql -U msdata_user -d msdata -c "SELECT extname, extversion FROM pg_extension WHERE extname NOT IN ('plpgsql') ORDER BY extname;" 2>/dev/null || echo "   (Ejecutando inicialización...)"

echo ""
echo "🕐 Timezone configurado:"
docker-compose exec -T postgres psql -U msdata_user -d msdata -c "SHOW timezone;" 2>/dev/null || echo "   (Configurando...)"

echo ""
echo "📋 Funciones de particionamiento disponibles:"
docker-compose exec -T postgres psql -U msdata_user -d msdata -c "SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'timeseries' ORDER BY routine_name;" 2>/dev/null || echo "   (Configurando...)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ PostgreSQL iniciado correctamente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Comandos útiles:"
echo ""
echo "  # Conectar a PostgreSQL"
echo "  docker-compose exec postgres psql -U msdata_user -d msdata"
echo ""
echo "  # Ver logs"
echo "  docker-compose logs -f postgres"
echo ""
echo "  # Detener PostgreSQL"
echo "  docker-compose down"
echo ""
echo "  # Backup"
echo "  docker-compose exec postgres pg_dump -U msdata_user msdata > backup.sql"
echo ""
echo "📖 Documentación: docker/postgres/PARTICIONES_SIMPLE.md"
echo ""
