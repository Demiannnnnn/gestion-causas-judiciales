#!/bin/bash
set -e

# Variables
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/backups/complete"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# Crear directorio
mkdir -p "$BACKUP_DIR"

echo "========================================"
echo "  BACKUP COMPLETO DEL SISTEMA"
echo "  Fecha: $(date)"
echo "========================================"

# 1. Backup de Base de Datos
echo "[$(date)] [1/3] Realizando backup de base de datos..."
/app/scripts/backup-db-only.sh

# 2. Backup de Archivos (si existen)
echo "[$(date)] [2/3] Realizando backup de archivos..."
FILES_DIR="/backups/files"
mkdir -p "$FILES_DIR"

if [ -d "/data/documentos" ]; then
    tar -czf "$FILES_DIR/files_${TIMESTAMP}.tar.gz" -C /data documentos/
    echo "[$(date)] ✓ Backup de archivos completado"
else
    echo "[$(date)] ⚠ Directorio de archivos no encontrado, omitiendo..."
fi

# 3. Crear backup consolidado
echo "[$(date)] [3/3] Creando backup consolidado..."
COMPLETE_FILE="$BACKUP_DIR/backup_complete_${TIMESTAMP}.tar.gz"

tar -czf "$COMPLETE_FILE" \
    -C /backups database/ \
    -C /backups files/ 2>/dev/null || true

if [ -f "$COMPLETE_FILE" ]; then
    echo "[$(date)] ✓ Backup completo creado: $COMPLETE_FILE"
    
    # Limpiar backups antiguos
    find "$BACKUP_DIR" -name "backup_complete_*.tar.gz" -mtime +$RETENTION_DAYS -delete
    echo "[$(date)] ✓ Limpieza completada"
else
    echo "[$(date)] ✗ Error al crear backup completo"
    exit 1
fi

echo "========================================"
echo "  ✓ BACKUP COMPLETO EXITOSO"
echo "========================================"
