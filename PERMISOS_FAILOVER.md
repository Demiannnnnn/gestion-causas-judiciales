# Permisos para Failover/Failback - Documentación

## Problema Solucionado

El usuario `replicator` solo tenía permisos `REPLICATION SLAVE` y `REPLICATION CLIENT`, lo que NO era suficiente para ejecutar las operaciones necesarias durante el failover/failback:
- `SET GLOBAL read_only=1`
- `STOP REPLICA`
- `RESET REPLICA ALL`
- `FLUSH TABLES`

Error: `ERROR 1045 (28000): Access denied for user 'replicator'@'localhost'`

## Solución Implementada

### 1. Template de Grants Actualizado (PERSISTENTE)
**Archivo**: `db/master/mysql/02-grants.sql.template`

```sql
-- Replicación (con permisos para failover/failback)
CREATE USER IF NOT EXISTS 'replicator'@'%' IDENTIFIED WITH caching_sha2_password BY '__MYSQL_REPLICATION_PASSWORD__' REQUIRE SSL;
GRANT REPLICATION SLAVE, REPLICATION CLIENT, SUPER ON *.* TO 'replicator'@'%';
```

**Cambios:**
- ✅ Agregado permiso `SUPER` al usuario `replicator` en la creación
- ✅ Este cambio es PERSISTENTE en todos los nuevos deploys

### 2. Docker Compose (ACTUALIZADO)
**Archivo**: `docker-compose.yml`

Los permisos se aplican automáticamente durante el `db-init`:
```yaml
Processing MASTER grants template...
sed -e 's|__MYSQL_REPLICATION_PASSWORD__|${MYSQL_REPLICATION_PASSWORD}|g' \
    /init-target-master/02-grants.sql.template > /init-target-master/02-grants.sql
```

## Flujo de Inicialización (PERSISTENTE)

En cada inicialización de docker-compose:
1. `db-init` procesa `02-grants.sql.template`
2. Reemplaza variables de entorno
3. MySQL ejecuta en orden:
   - `01-schema.sql` - Crea tablas
   - `02-grants.sql` - Crea usuarios CON SUPER incluido
   - `03-triggers.sql` - Crea triggers

## Permisos Otorgados (FINALES)

### Usuario `replicator` ✅
```sql
GRANT REPLICATION SLAVE, REPLICATION CLIENT, SUPER ON *.* TO 'replicator'@'%';
```

### Usuario `monitor_user` ✅
```sql
GRANT REPLICATION CLIENT, SELECT, SUPER, REPLICATION SLAVE ON *.* TO '__MYSQL_MONITOR_USER__'@'%';
GRANT SELECT ON `__MYSQL_DATABASE__`.* TO '__MYSQL_MONITOR_USER__'@'%';
```

## Para Contenedores Actuales (Temporal)

Si necesitas que funcione YA en los contenedores actuales sin reiniciar:

```bash
./scripts/update-container-permissions.sh
```

Este script:
1. ✅ Otorga SUPER a replicator en db-slave
2. ✅ Otorga SUPER a monitor_user en db-slave
3. ⚠️ Cambios TEMPORALES (se pierden si reinician los contenedores)
4. 📝 Mensaje recordando que los cambios serán persistentes después de `docker-compose up`

## Persistencia

✅ **Los cambios SERÁN persistentes** cuando:
1. Ejecutes: `sudo docker-compose down`
2. Luego: `sudo docker-compose up`
3. Docker recreará los contenedores con los nuevos permisos desde `02-grants.sql.template`

✅ **Los cambios son TEMPORALES** si:
1. Solo ejecutas `./scripts/update-container-permissions.sh`
2. Los contenedores no se reinician
3. Al reiniciar, se perderán PERO se aplicarán los de init.sql

## Validación

Para verificar permisos actuales:

```bash
# En contenedores actuales
docker exec -e MYSQL_PWD="$MYSQL_REPLICATION_PASSWORD" db-slave \
  mysql -u"replicator" -e "SHOW GRANTS FOR 'replicator'@'%';"

# Debería mostrar:
# GRANT REPLICATION SLAVE, REPLICATION CLIENT, SUPER ON *.* TO 'replicator'@'%' REQUIRE SSL
```

## Cambios Realizados a Nivel de Script

Todos los scripts ahora usan usuarios seguros:
- ✅ `scripts/failover-promote-slave.sh` - Usa `replicator` 
- ✅ `scripts/failback-restore-master.sh` - Usa `replicator`
- ✅ `scripts/auto-failover-daemon.sh` - Usa `monitor_user`
- ✅ `scripts/auto-failback-daemon.sh` - Usa `monitor_user`
- ✅ `scripts/check-replication-status.sh` - Usa usuarios seguros
- ✅ `scripts/diagnose-db.sh` - Usa `monitor_user`

## Roadmap

**Ahora (Temporal)**
```
1. Ejecutar: ./scripts/update-container-permissions.sh
2. Probar failover: ./scripts/failover-promote-slave.sh -y
```

**Próxima Reinicialización (Persistente)**
```
sudo docker-compose down
sudo docker-compose up
# Los permisos se aplicarán automáticamente desde 02-grants.sql.template
```

## Notas Importantes

⚠️ El permiso SUPER es necesario porque:
- `SET GLOBAL read_only=1` requiere SUPER
- `STOP REPLICA` requiere SUPER en MySQL 8.x
- No hay forma más específica de otorgar solo estas operaciones

✅ Seguridad:
- No usamos credenciales root en scripts
- Cada usuario tiene permisos específicos
- Los cambios están documentados y versionados

