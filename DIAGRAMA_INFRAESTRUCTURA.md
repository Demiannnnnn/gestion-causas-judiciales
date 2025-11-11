# 🏗️ Diagrama de Infraestructura - Sistema de Gestión de Causas Judiciales

**Proyecto:** Sistema de Gestión de Causas Judiciales  
**Fecha:** 11 de Noviembre de 2025  
**Versión:** 1.0

---

## 📐 Arquitectura General del Sistema

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   INTERNET                                       │
│                                      ↓                                           │
│                           Puerto 80 (HTTP) / 443 (HTTPS)                        │
└──────────────────────────────────────┬──────────────────────────────────────────┘
                                       ↓
┌──────────────────────────────────────────────────────────────────────────────────┐
│                          🌐 FRONTEND-NETWORK (172.20.0.0/24)                      │
│                                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                        TRAEFIK GATEWAY (Load Balancer)                   │   │
│  │  - Routing automático                                                     │   │
│  │  - Health checks                                                          │   │
│  │  - Dashboard: :8080                                                       │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                      ↓                                           │
│  ┌──────────────────────────┐     ┌──────────────────────────┐                 │
│  │   FRONTEND-1 (React)     │     │   FRONTEND-2 (React)     │                 │
│  │   Puerto: 3000           │     │   Puerto: 3000           │                 │
│  │   Status: ✅ Running     │     │   Status: ✅ Running     │                 │
│  └──────────────────────────┘     └──────────────────────────┘                 │
└──────────────────────────────────────────────────────────────────────────────────┘
                                       ↓
┌──────────────────────────────────────────────────────────────────────────────────┐
│                         🔧 BACKEND-NETWORK (172.21.0.0/24)                        │
│                                                                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                 │
│  │ AUTENTICACION   │  │    CASOS-1      │  │    CASOS-2      │                 │
│  │ Puerto: 8000    │  │ Puerto: 5001    │  │ Puerto: 5001    │                 │
│  │ JWT, Login      │  │ CRUD Causas     │  │ CRUD Causas     │                 │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                 │
│                                                                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                 │
│  │  DOCUMENTOS     │  │ NOTIFICACIONES  │  │   REPORTES      │                 │
│  │  Puerto: 8002   │  │  Puerto: 8003   │  │  Puerto: 8004   │                 │
│  │  Upload/Files   │  │  Alertas        │  │  PDFs/Excel     │                 │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                 │
│                                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐                │
│  │                    IA-SEGURIDAD                              │                │
│  │  Puerto: 8005                                                │                │
│  │  • Análisis de logs con Gemini AI                           │                │
│  │  • Detección de anomalías                                   │                │
│  │  • Sistema de alertas inteligente                           │                │
│  └─────────────────────────────────────────────────────────────┘                │
│                                                                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                 │
│  │  DB-PROXY       │  │     CRON        │  │    MAILHOG      │                 │
│  │  (ProxySQL)     │  │  Tareas Auto    │  │  Test Email     │                 │
│  │  Puerto: 6033   │  │  Backup: 01:00  │  │  Puerto: 8025   │                 │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                 │
└──────────────────────────────────────────────────────────────────────────────────┘
            ↓                           ↓                           ↓
