#!/bin/bash

# ============================================
# Script de Respaldo Completo del Sistema
# Sistema de Gestión de Causas Judiciales
# ============================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# ============================================
# BANNER
# ============================================
clear
print_color "$MAGENTA" "╔════════════════════════════════════════╗"
print_color "$MAGENTA" "║   📦 RESPALDO COMPLETO DEL SISTEMA    ║"
print_color "$MAGENTA" "║   Sistema de Causas Judiciales        ║"
print_color "$MAGENTA" "╚════════════════════════════════════════╝"
echo ""
print_color "$CYAN" "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_BASE_DIR="../../backups"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
COMPLETE_BACKUP_DIR="$BACKUP_BASE_DIR/complete/backup_$TIMESTAMP"

# Crear directorio para este backup completo
mkdir -p "$COMPLETE_BACKUP_DIR"

# ============================================
# 1. RESPALDO DE BASE DE DATOS
# ============================================
print_color "$YELLOW" "═══════════════════════════════════════"
print_color "$YELLOW" " [1/4] RESPALDO DE BASE DE DATOS"
print_color "$YELLOW" "═══════════════════════════════════════"
echo ""

if [ -f "$SCRIPT_DIR/backup-db.sh" ]; then
    bash "$SCRIPT_DIR/backup-db.sh"
    
    # Copiar el backup más reciente al directorio completo
    LATEST_DB_BACKUP=$(find "$BACKUP_BASE_DIR/database" -name "db_*.sql.gz" | sort -r | head -n 1)
    if [ -f "$LATEST_DB_BACKUP" ]; then
        cp "$LATEST_DB_BACKUP" "$COMPLETE_BACKUP_DIR/"
        print_color "$GREEN" "  ✓ Backup de BD copiado al respaldo completo"
    fi
else
    print_color "$RED" "  ✗ Script backup-db.sh no encontrado"
fi

echo ""
sleep 2

# ============================================
# 2. RESPALDO DE ARCHIVOS/DOCUMENTOS
# ============================================
print_color "$YELLOW" "═══════════════════════════════════════"
print_color "$YELLOW" " [2/4] RESPALDO DE ARCHIVOS"
print_color "$YELLOW" "═══════════════════════════════════════"
echo ""

if [ -f "$SCRIPT_DIR/backup-files.sh" ]; then
    bash "$SCRIPT_DIR/backup-files.sh"
    
    # Copiar el backup más reciente
    LATEST_FILES_BACKUP=$(find "$BACKUP_BASE_DIR/files" -name "files_*.tar.gz" | sort -r | head -n 1)
    if [ -f "$LATEST_FILES_BACKUP" ]; then
        cp "$LATEST_FILES_BACKUP" "$COMPLETE_BACKUP_DIR/"
        print_color "$GREEN" "  ✓ Backup de archivos copiado"
    fi
else
    print_color "$RED" "  ✗ Script backup-files.sh no encontrado"
fi

echo ""
sleep 2

# ============================================
# 3. RESPALDO DE CONFIGURACIONES
# ============================================
print_color "$YELLOW" "═══════════════════════════════════════"
print_color "$YELLOW" " [3/4] RESPALDO DE CONFIGURACIONES"
print_color "$YELLOW" "═══════════════════════════════════════"
echo ""

cd ../..

print_color "$BLUE" "  → Respaldando archivos de configuración..."

CONFIG_FILES=(
    "docker-compose.yml"
    ".env.example"
    "monitoring/prometheus/prometheus_main.yml"
)

CONFIG_BACKUP_DIR="$COMPLETE_BACKUP_DIR/configs"
mkdir -p "$CONFIG_BACKUP_DIR"

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        # Crear estructura de directorios si es necesario
        DIR=$(dirname "$file")
        mkdir -p "$CONFIG_BACKUP_DIR/$DIR"
        
        cp "$file" "$CONFIG_BACKUP_DIR/$file"
        print_color "$GREEN" "    ✓ $file"
    else
        print_color "$YELLOW" "    ! $file no existe"
    fi
done

# Respaldar scripts
print_color "$BLUE" "  → Respaldando scripts..."
if [ -d "scripts" ]; then
    cp -r "scripts" "$CONFIG_BACKUP_DIR/"
    print_color "$GREEN" "    ✓ Scripts respaldados"
fi

cd scripts/backup

echo ""

# ============================================
# 4. CREAR ARCHIVO CONSOLIDADO
# ============================================
print_color "$YELLOW" "═══════════════════════════════════════"
print_color "$YELLOW" " [4/4] CREANDO ARCHIVO CONSOLIDADO"
print_color "$YELLOW" "═══════════════════════════════════════"
echo ""

print_color "$BLUE" "  → Creando manifiesto del backup..."

# Crear manifiesto con información del backup
MANIFEST="$COMPLETE_BACKUP_DIR/MANIFEST.txt"
cat > "$MANIFEST" << EOF
╔════════════════════════════════════════════════════════════╗
║           MANIFIESTO DE RESPALDO COMPLETO                  ║
║           Sistema de Gestión de Causas Judiciales         ║
╚════════════════════════════════════════════════════════════╝

INFORMACIÓN DEL RESPALDO
========================
Fecha de creación: $(date '+%Y-%m-%d %H:%M:%S')
Nombre del backup: backup_$TIMESTAMP
Hostname: $(hostname)
Usuario: $(whoami)

CONTENIDO DEL BACKUP
====================
EOF

