#!/bin/bash
# Script para generar certificados TLS autofirmados para Dex
# Estos son para desarrollo/testing. En producción usa certificados válidos.

set -e

CERT_DIR="$(dirname "$0")/tls"
DAYS=3650  # 10 años

echo "🔐 Generando certificados TLS para Dex..."
echo ""

cd "$CERT_DIR"

# 1. Generar CA (Certificate Authority)
echo "1️⃣  Generando CA (Certificate Authority)..."
openssl genrsa -out ca.key 4096 2>/dev/null
openssl req -new -x509 -days $DAYS -key ca.key -out ca.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=Development/CN=Dex CA" 2>/dev/null

echo "   ✅ CA generada"
echo ""

# 2. Generar clave privada del servidor Dex
echo "2️⃣  Generando clave privada de Dex..."
openssl genrsa -out dex.key 4096 2>/dev/null
echo "   ✅ Clave privada generada"
echo ""

# 3. Generar Certificate Signing Request (CSR) con SANs
echo "3️⃣  Generando CSR con Subject Alternative Names..."

# Crear archivo de configuración temporal para SANs
cat > san.cnf << EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C = ES
ST = Madrid
L = Madrid
O = Development
CN = localhost

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = dex
DNS.3 = ms-data-dex
IP.1 = 127.0.0.1
EOF

openssl req -new -key dex.key -out dex.csr -config san.cnf 2>/dev/null
echo "   ✅ CSR generado con SANs"
echo ""

# 4. Firmar el certificado con la CA
echo "4️⃣  Firmando certificado con CA..."
openssl x509 -req -days $DAYS -in dex.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out dex.crt -extensions v3_req -extfile san.cnf 2>/dev/null
echo "   ✅ Certificado firmado"
echo ""

# 5. Limpiar archivos temporales
rm -f dex.csr ca.srl san.cnf

# 6. Ajustar permisos
chmod 644 ca.crt dex.crt
chmod 600 ca.key dex.key

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Certificados TLS generados correctamente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Archivos generados en: $CERT_DIR"
echo ""
echo "  • ca.crt       - Certificado CA"
echo "  • ca.key       - Clave privada CA"
echo "  • dex.crt      - Certificado Dex"
echo "  • dex.key      - Clave privada Dex"
echo ""
echo "⚠️  IMPORTANTE: Estos certificados son autofirmados"
echo "   Para producción, usa certificados válidos de una CA real."
echo ""
echo "🚀 Ahora puedes iniciar Dex con:"
echo "   docker-compose up -d dex"
echo ""