┌──────────────────────────────────────────────────────────────────────────────────┐
│                       💾 DATABASE-NETWORK (172.22.0.0/24)                         │
│                                                                                   │
│  ┌────────────────────────────────────────────────────────────────────────┐     │
│  │                         MYSQL REPLICATION                               │     │
│  │                                                                          │     │
│  │  ┌──────────────────────┐         GTID         ┌──────────────────────┐│     │
│  │  │   DB-MASTER          │ ═══════════════════> │    DB-SLAVE          ││     │
│  │  │   MySQL 8.4.7        │   Auto-Position     │    MySQL 8.4.7       ││     │
│  │  │   server_id: 1       │   Replication       │    server_id: 2      ││     │
│  │  │   Puerto: 3306       │   IO: ✅ Yes         │    Puerto: 3306      ││     │
│  │  │   Puerto ext: 3307   │   SQL: ✅ Yes        │    Puerto ext: 3308  ││     │
│  │  │   Status: ✅ Healthy │                     │    Status: ✅ Healthy ││     │
│  │  └──────────────────────┘                     └──────────────────────┘│     │
│  │                 ↓                                        ↓             │     │
│  │                 └────────────────┬───────────────────────┘             │     │
│  │                                  ↓                                     │     │
│  │                    ┌──────────────────────────┐                        │     │
│  │                    │  PROXYSQL (Load Balancer)│                        │     │
│  │                    │  Puerto: 6033            │                        │     │
│  │                    │  Admin: 6032             │                        │     │
│  │                    │                          │                        │     │
│  │                    │  Hostgroup 10 → Master   │                        │     │
│  │                    │  Hostgroup 20 → Slave    │                        │     │
│  │                    │                          │                        │     │
│  │                    │  Rules:                  │                        │     │
│  │                    │  SELECT FOR UPDATE → 10  │                        │     │
│  │                    │  SELECT → 20             │                        │     │
│  │                    └──────────────────────────┘                        │     │
│  └────────────────────────────────────────────────────────────────────────┘     │
│                                                                                   │
│  ┌─────────────────┐  ┌─────────────────┐                                       │
│  │ BACKUP-SERVICE  │  │ FAILOVER-DAEMON │                                       │
│  │ Backups Auto    │  │ Check: 30s      │                                       │
│  │ Retention: 7d   │  │ Threshold: 3    │                                       │
│  └─────────────────┘  └─────────────────┘                                       │
└──────────────────────────────────────────────────────────────────────────────────┘
                                       ↓
┌──────────────────────────────────────────────────────────────────────────────────┐
│                        🗃️  CACHE-NETWORK (172.23.0.0/24)                         │
│                                                                                   │
│  ┌───────────────────────────────────────────────────────────────────────┐      │
│  │                         REDIS REPLICATION                              │      │
│  │                                                                         │      │
│  │  ┌──────────────────────┐                   ┌──────────────────────┐  │      │
│  │  │   REDIS MASTER       │ ═════════════════>│   REDIS REPLICA      │  │      │
│  │  │   Redis 7.4.7        │   Master-Slave    │   Redis 7.4.7        │  │      │
│  │  │   role: master       │   Replication     │   role: slave        │  │      │
│  │  │   Puerto: 6379       │                   │   Puerto: 6380       │  │      │
│  │  │   Slaves: 1          │   Link: ✅ UP      │   Master: redis      │  │      │
│  │  │   Auth: ✅ ***REMOVED***│                   │   Auth: ✅ ***REMOVED***│  │      │
│  │  └──────────────────────┘                   └──────────────────────┘  │      │
│  └───────────────────────────────────────────────────────────────────────┘      │
│                                                                                   │
│  Servicios conectados: autenticacion, casos-1, casos-2, notificaciones          │
└──────────────────────────────────────────────────────────────────────────────────┘
                                       ↓
┌──────────────────────────────────────────────────────────────────────────────────┐
│                      📊 MONITORING-NETWORK (172.24.0.0/24)                        │
│                                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                      STACK DE MONITOREO                                  │    │
│  │                                                                           │    │
│  │  ┌──────────────────────┐                   ┌──────────────────────┐    │    │
│  │  │   PROMETHEUS         │ ───────scrape────>│     GRAFANA          │    │    │
│  │  │   Puerto: 9090       │                   │     v12.2.1          │    │    │
│  │  │   Interval: 15s      │                   │     Puerto: 3000     │    │    │
│  │  │                      │                   │     DB: ✅ OK        │    │    │
│  │  │   Targets:           │                   │                      │    │    │
│  │  │   • MySQL Exporter   │                   │   Dashboards:        │    │    │
│  │  │   • Redis Exporter   │                   │   • Sistema          │    │    │
│  │  │   • Node Exporter    │                   │   • MySQL            │    │    │
│  │  │   • Backend Services │                   │   • Redis            │    │    │
│  │  └──────────────────────┘                   └──────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│                                                                                   │
│  Servicios conectados: ia-seguridad, backup-service, failover-daemon            │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de Alta Disponibilidad