# Listar contenido
echo "" >> "$MANIFEST"
echo "ARCHIVOS INCLUIDOS:" >> "$MANIFEST"
echo "===================" >> "$MANIFEST"
find "$COMPLETE_BACKUP_DIR" -type f -exec ls -lh {} \; | awk '{print $9, "("$5")"}' >> "$MANIFEST"

echo "" >> "$MANIFEST"
echo "ESTADÍSTICAS:" >> "$MANIFEST"
echo "=============" >> "$MANIFEST"
echo "Total de archivos: $(find "$COMPLETE_BACKUP_DIR" -type f | wc -l)" >> "$MANIFEST"
echo "Tamaño total: $(du -sh "$COMPLETE_BACKUP_DIR" | cut -f1)" >> "$MANIFEST"

print_color "$GREEN" "  ✓ Manifiesto creado"

# Comprimir todo el directorio
print_color "$BLUE" "  → Comprimiendo backup completo..."

cd "$BACKUP_BASE_DIR/complete"
FINAL_BACKUP="backup_complete_$TIMESTAMP.tar.gz"

if tar -czf "$FINAL_BACKUP" "backup_$TIMESTAMP" 2>/dev/null; then
    print_color "$GREEN" "  ✓ Backup consolidado creado"
    
    FINAL_SIZE=$(du -h "$FINAL_BACKUP" | cut -f1)
    print_color "$BLUE" "  Tamaño final: $FINAL_SIZE"
    
    # Eliminar directorio temporal
    rm -rf "backup_$TIMESTAMP"
    print_color "$BLUE" "  → Directorio temporal eliminado"
else
    print_color "$RED" "  ✗ Error al crear archivo consolidado"
fi

cd "$SCRIPT_DIR"

echo ""

# ============================================
# VERIFICAR BACKUP
# ============================================
print_color "$YELLOW" "Verificando integridad del backup consolidado..."

if tar -tzf "$BACKUP_BASE_DIR/complete/$FINAL_BACKUP" > /dev/null 2>&1; then
    FILE_COUNT=$(tar -tzf "$BACKUP_BASE_DIR/complete/$FINAL_BACKUP" | wc -l)
    print_color "$GREEN" "  ✓ Backup íntegro"
    print_color "$BLUE" "  Archivos en el backup: $FILE_COUNT"
else
    print_color "$RED" "  ✗ Backup corrupto"
fi

echo ""

# ============================================
# LIMPIEZA DE BACKUPS ANTIGUOS
# ============================================
print_color "$YELLOW" "Limpiando backups completos antiguos (>30 días)..."

BEFORE=$(find "$BACKUP_BASE_DIR/complete" -name "backup_complete_*.tar.gz" | wc -l)
find "$BACKUP_BASE_DIR/complete" -name "backup_complete_*.tar.gz" -mtime +30 -delete 2>/dev/null
AFTER=$(find "$BACKUP_BASE_DIR/complete" -name "backup_complete_*.tar.gz" | wc -l)
DELETED=$((BEFORE - AFTER))

if [ $DELETED -gt 0 ]; then
    print_color "$GREEN" "  ✓ Eliminados $DELETED backups antiguos"
else
    print_color "$BLUE" "  → No hay backups antiguos para eliminar"
fi

print_color "$BLUE" "  Backups completos actuales: $AFTER"

echo ""

# ============================================
# RESUMEN FINAL
# ============================================
print_color "$MAGENTA" "╔════════════════════════════════════════════════════════╗"
print_color "$MAGENTA" "║                                                         ║"
print_color "$MAGENTA" "║          ✅ RESPALDO COMPLETO FINALIZADO               ║"
print_color "$MAGENTA" "║                                                         ║"
print_color "$MAGENTA" "╚════════════════════════════════════════════════════════╝"
echo ""

print_color "$CYAN" "📦 RESUMEN DEL RESPALDO"
print_color "$CYAN" "════════════════════════"
echo ""

print_color "$BLUE" "Ubicación del backup:"
print_color "$GREEN" "  $BACKUP_BASE_DIR/complete/$FINAL_BACKUP"
echo ""

print_color "$BLUE" "Componentes respaldados:"
print_color "$GREEN" "  ✓ Base de datos MySQL"
print_color "$GREEN" "  ✓ Archivos y documentos"
print_color "$GREEN" "  ✓ Configuraciones del sistema"
print_color "$GREEN" "  ✓ Scripts de administración"
echo ""

print_color "$BLUE" "Tamaño del backup:"
print_color "$GREEN" "  $FINAL_SIZE"
echo ""

print_color "$BLUE" "Backups disponibles:"
print_color "$GREEN" "  $AFTER backup(s) completo(s)"
echo ""

print_color "$YELLOW" "💡 COMANDOS ÚTILES:"
echo ""
print_color "$BLUE" "Ver contenido del backup:"
print_color "$GREEN" "  tar -tzf $BACKUP_BASE_DIR/complete/$FINAL_BACKUP | less"
echo ""
print_color "$BLUE" "Extraer backup:"
print_color "$GREEN" "  tar -xzf $BACKUP_BASE_DIR/complete/$FINAL_BACKUP"
echo ""
print_color "$BLUE" "Ver manifiesto:"
print_color "$GREEN" "  tar -xzOf $BACKUP_BASE_DIR/complete/$FINAL_BACKUP backup_$TIMESTAMP/MANIFEST.txt"
echo ""

print_color "$CYAN" "════════════════════════════════════════════════════════"
print_color "$GREEN" "Backup completado exitosamente en: $(date '+%H:%M:%S')"
print_color "$CYAN" "════════════════════════════════════════════════════════"
echo ""