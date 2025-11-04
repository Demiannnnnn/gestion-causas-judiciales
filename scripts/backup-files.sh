#!/bin/bash

# ============================================
# Script de Respaldo de Archivos/Documentos
# Sistema de Gestión de Causas Judiciales
# ============================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# ============================================
# CONFIGURACIÓN
# ============================================

BACKUP_DIR=${BACKUP_DIR:-"../../backups/files"}
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Directorios a respaldar (según tu docker-compose.yml)
SOURCE_DIRS=(
    "../../backend/documentos/uploads"
    # Agregar más directorios si es necesario
)

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

BACKUP_FILE="${BACKUP_DIR}/files_${TIMESTAMP}.tar.gz"

# ============================================
# BANNER
# ============================================
print_color "$BLUE" "========================================"
print_color "$BLUE" "  📦 Respaldo de Archivos"
print_color "$BLUE" "  $(date '+%Y-%m-%d %H:%M:%S')"
print_color "$BLUE" "========================================"
echo ""

# ============================================
# VERIFICAR DIRECTORIOS FUENTE
# ============================================
print_color "$YELLOW" "[1/4] Verificando directorios fuente..."

VALID_DIRS=()
for dir in "${SOURCE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        FILE_COUNT=$(find "$dir" -type f | wc -l)
        DIR_SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)
        print_color "$GREEN" "  ✓ $dir"
        print_color "$BLUE" "    Archivos: $FILE_COUNT | Tamaño: $DIR_SIZE"
        VALID_DIRS+=("$dir")
    else
        print_color "$YELLOW" "  ! $dir no existe (se creará si es necesario)"
        mkdir -p "$dir"
        VALID_DIRS+=("$dir")
    fi
done

if [ ${#VALID_DIRS[@]} -eq 0 ]; then
    print_color "$RED" "  ✗ No hay directorios para respaldar"
    exit 1
fi

echo ""

# ============================================
# CREAR RESPALDO
# ============================================
print_color "$YELLOW" "[2/4] Creando archivo comprimido..."

# Cambiar al directorio raíz del proyecto para rutas relativas
cd ../..

# Crear el archivo tar.gz
if tar -czf "$BACKUP_FILE" "${VALID_DIRS[@]}" 2>/dev/null; then
    print_color "$GREEN" "  ✓ Archivo tar.gz creado exitosamente"
    
    # Obtener tamaño
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    print_color "$BLUE" "  Tamaño: $BACKUP_SIZE"
else
    print_color "$RED" "  ✗ Error al crear el archivo comprimido"
    exit 1
fi

# Regresar al directorio de scripts
cd scripts/backup

echo ""

# ============================================
# VERIFICAR INTEGRIDAD
# ============================================
print_color "$YELLOW" "[3/4] Verificando integridad del backup..."

if tar -tzf "$BACKUP_FILE" > /dev/null 2>&1; then
    print_color "$GREEN" "  ✓ Backup íntegro y válido"
    
    # Contar archivos en el backup
    FILE_COUNT=$(tar -tzf "$BACKUP_FILE" | grep -v '/$' | wc -l)
    print_color "$BLUE" "  Archivos respaldados: $FILE_COUNT"
else
    print_color "$RED" "  ✗ Backup corrupto"
    rm -f "$BACKUP_FILE"
    exit 1
fi

echo ""

# ============================================
# LIMPIAR RESPALDOS ANTIGUOS
# ============================================
print_color "$YELLOW" "[4/4] Limpiando respaldos antiguos (>${RETENTION_DAYS} días)..."

BEFORE_COUNT=$(find "$BACKUP_DIR" -name "files_*.tar.gz" | wc -l)
print_color "$BLUE" "  Backups antes: $BEFORE_COUNT"

# Eliminar backups antiguos
find "$BACKUP_DIR" -name "files_*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete 2>/dev/null

AFTER_COUNT=$(find "$BACKUP_DIR" -name "files_*.tar.gz" | wc -l)
DELETED_COUNT=$((BEFORE_COUNT - AFTER_COUNT))

if [ $DELETED_COUNT -gt 0 ]; then
    print_color "$GREEN" "  ✓ Eliminados: $DELETED_COUNT backups"
else
    print_color "$BLUE" "  → No hay backups antiguos"
fi

print_color "$BLUE" "  Backups actuales: $AFTER_COUNT"

echo ""

# ============================================
# RESUMEN
# ============================================
print_color "$BLUE" "========================================"
print_color "$GREEN" "  ✅ Respaldo completado"
print_color "$BLUE" "========================================"
echo ""
print_color "$BLUE" "📁 Ubicación:"
print_color "$GREEN" "   $BACKUP_FILE"
echo ""
print_color "$BLUE" "📊 Estadísticas:"
print_color "$GREEN" "   • Tamaño: $BACKUP_SIZE"
print_color "$GREEN" "   • Archivos: $FILE_COUNT"
print_color "$GREEN" "   • Total backups: $AFTER_COUNT"
print_color "$GREEN" "   • Retención: $RETENTION_DAYS días"
echo ""
print_color "$YELLOW" "💡 Para restaurar:"
print_color "$BLUE" "   ./scripts/backup/restore-files.sh $(basename $BACKUP_FILE)"
echo ""