### Escenario 1: Operación Normal

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ESTADO NORMAL                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  USUARIO → TRAEFIK → FRONTEND-1 ✅                                      │
│                   └→ FRONTEND-2 ✅  (Load Balancing Round Robin)       │
│                                                                          │
│  FRONTEND → TRAEFIK → CASOS-1 ✅                                        │
│                   └→ CASOS-2 ✅  (Load Balancing)                       │
│                                                                          │
│  BACKEND → PROXYSQL → SELECT queries → DB-SLAVE ✅                      │
│                   └→ INSERT/UPDATE → DB-MASTER ✅                       │
│                                                                          │
│  BACKEND → REDIS-MASTER ✅ ─────replica────> REDIS-REPLICA ✅           │
│                                                                          │
│  FAILOVER-DAEMON: Master health: ✅ OK  (check cada 30s)                │
└─────────────────────────────────────────────────────────────────────────┘
```

### Escenario 2: Fallo de Réplica Frontend

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    FALLO: FRONTEND-2 CAÍDO                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  USUARIO → TRAEFIK → FRONTEND-1 ✅  (Todo el tráfico)                  │
│                   └→ FRONTEND-2 ❌  (Traefik detecta y excluye)        │
│                                                                          │
│  Health Check: FRONTEND-1 responde → Sistema operacional ✅             │
│                                                                          │
│  ACCIÓN: Traefik redirige automáticamente todo a FRONTEND-1             │
│  RESULTADO: ✅ Servicio continúa sin interrupción                       │
└─────────────────────────────────────────────────────────────────────────┘
```

### Escenario 3: Fallo de MySQL Master

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    FALLO: DB-MASTER CAÍDO                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. FAILOVER-DAEMON detecta fallo (3 checks consecutivos fallidos)     │
│     ↓                                                                    │
│  2. Promueve DB-SLAVE a MASTER                                          │
│     ↓                                                                    │
│  3. Reconfigura ProxySQL:                                               │
│     - Hostgroup 10 (WRITE) → DB-SLAVE (ahora master)                   │
│     - Hostgroup 20 (READ) → DB-SLAVE                                   │
│     ↓                                                                    │
│  4. Notifica a servicios                                                │
│     ↓                                                                    │
│  5. Sistema continúa operando desde nuevo master ✅                     │
│                                                                          │
│  TIEMPO DE FAILOVER: ~90 segundos (3 checks × 30s)                     │
└─────────────────────────────────────────────────────────────────────────┘
```

### Escenario 4: Recuperación Master (Failback)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                DB-MASTER SE RECUPERA (FAILBACK)                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. FAILOVER-DAEMON detecta que DB-MASTER está disponible              │
│     ↓                                                                    │
│  2. Verifica integridad de datos                                        │
│     ↓                                                                    │
│  3. Configura DB-MASTER como SLAVE del actual master                   │
│     ↓                                                                    │
│  4. Sincroniza datos via GTID                                           │
│     ↓                                                                    │
│  5. Cuando está sincronizado, restablece roles:                         │
│     - DB-MASTER vuelve a ser MASTER                                     │
│     - DB-SLAVE vuelve a ser SLAVE                                       │
│     ↓                                                                    │
│  6. Reconfigura ProxySQL a estado original                              │
│     ↓                                                                    │
│  7. Sistema vuelve a arquitectura normal ✅                             │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Segmentación de Redes - Vista Detallada

```
┌──────────────────────────────────────────────────────────────────────────┐
│                    FRONTEND-NETWORK (172.20.0.0/24)                       │
├──────────────────────────────────────────────────────────────────────────┤
│  • gateway              ← Único punto de entrada/salida                  │
│  • frontend-1           ← Sirve aplicación React                         │
│  • frontend-2           ← Réplica para HA                                │
│                                                                           │
│  PROPÓSITO: Capa de presentación aislada                                │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                    BACKEND-NETWORK (172.21.0.0/24)                        │
├──────────────────────────────────────────────────────────────────────────┤
│  • gateway              ← Router entre frontend y backend                │
│  • autenticacion        ← API de auth                                    │
│  • casos-1, casos-2     ← Microservicio principal (2 réplicas)          │
│  • documentos           ← Gestión de archivos                            │
│  • notificaciones       ← Sistema de alertas                             │
│  • reportes             ← Generación de reportes                         │
│  • ia-seguridad         ← Análisis inteligente                           │
│  • mailhog              ← Testing de emails                              │
│  • cron                 ← Tareas programadas                             │
│  • db-proxy             ← Acceso a bases de datos                        │
│                                                                           │
│  PROPÓSITO: Lógica de negocio aislada                                   │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                   DATABASE-NETWORK (172.22.0.0/24)                        │
├──────────────────────────────────────────────────────────────────────────┤
│  • db-master            ← MySQL principal                                │
│  • db-slave             ← Réplica de lectura                             │
│  • db-proxy             ← ProxySQL load balancer                         │
│  • autenticacion        ← Servicios con acceso a DB                      │
│  • casos-1, casos-2     ← Servicios con acceso a DB                      │
│  • documentos           ← Servicios con acceso a DB                      │
│  • notificaciones       ← Servicios con acceso a DB                      │
│  • reportes             ← Servicios con acceso a DB                      │
│  • backup-service       ← Backups de DB                                  │
│  • failover-daemon      ← Monitoreo y failover                           │
│                                                                           │
│  PROPÓSITO: Capa de persistencia protegida                              │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                    CACHE-NETWORK (172.23.0.0/24)                          │
├──────────────────────────────────────────────────────────────────────────┤
│  • redis                ← Cache principal                                │
│  • redis-replica        ← Réplica de cache                               │
│  • autenticacion        ← Sesiones de usuario                            │
│  • casos-1, casos-2     ← Cache de consultas                             │
│  • notificaciones       ← Queue de notificaciones                        │
│                                                                           │
│  PROPÓSITO: Cache distribuido para performance                          │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                  MONITORING-NETWORK (172.24.0.0/24)                       │
├──────────────────────────────────────────────────────────────────────────┤
│  • prometheus           ← Recolección de métricas                        │
│  • grafana              ← Visualización                                  │
│  • ia-seguridad         ← Analiza métricas con IA                        │
│  • backup-service       ← Métricas de backups                            │
│  • failover-daemon      ← Métricas de HA                                 │
│                                                                           │
│  PROPÓSITO: Observabilidad del sistema                                  │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 💾 Persistencia de Datos - Volúmenes

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          VOLÚMENES DOCKER                                   │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  BASES DE DATOS:                                                           │
│  ├─ mysql-master-data         → /var/lib/mysql (db-master)                │
│  ├─ mysql-slave-data          → /var/lib/mysql (db-slave)                 │
│  ├─ redis-data                → /data (redis)                              │
│  └─ proxysql-data             → /var/lib/proxysql                          │
│                                                                             │
│  CONFIGURACIONES:                                                          │
│  ├─ traefik-config            → /etc/traefik                               │
│  ├─ prometheus-config         → /etc/prometheus                            │
│  ├─ proxysql-config           → /etc/proxysql                              │
│  ├─ redis-config              → /etc/redis                                 │
│  ├─ db-master-init-scripts    → /docker-entrypoint-initdb.d               │
│  └─ db-slave-init-scripts     → /docker-entrypoint-initdb.d               │
│                                                                             │
│  DATOS DE APLICACIÓN:                                                      │
│  ├─ documentos-uploads        → /app/uploads (documentos)                 │
│  ├─ grafana-data              → /var/lib/grafana                           │
│  ├─ prometheus-data           → /prometheus                                │
│  └─ frontend-node-modules     → /app/node_modules                          │
│                                                                             │
│  BACKUPS (Host mount):                                                     │
│  └─ ./backups                 → /backups (backup-service)                 │
│                                                                             │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de Datos - Operaciones CRUD

