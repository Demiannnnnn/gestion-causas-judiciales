#!/bin/bash
# ============================================================
# AUTO-FAILOVER SERVICE - VERSIÓN HOST
# ============================================================
# Este script debe ejecutarse en el HOST (no en contenedor)
# Usar con systemd o supervisord para que sea un servicio

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Cargar .env
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Configuración
CHECK_INTERVAL="${FAILOVER_CHECK_INTERVAL:-30}"
FAILURE_THRESHOLD="${FAILOVER_FAILURE_THRESHOLD:-3}"
LOG_FILE="${FAILOVER_LOG_FILE:-./logs/failover-daemon.log}"
MYSQL_MONITOR_USER="${MYSQL_MONITOR_USER:-monitor_user}"
MYSQL_MONITOR_PASSWORD="${MYSQL_MONITOR_PASSWORD:-***REMOVED***}"

# Crear directorio de logs
mkdir -p "$(dirname "$LOG_FILE")"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Contadores
CONSECUTIVE_FAILURES=0
FAILOVER_IN_PROGRESS=false

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$msg" | tee -a "$LOG_FILE"
}

log_error() {
    log "${RED}ERROR:${NC} $1"
}

log_success() {
    log "${GREEN}SUCCESS:${NC} $1"
}

log_warning() {
    log "${YELLOW}WARNING:${NC} $1"
}

notify() {
    local message="$1"
    if [ -n "$FAILOVER_NOTIFICATION_WEBHOOK" ]; then
        curl -s -X POST "$FAILOVER_NOTIFICATION_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"[AUTO-FAILOVER] $message\"}" \
            >/dev/null 2>&1 || true
    fi
}

check_master_health() {
    # Check 1: Contenedor corriendo
    if ! docker ps --format '{{.Names}}' | grep -q "^${MYSQL_MASTER_HOST:-db-master}$"; then
        log_warning "Master container not running"
        return 1
    fi
    
    # Check 2: MySQL responde (usar usuario monitor)
    if ! docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" ${MYSQL_MASTER_HOST:-db-master} \
        mysql -u"$MYSQL_MONITOR_USER" -e "SELECT 1;" >/dev/null 2>&1; then
        log_warning "Master MySQL not responding"
        return 1
    fi
    
    # Check 3: No está en read-only (usar usuario monitor)
    local read_only=$(docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" ${MYSQL_MASTER_HOST:-db-master} \
        mysql -u"$MYSQL_MONITOR_USER" -NB -e "SELECT @@read_only;" 2>/dev/null || echo "1")
    
    if [ "$read_only" != "0" ]; then
        log_warning "Master is read-only"
        return 1
    fi
    
    return 0
}

check_slave_health() {
    # Usar usuario monitor para verificar salud del slave
    if ! docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" ${MYSQL_SLAVE_HOST:-db-slave} \
        mysql -u"$MYSQL_MONITOR_USER" -e "SELECT 1;" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

execute_failover() {
    log_warning "=========================================="
    log_warning "INITIATING AUTOMATIC FAILOVER"
    log_warning "=========================================="
    
    FAILOVER_IN_PROGRESS=true
    notify "⚠️ AUTOMATIC FAILOVER INITIATED"
    
    if ! check_slave_health; then
        log_error "Slave not healthy - ABORTING"
        notify "❌ FAILOVER ABORTED - Slave not healthy"
        FAILOVER_IN_PROGRESS=false
        return 1
    fi
    
    log "Executing failover script..."
    if sudo bash "$SCRIPT_DIR/failover-promote-slave.sh" -y >> "$LOG_FILE" 2>&1; then
        log_success "✅ FAILOVER COMPLETED"
        notify "✅ FAILOVER SUCCESS"
        CONSECUTIVE_FAILURES=0
        FAILOVER_IN_PROGRESS=false
        return 0
    else
        log_error "❌ FAILOVER FAILED"
        notify "❌ FAILOVER FAILED - Manual intervention required"
        FAILOVER_IN_PROGRESS=false
        return 1
    fi
}

# Trap para cleanup
trap 'log "Daemon stopped"; exit 0' SIGTERM SIGINT

log_success "=========================================="
log_success "AUTO-FAILOVER DAEMON STARTED"
log_success "=========================================="
log "Check interval: ${CHECK_INTERVAL}s"
log "Failure threshold: $FAILURE_THRESHOLD"
log "Log file: $LOG_FILE"
log_success "=========================================="

notify "🚀 Auto-failover daemon started"

while true; do
    if [ "$FAILOVER_IN_PROGRESS" = false ]; then
        if check_master_health; then
            if [ $CONSECUTIVE_FAILURES -gt 0 ]; then
                log_success "Master recovered (was down for $CONSECUTIVE_FAILURES checks)"
                notify "✅ Master recovered"
            fi
            CONSECUTIVE_FAILURES=0
            log "Master health: OK"
        else
            ((CONSECUTIVE_FAILURES++))
            log_warning "Master check failed ($CONSECUTIVE_FAILURES/$FAILURE_THRESHOLD)"
            
            if [ $CONSECUTIVE_FAILURES -ge $FAILURE_THRESHOLD ]; then
                log_error "Failure threshold reached!"
                execute_failover
            fi
        fi
    fi
    
    sleep $CHECK_INTERVAL
done
