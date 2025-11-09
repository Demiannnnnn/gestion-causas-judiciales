#!/bin/bash
set -e

echo "========================================"
echo "  Sistema de Backup Automático"
echo "  Iniciado: $(date)"
echo "========================================"

# Crear archivo de log
touch /var/log/backup.log
touch /var/log/backup-db.log

# Iniciar cron en primer plano
echo "Iniciando servicio cron..."
crond -f -l 2