### Crear Caso (POST /api/casos)

```
Usuario                                                          
   │                                                             
   │ 1. POST /api/casos                                         
   ↓                                                             
┌────────┐                                                       
│ TRAEFIK│──┐                                                   
└────────┘  │                                                   
            │ 2. Route to backend                               
            ↓                                                   
      ┌─────────┐                                               
      │ CASOS-1 │  ← Load balancing                            
      └─────────┘                                               
      ┌─────────┐                                               
      │ CASOS-2 │  ← Alternate                                 
      └─────────┘                                               
            │                                                   
            │ 3. Verify JWT                                     
            ↓                                                   
    ┌──────────────┐                                            
    │ AUTENTICACION│                                            
    └──────────────┘                                            
            │                                                   
            │ 4. Token válido ✅                                
            ↓                                                   
      ┌─────────┐                                               
      │ PROXYSQL│                                               
      └─────────┘                                               
            │                                                   
            │ 5. INSERT → Hostgroup 10 (WRITE)                 
            ↓                                                   
      ┌──────────┐         GTID          ┌──────────┐         
      │DB-MASTER │ ═════════════════════>│ DB-SLAVE │         
      └──────────┘    Auto-Replicate     └──────────┘         
            │                                                   
            │ 6. Registro creado                                
            ↓                                                   
      ┌─────────┐                                               
      │ REDIS   │ ← Cache invalidado                           
      └─────────┘                                               
            │                                                   
            │ 7. Response JSON                                  
            ↓                                                   
        Usuario ✅                                              
```

