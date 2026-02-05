#!/bin/bash
# Script para generar certificados TLS autofirmados para Redis
# Estos son para desarrollo/testing. En producción usa certificados válidos.

set -e

CERT_DIR="$(dirname "$0")/tls"
DAYS=3650  # 10 años

echo "🔐 Generando certificados TLS para Redis..."
echo ""

cd "$CERT_DIR"

# 1. Generar CA (Certificate Authority)
echo "1️⃣  Generando CA (Certificate Authority)..."
openssl genrsa -out ca.key 4096 2>/dev/null
openssl req -new -x509 -days $DAYS -key ca.key -out ca.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=Development/CN=Redis CA" 2>/dev/null

echo "   ✅ CA generada"
echo ""

# 2. Generar clave privada del servidor Redis
echo "2️⃣  Generando clave privada de Redis..."
openssl genrsa -out redis.key 4096 2>/dev/null
echo "   ✅ Clave privada generada"
echo ""

# 3. Generar Certificate Signing Request (CSR)
echo "3️⃣  Generando CSR..."
openssl req -new -key redis.key -out redis.csr \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=Development/CN=redis" 2>/dev/null
echo "   ✅ CSR generado"
echo ""

# 4. Firmar el certificado con la CA
echo "4️⃣  Firmando certificado con CA..."
openssl x509 -req -days $DAYS -in redis.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out redis.crt 2>/dev/null
echo "   ✅ Certificado firmado"
echo ""

# 5. Limpiar archivos temporales
rm -f redis.csr ca.srl

# 6. Ajustar permisos
chmod 644 ca.crt redis.crt
chmod 600 ca.key redis.key

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Certificados TLS generados correctamente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Archivos generados en: $CERT_DIR"
echo ""
echo "  • ca.crt       - Certificado CA"
echo "  • ca.key       - Clave privada CA"
echo "  • redis.crt    - Certificado Redis"
echo "  • redis.key    - Clave privada Redis"
echo ""
echo "⚠️  IMPORTANTE: Estos certificados son autofirmados"
echo "   Para producción, usa certificados válidos de una CA real."
echo ""
echo "🚀 Ahora puedes iniciar Redis con:"
echo "   docker-compose up -d redis"
echo ""
