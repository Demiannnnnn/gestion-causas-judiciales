#!/bin/bash

# ============================================
# Script de Restauración de Base de Datos
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

# Cargar variables de entorno
if [ -f "../../.env" ]; then
    export $(cat ../../.env | grep -v '^#' | xargs)
elif [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

MYSQL_USER=${MYSQL_ROOT_PASSWORD:+"root"}
MYSQL_USER=${MYSQL_USER:-${MYSQL_USER:-"admin_db"}}
MYSQL_PASSWORD=${MYSQL_ROOT_PASSWORD:-${MYSQL_PASSWORD:-"admin"}}
MYSQL_DATABASE=${MYSQL_DATABASE:-"causas_judiciales_db"}
BACKUP_DIR=${BACKUP_DIR:-"../../backups/database"}

# ============================================
# BANNER
# ============================================
print_color "$CYAN" "========================================"
print_color "$CYAN" "  🔄 Restauración de Base de Datos"
print_color "$CYAN" "  $(date '+%Y-%m-%d %H:%M:%S')"
print_color "$CYAN" "========================================"
echo ""

# ============================================
# VALIDAR PARÁMETROS
# ============================================

# Función para listar backups disponibles
list_backups() {
    print_color "$YELLOW" "📦 Backups disponibles:"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_color "$RED" "  ✗ Directorio de backups no existe: $BACKUP_DIR"
        return
    fi
    
    # Buscar archivos de backup
    BACKUPS=($(find "$BACKUP_DIR" -name "db_*.sql.gz" -o -name "db_*.sql" | sort -r))
    
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        print_color "$YELLOW" "  → No hay backups disponibles"
        print_color "$BLUE" "  → Crea uno con: ./scripts/backup/backup-db.sh"
        return
    fi
    
    # Mostrar lista numerada
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

# Si no se proporciona archivo o se pide listado
if [ $# -eq 0 ] || [ "$1" == "--list" ] || [ "$1" == "-l" ]; then
    list_backups
    echo ""
    print_color "$YELLOW" "💡 Uso:"
    print_color "$BLUE" "   ./scripts/backup/restore-db.sh <archivo_backup>"
    print_color "$BLUE" "   ./scripts/backup/restore-db.sh --latest    # Restaurar el más reciente"
    print_color "$BLUE" "   ./scripts/backup/restore-db.sh --list      # Listar backups"
    echo ""
    exit 0
fi

# ============================================
# SELECCIONAR ARCHIVO DE BACKUP
# ============================================

BACKUP_FILE=""

if [ "$1" == "--latest" ]; then
    # Buscar el backup más reciente
    BACKUP_FILE=$(find "$BACKUP_DIR" -name "db_*.sql.gz" -o -name "db_*.sql" | sort -r | head -n 1)
    
    if [ -z "$BACKUP_FILE" ]; then
        print_color "$RED" "✗ No se encontraron backups"
        exit 1
    fi
    
    print_color "$BLUE" "→ Usando el backup más reciente:"
    print_color "$GREEN" "  $(basename $BACKUP_FILE)"
    echo ""
else
    # Buscar el archivo especificado
    if [ -f "$1" ]; then
        BACKUP_FILE="$1"
    elif [ -f "$BACKUP_DIR/$1" ]; then
        BACKUP_FILE="$BACKUP_DIR/$1"
    else
        print_color "$RED" "✗ Archivo de backup no encontrado: $1"
        echo ""
        list_backups
        exit 1
    fi
fi

# ============================================
# CONFIRMACIÓN
# ============================================
print_color "$YELLOW" "⚠️  ADVERTENCIA:"
print_color "$RED" "   Esta operación SOBRESCRIBIRÁ la base de datos actual"
print_color "$RED" "   Base de datos: $MYSQL_DATABASE"
print_color "$BLUE" "   Backup a restaurar: $(basename $BACKUP_FILE)"
echo ""
read -p "¿Estás seguro de continuar? (escribe 'SI' para confirmar): " -r
echo ""

if [ "$REPLY" != "SI" ]; then
    print_color "$YELLOW" "→ Operación cancelada"
    exit 0
fi

# ============================================
# VERIFICAR CONECTIVIDAD
# ============================================
print_color "$YELLOW" "[1/5] Verificando conexión a MySQL..."

if docker exec mysql mysqladmin ping -h localhost -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent > /dev/null 2>&1; then
    print_color "$GREEN" "  ✓ Conexión exitosa"
else
    print_color "$RED" "  ✗ No se puede conectar a MySQL"
    exit 1
fi

echo ""

# ============================================
# CREAR BACKUP DE SEGURIDAD
# ============================================
print_color "$YELLOW" "[2/5] Creando backup de seguridad de la BD actual..."

SAFETY_BACKUP="${BACKUP_DIR}/db_${MYSQL_DATABASE}_before_restore_$(date +%Y-%m-%d_%H-%M-%S).sql.gz"

if docker exec mysql mysqldump \
    -u "$MYSQL_USER" \
    -p"$MYSQL_PASSWORD" \
    --databases "$MYSQL_DATABASE" \
    2>/dev/null | gzip > "$SAFETY_BACKUP"; then
    
    print_color "$GREEN" "  ✓ Backup de seguridad creado"
    print_color "$BLUE" "  → $SAFETY_BACKUP"
else
    print_color "$YELLOW" "  ! No se pudo crear backup de seguridad"
    read -p "  ¿Continuar de todas formas? (s/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        print_color "$YELLOW" "→ Operación cancelada"
        exit 0
    fi
fi

echo ""

# ============================================
# DESCOMPRIMIR SI ES NECESARIO
# ============================================
print_color "$YELLOW" "[3/5] Preparando archivo de backup..."

RESTORE_FILE="$BACKUP_FILE"

if [[ "$BACKUP_FILE" == *.gz ]]; then
    print_color "$BLUE" "  → Descomprimiendo archivo..."
    RESTORE_FILE="${BACKUP_FILE%.gz}"
    
    if gunzip -c "$BACKUP_FILE" > "$RESTORE_FILE.tmp" 2>/dev/null; then
        RESTORE_FILE="$RESTORE_FILE.tmp"
        print_color "$GREEN" "  ✓ Archivo descomprimido"
    else
        print_color "$RED" "  ✗ Error al descomprimir"
        exit 1
    fi
else
    print_color "$GREEN" "  ✓ Archivo ya está descomprimido"
fi

echo ""

# ============================================
# ELIMINAR BASE DE DATOS ACTUAL
# ============================================
print_color "$YELLOW" "[4/5] Eliminando base de datos actual..."

if docker exec mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
    -e "DROP DATABASE IF EXISTS $MYSQL_DATABASE;" 2>/dev/null; then
    print_color "$GREEN" "  ✓ Base de datos eliminada"
else
    print_color "$RED" "  ✗ Error al eliminar base de datos"
    # Limpiar archivo temporal
    [ -f "$RESTORE_FILE.tmp" ] && rm -f "$RESTORE_FILE.tmp"
    exit 1
fi

echo ""

# ============================================
# RESTAURAR BASE DE DATOS
# ============================================
print_color "$YELLOW" "[5/5] Restaurando base de datos desde backup..."

if docker exec -i mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" < "$RESTORE_FILE" 2>/dev/null; then
    print_color "$GREEN" "  ✓ Base de datos restaurada exitosamente"
else
    print_color "$RED" "  ✗ Error al restaurar base de datos"
    print_color "$YELLOW" "  → Intentando recuperar desde backup de seguridad..."
    
    # Intentar restaurar desde backup de seguridad
    if [ -f "$SAFETY_BACKUP" ]; then
        gunzip -c "$SAFETY_BACKUP" | docker exec -i mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" 2>/dev/null
        print_color "$GREEN" "  ✓ Base de datos recuperada desde backup de seguridad"
    fi
    
    # Limpiar archivo temporal
    [ -f "$RESTORE_FILE.tmp" ] && rm -f "$RESTORE_FILE.tmp"
    exit 1
fi

# Limpiar archivo temporal
[ -f "$RESTORE_FILE.tmp" ] && rm -f "$RESTORE_FILE.tmp"

echo ""

# ============================================
# VERIFICAR RESTAURACIÓN
# ============================================
print_color "$YELLOW" "Verificando restauración..."

# Contar tablas
TABLE_COUNT=$(docker exec mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
    -D "$MYSQL_DATABASE" \
    -e "SHOW TABLES;" 2>/dev/null | wc -l)

TABLE_COUNT=$((TABLE_COUNT - 1))  # Restar la línea del header

print_color "$GREEN" "  ✓ Tablas encontradas: $TABLE_COUNT"

# Contar registros en tabla usuarios (como ejemplo)
if docker exec mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
    -D "$MYSQL_DATABASE" \
    -e "SELECT COUNT(*) FROM usuarios;" &>/dev/null; then
    USER_COUNT=$(docker exec mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
        -D "$MYSQL_DATABASE" \
        -e "SELECT COUNT(*) FROM usuarios;" 2>/dev/null | tail -n 1)
    print_color "$GREEN" "  ✓ Usuarios en la BD: $USER_COUNT"
fi

echo ""

# ============================================
# RESUMEN
# ============================================
print_color "$CYAN" "========================================"
print_color "$GREEN" "  ✅ Restauración completada"
print_color "$CYAN" "========================================"
echo ""
print_color "$BLUE" "📊 Resumen:"
print_color "$GREEN" "   • Backup restaurado: $(basename $BACKUP_FILE)"
print_color "$GREEN" "   • Base de datos: $MYSQL_DATABASE"
print_color "$GREEN" "   • Tablas: $TABLE_COUNT"
if [ ! -z "$USER_COUNT" ]; then
    print_color "$GREEN" "   • Usuarios: $USER_COUNT"
fi
echo ""
print_color "$BLUE" "💾 Backup de seguridad guardado en:"
print_color "$GREEN" "   $SAFETY_BACKUP"
echo ""
print_color "$YELLOW" "💡 Reinicia los servicios backend para aplicar los cambios:"
print_color "$BLUE" "   docker-compose restart autenticacion casos documentos notificaciones"
echo ""