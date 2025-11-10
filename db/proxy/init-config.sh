#!/bin/sh
# Script de inicialización para ProxySQL
# Genera configuración desde template y arranca ProxySQL

echo "Generando configuración de ProxySQL desde template..."
envsubst < /etc/proxysql/proxysql.cnf.template > /etc/proxysql/proxysql.cnf

echo "Configuración generada. Contenido:"
cat /etc/proxysql/proxysql.cnf

echo "Eliminando base de datos interna para forzar lectura de config..."
rm -f /var/lib/proxysql/proxysql.db

echo "Iniciando ProxySQL..."
proxysql --config /etc/proxysql/proxysql.cnf --initial --foreground &
PROXYSQL_PID=$!

echo "Esperando a que ProxySQL inicie..."
sleep 8

echo "Aplicando configuración personalizada..."
mysql -h127.0.0.1 -P6032 -uadmin -padmin -e "
UPDATE global_variables 
SET variable_value='86400000' 
WHERE variable_name='mysql-monitor_replication_lag_interval';

LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
" 2>&1 || true

echo "✅ ProxySQL iniciado correctamente"
wait $PROXYSQL_PID
