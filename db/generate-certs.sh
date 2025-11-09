#!/bin/bash
set -e

# Directorio donde se guardarán los certificados
CERT_DIR="db/certs"

# Días de validez para los certificados
DAYS=365

# Crear directorio si no existe
mkdir -p "$CERT_DIR"

echo "Generando certificados en el directorio $CERT_DIR..."

# 1. Clave privada para la CA
echo "Paso 1: Generando clave de la Autoridad Certificadora (CA)..."
openssl genrsa 2048 > "$CERT_DIR/ca-key.pem"

# 2. Certificado de la CA
echo "Paso 2: Generando certificado de la CA..."
openssl req -new -x509 -nodes -days "$DAYS" -key "$CERT_DIR/ca-key.pem" -out "$CERT_DIR/ca.pem" -subj "/CN=MySQL-CA"

# 3. Clave y solicitud de firma para el servidor (maestro)
echo "Paso 3: Generando clave y solicitud de firma para el servidor (maestro)..."
openssl req -newkey rsa:2048 -nodes -keyout "$CERT_DIR/server-key.pem" -out "$CERT_DIR/server-req.pem" -subj "/CN=db-master"

# 4. Firma del certificado del servidor
echo "Paso 4: Firmando el certificado del servidor..."
openssl x509 -req -in "$CERT_DIR/server-req.pem" -days "$DAYS" -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca-key.pem" -set_serial 01 -out "$CERT_DIR/server-cert.pem"

# 5. Clave y solicitud de firma para el cliente (esclavo)
echo "Paso 5: Generando clave y solicitud de firma para el cliente (réplica)..."
openssl req -newkey rsa:2048 -nodes -keyout "$CERT_DIR/client-key.pem" -out "$CERT_DIR/client-req.pem" -subj "/CN=db-slave"

# 6. Firma del certificado del cliente
echo "Paso 6: Firmando el certificado del cliente..."
openssl x509 -req -in "$CERT_DIR/client-req.pem" -days "$DAYS" -CA "$CERT_DIR/ca.pem" -CAkey "$CERT_DIR/ca-key.pem" -set_serial 02 -out "$CERT_DIR/client-cert.pem"

# Limpieza de archivos de solicitud de firma (no son necesarios después de la firma)
rm "$CERT_DIR/server-req.pem"
rm "$CERT_DIR/client-req.pem"

echo ""
echo "¡Certificados generados exitosamente!"
ls -l "$CERT_DIR"
