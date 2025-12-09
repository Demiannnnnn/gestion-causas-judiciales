#!/bin/bash
set -e

CERTS_DIR="api-gateway/certs-local"
CERT_FILE="${CERTS_DIR}/traefik.crt"
KEY_FILE="${CERTS_DIR}/traefik.key"
DOMAIN="localhost"

echo "================================================"
echo "Generando certificados TLS autofirmados para Traefik"
echo "Dominio: ${DOMAIN}"
echo "------------------------------------------------"

# Crear directorio si no existe
mkdir -p "$CERTS_DIR"

# Generar clave privada
openssl genrsa -out "$KEY_FILE" 2048

# Generar solicitud de firma de certificado (CSR)
openssl req -new -key "$KEY_FILE" -out "${CERTS_DIR}/traefik.csr" -subj "/CN=${DOMAIN}"

# Generar certificado autofirmado
openssl x509 -req -days 365 -in "${CERTS_DIR}/traefik.csr" -signkey "$KEY_FILE" -out "$CERT_FILE"

echo "================================================"
echo "Certificados generados en: ${CERTS_DIR}"
echo " - Certificado: ${CERT_FILE}"
echo " - Clave privada: ${KEY_FILE}"
echo "------------------------------------------------"
echo "Para usar estos certificados con Traefik, asegúrate de que el volumen"
echo "de certificados en docker-compose.yml apunte a ${CERTS_DIR}."
echo "================================================"