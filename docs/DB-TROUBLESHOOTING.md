# 🔧 Guía de Troubleshooting: MySQL Master-Slave + ProxySQL

## Índice
1. [Diagnóstico Rápido](#diagnóstico-rápido)
2. [Problemas Comunes y Soluciones](#problemas-comunes-y-soluciones)
3. [Scripts de Reparación](#scripts-de-reparación)
4. [Verificación Manual](#verificación-manual)
5. [Monitoreo de la Replicación](#monitoreo-de-la-replicación)

---

## Diagnóstico Rápido

### Script Automatizado (Recomendado)
```bash
# Chequeo rápido - Resumen conciso del estado
./scripts/quick-db-check.sh

# Diagnóstico completo - Análisis detallado
./scripts/diagnose-db.sh
```

**Nota:** Los scripts usan `MYSQL_PWD` como variable de entorno para evitar warnings de seguridad.

Este script verifica:
- ✅ Estado de contenedores
- ✅ Configuración del master
- ✅ Configuración del slave
- ✅ Estado de replicación
- ✅ Conectividad entre nodos
- ✅ ProxySQL backends
- ✅ Certificados SSL

---

## Problemas Comunes y Soluciones

### 1. ❌ Slave no se conecta al Master

**Síntomas:**
- `Replica_IO_Running: Connecting`
- Error: "Can't connect to MySQL server on 'db-master'"

**Causas posibles:**
- Master no está levantado
- Problemas de red
- Certificados SSL incorrectos

**Solución:**
```bash
# 1. Verificar que el master esté healthy
docker compose ps db-master

# 2. Verificar conectividad de red
docker compose exec db-slave ping -c 3 db-master

# 3. Verificar puerto MySQL
docker compose exec db-slave nc -zv db-master 3306

# 4. Verificar certificados
docker compose exec db-slave ls -la /etc/mysql/certs/

# 5. Si todo está OK, reparar replicación
./scripts/fix-replication.sh
```

---

### 2. ❌ Error de autenticación del usuario replicator

**Síntomas:**
- `Replica_IO_Running: No`
- Error: "Access denied for user 'replicator'@'%'"

**Causas:**
- Usuario no existe
- Contraseña incorrecta
- Permisos insuficientes

**Solución:**
```bash
# Recrear usuario replicator en el master
docker compose exec db-master mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<EOF
DROP USER IF EXISTS 'replicator'@'%';
CREATE USER 'replicator'@'%' IDENTIFIED WITH caching_sha2_password 
    BY '${MYSQL_REPLICATION_PASSWORD}' REQUIRE SSL;
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'replicator'@'%';
FLUSH PRIVILEGES;
EOF

# Verificar
docker compose exec db-master mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e \
    "SHOW GRANTS FOR 'replicator'@'%';"

# Reiniciar replicación
./scripts/fix-replication.sh
```

---

### 3. ❌ Error de SSL/TLS

**Síntomas:**
- Error: "SSL connection error"
- Error: "Unable to get public key"

**Causas:**
- Certificados no están montados
- Certificados inválidos o expirados
- Configuración SSL incorrecta

**Solución:**
```bash
# 1. Verificar que los certificados existen
ls -la db/certs/

# 2. Si no existen, generarlos
cd db
./generate-certs.sh
cd ..

# 3. Reiniciar servicios
docker compose restart db-master db-slave

# 4. Reparar replicación
./scripts/fix-replication.sh
```

---

### 4. ❌ GTID Consistency Error

**Síntomas:**
- Error: "@@SESSION.GTID_NEXT cannot be set"
- Error: "When @@GLOBAL.ENFORCE_GTID_CONSISTENCY is true"

**Causas:**
- Operaciones no soportadas con GTID
- Inconsistencia en la configuración GTID

**Solución:**
```bash
# Verificar configuración GTID en master
docker compose exec db-master mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SHOW VARIABLES LIKE 'gtid_mode';
    SHOW VARIABLES LIKE 'enforce_gtid_consistency';
"

# Verificar en slave
docker compose exec db-slave mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SHOW VARIABLES LIKE 'gtid_mode';
    SHOW VARIABLES LIKE 'enforce_gtid_consistency';
"

# Ambos deben mostrar:
# gtid_mode = ON
# enforce_gtid_consistency = ON

# Si no, reiniciar servicios
docker compose restart db-master db-slave
```

---

### 5. ❌ ProxySQL no se conecta a los backends

**Síntomas:**
- ProxySQL no puede alcanzar db-master o db-slave
- Monitor logs muestran errores

**Solución:**
```bash
# 1. Verificar configuración de ProxySQL
docker compose exec db-proxy mysql -h127.0.0.1 -P6032 -uadmin -padmin -e "
    SELECT * FROM mysql_servers;
"

# 2. Verificar monitor logs
docker compose exec db-proxy mysql -h127.0.0.1 -P6032 -uadmin -padmin -e "
    SELECT * FROM monitor.mysql_server_ping_log 
    ORDER BY time_start_us DESC LIMIT 10;
"

# 3. Verificar que el usuario monitor existe en master
docker compose exec db-master mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SELECT User, Host FROM mysql.user WHERE User='monitor_user';
"

# 4. Si el usuario no existe
docker compose exec db-master mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<EOF
CREATE USER IF NOT EXISTS 'monitor_user'@'%' 
    IDENTIFIED WITH caching_sha2_password BY '${MYSQL_MONITOR_PASSWORD}';
GRANT REPLICATION CLIENT, SELECT ON *.* TO 'monitor_user'@'%';
FLUSH PRIVILEGES;
EOF

# 5. Reiniciar ProxySQL
docker compose restart db-proxy
```

---

### 6. ❌ Slave con retraso (Lag)

**Síntomas:**
- `Seconds_Behind_Source` > 0 y creciendo

**Causas:**
- Slave más lento que master
- Query pesadas en el slave
- Red lenta

**Verificación:**
```bash
# Ver el lag actual
docker compose exec db-slave mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SHOW REPLICA STATUS\G
" | grep Seconds_Behind_Source

# Ver procesos en el slave
docker compose exec db-slave mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SHOW PROCESSLIST;
"
```

**Solución:**
```bash
# 1. Aumentar recursos del slave (en docker-compose.yml)
#    Agregar:
#    deploy:
#      resources:
#        limits:
#          cpus: '2'
#          memory: 2G

# 2. Optimizar configuración de MySQL
docker compose exec db-slave mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SET GLOBAL innodb_flush_log_at_trx_commit = 2;
    SET GLOBAL sync_binlog = 0;
"

# 3. Reiniciar slave
docker compose restart db-slave
```

---

### 7. ❌ db-init container failed

**Síntomas:**
- db-init muestra "Exit 1"
- Master no tiene los scripts inicializados

**Solución:**
```bash
# Ver logs del db-init
docker compose logs db-init

# Verificar que las variables están en .env
grep -E "MYSQL_DATABASE|MYSQL_MONITOR" .env

# Limpiar y reiniciar
docker compose down
docker volume rm proy2_db-master-init-scripts proy2_db-slave-init-scripts
docker compose up -d db-init

# Esperar y ver logs
docker compose logs -f db-init
```

---

## Scripts de Reparación

### Reparar Replicación Completa
```bash
./scripts/fix-replication.sh
```

Este script:
1. Detiene la replicación en el slave
2. Verifica el estado del master
3. Recrea el usuario replicator
4. Configura la replicación con SSL
5. Inicia la replicación
6. Verifica el estado

### Diagnóstico Completo
```bash
./scripts/diagnose-db.sh
```

Realiza diagnóstico de:
- Estados de contenedores
- Configuración master/slave
- Conectividad
- ProxySQL
- Certificados SSL

---

## Verificación Manual

### Verificar Master
```bash
# Conectar al master
docker compose exec db-master mysql -uroot -p"$MYSQL_ROOT_PASSWORD"

# En MySQL:
SHOW MASTER STATUS;
SHOW VARIABLES LIKE '%server_id%';
SHOW VARIABLES LIKE '%gtid%';
SELECT User, Host FROM mysql.user;
```

### Verificar Slave
```bash
# Conectar al slave
docker compose exec db-slave mysql -uroot -p"$MYSQL_ROOT_PASSWORD"

# En MySQL:
SHOW REPLICA STATUS\G
SHOW VARIABLES LIKE '%server_id%';
SHOW VARIABLES LIKE '%read_only%';
```

### Verificar ProxySQL
```bash
# Conectar a la interfaz admin de ProxySQL
docker compose exec db-proxy mysql -h127.0.0.1 -P6032 -uadmin -padmin

# En ProxySQL:
SELECT * FROM mysql_servers;
SELECT * FROM mysql_users;
SELECT * FROM mysql_query_rules;

# Ver logs de monitoreo
SELECT * FROM monitor.mysql_server_ping_log ORDER BY time_start_us DESC LIMIT 10;
SELECT * FROM monitor.mysql_server_connect_log ORDER BY time_start_us DESC LIMIT 10;
```

---

## Monitoreo de la Replicación

### Script de Monitoreo Continuo
```bash
# Crear script de monitoreo
cat > /tmp/monitor-replication.sh <<'EOF'
#!/bin/bash
while true; do
    clear
    echo "=== Replication Status ==="
    echo "Time: $(date)"
    echo ""
    docker compose exec -T db-slave mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
        SHOW REPLICA STATUS\G
    " 2>/dev/null | grep -E "Replica_IO_Running|Replica_SQL_Running|Seconds_Behind_Source|Last_Error"
    sleep 5
done
EOF

chmod +x /tmp/monitor-replication.sh
/tmp/monitor-replication.sh
```

### Métricas Clave
```bash
# Ver lag de replicación
docker compose exec db-slave mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SELECT 
        IF(Seconds_Behind_Source IS NULL, 'Replication Stopped', 
           CONCAT(Seconds_Behind_Source, ' seconds')) AS Replication_Lag
    FROM performance_schema.replication_applier_status_by_worker
    LIMIT 1;
"

# Ver transacciones ejecutadas
docker compose exec db-slave mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SELECT @@GLOBAL.GTID_EXECUTED;
"
```

---

## Comandos Útiles

### Reiniciar Replicación desde Cero
```bash
# ⚠️ CUIDADO: Esto elimina datos del slave

# 1. Detener servicios
docker compose stop db-slave

# 2. Eliminar datos del slave
docker volume rm proy2_mysql-slave-data

# 3. Reiniciar
docker compose up -d db-slave

# 4. Esperar a que inicie
sleep 10

# 5. Configurar replicación
./scripts/fix-replication.sh
```

### Test de Replicación
```bash
# En el master, crear una tabla de prueba
docker compose exec db-master mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    USE ${MYSQL_DATABASE};
    CREATE TABLE IF NOT EXISTS test_replication (
        id INT PRIMARY KEY AUTO_INCREMENT,
        data VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    INSERT INTO test_replication (data) VALUES ('test data from master');
"

# En el slave, verificar que la tabla existe
docker compose exec db-slave mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    USE ${MYSQL_DATABASE};
    SELECT * FROM test_replication;
"

# Si ves los datos, la replicación funciona ✅
```

---

## Checklist de Problemas

Antes de pedir ayuda, verifica:

- [ ] Contenedores están corriendo: `docker compose ps`
- [ ] Master está healthy: `docker compose ps db-master`
- [ ] Variables en .env están correctas
- [ ] Certificados SSL existen: `ls db/certs/`
- [ ] Ran diagnostic script: `./scripts/diagnose-db.sh`
- [ ] Tried fix script: `./scripts/fix-replication.sh`
- [ ] Checked logs: `docker compose logs db-master db-slave db-proxy`

---

## Recursos Adicionales

- [MySQL Replication Documentation](https://dev.mysql.com/doc/refman/8.0/en/replication.html)
- [ProxySQL Documentation](https://proxysql.com/documentation/)
- [GTID Replication](https://dev.mysql.com/doc/refman/8.0/en/replication-gtids.html)

---

**Última actualización:** 2025-11-10  
**Versión:** 1.0.0
