#!/bin/bash
# ============================================================
# AUTO-FAILOVER DAEMON
# ============================================================
# Monitorea la salud del master y ejecuta failover automático
# si detecta fallas críticas

set -e

# Configuración
CHECK_INTERVAL="${FAILOVER_CHECK_INTERVAL:-30}"  # segundos entre checks
FAILURE_THRESHOLD="${FAILOVER_FAILURE_THRESHOLD:-3}"  # fallos consecutivos antes de failover
NOTIFICATION_WEBHOOK="${FAILOVER_NOTIFICATION_WEBHOOK:-}"

# Colores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Cargar variables de entorno
if [ -f /config/.env ]; then
    set -a
    source /config/.env
    set +a
fi

# Variables
MYSQL_MONITOR_USER="${MYSQL_MONITOR_USER:-monitor_user}"
MYSQL_MONITOR_PASSWORD="${MYSQL_MONITOR_PASSWORD:-***REMOVED***}"
PROXYSQL_ADMIN_USER="${PROXYSQL_ADMIN_USER:-admin}"
PROXYSQL_ADMIN_PASSWORD="${PROXYSQL_ADMIN_PASSWORD:-admin}"
MASTER_HOST="${MYSQL_MASTER_HOST:-db-master}"
SLAVE_HOST="${MYSQL_SLAVE_HOST:-db-slave}"

# Contadores
CONSECUTIVE_FAILURES=0
FAILOVER_IN_PROGRESS=false

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_error() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}ERROR:${NC} $1"
}

log_warning() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}WARNING:${NC} $1"
}

log_success() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}SUCCESS:${NC} $1"
}

log_info() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${BLUE}INFO:${NC} $1"
}

# Notificar evento crítico
notify() {
    local message="$1"
    local severity="${2:-INFO}"
    
    log_info "Notification: [$severity] $message"
    
    if [ -n "$NOTIFICATION_WEBHOOK" ]; then
        curl -s -X POST "$NOTIFICATION_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"[FAILOVER-DAEMON] [$severity] $message\",\"timestamp\":\"$(date -Iseconds)\"}" \
            >/dev/null 2>&1 || true
    fi
}

