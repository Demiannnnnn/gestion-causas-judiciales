#!/bin/bash
set -e

# Generar archivo de configuración reemplazando variables de entorno
echo "Generando configuración de Orchestrator desde plantilla..."
envsubst < /etc/orchestrator.conf.json.template > /etc/orchestrator.conf.json

echo "Configuración generada:"
# Ocultar contraseña en logs por seguridad (opcional, grep -v o similar)
# cat /etc/orchestrator.conf.json | grep -v "Password" 

# Ejecutar Orchestrator en segundo plano
/usr/local/orchestrator/orchestrator http &
ORCH_PID=$!

# Esperar a que Orchestrator arranque (por ejemplo, 10 segundos)
echo "Esperando arranque de Orchestrator..."
sleep 10

# Forzar descubrimiento de todos los nodos
echo "Ejecutando descubrimiento automático del cluster..."
curl -s "http://127.0.0.1:3000/api/discover/db-master/3306"
curl -s "http://127.0.0.1:3000/api/discover/db-slave/3306"
curl -s "http://127.0.0.1:3000/api/discover/db-slave-2/3306"

# Mantener el contenedor vivo esperando al proceso principal
wait $ORCH_PID
