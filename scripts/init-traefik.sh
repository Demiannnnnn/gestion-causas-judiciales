#!/bin/sh
set -e

echo "===========================================" 
echo "Traefik Config Generator"
echo "==========================================="

# Variables con valores por defecto
API_INSECURE=${API_INSECURE:-true}
DASHBOARD_ENABLED=${DASHBOARD_ENABLED:-true}
NETWORK_NAME=${NETWORK_NAME:-app-network}
LOG_LEVEL=${LOG_LEVEL:-INFO}

echo "Using API_INSECURE: $API_INSECURE"
echo "Using DASHBOARD_ENABLED: $DASHBOARD_ENABLED"
echo "Using NETWORK_NAME: $NETWORK_NAME"
echo "Using LOG_LEVEL: $LOG_LEVEL"

# Crear directorio para logs
mkdir -p /var/log/traefik

# Generar configuración de Traefik
sed -e "s|__API_INSECURE__|${API_INSECURE}|g" \
    -e "s|__DASHBOARD_ENABLED__|${DASHBOARD_ENABLED}|g" \
    -e "s|__NETWORK_NAME__|${NETWORK_NAME}|g" \
    -e "s|__LOG_LEVEL__|${LOG_LEVEL}|g" \
    /templates/traefik.yml.template > /config/traefik.yml

echo "✅ Traefik configuration generated successfully"
cat /config/traefik.yml

echo "==========================================="
echo "Configuration files ready at /config"
echo "==========================================="
