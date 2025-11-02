#!/bin/bash

# ============================================
# Script de Restauración de Archivos
# Sistema de Gestión de Causas Judiciales
# ============================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# ============================================
# BANNER
# ============================================
print_color "$CYAN" "========================================"
print_color "$CYAN" "  🔄 Restauración de Archivos"
print_color "$CYAN" "  $(date '+%Y-%m-%d %H:%M:%S')"
print_color "$CYAN" "========================================"
echo ""

# ============================================
# FUNCIONES AUXILIARES
# ============================================

list_backups() {
    print_color "$YELLOW" "📦 Backups de archivos disponibles:"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_color "$RED" "  ✗ Directorio de backups no existe"
        return
    fi
    
    BACKUPS=($(find "$BACKUP_DIR" -name "files_*.tar.gz" | sort -r))
    
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        print_color "$YELLOW" "  → No hay backups disponibles"
        return
    fi
    
    for i in "${!BACKUPS[@]}"; do
        BACKUP_FILE="${BACKUPS[$i]}"
        FILENAME=$(basename "$BACKUP_FILE")
        SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        DATE=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$BACKUP_FILE" 2>/dev/null || stat -c "%y" "$BACKUP_FILE" 2>/dev/null | cut -d'.' -f1)
        
        if [ $i -eq 0 ]; then
            print_color "$GREEN" "  [$((i+1))] $FILENAME"
            print_color "$BLUE" "      Tamaño: $SIZE | Fecha: $DATE | [MÁS RECIENTE]"
        else
            print_color "$BLUE" "  [$((i+1))] $FILENAME"
            print_color "$BLUE" "      Tamaño: $SIZE | Fecha: $DATE"
        fi
    done
    echo ""
}

# ============================================
# VALIDAR PARÁMETROS
# ============================================

if [ $# -eq 0 ] || [ "$1" == "--list" ] || [ "$1" == "-l" ]; then
    list_backups
    echo ""
    print_color "$YELLOW" "💡 Uso:"
    print_color "$BLUE" "   ./scripts/backup/restore-files.sh <archivo_backup>"
    print_color "$BLUE" "   ./scripts/backup/restore-files.sh --latest"
    print_color "$BLUE" "   ./scripts/backup/restore-files.sh --list"
    echo ""
    exit 0
fi

# ============================================
# SELECCIONAR ARCHIVO
# ============================================

BACKUP_FILE=""

if [ "$1" == "--latest" ]; then
    BACKUP_FILE=$(find "$BACKUP_DIR" -name "files_*.tar.gz" | sort -r | head -n 1)
    
    if [ -z "$BACKUP_FILE" ]; then
        print_color "$RED" "✗ No se encontraron backups"
        exit 1
    fi
    
    print_color "$BLUE" "→ Usando el backup más reciente:"
    print_color "$GREEN" "  $(basename $BACKUP_FILE)"
    echo ""
else
    if [ -f "$1" ]; then
        BACKUP_FILE="$1"
    elif [ -f "$BACKUP_DIR/$1" ]; then
        BACKUP_FILE="$BACKUP_DIR/$1"
    else
        print_color "$RED" "✗ Archivo no encontrado: $1"
        list_backups
        exit 1
    fi
fi

# ============================================
# CONFIRMACIÓN
# ============================================
print_color "$YELLOW" "⚠️  ADVERTENCIA:"
print_color "$RED" "   Esta operación SOBRESCRIBIRÁ los archivos actuales"
print_color "$BLUE" "   Backup: $(basename $BACKUP_FILE)"
echo ""

# Mostrar contenido del backup
print_color "$BLUE" "📄 Contenido del backup:"
tar -tzf "$BACKUP_FILE" | head -n 10
TOTAL_FILES=$(tar -tzf "$BACKUP_FILE" | wc -l)
if [ $TOTAL_FILES -gt 10 ]; then
    print_color "$BLUE" "   ... y $((TOTAL_FILES - 10)) archivos más"
fi
echo ""

read -p "¿Continuar con la restauración? (escribe 'SI'): " -r
echo ""

if [ "$REPLY" != "SI" ]; then
    print_color "$YELLOW" "→ Operación cancelada"
    exit 0
fi

# ============================================
# CREAR BACKUP DE SEGURIDAD
# ============================================
print_color "$YELLOW" "[1/3] Creando backup de seguridad..."

SAFETY_BACKUP="${BACKUP_DIR}/files_before_restore_$(date +%Y-%m-%d_%H-%M-%S).tar.gz"

# Cambiar al directorio raíz
cd ../..

# Respaldar archivos actuales
SOURCE_DIRS=(
    "backend/documentos/uploads"
)

if tar -czf "$SAFETY_BACKUP" "${SOURCE_DIRS[@]}" 2>/dev/null; then
    print_color "$GREEN" "  ✓ Backup de seguridad creado"
    print_color "$BLUE" "  → $SAFETY_BACKUP"
else
    print_color "$YELLOW" "  ! No se pudo crear backup de seguridad"
fi

echo ""

# ============================================
# RESTAURAR ARCHIVOS
# ============================================
print_color "$YELLOW" "[2/3] Restaurando archivos..."

if tar -xzf "$BACKUP_FILE" 2>/dev/null; then
    print_color "$GREEN" "  ✓ Archivos extraídos exitosamente"
else
    print_color "$RED" "  ✗ Error al extraer archivos"
    exit 1
fi

echo ""

# ============================================
# VERIFICAR RESTAURACIÓN
# ============================================
print_color "$YELLOW" "[3/3] Verificando restauración..."

# Contar archivos restaurados
RESTORED_COUNT=0
for dir in "${SOURCE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        COUNT=$(find "$dir" -type f | wc -l)
        RESTORED_COUNT=$((RESTORED_COUNT + COUNT))
    fi
done

print_color "$GREEN" "  ✓ Archivos restaurados: $RESTORED_COUNT"

# Regresar al directorio de scripts
cd scripts/backup

echo ""

# ============================================
# RESUMEN
# ============================================
print_color "$CYAN" "========================================"
print_color "$GREEN" "  ✅ Restauración completada"
print_color "$CYAN" "========================================"
echo ""
print_color "$BLUE" "📊 Resumen:"
print_color "$GREEN" "   • Backup: $(basename $BACKUP_FILE)"
print_color "$GREEN" "   • Archivos: $RESTORED_COUNT"
echo ""
print_color "$BLUE" "💾 Backup de seguridad:"
print_color "$GREEN" "   $SAFETY_BACKUP"
echo ""
print_color "$YELLOW" "💡 Reinicia el servicio de documentos:"
print_color "$BLUE" "   docker-compose restart documentos"
echo ""