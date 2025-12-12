#!/bin/bash
set -e

echo "========================================"
echo "  Sistema de Backup Automático"
echo "  Iniciado: $(date)"
echo "========================================"

# Crear directorio de logs si no existe
mkdir -p /backups/logs

# Log functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /backups/logs/backup.log
}

# Función para ejecutar backup completo (diario a las 2 AM)
run_daily_backup() {
    log "Iniciando backup diario completo..."
    /app/scripts/backup-all.sh >> /backups/logs/backup.log 2>&1
    log "Backup diario completado"
}

# Función para ejecutar backup de BD (cada 6 horas)
run_db_backup() {
    log "Iniciando backup de base de datos..."
    /app/scripts/backup-db.sh >> /backups/logs/backup-db.log 2>&1
    log "Backup de BD completado"
}

# Loop infinito para ejecutar backups programados
log "Sistema de backup iniciado. Programado para ejecutar cada 6 horas (00:00, 06:00, 12:00, 18:00)"
log "Backup completo diario programado a las 02:00 AM"

LAST_DB_BACKUP_HOUR=""
LAST_FULL_BACKUP_DAY=""

while true; do
    CURRENT_HOUR=$(date '+%H')
    CURRENT_DAY=$(date '+%d')
    
    # Backup completo a las 2 AM (una vez por día)
    if [ "$CURRENT_HOUR" == "02" ] && [ "$LAST_FULL_BACKUP_DAY" != "$CURRENT_DAY" ]; then
        run_daily_backup
        LAST_FULL_BACKUP_DAY="$CURRENT_DAY"
    fi
    
    # Backup de BD cada 6 horas (00, 06, 12, 18)
    if [ $(($CURRENT_HOUR % 6)) -eq 0 ] && [ "$LAST_DB_BACKUP_HOUR" != "$CURRENT_HOUR" ]; then
        run_db_backup
        LAST_DB_BACKUP_HOUR="$CURRENT_HOUR"
    fi
    
    # Sleep 5 minutos antes del próximo chequeo
    sleep 300
done