### Consultar Casos (GET /api/casos)

```
Usuario                                                          
   │                                                             
   │ 1. GET /api/casos                                          
   ↓                                                             
┌────────┐                                                       
│ TRAEFIK│                                                       
└────────┘                                                       
   │                                                             
   │ 2. Route to backend                                        
   ↓                                                             
┌─────────┐                                                      
│ CASOS-1 │                                                      
└─────────┘                                                      
   │                                                             
   │ 3. Check cache                                             
   ↓                                                             
┌─────────┐                                                      
│ REDIS   │ ← Cache hit? ✅ Return                              
└─────────┘                                                      
   │                                                             
   │ Cache miss → Query DB                                      
   ↓                                                             
┌─────────┐                                                      
│ PROXYSQL│                                                      
└─────────┘                                                      
   │                                                             
   │ 4. SELECT → Hostgroup 20 (READ)                           
   ↓                                                             
┌──────────┐                                                     
│ DB-SLAVE │ ← Consulta réplica (reduce carga master)          
└──────────┘                                                     
   │                                                             
   │ 5. Resultados                                              
   ↓                                                             
┌─────────┐                                                      
│ REDIS   │ ← Store in cache                                   
└─────────┘                                                      
   │                                                             
   │ 6. Response JSON                                           
   ↓                                                             
Usuario ✅                                                       
```

---

## 🤖 Flujo de IA - Análisis de Logs

```
┌──────────────────────────────────────────────────────────────────────┐
│                   SISTEMA DE ANÁLISIS CON IA                          │
└──────────────────────────────────────────────────────────────────────┘

1. RECOLECCIÓN DE LOGS
   ↓
┌──────────────┐
│ Contenedores │ ──→ Docker API ──→ ┌────────────────┐
│ - db-master  │                     │                │
│ - casos-1    │                     │  IA-SEGURIDAD  │
│ - frontend   │                     │                │
│ - etc...     │                     └────────────────┘
└──────────────┘                              │
                                              │
2. ANÁLISIS INTELIGENTE                       │
   ↓                                          ↓
┌─────────────────────────────────────────────────────┐
│              GEMINI 2.0-FLASH-LITE                   │
│                                                      │
│  • Detecta errores y warnings                       │
│  • Identifica problemas de seguridad                │
│  • Analiza patrones anómalos                        │
│  • Genera diagnósticos                              │
│  • Sugiere soluciones                               │
└─────────────────────────────────────────────────────┘
                     │
3. DETECCIÓN DE ANOMALÍAS  │
   ↓                       │
┌──────────────────────────┴───────────────────────────┐
│  Health Monitor                                       │
│  • Container down (crítico)                          │
│  • Alto uso CPU (> 80%)                              │
│  • Alto uso memoria (> 85%)                          │
│  • Errores recurrentes                               │
└──────────────────────────────────────────────────────┘
                     │
4. SISTEMA DE ALERTAS      │
   ↓                       │
┌──────────────────────────┴───────────────────────────┐
│  Almacenamiento en BD                                │
│  Severidad: info | warning | error | critical        │
│  Timestamp, container, tipo, mensaje                 │
└──────────────────────────────────────────────────────┘
                     │
5. NOTIFICACIÓN            │
   ↓                       │
┌──────────────────────────┴───────────────────────────┐
│  • Dashboard web (consulta via API)                  │
│  • Prometheus metrics                                │
│  • Grafana alerts                                    │
└──────────────────────────────────────────────────────┘
```

---

## 📊 Monitoreo - Flujo de Métricas

```
┌────────────────────────────────────────────────────────────────────┐
│                      STACK DE OBSERVABILIDAD                        │
└────────────────────────────────────────────────────────────────────┘

EXPORTERS                  PROMETHEUS              GRAFANA
    │                          │                      │
    │                          │                      │
┌──────────┐                  │                      │
│ MySQL    │──metrics──────┐  │                      │
│ Exporter │               │  │                      │
└──────────┘               │  │                      │
                           ↓  ↓                      │
┌──────────┐          ┌──────────────┐              │
│  Redis   │─metrics─>│  PROMETHEUS  │──query────┐  │
│ Exporter │          │              │           │  │
└──────────┘          │  Scrape: 15s │           ↓  ↓
                      │  Retention:  │     ┌────────────┐
┌──────────┐          │    15 days   │     │  GRAFANA   │
│   Node   │─metrics─>│              │────>│            │
│ Exporter │          └──────────────┘     │ Dashboards:│
└──────────┘                 ↑             │ • Sistema  │
                             │             │ • MySQL    │
Backend Services             │             │ • Redis    │
┌──────────┐                 │             │ • Docker   │
│  casos   │──/metrics───────┤             └────────────┘
│  auth    │                 │                    │
│  docs    │                 │                    │
└──────────┘                 │                    ↓
                             │              Admin visualiza
IA-Seguridad                 │              métricas en
┌──────────┐                 │              tiempo real
│   IA     │──stats──────────┘              
│ Security │  
└──────────┘
```

