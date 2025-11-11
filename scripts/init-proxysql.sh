#!/bin/sh
set -e

echo "===========================================" 
echo "ProxySQL Config Generator"
echo "==========================================="

# Variables obligatorias desde .env
ADMIN_USER=${PROXYSQL_ADMIN_USER:-admin}
ADMIN_PASSWORD=${PROXYSQL_ADMIN_PASSWORD:-admin}
MONITOR_USER=${MYSQL_MONITOR_USER:-monitor}
MONITOR_PASSWORD=${MYSQL_MONITOR_PASSWORD:-monitor}
DEFAULT_DB=${MYSQL_DATABASE:-causas_judiciales_db}
MASTER_HOST=${MYSQL_MASTER_HOST:-db-master}
SLAVE_HOST=${MYSQL_SLAVE_HOST:-db-slave}
APP_USER=${MYSQL_USER:-appuser}
APP_PASSWORD=${MYSQL_PASSWORD:-password}

echo "Using ADMIN_USER: $ADMIN_USER"
echo "Using MONITOR_USER: $MONITOR_USER"
echo "Using DEFAULT_DB: $DEFAULT_DB"
echo "Using MASTER_HOST: $MASTER_HOST"
echo "Using SLAVE_HOST: $SLAVE_HOST"
echo "Using APP_USER: $APP_USER"

# Generar configuración de ProxySQL
sed -e "s|__ADMIN_USER__|${ADMIN_USER}|g" \
    -e "s|__ADMIN_PASSWORD__|${ADMIN_PASSWORD}|g" \
    -e "s|__MONITOR_USER__|${MONITOR_USER}|g" \
    -e "s|__MONITOR_PASSWORD__|${MONITOR_PASSWORD}|g" \
    -e "s|__DEFAULT_DB__|${DEFAULT_DB}|g" \
    -e "s|__MASTER_HOST__|${MASTER_HOST}|g" \
    -e "s|__SLAVE_HOST__|${SLAVE_HOST}|g" \
    -e "s|__APP_USER__|${APP_USER}|g" \
    -e "s|__APP_PASSWORD__|${APP_PASSWORD}|g" \
    /templates/proxysql.cnf.template > /config/proxysql.cnf

echo "✅ ProxySQL configuration generated successfully"
echo "Configuration preview (passwords hidden):"
grep -v "password" /config/proxysql.cnf || true

echo "==========================================="
echo "Configuration files ready at /config"
echo "==========================================="
