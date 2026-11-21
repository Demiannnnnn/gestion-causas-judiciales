# Failover y Failback - Guía de Uso

## Scripts Disponibles

### 1. `check-replication-status.sh` - Monitoreo
Verifica el estado completo de replicación y ProxySQL.

**Uso:**
```bash
./scripts/check-replication-status.sh
```

**Ejecutar periódicamente (cada 30s):**
```bash
watch -n 30 ./scripts/check-replication-status.sh
```

---

### 2. `failover-promote-slave.sh` - Promoción de Slave
Promueve el slave a master cuando el master original falla.

**Escenario:** db-master caído o inaccesible

**Uso:**
```bash
export MYSQL_ROOT_PASSWORD="<CHANGE_ME>"
./scripts/failover-promote-slave.sh
```

**Pasos ejecutados:**
1. Detiene escrituras en antiguo master (si está activo)
2. Promueve db-slave a master (STOP SLAVE, SET read_only=0)
3. Reconfigura ProxySQL (db-slave → HG 10, db-master → HG 20 OFFLINE)
4. Guarda configuración en ProxySQL

**Después del failover:**
- Las aplicaciones escriben en db-slave (ahora master)
- db-master queda offline hasta failback

---

### 3. `failback-restore-master.sh` - Restauración del Master Original
Restaura db-master como master principal.

**Escenario:** db-master recuperado y quieres volver a topología original

**Uso:**
```bash
export MYSQL_ROOT_PASSWORD="<CHANGE_ME>"
export MYSQL_REPLICATION_USER="***REMOVED***"
export MYSQL_REPLICATION_PASSWORD="<CHANGE_ME>"
./scripts/failback-restore-master.sh
```

**Pasos ejecutados:**
1. Configura db-master como slave de db-slave (sincronización)
2. Espera 30s y verifica replicación
3. **Switchover controlado:**
   - Bloquea escrituras en db-slave (read_only=1)
   - Promueve db-master a master
   - Configura db-slave como slave de db-master
4. Reconfigura ProxySQL (db-master → HG 10, db-slave → HG 20)
5. Guarda configuración

**Después del failback:**
- Topología original restaurada
- db-master es master (HG 10)
- db-slave es slave (HG 20)

---

## Flujo Completo de Failover/Failback

### Situación Normal
```
db-master (HG 10 - WRITER) → replicación → db-slave (HG 20 - READER)
```

### Failover (master falla)
```bash
./scripts/failover-promote-slave.sh
```
```
db-master (OFFLINE) ← db-slave (HG 10 - WRITER)
```

### Failback (restaurar master original)
```bash
# 1. Primero verificar que db-master está operativo
docker start db-master

# 2. Ejecutar failback
./scripts/failback-restore-master.sh
```
```
db-master (HG 10 - WRITER) → replicación → db-slave (HG 20 - READER)
```

---

## Verificaciones Post-Failover/Failback

### 1. Estado de ProxySQL
```bash
docker exec db-proxy mysql -h127.0.0.1 -P6032 -uadmin -padmin -e "
SELECT hostgroup_id, hostname, status FROM mysql_servers ORDER BY hostgroup_id;
"
```

**Esperado:**
- HG 10 con status ONLINE (writer)
- HG 20 con status ONLINE (reader)

### 2. Conectividad desde aplicaciones
```bash
docker exec db-proxy mysql -h127.0.0.1 -P6033 -uadmin_db -p'password' -e "
SELECT @@hostname, @@port, @@read_only, NOW();
"
```

**Esperado:**
- `@@read_only = 0` (escribe en master)
- Respuesta exitosa

### 3. Replicación activa
```bash
docker exec db-slave mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master"
```

**Esperado:**
```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Seconds_Behind_Master: 0
```

---

## Configuración de Semisynchronous Replication (Recomendado)

### En db-master
```sql
SET GLOBAL rpl_semi_sync_master_enabled=ON;
SET GLOBAL rpl_semi_sync_master_timeout=10000;
```

### En db-slave
```sql
SET GLOBAL rpl_semi_sync_slave_enabled=ON;
STOP SLAVE IO_THREAD;
START SLAVE IO_THREAD;
```

### Persistir en my.cnf
Añadir en `db/master/my.cnf`:
```ini
[mysqld]
rpl_semi_sync_master_enabled=1
rpl_semi_sync_master_timeout=10000
```

Añadir en `db/slave/my.cnf`:
```ini
[mysqld]
rpl_semi_sync_slave_enabled=1
```

---

## Troubleshooting

### Failover no completa (db-master bloqueado)
Si el script falla al bloquear el antiguo master:
```bash
# Forzar promoción sin bloquear antiguo master
# Editar failover-promote-slave.sh y comentar línea:
# docker exec db-master mysql ... FLUSH TABLES WITH READ LOCK;
```

### Replicación rota después de failback
```bash
# Verificar GTID
docker exec db-slave mysql -uroot -p... -e "SELECT @@GLOBAL.gtid_executed;"

# Reiniciar replicación con auto_position
docker exec db-slave mysql -uroot -p... -e "
STOP SLAVE;
RESET SLAVE;
CHANGE MASTER TO MASTER_AUTO_POSITION=1;
START SLAVE;
"
```

### ProxySQL no enruta correctamente
```bash
# Recargar configuración
docker exec db-proxy mysql -h127.0.0.1 -P6032 -uadmin -padmin -e "
LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL USERS TO RUNTIME;
"
```

---

## Monitoreo Automatizado (Opcional)

### Script de detección automática de fallo
Crear `scripts/auto-failover-monitor.sh`:
```bash
#!/bin/bash
while true; do
    if ! docker exec db-master mysqladmin ping -uroot -p... --silent 2>/dev/null; then
        echo "❌ MASTER DOWN - Ejecutando failover..."
        ./scripts/failover-promote-slave.sh
        exit 0
    fi
    sleep 10
done
```

**NO recomendado en producción sin validación exhaustiva y sistema de consenso (usa Orchestrator/MHA en su lugar)**

---

## Referencias
- ProxySQL: https://proxysql.com/documentation/
- MySQL GTID: https://dev.mysql.com/doc/refman/8.0/en/replication-gtids.html
- Semisync Replication: https://dev.mysql.com/doc/refman/8.0/en/replication-semisync.html
