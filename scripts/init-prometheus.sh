#!/bin/sh
set -e

echo "===========================================" 
echo "Prometheus Config Generator"
echo "==========================================="

# Variables con valores por defecto
SCRAPE_INTERVAL=${SCRAPE_INTERVAL:-15s}
EVALUATION_INTERVAL=${EVALUATION_INTERVAL:-15s}

echo "Using SCRAPE_INTERVAL: $SCRAPE_INTERVAL"
echo "Using EVALUATION_INTERVAL: $EVALUATION_INTERVAL"

# Generar configuración de Prometheus
sed -e "s|__SCRAPE_INTERVAL__|${SCRAPE_INTERVAL}|g" \
    -e "s|__EVALUATION_INTERVAL__|${EVALUATION_INTERVAL}|g" \
    /templates/prometheus.yml.template > /config/prometheus.yml

echo "✅ Prometheus configuration generated successfully"
cat /config/prometheus.yml

echo "==========================================="
echo "Configuration files ready at /config"
echo "==========================================="
