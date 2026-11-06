# 🏛️ Sistema de Gestión de Causas Judiciales

## Información del Proyecto

### Licitación
- **Código**: 1552-56-LE25
- **Nombre**: Sistema Informático de Gestión de Causas Judiciales para Servicio de salud de Atacama
- **Link**: [Ver licitación en Mercado Público](http://www.mercadopublico.cl/Procurement/Modules/RFB/DetailsAcquisition.aspx?qs=tyy5Bzwfkbwk7fVwIC5aDA==)

### Integrantes del Equipo
- Camilo Fuentes
- Demian Maturana
- Catalina Herrera

### ¿Qué resuelve este sistema?
El sistema moderniza y digitaliza la gestión integral de causas judiciales, proporcionando una plataforma web centralizada que permite:
- Registro y seguimiento de procesos judiciales
- Gestión documental completa
- Notificaciones automáticas a las partes
- Generación de reportes y estadísticas
- Control de acceso según roles y permisos
- Análisis de seguridad con IA

---

## Arquitectura del Sistema

### Diagrama de Arquitectura
```
┌─────────────────────────────────────────────────────────────────┐
│                         USUARIOS FINALES                        │
│              (Jueces, Abogados, Administrativos)                │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                    FRONTEND (React + Nginx)                      │
│                         2 Réplicas (HA)                          │
│  frontend-1: :80  │  frontend-2: :80  │  Load Balanced           │
└──────────────────────────┬───────────────────────────────────────┘
                           │ frontend-network
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                  API GATEWAY (Traefik v2.10)                    │
│           - Load Balancing  - Service Discovery                 │
│           - SSL Termination - Rate Limiting                     │
│                    Dashboard: :8080                             │
└─────┬────────┬────────┬────────┬────────┬────────┬──────────────┘
      │        │        │        │        │        │ backend-network
      ▼        ▼        ▼        ▼        ▼        ▼
┌─────────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│  Auth   │ │  Casos  │ │Documentos│ │Notificac.│ │    AI    │
│ Service │ │ Service │ │ Service  │ │ Service  │ │ Service  │
│  :5001  │ │  :5002  │ │  :5003   │ │  :5004   │ │  :5005   │
└────┬────┘ └────┬────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
     │           │           │            │            │
     └───────────┴───────────┴────────────┴────────────┘
                           │ database-network
         ┌─────────────────┼─────────────────┐
         │                 │                 │
    ┌────▼─────┐     ┌─────▼─────┐    ┌────▼──────┐
    │  MySQL   │     │   Redis   │    │  Storage  │
    │  Master  │     │  Master   │    │  (Docs)   │
    │  :3306   │     │   :6379   │    └───────────┘
    └────┬─────┘     └─────┬─────┘
         │                 │
    ┌────▼─────┐     ┌─────▼─────┐
    │  MySQL   │     │   Redis   │
    │  Replica │     │  Replica  │
    │  :3307   │     │   :6380   │
    └──────────┘     └───────────┘

┌──────────────────────────────────────────────────────────────────┐
│                  MONITOREO & OBSERVABILIDAD                      │
│  Prometheus (:9090)  │  Grafana (:3000)  │  Logs Centralizados   │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                    BACKUP & RECUPERACIÓN                         │
│         Backup Service - Respaldos automatizados diarios         │
└──────────────────────────────────────────────────────────────────┘
```

### Servicios Implementados (14 servicios totales)

#### Frontend (Alta Disponibilidad)
1. **Frontend-1** (React + Nginx) - Primera réplica
2. **Frontend-2** (React + Nginx) - Segunda réplica

#### API Gateway
3. **Gateway** (Traefik) - Enrutamiento y Load Balancing

#### Microservicios Backend
4. **Auth Service** - Autenticación y gestión de usuarios/roles
5. **Casos Service** - CRUD de causas judiciales (Core del sistema)
6. **Documentos Service** - Gestión de archivos y documentos
7. **Notificaciones Service** - Alertas y notificaciones automáticas
8. **AI Service** - Análisis de seguridad con IA

#### Bases de Datos (Alta Disponibilidad)
9. **MySQL Master** - Base de datos principal
10. **MySQL Replica** - Réplica para lectura y failover
11. **Redis Master** - Caché principal
12. **Redis Replica** - Réplica de caché

#### Monitoreo
13. **Prometheus** - Recolección de métricas
14. **Grafana** - Visualización de dashboards

#### Infraestructura
15. **Backup Service** - Respaldos automatizados

### Redes Docker (3 redes personalizadas)
- **frontend-network**: Comunicación Frontend ↔ Gateway
- **backend-network**: Comunicación entre microservicios
- **database-network**: Acceso seguro a bases de datos

### Tecnologías Utilizadas

| Componente | Tecnología | Justificación |
|------------|-----------|---------------|
| **Orquestación** | Docker Compose | Requisito obligatorio del proyecto |
| **API Gateway** | Traefik | Load balancing automático y configuración simple |
| **Backend** | Python (FastAPI) | Alto rendimiento para APIs REST |
| **Frontend** | React + Nginx | SPA moderna con servidor web robusto |
| **BD Principal** | MySQL 8.0 | Replicación Master-Replica para HA |
| **Caché** | Redis 7 | Alto rendimiento con soporte para Sentinel |
| **Monitoreo** | Prometheus + Grafana | Estándar de la industria |
| **IA** | Ollama (Llama2) | Análisis de seguridad en logs |

---

## Alta Disponibilidad (HA)

### Estrategias Implementadas

#### 1. Replicación de Base de Datos MySQL
- **Configuración**: 1 Master + 1 Replica
- **Tipo**: Streaming Replication
- **Failover**: Automático mediante health checks
- **Beneficio**: Si cae el Master, la Replica toma el control

#### 2. Replicación de Redis
- **Configuración**: 1 Master + 1 Replica
- **Tipo**: Master-Slave replication
- **Beneficio**: Lectura distribuida y recuperación rápida

#### 3. Múltiples Réplicas de Frontend
- **Configuración**: 2 réplicas independientes
- **Load Balancer**: Traefik distribuye el tráfico
- **Beneficio**: Si cae una réplica, la otra mantiene el servicio

#### 4. Health Checks en Todos los Servicios
- Monitoreo constante del estado de cada contenedor
- Restart automático si un servicio falla
- Dependencias configuradas con `condition: service_healthy`

### Demostración de HA
Durante la presentación se mostrará:
1. Sistema funcionando con todas las réplicas activas
2. Detener manualmente una réplica de MySQL
3. Sistema continúa operando sin interrupciones
4. Réplica se recupera automáticamente

---

## 🔄 Sistema de Failover y Failback Automático

### Descripción General

El sistema incluye **automatización completa de failover y failback** para garantizar alta disponibilidad de la base de datos. En caso de que el servidor Master (primario) falle, la Replica (esclavo) se promueve automáticamente como nuevo Master.

### Tabla de Contenidos de Failover/Failback
1. [Conceptos Clave](#conceptos-clave-failover)
2. [Arquitectura](#arquitectura-de-failover-1)
3. [Scripts Disponibles](#scripts-disponibles-failover)
4. [Procedimiento Completo](#procedimiento-completo-failover-failback)
5. [Monitoreo](#monitoreo-y-validación-1)
6. [Troubleshooting](#troubleshooting-failover)

### Arquitectura de Failover

```
Estado Normal:
┌──────────────┐         ┌──────────────┐
│  db-master   │◄────────│  db-proxy    │
│   :3306      │         │   :6033      │
│ (WRITE/READ) │         │ (LOAD BALANCE)
└──────────────┘         └──────────────┘
       ▲                         ▲
       │                         │
       └─── Monitoreo activo ────┘
              (health checks)

Estado de Failover (Master cae):
┌──────────────┐         ┌──────────────┐
│  db-master   │ ✗ CAÍDA │  db-proxy    │
│   OFFLINE    │         │   SWITCHING  │
└──────────────┘         └──────────────┘
                                │
                                ▼
                         ┌──────────────┐
                         │  db-slave    │
                         │ PROMOVIDO    │
                         │ (NUEVO MASTER)
                         └──────────────┘
```

### Componentes del Sistema

#### 1. **ProxySQL (db-proxy:6033)**
- Monitorea continuamente la salud de db-master y db-slave
- Enruta automáticamente el tráfico al servidor disponible
- Soporta 2 hostgroups:
  - **Hostgroup 10**: Master (escritura)
  - **Hostgroup 20**: Slave/Replica (lectura)

#### 2. **Failover Daemon** (Auto-activado)
```bash
Container: failover-daemon
Script: scripts/auto-failover-daemon.sh
```
- Monitorea cada 5 segundos si db-master está activo
- Ejecuta automáticamente la promoción del slave si master cae
- Modifica docker-compose.yml para actualizar las réplicas

#### 3. **Failback Daemon** (Opcional, requiere perfil)
```bash
Container: failback-daemon (perfil: failback)
Script: scripts/auto-failback-daemon.sh
```
- Monitorea si el Master original se recupera
- Reinicia la replicación de forma segura
- Evita conflictos y pérdida de datos

### Cómo Funciona el Failover Automático

#### Detección de Falla
```bash
1. ProxySQL intenta conectar a db-master cada segundo
2. Tres intentos fallidos = Master considerado DOWN
3. Activa el proceso de failover
```

#### Proceso de Failover
```bash
1. failover-daemon detecta que db-master está caído
2. Ejecuta: docker exec db-slave mysql -e "STOP REPLICA"
3. Ejecuta: docker exec db-slave mysql -e "RESET REPLICA ALL"
4. Ejecuta: docker exec db-slave mysql -e "SET GLOBAL read_only=0"
5. Actualiza docker-compose.yml:
   - Cambia db-master a "paused: true"
   - Configura db-slave como nuevo master
6. ProxySQL detecta cambios y redirige tráfico
7. El sistema continúa funcionando con el nuevo Master
```

### Instrucciones de Uso

#### 1. Monitoreo del Estado Actual
```bash
# Ver estado de la replicación
docker exec db-slave mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW REPLICA STATUS\G"

# Ver estadísticas de ProxySQL
docker exec -it db-proxy proxysql-admin --config-file=/etc/proxysql/proxysql.cnf
```

#### 2. Simular una Falla (Prueba de Failover)
```bash
# Detener el Master deliberadamente
docker compose stop db-master

# Esperar 5-10 segundos...

# Verificar que el slave fue promovido
docker compose logs failover-daemon | tail -20

# Ver que el sistema continúa funcionando
curl http://localhost:8081/api/casos
```

#### 3. Recuperación Manual del Master Original

**Opción A: Sin Failback Automático**
```bash
# 1. Reiniciar el Master
docker compose start db-master

# 2. Esperar a que esté listo (~30 segundos)
docker compose exec db-master mysqladmin ping -u root -p${MYSQL_ROOT_PASSWORD}

# 3. Reconfigurar manualmente la replicación
docker compose exec db-master mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \
  "CHANGE REPLICATION SOURCE TO SOURCE_HOST='db-slave', SOURCE_USER='replicator', SOURCE_PASSWORD='${MYSQL_REPLICATION_PASSWORD}'"

docker compose exec db-master mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \
  "SET GLOBAL read_only=1; START REPLICA"

# 4. Actualizar docker-compose.yml para restaurar configuración original
# (Cambiar db-slave back a replica)
```

**Opción B: Con Failback Automático**
```bash
# 1. Activar el daemon de failback
docker compose --profile failback up -d failback-daemon

# 2. Reiniciar el Master
docker compose start db-master

# 3. El failback-daemon automáticamente:
#    - Detecta que db-master se recuperó
#    - Copia datos del nuevo master al antiguo
#    - Reconfigura la replicación
#    - Promueve db-master como master nuevamente
#    - Detiene failback-daemon (autocompletado)

# 4. Verificar estado final
docker compose exec db-master mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW MASTER STATUS\G"
```

#### 4. Forzar un Failover Manual (Si es Necesario)
```bash
# ADVERTENCIA: Esto rompe la replicación. Solo usar en emergencias.

# 1. Promover el slave
docker exec db-slave mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "STOP REPLICA; RESET REPLICA ALL; SET GLOBAL read_only=0"

# 2. Actualizar aplicación para usar nuevo master
# (Cambiar DATABASE_URL en servicios a apuntar a db-slave)

# 3. Luego, cuando master se recupere, sincronizar desde backup
scripts/restore-db.sh --latest
```

### Scripts Disponibles

| Script | Ubicación | Función |
|--------|-----------|---------|
| `auto-failover-daemon.sh` | `scripts/auto-failover-daemon.sh` | Monitorea y promueve replica en caso de falla del master |
| `auto-failback-daemon.sh` | `scripts/auto-failback-daemon.sh` | Restaura master cuando se recupera (opcional) |
| `failover-promote-slave.sh` | `scripts/failover-promote-slave.sh` | Promueve replica manualmente |
| `failback-restore-master.sh` | `scripts/failback-restore-master.sh` | Restaura configuración original del master |
| `check-replication-status.sh` | `scripts/check-replication-status.sh` | Verifica estado actual de replicación |

### Verificar Estado de Failover

```bash
# Ver logs del daemon de failover
docker compose logs failover-daemon

# Buscar eventos de failover
docker compose logs failover-daemon | grep -i "failover\|promote"

# Ver cambios en docker-compose.yml
git diff docker-compose.yml

# Verificar que db-proxy está enrutando correctamente
docker exec -it db-proxy mysql -h localhost -u admin -padmin -e "SHOW PROCESSLIST"
```

### Monitoreo con Prometheus/Grafana

Los eventos de failover se registran y pueden monitorearse en Grafana:

```bash
# Acceder a Grafana
http://localhost:3000

# Dashboard: "Base de Datos - Replicación"
# Buscar métricas:
- mysql_global_status_threads_running (cambio en master)
- mysql_global_status_read_only (cambio a read_only=0)
- proxysql_mysql_monitor_errors (errores de conexión)
```

### Mejores Prácticas

1. **Mantener backups actualizados**
   ```bash
   # Ejecutar backups regularmente
   scripts/backup/backup-db.sh
   ```

2. **Probar failover regularmente**
   ```bash
   # Una vez al mes, simular una falla en control y confirmar que el sistema se recupera
   ```

3. **Monitorear logs**
   ```bash
   # Revisar regularmente los logs de failover
   docker compose logs -f failover-daemon
   ```

4. **Actualizar credenciales en ProxySQL**
   ```bash
   # Si cambia MYSQL_MONITOR_PASSWORD, actualizar:
   # scripts/config-templates/proxysql/proxysql.cnf.template
   # Luego regenerar config: scripts/init-proxysql.sh
   ```

### Troubleshooting

**Problema: Failover no se ejecuta automáticamente**
```bash
# Verificar que failover-daemon está corriendo
docker compose ps failover-daemon

# Ver logs del daemon
docker compose logs failover-daemon

# Verificar que ProxySQL está monitoreando
docker compose exec db-proxy proxysql-admin --check-status
```

**Problema: ProxySQL no reconoce cambios**
```bash
# Reiniciar ProxySQL
docker compose restart db-proxy

# Esperar 10 segundos para que reconecte
sleep 10

# Verificar status
docker compose exec db-proxy proxysql-admin --config-file=/etc/proxysql/proxysql.cnf
```

**Problema: Replicación rota después de failback**
```bash
# Detener ambos servidores
docker compose stop db-master db-slave

# Reiniciar limpio
docker compose up -d db-master db-slave

# Verificar replicación
docker compose exec db-slave mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW REPLICA STATUS\G"
```

---

## 📋 Referencia Completa de Scripts de Failover/Failback

### 1. `check-replication-status.sh` - Verificar Estado de Replicación

**Ubicación:** `scripts/check-replication-status.sh`

**Descripción:** Script para monitorear la salud general de la replicación MySQL y ProxySQL.

**Uso básico:**
```bash
# Hacer el script ejecutable (solo la primera vez)
chmod +x scripts/check-replication-status.sh

# Ejecutar el script
./scripts/check-replication-status.sh
```

**¿Qué verifica?**
- Estado de los servidores en ProxySQL (Master, Slave)
- Status del thread replicador
- Lag de replicación
- Errores en la replicación
- Conexiones activas

**Salida esperada:**
```
==========================================
Database Replication Health Check
==========================================

=== ProxySQL Server Status ===
hostgroup_id | hostname  | port | status | weight | max_connections
10           | db-master | 3306 | ONLINE | 1      | 100
20           | db-master | 3306 | ONLINE | 1      | 100
20           | db-slave  | 3306 | ONLINE | 1      | 100

=== Master Replication Status ===
(Información del master)

=== Slave Replication Status ===
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Seconds_Behind_Master: 0
```

**Interpretar resultados:**
- ✅ `ONLINE` en ambos servidores = Replicación sana
- ❌ `OFFLINE` en db-slave = Falla detectada, failover debe activarse
- ⚠️ `Seconds_Behind_Master > 10` = Lag alto, investigar carga en slave

---

### 2. `failover-promote-slave.sh` - Promover Slave Manualmente

**Ubicación:** `scripts/failover-promote-slave.sh`

**Descripción:** Script para promover manualmente el Slave como nuevo Master (ejecutar failover manual).

**⚠️ ADVERTENCIA:** Este script rompe la replicación. Solo usar cuando:
- El Master está permanentemente caído
- El failover automático no se ejecutó
- Se necesita forzar un cambio de master

**Uso:**
```bash
# Hacer el script ejecutable
chmod +x scripts/failover-promote-slave.sh

# Ejecutar el failover
./scripts/failover-promote-slave.sh
```

**Proceso que ejecuta:**
1. Verifica que el Slave está sano
2. Detiene la replicación en el Slave
3. Promueve el Slave como nuevo Master (`read_only = OFF`)
4. Actualiza ProxySQL para cambiar hostgroups
5. Verifica que ProxySQL reconoce los cambios
6. Redirige el tráfico al nuevo Master

**Ejemplo de ejecución:**
```bash
$ ./scripts/failover-promote-slave.sh

==========================================
ProxySQL Failover: Promote Slave to Master
==========================================

Verificando estado actual de ProxySQL...
hostgroup_id | hostname | status
10           | db-master| OFFLINE
20           | db-master| OFFLINE
20           | db-slave | ONLINE

✓ Deteniendo replicación en db-slave...
✓ Promoviendo db-slave como nuevo Master...
✓ Actualizando ProxySQL...
✓ Verificando cambios...

✅ Failover completado exitosamente
    Nuevo Master: db-slave
    Los clientes ahora están conectados a db-slave
```

**Verificar después:**
```bash
# Confirmar que ProxySQL cambió
./scripts/check-replication-status.sh

# Ver que las aplicaciones siguen funcionando
curl http://localhost:8081/api/casos
```

---

### 3. `failback-restore-master.sh` - Restaurar Master Original

**Ubicación:** `scripts/failback-restore-master.sh`

**Descripción:** Script para restaurar la configuración original después de un failover (convertir db-master nuevamente en Master y db-slave en Replica).

**⚠️ REQUIERE:** Que db-master esté nuevamente disponible y sincronizado con datos del nuevo master.

**Uso:**
```bash
# Hacer el script ejecutable
chmod +x scripts/failback-restore-master.sh

# Ejecutar el failback
./scripts/failback-restore-master.sh
```

**Proceso que ejecuta:**
1. Verifica que db-master esté disponible
2. Sincroniza datos desde el nuevo master a db-master (si es necesario)
3. Configura db-master como nuevo Slave del actual Master (db-slave)
4. Espera a que se sincronice completamente
5. Promueve db-master a Master (`read_only = OFF`)
6. Actualiza ProxySQL para volver a la configuración original
7. Verifica la integridad de la replicación

**Ejemplo de ejecución:**
```bash
$ ./scripts/failback-restore-master.sh

==========================================
ProxySQL Failback: Restore Original Master
==========================================

✓ Verificando disponibilidad de db-master...
✓ Sincronizando datos...
✓ Configurando replicación...
✓ Esperando sincronización (Lag: 5s)...
✓ Esperando sincronización (Lag: 0s)...
✓ Promoviendo db-master...
✓ Actualizando ProxySQL...

✅ Failback completado exitosamente
    Master Principal: db-master
    Replica: db-slave
    Sistema restaurado a configuración original
```

**Verificar después:**
```bash
# Confirmar que ProxySQL volvió a la config original
./scripts/check-replication-status.sh

# Verificar que db-master es Master
docker exec db-master mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW MASTER STATUS\G"

# Verificar que db-slave es Slave
docker exec db-slave mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW REPLICA STATUS\G"
```

---

### 4. `auto-failover-daemon.sh` - Daemon de Failover Automático

**Ubicación:** `scripts/auto-failover-daemon.sh`

**Descripción:** Daemon que monitorea continuamente la salud del Master y ejecuta failover automáticamente si falla.

**Nota:** Normalmente se ejecuta en contenedor (`failover-daemon` en docker-compose.yml)

**Uso desde línea de comandos:**
```bash
# Hacer el script ejecutable
chmod +x scripts/auto-failover-daemon.sh

# Ejecutar el daemon (se ejecutará indefinidamente)
./scripts/auto-failover-daemon.sh

# O en background
./scripts/auto-failover-daemon.sh &

# Ver logs
tail -f /tmp/failover-daemon.log
```

**Variables de configuración (.env):**
```bash
FAILOVER_CHECK_INTERVAL=5          # Verificar cada 5 segundos
FAILOVER_FAILURE_THRESHOLD=3       # Fallar 3 veces = activar failover
FAILOVER_LOG_FILE=/tmp/failover.log
```

**¿Qué hace?**
1. Lee variables del `.env`
2. Entra en un loop infinito
3. Cada 5 segundos intenta conectar a db-master
4. Si falla 3 veces consecutivas, ejecuta `failover-promote-slave.sh`
5. Registra toda la actividad en logs

**Monitorar el daemon:**
```bash
# Ver si está corriendo
docker compose ps failover-daemon

# Ver logs en tiempo real
docker compose logs -f failover-daemon

# Buscar eventos de failover en logs
docker compose logs failover-daemon | grep -i "failover\|promote"
```

---

### 5. `auto-failback-daemon.sh` - Daemon de Failback Automático (Opcional)

**Ubicación:** `scripts/auto-failback-daemon.sh`

**Descripción:** Daemon que monitorea si el Master original se recupera y ejecuta failback automáticamente.

**⚠️ OPCIONAL:** Solo se ejecuta si se activa el perfil `failback`

**Uso:**
```bash
# Activar el daemon de failback (con perfil)
docker compose --profile failback up -d failback-daemon

# Verificar que está corriendo
docker compose ps failback-daemon

# Ver logs
docker compose logs -f failback-daemon

# Detener el daemon cuando se completa el failback
docker compose --profile failback down failback-daemon
```

**¿Qué hace?**
1. Monitorea si db-master se recupera
2. Detecta cuando db-master está disponible
3. Sincroniza datos desde db-slave a db-master
4. Reconfigura la replicación
5. Promueve db-master como Master nuevamente
6. Se detiene automáticamente

**Salida en logs:**
```
Iniciando failback daemon...
Esperando recuperación del Master original...
Master db-master detectado - iniciando failback
Sincronizando datos...
Failback completado - db-master es Master nuevamente
```

---

### 6. `auto-failover-host.sh` - Failover en Host (No Contenedor)

**Ubicación:** `scripts/auto-failover-host.sh`

**Descripción:** Versión del failover daemon para ejecutarse en el HOST como servicio systemd o supervisord (no en contenedor).

**Cuándo usar:**
- Cuando quieres que el failover funcione incluso si el contenedor del daemon falla
- Para máxima resiliencia

**Instalación como servicio systemd:**
```bash
# 1. Copiar script a /usr/local/bin
sudo cp scripts/auto-failover-host.sh /usr/local/bin/

# 2. Dar permisos de ejecución
sudo chmod +x /usr/local/bin/auto-failover-host.sh

# 3. Copiar archivo systemd
sudo cp scripts/systemd/auto-failover.service /etc/systemd/system/

# 4. Recargar systemd
sudo systemctl daemon-reload

# 5. Habilitar el servicio
sudo systemctl enable auto-failover.service

# 6. Iniciar el servicio
sudo systemctl start auto-failover.service

# 7. Verificar estado
sudo systemctl status auto-failover.service

# 8. Ver logs
sudo journalctl -u auto-failover.service -f
```

**Comandos útiles:**
```bash
# Ver estado
sudo systemctl status auto-failover.service

# Reiniciar
sudo systemctl restart auto-failover.service

# Detener
sudo systemctl stop auto-failover.service

# Ver últimos 50 logs
sudo journalctl -u auto-failover.service -n 50

# Monitoreo en tiempo real
sudo journalctl -u auto-failover.service -f
```

---

## 🚀 Flujo de Trabajo Típico: Failover y Failback

### Escenario: Master falla durante producción

**Paso 1: Detección automática (automático)**
```bash
failover-daemon detecta caída de db-master
→ Ejecuta failover-promote-slave.sh automáticamente
→ db-slave se promueve como nuevo Master
```

**Paso 2: Verificar estado (manual)**
```bash
./scripts/check-replication-status.sh
# Confirmar que db-slave ahora es Master
```

**Paso 3: Reparar Master original (operacional)**
```bash
# Ejemplo: reiniciar db-master
docker compose restart db-master

# Esperar a que esté listo
sleep 30
```

**Paso 4: Restaurar configuración original (manual)**
```bash
./scripts/failback-restore-master.sh
# db-master vuelve a ser Master
# db-slave vuelve a ser Replica
```

**Paso 5: Verificar integridad (manual)**
```bash
./scripts/check-replication-status.sh
# Confirmar que replicación está sana
# Ambos threads (IO y SQL) deben estar running
```

---

## 📊 Integración con Monitoreo

### Ver eventos de failover en Grafana

```bash
# 1. Acceder a Grafana
http://localhost:3000

# 2. Ir a Dashboard → "Base de Datos - Replicación"

# 3. Buscar estos eventos:
   - mysql_slave_status_seconds_behind_master = 999
   - mysql_slave_status_slave_io_running = 0
   - mysql_global_status_read_only cambios de 1 a 0
   - proxysql_mysql_monitor_connect_errors picos
```

---

## 🔧 Troubleshooting de Scripts

### Error: "Permission denied"
```bash
# Solución: Dar permisos de ejecución
chmod +x scripts/failover-promote-slave.sh
chmod +x scripts/failback-restore-master.sh
chmod +x scripts/check-replication-status.sh
```

### Error: "No se puede conectar a docker"
```bash
# Asegurar que el usuario puede ejecutar docker
sudo usermod -aG docker $USER
newgrp docker

# O ejecutar con sudo
sudo ./scripts/check-replication-status.sh
```

### Error: ".env no encontrado"
```bash
# Los scripts buscan .env relativo al proyecto
# Ejecutarlos desde la raíz del proyecto:
cd /ruta/al/proyecto
./scripts/check-replication-status.sh

# NO desde dentro de scripts/:
cd scripts
./check-replication-status.sh  # ❌ Esto fallará
```

### Error: "Slave no está sincronizado"
```bash
# Si failback falla porque hay un lag grande
# 1. Esperar más tiempo
sleep 60

# 2. Ejecutar nuevamente failback
./scripts/failback-restore-master.sh

# 3. Si sigue fallando, hacer failback manual:
docker compose exec db-slave mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW MASTER STATUS\G"
docker compose exec db-master mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CHANGE REPLICATION SOURCE TO SOURCE_HOST='db-slave'..."
```

---

## Componente de Inteligencia Artificial

### Funcionalidad: Agente IA para Detección de Brechas de Seguridad

#### ¿Qué hace?
El **AI Service** revisa continuamente los logs de acciones realizadas dentro de todos los microservicios y genera reportes automáticos para el Administrador del Sistema cuando detecta:
- Intentos de acceso no autorizado
- Patrones anómalos de comportamiento
- Accesos fuera de horario
- Múltiples intentos fallidos de login
- Actividad sospechosa en documentos sensibles

#### ¿Por qué es útil para la licitación?
La licitación exige cumplir con:
- **Ley N°19.628** sobre Protección de la Vida Privada
- **ISO/IEC 27001** - Certificación de Seguridad de la Información
- **RNF-2**: Protección de información sensible de carácter judicial

El AI Service automatiza la vigilancia de seguridad, reduciendo el riesgo humano y proporcionando alertas tempranas de posibles vulnerabilidades.

#### Tecnología
- **Modelo**: Llama2 (Ollama local)
- **Análisis**: Procesamiento de logs en tiempo real
- **Output**: Reportes en lenguaje natural para administradores

#### Endpoint de Ejemplo
```bash
POST /api/ai/analyze-security
{
  "service": "auth-service",
  "time_range": "last_24h"
}

Response:
{
  "status": "warning",
  "incidents": 3,
  "summary": "Se detectaron 3 intentos fallidos de login desde IP 192.168.1.100",
  "recommendation": "Considerar bloquear temporalmente esta IP"
}
```

---

## Instalación y Uso

### Requisitos Previos
- **Docker Desktop**: Versión 20.10 o superior
- **RAM**: Mínimo 8GB (recomendado 16GB)
- **Espacio en disco**: 10GB libres
- **Sistema Operativo**: Windows 11, macOS, o Linux

### Paso 1: Clonar el Repositorio
```bash
git clone https://github.com/tu-usuario/sistema-causas-judiciales.git
cd sistema-causas-judiciales
```

### Paso 2: Configurar Variables de Entorno
```bash
# Copiar el template
cp .env.example .env

# Editar el archivo .env con credenciales
# Puedes usar VS Code:
code .env
```

**Variables importantes a configurar:**
- `MYSQL_ROOT_PASSWORD`: Contraseña del usuario root de MySQL
- `SMTP_USER` y `SMTP_PASSWORD`: Para envío de notificaciones por email
- `OLLAMA_HOST`: URL de tu servidor Ollama (si usas IA local)

### Paso 3: Levantar el Sistema
```bash
# Construir e iniciar todos los servicios
docker-compose up -d

# Ver los logs en tiempo real
docker-compose logs -f

# Verificar que todos los servicios estén corriendo
docker-compose ps
```

### Paso 4: Acceder al Sistema

#### URLs de Acceso
- **Frontend**: http://localhost
- **API Gateway Dashboard**: http://localhost:8080
- **Grafana (Monitoreo)**: http://localhost:3000
- **Prometheus (Métricas)**: http://localhost:9090

#### Usuarios de Prueba (modificables)
| Rol | Usuario | Contraseña |
|-----|---------|-----------|
| Administrador | admin@judicial.cl | Admin123! |
| Abogado | abogado@judicial.cl | Abogado123! |

### Comandos Útiles

#### Ver estado de servicios
```bash
docker-compose ps
```

#### Ver logs de un servicio específico
```bash
docker-compose logs -f casos-service
```

#### Reiniciar un servicio
```bash
docker-compose restart casos-service
```

#### Detener todo el sistema
```bash
docker-compose down
```

#### Detener y eliminar todos los datos
```bash
docker-compose down -v
```

#### Ver métricas de recursos
```bash
docker stats
```

---

## Sistema de Respaldos

## 📋 Descripción

Sistema automatizado de respaldos para el proyecto de Causas Judiciales. Incluye scripts para respaldar y restaurar:

- **Base de datos MySQL** (esquema, datos, usuarios)
- **Archivos y documentos** (uploads de documentos judiciales)
- **Configuraciones del sistema** (docker-compose, .env, scripts)

---

## Uso Rápido

### Respaldo Completo del Sistema

```bash
# Ejecutar respaldo completo (recomendado)
cd scripts/backup
./backup-all.sh
```

Este comando respaldará automáticamente:
- ✅ Base de datos completa
- ✅ Todos los archivos cargados
- ✅ Configuraciones del sistema
- ✅ Scripts de administración

### Respaldos Individuales

```bash
# Solo base de datos
./backup-db.sh

# Solo archivos
./backup-files.sh
```

---

## Scripts Disponibles

### 1. `backup-db.sh` - Respaldo de Base de Datos

**¿Qué hace?**
- Exporta toda la base de datos MySQL
- Comprime el archivo SQL con gzip
- Mantiene los últimos 7 días de respaldos
- Verifica la integridad del backup

**Uso:**
```bash
./backup-db.sh
```

**Salida:**
```
backups/database/
├── db_causas_judiciales_db_2024-11-02_14-30-00.sql.gz
├── db_causas_judiciales_db_2024-11-01_14-30-00.sql.gz
└── ...
```

**Configuración:**
Puedes modificar estas variables en el script o en `.env`:
- `MYSQL_HOST`: Host de MySQL (default: `mysql`)
- `MYSQL_USER`: Usuario de MySQL (default: `admin_db`)
- `MYSQL_PASSWORD`: Contraseña
- `MYSQL_DATABASE`: Nombre de la BD (default: `causas_judiciales_db`)
- `BACKUP_RETENTION_DAYS`: Días de retención (default: `7`)

---

### 2. `restore-db.sh` - Para estaurar la Base de Datos

**¿Qué hace?**
- Lista backups disponibles
- Crea backup de seguridad antes de restaurar
- Restaura la base de datos desde un backup
- Verifica la restauración

**Uso:**
```bash
# Ver backups disponibles
./restore-db.sh --list

# Restaurar el más reciente
./restore-db.sh --latest

# Restaurar un backup específico
./restore-db.sh db_causas_judiciales_db_2024-11-02_14-30-00.sql.gz
```

**⚠️ ADVERTENCIA:** Esta operación SOBRESCRIBIRÁ la base de datos actual. Siempre crea un backup de seguridad antes de proceder.

**Proceso de restauración:**
1. Verifica conectividad con MySQL
2. Crea backup de seguridad de la BD actual
3. Elimina la base de datos actual
4. Restaura desde el backup seleccionado
5. Verifica que la restauración fue exitosa

---

### 3. `backup-files.sh` - Para Respaldo de Archivos

**¿Qué hace?**
- Respalda todos los archivos cargados (documentos judiciales)
- Crea un archivo tar.gz comprimido
- Mantiene los últimos 7 días de respaldos
- Verifica la integridad del backup

**Uso:**
```bash
./backup-files.sh
```

**Directorios respaldados:**
- `backend/documentos/uploads/` - Documentos cargados por usuarios

**Salida:**
```
backups/files/
├── files_2024-11-02_14-35-00.tar.gz
├── files_2024-11-01_14-35-00.tar.gz
└── ...
```

---

### 4. `restore-files.sh` - Para Restaurar Archivos

**¿Qué hace?**
- Lista backups de archivos disponibles
- Crea backup de seguridad de archivos actuales
- Restaura archivos desde un backup
- Verifica la restauración

**Uso:**
```bash
# Ver backups disponibles
./restore-files.sh --list

# Restaurar el más reciente
./restore-files.sh --latest

# Restaurar un backup específico
./restore-files.sh files_2024-11-02_14-35-00.tar.gz
```

---

### 5. `backup-all.sh` - Para un Respaldo Completo

**¿Qué hace?**
- Ejecuta backup-db.sh
- Ejecuta backup-files.sh
- Respalda configuraciones (docker-compose.yml, .env.example, etc.)
- Respalda scripts de administración
- Crea un archivo consolidado con todo
- Genera un MANIFEST con información del backup
- Mantiene los últimos 30 días de backups completos

**Uso:**
```bash
./backup-all.sh
```

**Salida:**
```
backups/complete/
└── backup_complete_2024-11-02_14-40-00.tar.gz
    ├── db_causas_judiciales_db_2024-11-02_14-40-00.sql.gz
    ├── files_2024-11-02_14-40-00.tar.gz
    ├── configs/
    │   ├── docker-compose.yml
    │   ├── .env.example
    │   ├── monitoring/
    │   └── scripts/
    └── MANIFEST.txt
```

**Contenido del MANIFEST.txt:**
```
╔════════════════════════════════════════╗
║   MANIFIESTO DE RESPALDO COMPLETO      ║
╚════════════════════════════════════════╝

INFORMACIÓN DEL RESPALDO
========================
Fecha de creación: 2024-11-02 14:40:00
Nombre del backup: backup_2024-11-02_14-40-00
Hostname: servidor-judicial
Usuario: admin

CONTENIDO DEL BACKUP
====================
- Base de datos (15.3 MB)
- Archivos documentos (234.7 MB)
- Configuraciones (2.1 MB)
- Scripts (0.5 MB)

Total: 252.6 MB
```

---

## 🔄 Automatización con Cron

### Configurar Backups Automáticos

Para ejecutar backups automáticamente, se pueden agrega estos trabajos a cron:

```bash
# Editar crontab
crontab -e

# Agregar estas líneas:

# Backup completo diario a las 2 AM
0 2 * * * cd /ruta/al/proyecto/scripts/backup && ./backup-all.sh >> /var/log/backup.log 2>&1

# Backup de BD cada 6 horas
0 */6 * * * cd /ruta/al/proyecto/scripts/backup && ./backup-db.sh >> /var/log/backup-db.log 2>&1

# Backup de archivos cada 12 horas
0 */12 * * * cd /ruta/al/proyecto/scripts/backup && ./backup-files.sh >> /var/log/backup-files.log 2>&1
```

### Usando Docker Compose (Recomendado)

Ya incluimos un servicio de backup automatizado en `docker-compose.yml`:

```yaml
backup-service:
  build:
    context: ./scripts/backup
    dockerfile: Dockerfile.backup
  container_name: backup-service
  environment:
    - BACKUP_SCHEDULE=0 2 * * *  # Diario a las 2 AM
    - BACKUP_RETENTION_DAYS=7
  volumes:
    - ./backups:/backups
    - ./db:/db
    - ./backend:/backend
  networks:
    - app-network
  restart: unless-stopped
```

**Para cambiar la frecuencia**, edita `BACKUP_SCHEDULE` usando formato cron:
- `0 2 * * *` - Diario a las 2 AM
- `0 */6 * * *` - Cada 6 horas
- `0 0 * * 0` - Cada domingo a medianoche
- `*/30 * * * *` - Cada 30 minutos

---

## Estructura de Directorios de Backup

```
backups/
├── database/              # Backups de base de datos
│   ├── db_causas_judiciales_db_2024-11-02_14-30-00.sql.gz
│   ├── db_causas_judiciales_db_2024-11-01_14-30-00.sql.gz
│   └── ...
│
├── files/                 # Backups de archivos
│   ├── files_2024-11-02_14-35-00.tar.gz
│   ├── files_2024-11-01_14-35-00.tar.gz
│   └── ...
│
└── complete/              # Backups completos consolidados
    ├── backup_complete_2024-11-02_14-40-00.tar.gz
    ├── backup_complete_2024-11-01_14-40-00.tar.gz
    └── ...
```

---

## Seguridad y Mejores Prácticas

### Protección de Backups

1. **Permisos restrictivos:**
```bash
chmod 700 backups/
chmod 600 backups/**/*.gz
```

2. **Excluir del control de versiones:**
Ya está configurado en `.gitignore`:
```
backups/
*.sql
*.sql.gz
*.tar.gz
```

3. **Encriptar backups sensibles:**
```bash
# Encriptar un backup
gpg --symmetric --cipher-algo AES256 backup_complete_2024-11-02.tar.gz

# Desencriptar
gpg --decrypt backup_complete_2024-11-02.tar.gz.gpg > backup.tar.gz
```

### Almacenamiento Externo

**Recomendación:** Los backups deberían copiarse a ubicaciones externas:

```bash
# Copiar a servidor remoto (SSH/SCP)
scp backups/complete/backup_complete_*.tar.gz user@servidor-backup:/backups/judicial/

# Copiar a almacenamiento en la nube (AWS S3)
aws s3 cp backups/complete/backup_complete_*.tar.gz s3://mi-bucket/backups/

# Copiar a Google Drive (usando rclone)
rclone copy backups/complete/ gdrive:Backups/Judicial/
```

---

## Verificación de Backups

### Verificar Integridad

```bash
# Verificar un backup de BD
gunzip -t backups/database/db_*.sql.gz

# Verificar un backup de archivos
tar -tzf backups/files/files_*.tar.gz > /dev/null

# Verificar un backup completo
tar -tzf backups/complete/backup_complete_*.tar.gz > /dev/null
```

### Prueba de Restauración

**Es crítico probar las restauraciones regularmente:**

```bash
# 1. Crear un entorno de prueba
docker-compose -f docker-compose.test.yml up -d

# 2. Restaurar el backup en el entorno de prueba
./restore-db.sh --latest

# 3. Verificar que los datos son correctos
docker exec mysql mysql -u admin_db -padmin -e "SELECT COUNT(*) FROM causas_judiciales_db.casos;"

# 4. Detener el entorno de prueba
docker-compose -f docker-compose.test.yml down
```

---

## 🐛 Solución de Posibles Problemas

### Error: "No se puede conectar a MySQL"

**Causa:** El contenedor de MySQL no está corriendo o no está listo.

**Solución:**
```bash
# Verificar que MySQL esté corriendo
docker-compose ps mysql

# Ver logs de MySQL
docker-compose logs mysql

# Reiniciar MySQL
docker-compose restart mysql

# Esperar a que esté listo
docker-compose exec mysql mysqladmin ping -h localhost --silent
```

### Error: "Permission denied"

**Causa:** Los scripts no tienen permisos de ejecución.

**Solución:**
```bash
# Dar permisos de ejecución
chmod +x scripts/backup/*.sh

# O todos los scripts
find scripts/ -name "*.sh" -exec chmod +x {} \;
```

### Error: "Backup corrupto"

**Causa:** El archivo se dañó durante la creación o copia.

**Solución:**
```bash
# Verificar integridad
gunzip -t backup.sql.gz

# Si está corrupto, eliminar y crear uno nuevo
rm backup.sql.gz
./backup-db.sh
```

### Espacio en disco insuficiente

**Síntoma:** Backups fallan con errores de espacio.

**Solución:**
```bash
# Ver espacio disponible
df -h

# Ver tamaño de backups
du -sh backups/

# Limpiar backups antiguos manualmente
find backups/ -type f -mtime +30 -delete

# Reducir período de retención en los scripts
# Editar BACKUP_RETENTION_DAYS=3
```

---

## Ejemplos de Uso

### Escenario 1: Backup Diario Antes de Actualización

```bash
#!/bin/bash
# Script para actualizar el sistema con backup previo

echo "Creando backup antes de actualizar..."
cd scripts/backup
./backup-all.sh

echo "Actualizando sistema..."
cd ../..
git pull
docker-compose build
docker-compose up -d

echo "Actualización completada. Backup disponible en backups/complete/"
```

### Escenario 2: Migración a Nuevo Servidor

```bash
# En el servidor antiguo:
./backup-all.sh
BACKUP=$(ls -t backups/complete/backup_complete_*.tar.gz | head -n 1)
scp $BACKUP nuevo-servidor:/tmp/

# En el servidor nuevo:
cd /ruta/proyecto
tar -xzf /tmp/backup_complete_*.tar.gz
cd scripts/backup
./restore-db.sh --latest
./restore-files.sh --latest
```

### Escenario 3: Recuperación de Desastre

```bash
# Si la base de datos se corrompe
./restore-db.sh --latest

# Si se eliminaron archivos por error
./restore-files.sh --latest

# Si el sistema completo falló
tar -xzf backups/complete/backup_complete_<fecha>.tar.gz
# Restaurar cada componente individualmente
```

---

## Soporte

Para problemas con los scripts de backup:

1. Revisar los logs: `docker-compose logs backup-service`
2. Verificar permisos: `ls -la scripts/backup/`
3. Compruebar espacio: `df -h`
4. Consultar este README
5. Contactar al administrador del sistema

---

## Changelog

### Versión 1.0.0 (2024-11-02)
- ✅ Script inicial de backup de BD
- ✅ Script de restauración de BD
- ✅ Script de backup de archivos
- ✅ Script de restauración de archivos
- ✅ Script de backup completo
- ✅ Automatización con cron
- ✅ Documentación completa

---

## Monitoreo del Sistema

### Acceso a Grafana
1. Abrir http://localhost:3000
2. Login: `admin` / `admin123`
3. Dashboard: "Sistema Causas Judiciales"

### Métricas Monitoreadas
- ✅ CPU y memoria de cada servicio
- ✅ Tasa de peticiones por segundo
- ✅ Tiempo de respuesta de APIs
- ✅ Estado de salud de bases de datos
- ✅ Uso de caché (Redis)
- ✅ Espacio en disco

### Alertas Configuradas
- CPU > 80% por más de 5 minutos
- Memoria > 90%
- Servicio caído
- Base de datos no responde
- Backup fallido

---

## Testing y Validación

### Health Checks
Todos los servicios tienen endpoints de salud:
```bash
# Frontend
curl http://localhost/health

# Auth Service
curl http://localhost/api/auth/health

# Casos Service
curl http://localhost/api/casos/health
```

### Prueba de Alta Disponibilidad
```bash
# 1. Verificar que todo funciona
docker-compose ps

# 2. Simular falla del MySQL Master
docker-compose stop mysql-master

# 3. Verificar que el sistema sigue funcionando
curl http://localhost/api/casos

# 4. Levantar nuevamente el Master
docker-compose start mysql-master
```
---

## Troubleshooting

### Problema: Servicios no inician
```bash
# Ver logs detallados
docker-compose logs

# Verificar puertos en uso
netstat -an | grep LISTEN

# Limpiar y reiniciar
docker-compose down -v
docker-compose up -d
```

### Problema: Base de datos no conecta
```bash
# Verificar que MySQL esté corriendo
docker-compose ps mysql-master

# Ver logs de MySQL
docker-compose logs mysql-master

# Conectar manualmente para probar
docker exec -it mysql-master mysql -u root -p
```

### Problema: Frontend muestra error 502
```bash
# Verificar que el gateway esté corriendo
docker-compose ps gateway

# Reiniciar el gateway
docker-compose restart gateway
```

---

## 📚 Recursos Adicionales

- [Documentación de Docker Compose](https://docs.docker.com/compose/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [React Documentation](https://react.dev/)
- [MySQL Replication Guide](https://dev.mysql.com/doc/refman/8.0/en/replication.html)

---

## 📄 Licencia

Este proyecto fue desarrollado como parte del curso de Administración de Redes y Sistemas Computacionales de la Universidad de Talca.

---

## Contacto

Para preguntas sobre el proyecto:
- Camilo Fuentes: [email]
- Demian Maturana: [email]
- Catalina Herrera: [email]

**Profesor**: Ricardo Pérez (riperez@utalca.cl)

---

## Para ejecutar

docker-compose build
docker-compose up
escribir en el navegador https://locahost:8081/

---

## Inicialización de la Base de Datos con Replicación Segura

El sistema está configurado para levantar un cluster de base de datos MySQL con replicación maestro-esclavo (source-replica) segura (vía SSL) y de forma totalmente automatizada.

Sigue estos pasos para la inicialización:

### 1. Configurar Variables de Entorno

Copia el archivo de ejemplo `.env.example` a un nuevo archivo llamado `.env`.

```bash
cp .env.example .env
```

Abre el archivo `.env` y ajusta las contraseñas y otros valores según sea necesario.

### 2. Generar Certificados SSL

Para la comunicación segura entre el maestro y el esclavo de la base de datos, se requieren certificados SSL. Se proporciona un script para generarlos automáticamente.

Primero, dale permisos de ejecución al script:

```bash
chmod +x db/generate-certs.sh
```

Luego, ejecútalo:

```bash
./db/generate-certs.sh
```

Esto creará todos los archivos necesarios en el directorio `db/certs`.

### 3. Levantar los Servicios

Con los certificados y las variables de entorno listas, puedes levantar todo el stack de servicios.

> **Nota**: Si has tenido ejecuciones anteriores, es recomendable limpiar los volúmenes de Docker para asegurar una inicialización limpia con la nueva configuración de SSL. Para ello, ejecuta `docker compose down -v` antes de continuar.

```bash
docker compose up -d --build
```

### 4. Verificar la Replicación

Después de que los contenedores se hayan iniciado (dale un minuto), puedes verificar que la replicación está funcionando correctamente. Ejecuta el siguiente comando:

```bash
docker compose exec db-slave mysql -u root -p${MYSQL_ROOT_PASSWORD:-root} -e "SHOW REPLICA STATUS\G"
```

En la salida, busca las siguientes líneas. Ambas deben indicar `Yes`:

```
Replica_IO_Running: Yes
Replica_SQL_Running: Yes
```

Si es así, la base de datos está operando en modo de alta disponibilidad con replicación segura.
---

## 🚀 Sistema de Configuración Dinámica

Este proyecto utiliza **contenedores Alpine Linux** para generar archivos de configuración dinámicamente desde templates, usando variables de entorno.

### Configuración Rápida

1. **Copia el archivo de ejemplo de variables:**
```bash
cp .env.example .env
```

2. **Edita las variables según tu entorno:**
```bash
nano .env  # O tu editor preferido
```

3. **Inicia el sistema (las configs se generan automáticamente):**
```bash
docker-compose up -d
```

### Gestión de Configuraciones

Usa el script de gestión para controlar las configuraciones:

```bash
# Ver estado de inicialización
./scripts/manage-configs.sh status

# Ver logs de generación de configs
./scripts/manage-configs.sh logs

# Regenerar configuraciones después de cambiar .env
./scripts/manage-configs.sh clean
docker-compose up -d
```

### Servicios con Configuración Dinámica

- **Prometheus** - Métricas y monitoreo
- **Redis** - Caché con autenticación
- **ProxySQL** - Routing de base de datos
- **Traefik** - API Gateway

📖 **Documentación completa:** [docs/CONFIG-INIT-SYSTEM.md](docs/CONFIG-INIT-SYSTEM.md)

---

## 📘 Conceptos Clave: Failover

### Failover
- Proceso de conmutación automática/manual a un servidor de respaldo cuando el servidor principal falla.
- Objetivo: Minimizar el tiempo de inactividad.
- Tipo: Puede ser **automático** (mediante orquestación) o **manual** (asistido por scripts).

### Failback
- Proceso inverso al failover: retorno del servicio al servidor principal una vez recuperado.
- Debe realizarse de forma ordenada y validada.
- Riesgo: Pérdida de datos si no se sincroniza correctamente.

### Check (Verificación)
- Validación continua del estado de los servicios.
- Detección de fallos.
- Confirmación de sincronización entre instancias primaria y secundaria.

---

## Arquitectura de Failover

```
┌─────────────────────────────────────────────────────────────┐
│                    Cliente (Frontend)                        │
└────────────────┬────────────────────────────────────────────┘
                 │
         ┌───────▼────────┐
         │  Traefik/LB    │
         │  (API Gateway) │
         └───────┬────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
┌───▼────┐  ┌───▼────┐  ┌───▼────┐
│ Primary│  │Secondary│  │Tertiary│
│ Server │  │ Server  │  │ Server │
└────────┘  └─────────┘  └────────┘
    │            │            │
    └────────────┼────────────┘
                 │
         ┌───────▼────────┐
         │  MySQL Cluster │
         │  (Replication) │
         └────────────────┘
```

---

## Scripts Disponibles: Failover

### 1. `check_health.sh` - Health Check Script

**Ubicación**: `scripts/failover/check_health.sh`

**Descripción**: Script para monitorear la salud general del sistema de replicación MySQL.

**Uso básico**:
```bash
chmod +x scripts/failover/check_health.sh
./scripts/failover/check_health.sh [--verbose] [--webhook <url>]
```

**Opciones**:
- `--verbose`: Salida detallada
- `--webhook`: URL para notificaciones en webhooks

**¿Qué verifica?**
- ✅ Estado de conectividad de los servicios principales
- ✅ Disponibilidad de la base de datos
- ✅ Estado del caché Redis
- ✅ Latencia de respuesta
- ✅ Replicación sincronizada

**Salida esperada**:
```
==========================================
HEALTH CHECK - Sistema de Causas Judiciales
==========================================

✅ Frontend: Healthy (127.0.0ms)
✅ Backend API: Healthy (45ms)
✅ MySQL Master: Healthy (2ms)
✅ MySQL Replica: Healthy (3ms)
✅ Redis: Healthy (1ms)

REPLICATION STATUS:
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Seconds_Behind_Master: 0

✅ SISTEMA OPERACIONAL - No se requiere acción
```

---

### 2. `do_failover.sh` - Ejecutar Failover

**Ubicación**: `scripts/failover/do_failover.sh`

**Descripción**: Script para promover manualmente el Replica como nuevo Master (ejecutar failover manual).

**Uso**:
```bash
chmod +x scripts/failover/do_failover.sh
./scripts/failover/do_failover.sh <primary_host> <secondary_host> [--force] [--no-verify]
```

**Opciones**:
- `--force`: Forzar failover sin confirmación
- `--no-verify`: Omitir verificaciones post-failover

**Ejemplo**:
```bash
./scripts/failover/do_failover.sh db-master db-slave --force
```

**Proceso que ejecuta**:
1. Validación de prerrequisitos
2. Sincronización de datos pendientes
3. Activación del servidor secundario
4. Actualización de la configuración de Traefik
5. Redirección de tráfico
6. Validación post-failover

**Salida esperada**:
```
==========================================
EJECUTANDO FAILOVER
==========================================

✓ Validando conexión a db-master... OFFLINE
✓ Validando conexión a db-slave... ONLINE
✓ Sincronizando datos pendientes...
✓ Deteniendo replicación en db-slave...
✓ Promoviendo db-slave como nuevo Master...
✓ Actualizando Traefik...
✓ Redirigiendo tráfico...

✅ FAILOVER COMPLETADO
   Nuevo Master: db-slave
   Replicación pausada hasta recuperación del primario
```

---

### 3. `check_failover_status.sh` - Verificar Estado

**Ubicación**: `scripts/failover/check_failover_status.sh`

**Descripción**: Script para verificar el estado actual del failover y replicación.

**Uso**:
```bash
chmod +x scripts/failover/check_failover_status.sh
./scripts/failover/check_failover_status.sh [--json]
```

**Opciones**:
- `--json`: Salida en formato JSON para integración

**Salida esperada (texto)**:
```
==========================================
ESTADO DEL FAILOVER
==========================================

MASTER ACTUAL: db-slave
REPLICA: db-master (OFFLINE - Esperando recuperación)

ESTADO DE REPLICACIÓN:
  IO Thread: Stopped (Esperando master)
  SQL Thread: Stopped

DATOS:
  Tablas sincronizadas: 25/25
  Últimas transacciones: 1500
  Lag de replicación: N/A

SERVICIOS:
  Frontend: OK
  Auth Service: OK
  Casos Service: OK
  Documentos Service: OK
```

**Salida esperada (JSON)**:
```json
{
  "status": "active_failover",
  "master": "db-slave",
  "replica": "db-master",
  "replica_status": "offline",
  "replication": {
    "io_thread": "stopped",
    "sql_thread": "stopped",
    "lag_seconds": null
  },
  "services": {
    "frontend": "healthy",
    "api": "healthy"
  }
}
```

---

## Procedimiento Completo: Failover y Failback

### Escenario: Master falla durante producción

#### Paso 1: Detección automática (automático)
```bash
failover-daemon detecta caída de db-master
→ Ejecuta do_failover.sh automáticamente
→ db-slave se promueve como nuevo Master
```

#### Paso 2: Verificar estado (manual)
```bash
./scripts/failover/check_failover_status.sh

# Confirmar que db-slave ahora es Master
# Todos los servicios deben estar operacionales
```

#### Paso 3: Reparar Master original (operacional)
```bash
# Ejemplo: reiniciar db-master
docker compose restart db-master

# Esperar a que esté listo
sleep 30

# Verificar que está disponible
./scripts/failover/check_health.sh --verbose
```

#### Paso 4: Ejecutar Failback (manual)
```bash
# Restaurar configuración original
./scripts/failback/do_failback.sh db-master db-slave

# El script:
# 1. Valida estado del db-master recuperado
# 2. Sincroniza datos desde db-slave
# 3. Reconecta db-master como Replica
# 4. Promueve db-master a Master
# 5. Actualiza Traefik
```

#### Paso 5: Verificar integridad (manual)
```bash
# Confirmar estado final
./scripts/failover/check_failover_status.sh

# Debe mostrar:
# MASTER ACTUAL: db-master
# REPLICA: db-slave (ONLINE)
# Replicación normal
```

---

## Monitoreo y Validación

### Puntos de Control Críticos

1. **Base de Datos**
   - ✅ Replicación sincronizada
   - ✅ Sin error de replicación
   - ✅ Consistencia de datos verificada

2. **Servicios Backend**
   - ✅ Todos los microservicios en estado "healthy"
   - ✅ Sin errores de conexión
   - ✅ Latencia dentro de límites

3. **Frontend**
   - ✅ Accesible desde navegador
   - ✅ Sesiones activas preservadas
   - ✅ Sin errores de consola

4. **Cache Redis**
   - ✅ Conectividad activa
   - ✅ TTL de keys preservado
   - ✅ Sin pérdida de sesiones

### Métricas Monitoreadas

```
Sistema de Alertas:
├── CPU > 80% → Investigar
├── Memoria > 85% → Investigar
├── Latencia DB > 200ms → Crítico
├── Replicación lag > 5s → Crítico
├── Conexiones rechazadas → Crítico
└── Errores 5xx > 1% → Crítico
```

### Ver eventos en Grafana

```bash
# 1. Acceder a Grafana
http://localhost:3000

# 2. Ir a Dashboard → "Base de Datos - Replicación"

# 3. Buscar estos eventos:
   - mysql_slave_status_seconds_behind_master
   - mysql_slave_status_slave_io_running
   - mysql_global_status_read_only
   - proxysql_mysql_monitor_connect_errors
```

---

## Troubleshooting: Failover

### Problema: Failover Lento

**Síntomas**:
- Tiempo de conmutación > 5 minutos
- Usuarios reportan desconexiones prolongadas

**Causas Posibles**:
1. Sincronización de datos incompleta
2. Cierre gradual de conexiones lento

**Solución**:
```bash
# Aumentar agresividad de sincronización
export FAILOVER_TIMEOUT=300

# Forzar cierre de conexiones antiguas
docker compose exec db-proxy mysql -e "KILL QUERY ALL"

# Ejecutar failover nuevamente
./scripts/failover/do_failover.sh db-master db-slave --force
```

### Problema: Pérdida de Datos

**Síntomas**:
- Transacciones no registradas
- Inconsistencia entre servidores

**Causas Posibles**:
1. Replicación no sincronizada
2. Transacciones en curso durante failover

**Solución**:
```bash
# Validar integridad
./scripts/failover/check_health.sh --verbose

# Esperar sincronización completa
while [ $(./scripts/failover/check_failover_status.sh --json | grep "lag_seconds" | grep -v null) ]; do
  sleep 5
done

# Luego ejecutar failover
./scripts/failover/do_failover.sh db-master db-slave
```

### Problema: Failback Fallido

**Síntomas**:
- Script retorna error
- Servidor primario no activa

**Causas Posibles**:
1. Servidor primario aún no recuperado
2. Problemas de sincronización

**Solución**:
```bash
# Verificar estado del primario
./scripts/failover/check_health.sh

# Si hay errores, esperar más
sleep 60 && ./scripts/failover/check_health.sh

# Luego ejecutar failback
./scripts/failback/do_failback.sh db-master db-slave

# Si persiste, contactar soporte y revisar logs:
docker compose logs failover-daemon | tail -50
```

### Problema: ProxySQL no reconoce cambios

**Síntomas**:
- Las aplicaciones siguen apuntando al antiguo master
- Tráfico no se redirige

**Solución**:
```bash
# Reiniciar ProxySQL
docker compose restart db-proxy

# Esperar a que reconecte
sleep 10

# Verificar status
./scripts/failover/check_failover_status.sh
```

---

## Checklist de Failover

### ✅ Antes de Failover
- [ ] Notificar al equipo y usuarios
- [ ] Crear ticket de incidente
- [ ] Ejecutar `./scripts/failover/check_health.sh`
- [ ] Verificar backups recientes
- [ ] Confirmar servidor secundario está listo

### ⚙️ Durante Failover
- [ ] Ejecutar `./scripts/failover/do_failover.sh`
- [ ] Monitorear logs en tiempo real: `docker compose logs -f failover-daemon`
- [ ] Verificar alertas en Grafana
- [ ] Validar estado post-failover: `./scripts/failover/check_failover_status.sh`

### ✅ Después de Failover
- [ ] Confirmar servicios operativos
- [ ] Probar funcionalidades críticas
- [ ] Notificar al usuario
- [ ] Documentar incidente

---

## Checklist de Failback

### ✅ Antes de Failback
- [ ] Servidores primario completamente recuperado
- [ ] Ejecutar `./scripts/failover/check_health.sh`
- [ ] Datos sincronizados al 100%
- [ ] Ventana de mantenimiento confirmada
- [ ] Equipo de soporte disponible
- [ ] Backups actuales realizados

### ⚙️ Durante Failback
- [ ] Ejecutar `./scripts/failback/do_failback.sh`
- [ ] Monitorear durante transición: `docker compose logs -f failover-daemon`
- [ ] Estar listo para rollback: `./scripts/failover/do_failover.sh` (revertir)

### ✅ Después de Failback
- [ ] Verificar servicios normalizados: `./scripts/failover/check_failover_status.sh`
- [ ] Probar todas las funcionalidades
- [ ] Validar replicación secundaria está activa
- [ ] Documentar resultados
- [ ] Revisar logs para anomalías: `docker compose logs failover-daemon | grep -i error`

---

## Flujo Rápido de Referencia

```bash
# 1. DETECTAR PROBLEMA
./scripts/check-replication-status.sh

# 2. SI MASTER ESTÁ DOWN, EJECUTAR FAILOVER
sudo ./scripts/failover-promote-slave.sh -y

# 3. VERIFICAR ESTADO
./scripts/check-replication-status.sh

# 4. CUANDO MASTER SE RECUPERA, EJECUTAR FAILBACK
sudo ./scripts/failback-restore-master.sh -y

# 5. VERIFICAR VUELTA A NORMAL
./scripts/check-replication-status.sh
```

---

## 🎯 Scripts Principales (Producción)

### 1. `check-replication-status.sh` - Verificar Estado

**Ubicación**: `scripts/check-replication-status.sh`

**Descripción**: Verifica la salud general del sistema de replicación MySQL y ProxySQL.

**Uso**:
```bash
./scripts/check-replication-status.sh
```

**¿Qué verifica?**
- ✅ Estado de ProxySQL (hostgroups, servidor)
- ✅ Pool de conexiones
- ✅ Estado del Master (hostname, server_id, read_only)
- ✅ Estado de replicación del Slave
- ✅ GTID sincronizados

**Salida esperada (sistema saludable)**:
```
==========================================
Database Replication Health Check
==========================================

=== ProxySQL Server Status ===
hostgroup_id | hostname  | port | status | weight | max_connections
10           | db-master | 3306 | ONLINE | 1      | 100
20           | db-master | 3306 | ONLINE | 1      | 100
20           | db-slave  | 3306 | ONLINE | 1      | 100

=== DB Master Status ===
hostname | server_id | read_only | super_read_only
db-master| 1        | 0         | 0

=== DB Slave Replication Status ===
SERVICE_STATE: ON
LAST_ERROR_MESSAGE: (vacío)

=== GTID Status ===
Master GTID: a1b2c3d4:1-1000
Slave GTID:  a1b2c3d4:1-1000
```

---

### 2. `failover-promote-slave.sh` - Ejecutar Failover

**Ubicación**: `scripts/failover-promote-slave.sh`

**Descripción**: Promueve el Slave como nuevo Master automáticamente.

**Uso**:
```bash
# Con confirmación interactiva
sudo ./scripts/failover-promote-slave.sh

# Sin confirmación (modo automático)
sudo ./scripts/failover-promote-slave.sh -y
```

**Opciones**:
- `-y`: Ejecutar sin confirmación interactiva

**Variables de entorno (.env)**:
```bash
OLD_MASTER=db-master
NEW_MASTER=db-slave
PROXYSQL_CONTAINER=db-proxy
PROXYSQL_ADMIN_USER=admin
PROXYSQL_ADMIN_PASSWORD=admin
MYSQL_ROOT_PASSWORD=tu_contraseña
MYSQL_REPLICATION_USER=replicator
MYSQL_REPLICATION_PASSWORD=tu_contraseña
```

**Proceso que ejecuta**:
1. Bloquea escrituras en el master antiguo
2. Detiene replicación en el slave
3. Promueve slave como nuevo master
4. Actualiza ProxySQL (hostgroup 10 y 20)
5. Verifica funcionamiento

**Ejemplo de ejecución**:
```bash
$ sudo ./scripts/failover-promote-slave.sh -y

==========================================
ProxySQL Failover: Promote Slave to Master
==========================================

Verificando estado actual de ProxySQL...
hostgroup_id | hostname  | status
10           | db-master | ONLINE
20           | db-slave  | ONLINE

Modo automático: procediendo sin confirmación

Paso 1: Deteniendo escrituras en antiguo master (db-master)...
Paso 2: Desactivando replicación en db-slave y habilitando writes...
Paso 3: Reconfigurando ProxySQL...

✅ Failover completado:
   - Nuevo Master: db-slave (hostgroups 10 y 20)
   - Antiguo Master: db-master (OFFLINE en ambos hostgroups)

⚠️  Próximos pasos:
   1. Verificar conectividad de aplicaciones
   2. Monitorear logs: docker logs -f db-proxy
   3. Planificar failback cuando el antiguo master esté disponible
```

---

### 3. `failback-restore-master.sh` - Ejecutar Failback

**Ubicación**: `scripts/failback-restore-master.sh`

**Descripción**: Restaura el master original y revierte la configuración.

**Uso**:
```bash
# Con confirmación interactiva en cada paso
sudo ./scripts/failback-restore-master.sh

# Sin confirmación (modo automático)
sudo ./scripts/failback-restore-master.sh -y
```

**Opciones**:
- `-y`: Ejecutar sin confirmación interactiva

**Variables de entorno (.env)**:
```bash
ORIGINAL_MASTER=db-master
CURRENT_MASTER=db-slave
PROXYSQL_CONTAINER=db-proxy
PROXYSQL_ADMIN_USER=admin
PROXYSQL_ADMIN_PASSWORD=admin
MYSQL_ROOT_PASSWORD=tu_contraseña
MYSQL_REPLICATION_USER=replicator
MYSQL_REPLICATION_PASSWORD=tu_contraseña
```

**Proceso que ejecuta**:
1. Configura master original como replica del actual
2. Espera sincronización completa (2+ confirmaciones GTID)
3. Bloquea escrituras en master actual
4. Promueve master original nuevamente
5. Configura master actual como replica
6. Actualiza ProxySQL

**Ejemplo de ejecución**:
```bash
$ sudo ./scripts/failback-restore-master.sh -y

==========================================
ProxySQL Failback: Restore Original Master
==========================================

Verificando estado actual de ProxySQL...
hostgroup_id | hostname  | status
20           | db-slave  | ONLINE

Modo automático: procediendo sin confirmación

Paso 1: Reconfigurando db-master como slave...
✅ Replicación activa

Paso 2: Verificando replicación...
✅ Replicación activa

Paso 3: Esperando sincronización completa...
✅ Sincronización confirmada (1/2)
✅ Sincronización confirmada (2/2)
✅ db-master está completamente sincronizado con GTIDs idénticos

[Pasos 4-7: Sincronización y promoción...]

Paso 8: Reconfigurando ProxySQL...

✅ Failback completado:
   - Master restaurado: db-master (hostgroup 10)
   - Slave: db-slave (hostgroup 20)

⚠️  Verificar:
   1. Conectividad de aplicaciones
   2. Replicación: docker exec db-slave mysql -u root -p -e "SHOW REPLICA STATUS\G"
   3. Logs ProxySQL: docker logs -f db-proxy
```

---

## ⚠️ Diferencias de Scripts

| Script | Ubicación | Cuando usarlo | Requiere |
|--------|-----------|---------------|----------|
| **check-replication-status.sh** | `scripts/` | Verificar estado | Lectura |
| **failover-promote-slave.sh** | `scripts/` | Master está DOWN | sudo |
| **failback-restore-master.sh** | `scripts/` | Master recuperado | sudo |
| check_health.sh | `scripts/failover/` | Health check completo | Lectura |
| do_failover.sh | `scripts/failover/` | Failover manual avanzado | sudo |
| prepare_failback.sh | `scripts/failback/` | Pre-validación failback | Lectura |
| do_failback.sh | `scripts/failback/` | Failback avanzado | sudo |
| verify_failback.sh | `scripts/failback/` | Post-validación | Lectura |

---

## 🚨 Casos de Uso Prácticos

### Caso 1: Master Falla Inesperadamente

```bash
# 1. Verificar qué pasó
./scripts/check-replication-status.sh

# 2. Ver que db-master está DOWN
# ❌ db-master no está corriendo

# 3. Ejecutar failover inmediatamente
sudo ./scripts/failover-promote-slave.sh -y

# 4. Verificar que sistema está UP con nuevo master
./scripts/check-replication-status.sh
# Debe mostrar: db-slave en hostgroup 10 (ONLINE)

# 5. Notificar al equipo
# "Master falla. Failover a db-slave completado. Sistema UP."
```

### Caso 2: Master Se Recupera, Hacer Failback

```bash
# 1. Verificar estado actual
./scripts/check-replication-status.sh
# Muestra: db-slave es master actual

# 2. Confirmar que master original está listo
docker compose ps db-master
# CONTAINER ID | STATUS: Up X seconds

# 3. Ejecutar failback
sudo ./scripts/failback-restore-master.sh -y

# 4. Verificar restauración
./scripts/check-replication-status.sh
# Debe mostrar: db-master en hostgroup 10 (ONLINE)

# 5. Confirmar con aplicaciones
curl http://localhost/api/casos
# Debe responder OK
```

### Caso 3: Verificación Regular (Health Check)

```bash
# Ejecutar cada 4 horas o según SLA
0 */4 * * * cd /path/to/proyecto && ./scripts/check-replication-status.sh | tee -a /var/log/replication-check.log

# Si hay problemas:
# - Enviar alerta a equipo
# - Revisar logs: docker compose logs failover-daemon
# - Contactar DevOps
```

---


## Tests y CI

### Backend (pytest)

Los tests unitarios viven en `backend/tests/` y no necesitan MySQL ni Docker:
usan SQLite en memoria en lugar de `db_manager` y simulan SMTP, Docker y las
llamadas HTTP entre servicios.

```bash
cd backend
python3.11 -m venv .venv && . .venv/bin/activate
pip install -r requirements-test.txt
python -m pytest
```

### Frontend (Jest / React Testing Library)

```bash
cd frontend
npm ci
CI=true npm test -- --watchAll=false
```

### GitHub Actions

`.github/workflows/ci.yml` se ejecuta en cada push y pull request:

- **Backend**: pytest con Python 3.11.
- **Frontend**: tests y `npm run build` con Node 20.
- **Imágenes Docker**: `docker build` (sin push) de cada servicio de la aplicación.

No hay workflow de despliegue: el despliegue se hace a mano con `docker compose`
(ver `start.sh`).