# Verificar si master está funcionando
check_master_health() {
    local checks_passed=0
    local checks_total=3
    
    # Check 1: Ping del contenedor (usar usuario monitor)
    if docker exec $MASTER_HOST mysqladmin -u"$MYSQL_MONITOR_USER" -p"$MYSQL_MONITOR_PASSWORD" ping >/dev/null 2>&1; then
        ((checks_passed++))
    else
        log_warning "Master ping failed"
        return 1
    fi
    
    # Check 2: Verificar que NO está en read-only (debe ser writable)
    local read_only=$(docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" $MASTER_HOST \
        mysql -u"$MYSQL_MONITOR_USER" -NB -e "SELECT @@read_only;" 2>/dev/null)
    
    if [ "$read_only" = "0" ]; then
        ((checks_passed++))
    else
        log_warning "Master is in read-only mode (read_only=$read_only)"
        return 1
    fi
    
    # Check 3: Query simple debe funcionar (usar usuario monitor)
    if docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" $MASTER_HOST \
        mysql -u"$MYSQL_MONITOR_USER" -NB -e "SELECT 1;" >/dev/null 2>&1; then
        ((checks_passed++))
    else
        log_warning "Master query test failed"
        return 1
    fi
    
    if [ $checks_passed -eq $checks_total ]; then
        return 0
    else
        return 1
    fi
}

# Verificar si slave está saludable para promoción
check_slave_health() {
    # Check 1: Contenedor responde (usar usuario monitor)
    if ! docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" $SLAVE_HOST \
        mysql -u"$MYSQL_MONITOR_USER" -NB -e "SELECT 1;" >/dev/null 2>&1; then
        log_error "Slave no responde - cannot failover"
        return 1
    fi
    
    # Check 2: Replicación está activa (usar usuario monitor con permisos de REPLICATION CLIENT)
    local io_running=$(docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" $SLAVE_HOST \
        mysql -u"$MYSQL_MONITOR_USER" -NB -e "SELECT SERVICE_STATE FROM performance_schema.replication_connection_status LIMIT 1;" 2>/dev/null)
    
    local sql_running=$(docker exec -e MYSQL_PWD="$MYSQL_MONITOR_PASSWORD" $SLAVE_HOST \
        mysql -u"$MYSQL_MONITOR_USER" -NB -e "SELECT SERVICE_STATE FROM performance_schema.replication_applier_status LIMIT 1;" 2>/dev/null)
    
    if [ "$io_running" = "ON" ] && [ "$sql_running" = "ON" ]; then
        log_info "Slave replication is healthy"
        return 0
    else
        log_warning "Slave replication status: IO=$io_running SQL=$sql_running"
        # Permitir failover si SQL está OK (puede tener lag pero datos consistentes)
        if [ "$sql_running" = "ON" ]; then
            return 0
        fi
        return 1
    fi
}

# Ejecutar failover automático
execute_failover() {
    log_warning "════════════════════════════════════════"
    log_warning "INITIATING AUTOMATIC FAILOVER"
    log_warning "════════════════════════════════════════"
    
    FAILOVER_IN_PROGRESS=true
    notify "⚠️ AUTOMATIC FAILOVER INITIATED - Master $MASTER_HOST is down" "CRITICAL"
    
    # Verificar que slave está OK
    if ! check_slave_health; then
        log_error "Slave is not healthy - ABORTING FAILOVER"
        notify "❌ FAILOVER ABORTED - Slave not healthy" "CRITICAL"
        FAILOVER_IN_PROGRESS=false
        return 1
    fi
    
    # Ejecutar script de failover
    log_info "Promoting slave to master..."
    if /scripts/failover-promote-slave.sh -y; then
        log_success "✅ FAILOVER COMPLETED SUCCESSFULLY"
        notify "✅ FAILOVER SUCCESS - $SLAVE_HOST is now master" "SUCCESS"
        CONSECUTIVE_FAILURES=0
        FAILOVER_IN_PROGRESS=false
        return 0
    else
        log_error "❌ FAILOVER SCRIPT FAILED"
        notify "❌ FAILOVER FAILED - Manual intervention required" "CRITICAL"
        FAILOVER_IN_PROGRESS=false
        return 1
    fi
}

# Loop principal
log_success "════════════════════════════════════════"
log_success "AUTO-FAILOVER DAEMON STARTED"
log_success "════════════════════════════════════════"
log_info "Check interval: ${CHECK_INTERVAL}s"
log_info "Failure threshold: $FAILURE_THRESHOLD consecutive failures"
log_info "Master: $MASTER_HOST"
log_info "Slave: $SLAVE_HOST"
log_success "════════════════════════════════════════"

notify "🚀 Auto-failover daemon started" "INFO"

while true; do
    if [ "$FAILOVER_IN_PROGRESS" = false ]; then
        if check_master_health; then
            if [ $CONSECUTIVE_FAILURES -gt 0 ]; then
                log_success "Master recovered (was down for $CONSECUTIVE_FAILURES checks)"
                notify "✅ Master $MASTER_HOST recovered" "INFO"
            fi
            CONSECUTIVE_FAILURES=0
            log "Master health: OK"
        else
            ((CONSECUTIVE_FAILURES++))
            log_warning "Master health check failed ($CONSECUTIVE_FAILURES/$FAILURE_THRESHOLD)"
            
            if [ $CONSECUTIVE_FAILURES -ge $FAILURE_THRESHOLD ]; then
                log_error "Failure threshold reached!"
                execute_failover
            fi
        fi
    else
        log_info "Failover in progress, skipping health check..."
    fi
    
    sleep $CHECK_INTERVAL
done
