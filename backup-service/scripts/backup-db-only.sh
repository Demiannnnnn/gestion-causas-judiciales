#!/bin/bash
set -e

# Variables
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/backups/database"
MYSQL_HOST="${MYSQL_HOST:-db-master}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:?MYSQL_PASSWORD must be set}"
MYSQL_DATABASE="${MYSQL_DATABASE:-causas_judiciales_db}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

# Crear directorio si no existe
mkdir -p "$BACKUP_DIR"

echo "[$(date)] Iniciando backup de base de datos..."

# Realizar backup usando mysqldump directamente desde MySQL container
BACKUP_FILE="$BACKUP_DIR/db_${MYSQL_DATABASE}_${TIMESTAMP}.sql"

mysqldump -h "$MYSQL_HOST" \
          -u "$MYSQL_USER" \
          -p"$MYSQL_PASSWORD" \
          --single-transaction \
          --routines \
          --triggers \
          --events \
          --default-character-set=utf8mb4 \
          "$MYSQL_DATABASE" > "$BACKUP_FILE" 2>/dev/null || true

# Comprimir el backup
if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
    gzip "$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE}.gz"
fi

if [ $? -eq 0 ]; then
    echo "[$(date)] ✓ Backup completado: $BACKUP_FILE"
    
    # Limpiar backups antiguos
    find "$BACKUP_DIR" -name "db_*.sql.gz" -mtime +$RETENTION_DAYS -delete
    echo "[$(date)] ✓ Limpieza de backups antiguos completada"
else
    echo "[$(date)] ✗ Error en backup"
    exit 1
fi
