#!/bin/bash
# ============================================================
# AUTO-FAILBACK DAEMON
# ============================================================
# Detecta cuando el master original vuelve a estar disponible
# y ejecuta failback automático si está configurado

set -e

# Configuración
CHECK_INTERVAL="${FAILBACK_CHECK_INTERVAL:-60}"  # segundos entre checks
HEALTHY_THRESHOLD="${FAILBACK_HEALTHY_THRESHOLD:-5}"  # checks exitosos consecutivos
AUTO_FAILBACK_ENABLED="${AUTO_FAILBACK_ENABLED:-false}"  # Por defecto manual

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Cargar variables
if [ -f /config/.env ]; then
    set -a
    source /config/.env
    set +a
fi

MYSQL_MONITOR_USER="${MYSQL_MONITOR_USER:-monitor_user}"
MYSQL_MONITOR_PASSWORD="${MYSQL_MONITOR_PASSWORD:-***REMOVED***}"
ORIGINAL_MASTER="${MYSQL_MASTER_HOST:-db-master}"
CURRENT_MASTER="${MYSQL_SLAVE_HOST:-db-slave}"
NOTIFICATION_WEBHOOK="${FAILOVER_NOTIFICATION_WEBHOOK:-}"

CONSECUTIVE_HEALTHY=0
FAILBACK_IN_PROGRESS=false

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_info() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${BLUE}INFO:${NC} $1"
}

log_success() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}WARNING:${NC} $1"
}

notify() {
    local message="$1"
    log_info "Notification: $message"
    if [ -n "$NOTIFICATION_WEBHOOK" ]; then
        curl -s -X POST "$NOTIFICATION_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"[FAILBACK-DAEMON] $message\",\"timestamp\":\"$(date -Iseconds)\"}" \
            >/dev/null 2>&1 || true
    fi
}

check_original_master_health() {
    # Usar usuario monitor para verificar la salud del master original
    if docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" $ORIGINAL_MASTER \
        mysql -u"$MYSQL_MONITOR_USER" -NB -e "SELECT 1;" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

execute_failback() {
    log_warning "════════════════════════════════════════"
    log_warning "INITIATING AUTOMATIC FAILBACK"
    log_warning "════════════════════════════════════════"
    
    FAILBACK_IN_PROGRESS=true
    notify "🔄 AUTOMATIC FAILBACK INITIATED - Original master $ORIGINAL_MASTER is healthy"
    
    if /scripts/failback-restore-master.sh -y; then
        log_success "✅ FAILBACK COMPLETED"
        notify "✅ FAILBACK SUCCESS - $ORIGINAL_MASTER restored as master"
        CONSECUTIVE_HEALTHY=0
        FAILBACK_IN_PROGRESS=false
        return 0
    else
        log_warning "❌ FAILBACK FAILED"
        notify "❌ FAILBACK FAILED - Manual intervention required"
        FAILBACK_IN_PROGRESS=false
        return 1
    fi
}

log_success "════════════════════════════════════════"
log_success "AUTO-FAILBACK DAEMON STARTED"
log_success "════════════════════════════════════════"
log_info "Check interval: ${CHECK_INTERVAL}s"
log_info "Healthy threshold: $HEALTHY_THRESHOLD checks"
log_info "Auto-failback: $AUTO_FAILBACK_ENABLED"
log_info "Original master: $ORIGINAL_MASTER"
log_success "════════════════════════════════════════"

notify "🚀 Auto-failback daemon started (auto=$AUTO_FAILBACK_ENABLED)"

while true; do
    if [ "$FAILBACK_IN_PROGRESS" = false ]; then
        if check_original_master_health; then
            ((CONSECUTIVE_HEALTHY++))
            log "Original master healthy ($CONSECUTIVE_HEALTHY/$HEALTHY_THRESHOLD)"
            
            if [ $CONSECUTIVE_HEALTHY -ge $HEALTHY_THRESHOLD ]; then
                if [ "$AUTO_FAILBACK_ENABLED" = "true" ]; then
                    log_info "Healthy threshold reached, executing failback..."
                    execute_failback
                else
                    log_warning "Original master ready for failback (AUTO_FAILBACK_ENABLED=false)"
                    notify "⚠️ Original master $ORIGINAL_MASTER is ready for manual failback"
                    # Reset para evitar spam de notificaciones
                    CONSECUTIVE_HEALTHY=0
                    sleep 300  # Esperar 5 min antes de notificar de nuevo
                fi
            fi
        else
            if [ $CONSECUTIVE_HEALTHY -gt 0 ]; then
                log "Original master went down again"
            fi
            CONSECUTIVE_HEALTHY=0
        fi
    fi
    
    sleep $CHECK_INTERVAL
done