---

## 🔄 Sistema de Backups - Flujo Completo

```
┌──────────────────────────────────────────────────────────────────────┐
│                      SISTEMA DE BACKUPS                               │
└──────────────────────────────────────────────────────────────────────┘

CRON SERVICE (01:00 AM diario)
    │
    │ Trigger
    ↓
┌─────────────────────┐
│  BACKUP-SERVICE     │
└─────────────────────┘
    │
    ├─────────────────┬─────────────────┐
    │                 │                 │
    ↓                 ↓                 ↓
┌─────────┐   ┌──────────────┐  ┌──────────────┐
│ DB      │   │  ARCHIVOS    │  │ CONFIGURACIÓN│
│ BACKUP  │   │  BACKUP      │  │  BACKUP      │
└─────────┘   └──────────────┘  └──────────────┘
    │                 │                 │
    │                 │                 │
    ├── mysqldump    ├── tar           ├── copy configs
    │   db-master    │   /uploads      │   /etc/*
    │   via proxy    │   /data         │
    │                 │                 │
    ↓                 ↓                 ↓
┌───────────────────────────────────────────────┐
│  /backups/database/                           │
│    db_gestion_causas_2025-11-11_01-00-00.sql │
│                                               │
│  /backups/files/                              │
│    files_2025-11-11_01-00-00.tar.gz          │
│                                               │
│  /backups/config/                             │
│    config_2025-11-11_01-00-00.tar.gz         │
└───────────────────────────────────────────────┘
    │
    │ Consolidate
    ↓
┌───────────────────────────────────────────────┐
│  /backups/complete/                           │
│    backup_complete_2025-11-11_01-00-00.tar.gz│
│                                               │
│  Contiene:                                    │
│  • Base de datos completa                    │
│  • Todos los archivos subidos                │
│  • Configuraciones del sistema               │
└───────────────────────────────────────────────┘
    │
    │ Cleanup
    ↓
┌───────────────────────────────────────────────┐
│  LIMPIEZA AUTOMÁTICA                          │
│  • Elimina backups > 7 días                   │
│  • Mantiene al menos 7 backups diarios        │
│  • Libera espacio en disco                    │
└───────────────────────────────────────────────┘
```

---

## 📍 Puertos y Endpoints

### Puertos Externos (acceso desde host)

```
┌──────────────────────────────────────────────────────────┐
│  Puerto  │  Servicio          │  Descripción             │
├──────────┼────────────────────┼─────────────────────────┤
│  80      │  Traefik           │  HTTP (Frontend + APIs) │
│  3000    │  Grafana           │  Dashboard monitoreo    │
│  3307    │  MySQL Master      │  Base de datos (admin)  │
│  3308    │  MySQL Slave       │  Réplica (readonly)     │
│  6033    │  ProxySQL          │  Load balancer DB       │
│  6379    │  Redis Master      │  Cache principal        │
│  6380    │  Redis Replica     │  Cache réplica          │
│  8025    │  MailHog           │  Web UI testing email   │
│  8080    │  Traefik Dashboard │  Monitoring gateway     │
│  9090    │  Prometheus        │  Métricas               │
└──────────────────────────────────────────────────────────┘
```

### Puertos Internos (solo entre contenedores)

```
┌──────────────────────────────────────────────────────────┐
│  Puerto  │  Servicio          │  Red                     │
├──────────┼────────────────────┼─────────────────────────┤
│  3000    │  Frontend          │  frontend-network       │
│  5001    │  Casos             │  backend-network        │
│  8000    │  Autenticacion     │  backend-network        │
│  8002    │  Documentos        │  backend-network        │
│  8003    │  Notificaciones    │  backend-network        │
│  8004    │  Reportes          │  backend-network        │
│  8005    │  IA-Seguridad      │  backend-network        │
│  3306    │  MySQL (interno)   │  database-network       │
│  6032    │  ProxySQL Admin    │  database-network       │
└──────────────────────────────────────────────────────────┘
```

