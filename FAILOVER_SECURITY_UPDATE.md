# Actualización de Seguridad - Scripts de Failover/Failback

## Resumen
Se han actualizado todos los scripts de failover y failback para mejorar la seguridad, eliminando el uso de credenciales root en operaciones de automatización.

## Cambios Realizados

### 1. **Eliminación de Credenciales Root**
- **Antes**: Los scripts usaban `-uroot` con `MYSQL_ROOT_PASSWORD`
- **Después**: Utilizan usuario `monitor_user` con permisos específicos

### 2. **Scripts Actualizados**

#### `scripts/auto-failover-host.sh` (Daemon en HOST)
- ✅ Cambio de usuario root a `MYSQL_MONITOR_USER` en ambas funciones de chequeo
- ✅ Uso de `MYSQL_PWD` con variables de entorno seguras

#### `scripts/auto-failover-daemon.sh` (Daemon en contenedor)
- ✅ Reemplazo de `-uroot` por `-u"$MYSQL_MONITOR_USER"`
- ✅ Variables de monitor agregadas: `MYSQL_MONITOR_USER`, `MYSQL_MONITOR_PASSWORD`
- ✅ Funciones actualizadas:
  - `check_master_health()` - Usa usuario monitor
  - `check_slave_health()` - Usa usuario monitor

#### `scripts/failover-promote-slave.sh`
- ✅ Cambio de `MYSQL_ROOT_PASSWORD` a `MYSQL_REPLICATION_PASSWORD`
- ✅ Cambio de `-uroot` a `-u"$MYSQL_REPLICATION_USER"`
- ✅ Todos los comandos MySQL ahora usan usuario replicador
- ✅ Comentario agregado explicando el cambio

#### `scripts/failback-restore-master.sh`
- ✅ Cambio completo de credenciales root a replicador
- ✅ Todas las operaciones SQL usan usuario de replicación
- ✅ Mensaje de ayuda actualizado con comandos seguros

#### `scripts/auto-failback-daemon.sh`
- ✅ Usuario monitor en función `check_original_master_health()`
- ✅ Variables de entorno actualizadas

### 3. **Actualización de Permisos de BD**

#### `db/master/mysql/02-grants.sql.template`
Permisos expandidos para usuario monitor (para operaciones de failover):
```sql
GRANT REPLICATION CLIENT, SELECT, SUPER, REPLICATION SLAVE ON *.* 
  TO '__MYSQL_MONITOR_USER__'@'%';
```

**Permisos otorgados:**
- `REPLICATION CLIENT` - Ver estado de replicación
- `SELECT` - Leer variables del servidor
- `SUPER` - Operaciones de failover (SET GLOBAL, FLUSH, etc.)
- `REPLICATION SLAVE` - Necesario para operaciones de replicación

## Variables de Entorno Utilizadas

### Monitor (solo lectura + operaciones de failover)
```
MYSQL_MONITOR_USER=monitor_user
MYSQL_MONITOR_PASSWORD=***REMOVED***
```

### Replicación (para failover/failback)
```
MYSQL_REPLICATION_USER=replicator
MYSQL_REPLICATION_PASSWORD=***REMOVED***
```

### ProxySQL Admin
```
PROXYSQL_ADMIN_USER=admin
PROXYSQL_ADMIN_PASSWORD=admin
```

## Beneficios de Seguridad

1. **Principio de Mínimos Privilegios**: 
   - Monitor: solo lectura + SUPER (suficiente para monitoreo y failover)
   - Replicador: solo para operaciones de replicación

2. **Eliminación de Root**: 
   - No se expone la contraseña root en scripts
   - Reduce superficie de ataque

3. **Separación de Responsabilidades**:
   - Usuario monitor: chequeos de salud
   - Usuario replicador: operaciones de failover/failback
   - Admin root: solo inicialización y cambios críticos

4. **Auditoría Mejorada**:
   - Fácil rastrear operaciones por usuario específico
   - MySQL puede auditar acciones del monitor vs. replicador

## Instrucciones de Uso

### Verificación de Variables
```bash
# Asegurarse que .env contiene:
grep MYSQL_MONITOR .env
grep MYSQL_REPLICATION .env
```

### Testing de Scripts
```bash
# Test de chequeo de salud
./scripts/auto-failover-host.sh  # Verifica variables

# Test manual de failover
./scripts/failover-promote-slave.sh -y  # Automático (seguro)

# Test manual de failback
./scripts/failback-restore-master.sh -y  # Automático (seguro)
```

## Notas Importantes

⚠️ **Los scripts NO usarán credenciales root en la terminal**, lo que:
- Evita bloqueos de queries por motivos de seguridad
- Permite mejor manejo de errores con usuarios específicos
- Cumple con mejores prácticas de seguridad

⚠️ **IMPORTANTE**: Si se ejecutan desde systemd o contenedores, asegurarse que:
- Las variables de entorno están cargadas desde `.env`
- El usuario monitor tiene permisos SUPER en la BD
- La replicación está configurada con SSL (SOURCE_SSL=1)

## Rollback (si es necesario)

Si hay problemas, los scripts originales pueden restaurarse modificando:
- Cambiar `MYSQL_MONITOR_USER` de vuelta a `root`
- Cambiar `MYSQL_MONITOR_PASSWORD` a `MYSQL_ROOT_PASSWORD`
- Cambiar `MYSQL_REPLICATION_USER` de vuelta a `root`

Pero NO se recomienda por motivos de seguridad.
