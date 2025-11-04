#!/bin/bash

# ============================================
# Script de Respaldo de Base de Datos MySQL
# Sistema de Gestión de Causas Judiciales
# ============================================

set -e  # Detener si hay error

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

# Cargar variables de entorno desde .env
if [ -f "../../.env" ]; then
    export $(cat ../../.env | grep -v '^#' | xargs)
elif [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Variables de configuración
MYSQL_HOST=${MYSQL_HOST:-"mysql"}
MYSQL_USER=${MYSQL_ROOT_PASSWORD:+"root"}
MYSQL_USER=${MYSQL_USER:-${MYSQL_USER:-"admin_db"}}
MYSQL_PASSWORD=${MYSQL_ROOT_PASSWORD:-${MYSQL_PASSWORD:-"admin"}}
MYSQL_DATABASE=${MYSQL_DATABASE:-"causas_judiciales_db"}
BACKUP_DIR=${BACKUP_DIR:-"../../backups/database"}
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

# Timestamp para el nombre del archivo
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="${BACKUP_DIR}/db_${MYSQL_DATABASE}_${TIMESTAMP}.sql"
BACKUP_FILE_GZ="${BACKUP_FILE}.gz"

# ============================================
# BANNER
# ============================================
print_color "$BLUE" "========================================"
print_color "$BLUE" "  📦 Respaldo de Base de Datos"
print_color "$BLUE" "  $(date '+%Y-%m-%d %H:%M:%S')"
print_color "$BLUE" "========================================"
echo ""

# ============================================
# VERIFICAR CONECTIVIDAD
# ============================================
print_color "$YELLOW" "[1/4] Verificando conexión a MySQL..."

# Intentar conectar usando Docker
if docker exec mysql mysqladmin ping -h localhost -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent > /dev/null 2>&1; then
    print_color "$GREEN" "  ✓ Conexión exitosa a MySQL"
else
    print_color "$RED" "  ✗ No se puede conectar a MySQL"
    print_color "$YELLOW" "  → Verifica que el contenedor 'mysql' esté corriendo"
    print_color "$YELLOW" "  → Ejecuta: docker-compose ps mysql"
    exit 1
fi

# Verificar que la base de datos existe
if docker exec mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "USE $MYSQL_DATABASE" > /dev/null 2>&1; then
    print_color "$GREEN" "  ✓ Base de datos '$MYSQL_DATABASE' encontrada"
else
    print_color "$RED" "  ✗ Base de datos '$MYSQL_DATABASE' no existe"
    exit 1
fi

echo ""

# ============================================
# CREAR RESPALDO
# ============================================
print_color "$YELLOW" "[2/4] Creando respaldo de la base de datos..."

# Mostrar información
print_color "$BLUE" "  Base de datos: $MYSQL_DATABASE"
print_color "$BLUE" "  Archivo destino: $(basename $BACKUP_FILE_GZ)"

# Crear dump de la base de datos
if docker exec mysql mysqldump \
    -u "$MYSQL_USER" \
    -p"$MYSQL_PASSWORD" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --databases "$MYSQL_DATABASE" \
    > "$BACKUP_FILE" 2>/dev/null; then
    
    print_color "$GREEN" "  ✓ Dump SQL creado exitosamente"
else
    print_color "$RED" "  ✗ Error al crear el dump SQL"
    exit 1
fi

# Obtener tamaño del archivo
DUMP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
print_color "$BLUE" "  Tamaño del dump: $DUMP_SIZE"

echo ""

# ============================================
# COMPRIMIR RESPALDO
# ============================================
print_color "$YELLOW" "[3/4] Comprimiendo respaldo..."

if gzip -f "$BACKUP_FILE" 2>/dev/null; then
    print_color "$GREEN" "  ✓ Archivo comprimido exitosamente"
    
    # Obtener tamaño comprimido
    COMPRESSED_SIZE=$(du -h "$BACKUP_FILE_GZ" | cut -f1)
    print_color "$BLUE" "  Tamaño comprimido: $COMPRESSED_SIZE"
else
    print_color "$RED" "  ✗ Error al comprimir el archivo"
    # Mantener el archivo sin comprimir
    BACKUP_FILE_GZ="$BACKUP_FILE"
    print_color "$YELLOW" "  → Manteniendo archivo sin comprimir"
fi

echo ""

# ============================================
# LIMPIAR RESPALDOS ANTIGUOS
# ============================================
print_color "$YELLOW" "[4/4] Limpiando respaldos antiguos (>${RETENTION_DAYS} días)..."

# Contar backups antes de limpiar
BEFORE_COUNT=$(find "$BACKUP_DIR" -name "db_*.sql.gz" -o -name "db_*.sql" | wc -l)
print_color "$BLUE" "  Backups antes de limpiar: $BEFORE_COUNT"

# Eliminar backups antiguos
find "$BACKUP_DIR" \( -name "db_*.sql.gz" -o -name "db_*.sql" \) -type f -mtime +${RETENTION_DAYS} -delete 2>/dev/null

# Contar backups después de limpiar
AFTER_COUNT=$(find "$BACKUP_DIR" -name "db_*.sql.gz" -o -name "db_*.sql" | wc -l)
DELETED_COUNT=$((BEFORE_COUNT - AFTER_COUNT))

if [ $DELETED_COUNT -gt 0 ]; then
    print_color "$GREEN" "  ✓ Se eliminaron $DELETED_COUNT respaldos antiguos"
else
    print_color "$BLUE" "  → No hay respaldos antiguos para eliminar"
fi

print_color "$BLUE" "  Backups actuales: $AFTER_COUNT"

echo ""

# ============================================
# RESUMEN
# ============================================
print_color "$BLUE" "========================================"
print_color "$GREEN" "  ✅ Respaldo completado exitosamente"
print_color "$BLUE" "========================================"
echo ""
print_color "$BLUE" "📁 Ubicación:"
print_color "$GREEN" "   $BACKUP_FILE_GZ"
echo ""
print_color "$BLUE" "📊 Estadísticas:"
print_color "$GREEN" "   • Tamaño original: $DUMP_SIZE"
print_color "$GREEN" "   • Tamaño comprimido: $COMPRESSED_SIZE"
print_color "$GREEN" "   • Total de backups: $AFTER_COUNT"
print_color "$GREEN" "   • Retención: $RETENTION_DAYS días"
echo ""
print_color "$YELLOW" "💡 Para restaurar este backup:"
print_color "$BLUE" "   ./scripts/backup/restore-db.sh $(basename $BACKUP_FILE_GZ)"
echo ""