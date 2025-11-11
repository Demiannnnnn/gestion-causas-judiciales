#!/bin/bash
# Script de validación de cambios de seguridad en failover/failback

echo "=============================================="
echo "VALIDACIÓN DE CAMBIOS DE SEGURIDAD"
echo "=============================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

errors=0

# Check 1: Variables en .env
echo "[1] Verificando variables de entorno..."
for var in MYSQL_MONITOR_USER MYSQL_MONITOR_PASSWORD MYSQL_REPLICATION_USER MYSQL_REPLICATION_PASSWORD; do
    if grep -q "^$var=" .env; then
        echo "  ✅ $var presente"
    else
        echo -e "  ${RED}❌ $var FALTANTE${NC}"
        ((errors++))
    fi
done
echo ""

# Check 2: Scripts con sintaxis correcta
echo "[2] Verificando sintaxis de scripts..."
for script in scripts/auto-failover-host.sh scripts/failover-promote-slave.sh scripts/failback-restore-master.sh scripts/auto-failover-daemon.sh scripts/auto-failback-daemon.sh; do
    if bash -n "$script" 2>/dev/null; then
        echo "  ✅ $script"
    else
        echo -e "  ${RED}❌ $script - SYNTAX ERROR${NC}"
        ((errors++))
    fi
done
echo ""

# Check 3: No usar root en scripts
echo "[3] Verificando ausencia de credenciales root en operaciones..."
for script in scripts/auto-failover-host.sh scripts/failover-promote-slave.sh scripts/failback-restore-master.sh scripts/auto-failover-daemon.sh scripts/auto-failback-daemon.sh; do
    # grep para -uroot o -u"root" (excluir comentarios)
    if grep -E "^\s*[^#]*(mysql|mysqladmin).*-u(root|\"root\")" "$script" 2>/dev/null; then
        echo -e "  ${RED}❌ $script - Encontrado uso de root${NC}"
        ((errors++))
    else
        echo "  ✅ $script - Sin uso de root"
    fi
done
echo ""

# Check 4: Permisos en grants template
echo "[4] Verificando permisos en template de grants..."
if grep -q "SUPER.*REPLICATION SLAVE" db/master/mysql/02-grants.sql.template; then
    echo "  ✅ Permisos SUPER y REPLICATION SLAVE presentes"
else
    echo -e "  ${RED}❌ Permisos incompletos en grants${NC}"
    ((errors++))
fi
echo ""

# Summary
echo "=============================================="
if [ $errors -eq 0 ]; then
    echo -e "${GREEN}✅ VALIDACIÓN EXITOSA - Todos los cambios correctos${NC}"
    echo "=============================================="
    exit 0
else
    echo -e "${RED}❌ VALIDACIÓN FALLIDA - $errors problemas encontrados${NC}"
    echo "=============================================="
    exit 1
fi
