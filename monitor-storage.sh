#!/bin/bash
# Script de monitoreo de storage de PostgreSQL
# Verifica el uso de almacenamiento y alerta si supera el umbral

set -e

# Configuración
THRESHOLD=85  # Alerta al 85%
LIMIT_GB=8

echo "════════════════════════════════════════════════════════"
echo "  📊 Monitor de Storage PostgreSQL"
echo "  Límite configurado: ${LIMIT_GB}GB"
echo "  Umbral de alerta: ${THRESHOLD}%"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que PostgreSQL está corriendo
if ! docker-compose ps postgres | grep -q "Up"; then
    echo "❌ Error: PostgreSQL no está corriendo"
    echo "   Iniciar con: docker-compose up -d postgres"
    exit 1
fi

# Obtener información de storage
echo "🔍 Obteniendo información de storage..."
echo ""

STORAGE_INFO=$(docker-compose exec -T postgres psql -U msdata_user -d msdata -t -A -F'|' << 'EOF'
SELECT
    size_bytes,
    size_pretty,
    percent_used,
    status
FROM public.check_database_size();
EOF
)

# Parsear resultados
SIZE_BYTES=$(echo "$STORAGE_INFO" | cut -d'|' -f1)
SIZE_PRETTY=$(echo "$STORAGE_INFO" | cut -d'|' -f2)
PERCENT_USED=$(echo "$STORAGE_INFO" | cut -d'|' -f3)
STATUS=$(echo "$STORAGE_INFO" | cut -d'|' -f4)

echo "📦 Tamaño actual: $SIZE_PRETTY"
echo "🎯 Límite: ${LIMIT_GB}GB"
echo "📊 Uso: ${PERCENT_USED}%"
echo "🚦 Estado: $STATUS"
echo ""

# Verificar umbral
PERCENT_INT=$(echo "$PERCENT_USED" | cut -d'.' -f1)

if [ "$PERCENT_INT" -ge "$THRESHOLD" ]; then
    echo "⚠️  ¡ALERTA! Uso de almacenamiento superior al ${THRESHOLD}%"
    echo ""
    echo "📋 Top 10 tablas más grandes:"
    docker-compose exec -T postgres psql -U msdata_user -d msdata << 'EOF'
SELECT
    schema_name || '.' || table_name as tabla,
    total_size as tamaño,
    row_count as filas
FROM public.table_sizes()
LIMIT 10;
EOF
    echo ""
    echo "🗑️  Ejecutando limpieza automática..."
    docker-compose exec -T postgres psql -U msdata_user -d msdata << 'EOF'
SELECT * FROM public.auto_cleanup_storage(85);
EOF
    echo ""
    echo "✅ Limpieza completada"
    echo ""

    # Obtener nuevo estado
    NEW_INFO=$(docker-compose exec -T postgres psql -U msdata_user -d msdata -t -A << 'EOF'
SELECT size_pretty || ' (' || percent_used || '%)' FROM public.check_database_size();
EOF
)
    echo "📊 Nuevo estado: $NEW_INFO"

elif [ "$PERCENT_INT" -ge 70 ]; then
    echo "⚠️  Advertencia: Uso de almacenamiento en ${PERCENT_USED}%"
    echo "   Considera ejecutar limpieza pronto"
    echo ""
    echo "💡 Para limpiar manualmente:"
    echo "   docker-compose exec postgres psql -U msdata_user -d msdata -c \"SELECT * FROM public.auto_cleanup_storage();\""
else
    echo "✅ Uso de almacenamiento dentro de límites normales"
fi

echo ""
echo "────────────────────────────────────────────────────────"
echo "📚 Comandos útiles:"
echo ""
echo "  # Ver detalle de storage"
echo "  docker-compose exec postgres psql -U msdata_user -d msdata -c 'SELECT * FROM public.storage_monitor;'"
echo ""
echo "  # Ver tamaño de tablas"
echo "  docker-compose exec postgres psql -U msdata_user -d msdata -c 'SELECT * FROM public.table_sizes();'"
echo ""
echo "  # Ejecutar limpieza manual"
echo "  docker-compose exec postgres psql -U msdata_user -d msdata -c 'SELECT * FROM public.auto_cleanup_storage();'"
echo ""
echo "════════════════════════════════════════════════════════"
