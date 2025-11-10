#!/bin/sh
set -e

echo "===========================================" 
echo "Redis Config Generator"
echo "==========================================="

# Variables con valores por defecto
REDIS_PASSWORD=${REDIS_PASSWORD:-***REMOVED***}
MAX_MEMORY=${REDIS_MAX_MEMORY:-256mb}
DATABASES=${REDIS_DATABASES:-16}

echo "Using MAX_MEMORY: $MAX_MEMORY"
echo "Using DATABASES: $DATABASES"
echo "Password configured: YES"

# Generar configuración de Redis
sed -e "s|__REDIS_PASSWORD__|${REDIS_PASSWORD}|g" \
    -e "s|__MAX_MEMORY__|${MAX_MEMORY}|g" \
    -e "s|__DATABASES__|${DATABASES}|g" \
    /templates/redis.conf.template > /config/redis.conf

echo "✅ Redis configuration generated successfully"
echo "Configuration preview (passwords hidden):"
grep -v "password\|auth" /config/redis.conf || true

echo "==========================================="
echo "Configuration files ready at /config"
echo "==========================================="
