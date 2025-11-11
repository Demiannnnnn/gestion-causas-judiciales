#!/bin/sh
# Script de post-inicialización para ProxySQL
# Desactiva el monitoreo de replication lag para compatibilidad con MySQL 8.0.22+

echo "Esperando a que ProxySQL inicie..."
sleep 5

echo "Aplicando configuración personalizada..."
mysql -h127.0.0.1 -P6032 -uadmin -padmin -e "
UPDATE global_variables 
SET variable_value='86400000' 
WHERE variable_name='mysql-monitor_replication_lag_interval';

LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;

SELECT variable_name, variable_value 
FROM global_variables 
WHERE variable_name='mysql-monitor_replication_lag_interval';
" 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Configuración aplicada exitosamente"
else
    echo "❌ Error al aplicar configuración"
    exit 1
fi