---

## 🎯 Tabla de Decisiones de Arquitectura

### ¿Por qué esta arquitectura?

| Decisión | Alternativa | Razón de Elección |
|----------|-------------|-------------------|
| **Traefik** | Nginx, HAProxy | Routing automático, discovery de servicios, dashboard integrado |
| **ProxySQL** | HAProxy, MaxScale | Especializado en MySQL, query routing inteligente, cache de queries |
| **MySQL GTID** | Binlog position | Failover más simple, consistencia garantizada, auto-positioning |
| **Redis Replica** | Redis Sentinel | Más simple para el scope, suficiente para HA básica |
| **Prometheus+Grafana** | ELK, Portainer | Stack estándar industria, dashboards potentes, alertas configurables |
| **Gemini AI** | Ollama local | API externa más rápida, mejor calidad, menor carga infraestructura |
| **5 redes** | 1 red | Segmentación por capas, mayor seguridad, aislamiento de fallas |
| **Docker Compose** | Kubernetes | Más simple para demo, adecuado para el alcance, rápido deployment |
| **Flask** | FastAPI, Express | Conocido, simple, rápido desarrollo, buena documentación |
| **React** | Vue, Angular | Ecosistema grande, performance, ampliamente adoptado |

---

## 📈 Evolución del Sistema

### Fase Actual: MVP Completado ✅

```
[Frontend HA] ━━━━━━━━━ ✅ Implementado
[Backend Services] ━━━━ ✅ 6 microservicios
[MySQL HA] ━━━━━━━━━━━ ✅ Master-Slave + ProxySQL
[Redis HA] ━━━━━━━━━━━ ✅ Master-Replica
[Backups] ━━━━━━━━━━━━ ✅ Automatizados 
[Monitoreo] ━━━━━━━━━━ ✅ Prometheus+Grafana
[IA] ━━━━━━━━━━━━━━━━━ ✅ Gemini análisis logs
[Failover] ━━━━━━━━━━━ ✅ Auto-failover daemon
```

### Mejoras Futuras (Roadmap)

```
Fase 2: Producción Enterprise
├─ Kubernetes deployment
├─ Redis Sentinel (3 sentinels)
├─ MySQL Orchestrator
├─ Vault para secretos
├─ CI/CD Pipeline (GitLab/GitHub Actions)
└─ SSL/TLS en todas las comunicaciones

Fase 3: Escalabilidad
├─ Auto-scaling horizontal
├─ CDN para assets estáticos
├─ Múltiples zonas de disponibilidad
├─ Database sharding
└─ Message queue (RabbitMQ/Kafka)

Fase 4: Avanzado
├─ Service mesh (Istio)
├─ Distributed tracing (Jaeger)
├─ Chaos engineering
├─ Multi-región replication
└─ ML-powered auto-optimization
```

---

## ✅ Estado Actual: 100% Operacional

```
┌──────────────────────────────────────────────────────────┐
│                  HEALTH CHECK SUMMARY                     │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  🟢 Frontend (2/2 réplicas)        ✅ Healthy           │
│  🟢 Backend Services (6/6)         ✅ Healthy           │
│  🟢 MySQL Master                   ✅ Healthy           │
│  🟢 MySQL Slave                    ✅ Replicating       │
│  🟢 ProxySQL                       ✅ Load Balancing    │
│  🟢 Redis Master                   ✅ Healthy           │
│  🟢 Redis Replica                  ✅ Replicating       │
│  🟢 Prometheus                     ✅ Scraping          │
│  🟢 Grafana                        ✅ Healthy           │
│  🟢 IA-Seguridad                   ✅ Analyzing         │
│  🟢 Failover Daemon                ✅ Monitoring        │
│  🟢 Backup Service                 ✅ Scheduled         │
│                                                           │
│  TOTAL: 21 containers activos                            │
│  ESTADO: ✅ 100% OPERACIONAL                             │
└──────────────────────────────────────────────────────────┘
```

---

**Generado:** 11 de Noviembre de 2025  
**Proyecto:** Sistema de Gestión de Causas Judiciales  
**Versión Infraestructura:** 1.0  
**Estado:** ✅ Producción Ready
