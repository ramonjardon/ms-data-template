#!/bin/bash
# Script para reiniciar PostgreSQL con el locale corregido

set -e

echo "🔧 Corrigiendo error de locale en PostgreSQL..."
echo ""

echo "1️⃣  Deteniendo contenedor actual..."
docker-compose down

echo ""
echo "2️⃣  Eliminando volumen con configuración errónea..."
docker volume rm ms-data-template_postgres_data 2>/dev/null || echo "   (Volumen ya eliminado o no existe)"

echo ""
echo "3️⃣  Iniciando PostgreSQL con locale corregido (C.UTF-8)..."
docker-compose up -d postgres

echo ""
echo "4️⃣  Esperando a que PostgreSQL esté listo..."
sleep 5

MAX_RETRIES=30
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    if docker-compose exec -T postgres pg_isready -U msdata_user -d msdata > /dev/null 2>&1; then
        echo ""
        echo "✅ PostgreSQL iniciado correctamente con locale C.UTF-8"
        break
    fi

    RETRY=$((RETRY + 1))
    echo -n "."
    sleep 1
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo ""
    echo "❌ Error: PostgreSQL no está respondiendo"
    echo ""
    echo "Ver logs con:"
    echo "  docker-compose logs postgres"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ PostgreSQL configurado correctamente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📊 Verificando configuración..."
echo ""

echo "🕐 Timezone:"
docker-compose exec -T postgres psql -U msdata_user -d msdata -c "SHOW timezone;" 2>/dev/null

echo ""
echo "🌍 Locale:"
docker-compose exec -T postgres psql -U msdata_user -d msdata -c "SHOW lc_collate;" 2>/dev/null
docker-compose exec -T postgres psql -U msdata_user -d msdata -c "SHOW lc_ctype;" 2>/dev/null

echo ""
echo "📦 Extensiones instaladas:"
docker-compose exec -T postgres psql -U msdata_user -d msdata -c "SELECT extname FROM pg_extension WHERE extname NOT IN ('plpgsql') ORDER BY extname;" 2>/dev/null

echo ""
echo "🔧 Funciones de particionamiento:"
docker-compose exec -T postgres psql -U msdata_user -d msdata -c "SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'timeseries' ORDER BY routine_name;" 2>/dev/null

echo ""
echo "📊 Storage monitor:"
docker-compose exec -T postgres psql -U msdata_user -d msdata -c "SELECT * FROM public.storage_monitor;" 2>/dev/null

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Todo listo para usar!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Para conectar:"
echo "  docker-compose exec postgres psql -U msdata_user -d msdata"
echo ""
