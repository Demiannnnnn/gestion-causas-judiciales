#!/bin/bash
set -e

# Generar archivo de configuración reemplazando variables de entorno
echo "Generando configuración de Orchestrator desde plantilla..."
envsubst < /etc/orchestrator.conf.json.template > /etc/orchestrator.conf.json

echo "Configuración generada:"
# Ocultar contraseña en logs por seguridad (opcional, grep -v o similar)
# cat /etc/orchestrator.conf.json | grep -v "Password" 

# Ejecutar el comando original (orchestrator)
exec /usr/local/orchestrator/orchestrator http
