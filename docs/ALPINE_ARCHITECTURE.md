# Arquitectura de Inicialización con Alpine Containers

## Diagrama de Flujo Completo

```
┌─────────────────────────────────────────────────────────────────┐
│                    USUARIO EJECUTA COMANDO                      │
│                    $ docker compose up -d                       │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DOCKER COMPOSE ORQUESTA                     │
│                    Fase 1: Init Containers                      │
└─────────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┬─────────────────┐
        │                   │                   │                 │
        ▼                   ▼                   ▼                 ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐  ┌──────────────┐
│   Alpine     │    │   Alpine     │    │   Alpine     │  │   Alpine     │
│  Prometheus  │    │    Redis     │    │  ProxySQL    │  │   Traefik    │
│    Init      │    │    Init      │    │    Init      │  │    Init      │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘  └──────┬───────┘
       │                   │                   │                 │
       │ 1. Lee .env       │                   │                 │
       │ 2. Carga script   │                   │                 │
       │ 3. Procesa template│                  │                 │
       │ 4. Ejecuta sed    │                   │                 │
       │ 5. Escribe config │                   │                 │
       │ 6. Termina (Exit 0)                   │                 │
       │                   │                   │                 │
       ▼                   ▼                   ▼                 ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐  ┌──────────────┐
│   Docker     │    │   Docker     │    │   Docker     │  │   Docker     │
│   Volume     │    │   Volume     │    │   Volume     │  │   Volume     │
│ prometheus-  │    │   redis-     │    │  proxysql-   │  │  traefik-    │
│   config     │    │   config     │    │   config     │  │   config     │
│              │    │              │    │              │  │              │
│ ✅ prom.yml  │    │ ✅ redis.conf│    │ ✅ proxy.cnf │  │ ✅ traefik.yml│
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘  └──────┬───────┘
       │                   │                   │                 │
       │                   │                   │                 │
       └───────────────────┴───────────────────┴─────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              DOCKER COMPOSE VERIFICA DEPENDENCIAS               │
│        depends_on: condition: service_completed_successfully    │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Fase 2: Servicios Principales                  │
└─────────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┬─────────────────┐
        │                   │                   │                 │
        ▼                   ▼                   ▼                 ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐  ┌──────────────┐
│  Prometheus  │    │    Redis     │    │  ProxySQL    │  │   Traefik    │
│  Container   │    │  Container   │    │  Container   │  │  Container   │
│              │    │              │    │              │  │              │
│  Monta:      │    │  Monta:      │    │  Monta:      │  │  Monta:      │
│  prometheus- │    │  redis-      │    │  proxysql-   │  │  traefik-    │
│  config:/etc │    │  config:/etc │    │  config:/etc │  │  config:/etc │
│              │    │              │    │              │  │              │
│  🟢 RUNNING  │    │  🟢 RUNNING  │    │  🟢 RUNNING  │  │  🟢 RUNNING  │
└──────────────┘    └──────────────┘    └──────────────┘  └──────────────┘
        │                   │                   │                 │
        └───────────────────┴───────────────────┴─────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ✅ SISTEMA OPERATIVO                         │
│         Todos los servicios con configuración dinámica          │
└─────────────────────────────────────────────────────────────────┘
```

## Componentes Detallados

### 1. Alpine Init Container: Prometheus

**Responsabilidad:** Generar `prometheus.yml` con endpoints de scraping

**Variables utilizadas:**
- `PROMETHEUS_SCRAPE_INTERVAL` (default: 15s)
- `PROMETHEUS_EVALUATION_INTERVAL` (default: 15s)

**Template:**
```yaml
global:
  scrape_interval: __SCRAPE_INTERVAL__
  evaluation_interval: __EVALUATION_INTERVAL__

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  # ... más targets
```

**Salida:** `/config/prometheus.yml` con valores reemplazados

---

### 2. Alpine Init Container: Redis

**Responsabilidad:** Generar `redis.conf` con autenticación y límites

**Variables utilizadas:**
- `REDIS_PASSWORD` (requerido)
- `REDIS_MAX_MEMORY` (default: 256mb)
- `REDIS_DATABASES` (default: 16)

**Template:**
```conf
bind 0.0.0.0
requirepass __REDIS_PASSWORD__
masterauth __REDIS_PASSWORD__
maxmemory __MAX_MEMORY__
maxmemory-policy allkeys-lru
appendonly yes
# ... más configuraciones
```

**Salida:** `/config/redis.conf` con autenticación configurada

---

### 3. Alpine Init Container: ProxySQL

**Responsabilidad:** Generar `proxysql.cnf` con routing master/slave

**Variables utilizadas:**
- `PROXYSQL_ADMIN_USER` (default: admin)
- `PROXYSQL_ADMIN_PASSWORD` (default: admin)
- `MYSQL_MONITOR_USER`
- `MYSQL_MONITOR_PASSWORD`
- `MYSQL_DATABASE`
- `MYSQL_MASTER_HOST` (default: db-master)
- `MYSQL_SLAVE_HOST` (default: db-slave)
- `MYSQL_USER`
- `MYSQL_PASSWORD`

**Template:**
```conf
datadir="/var/lib/proxysql"

mysql_replication_hostgroups=
(
    { writer_hostgroup=10, reader_hostgroup=20 }
)

mysql_servers=
(
    { address="__MASTER_HOST__", port=3306, hostgroup=10 },
    { address="__SLAVE_HOST__", port=3306, hostgroup=20 }
)

mysql_query_rules=
(
    { rule_id=1, match_pattern="^SELECT.*FOR UPDATE", destination_hostgroup=10 },
    { rule_id=2, match_pattern="^SELECT", destination_hostgroup=20 }
)
```

**Salida:** `/config/proxysql.cnf` con routing configurado

---

### 4. Alpine Init Container: Traefik

**Responsabilidad:** Generar `traefik.yml` para API Gateway

**Variables utilizadas:**
- `TRAEFIK_API_INSECURE` (default: true)
- `TRAEFIK_DASHBOARD_ENABLED` (default: true)
- `TRAEFIK_LOG_LEVEL` (default: INFO)

**Template:**
```yaml
api:
  insecure: __API_INSECURE__
  dashboard: __DASHBOARD_ENABLED__

entryPoints:
  web:
    address: ":80"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    network: __NETWORK_NAME__

log:
  level: __LOG_LEVEL__
```

**Salida:** `/config/traefik.yml` con configuración del gateway

---

## Ventajas Arquitecturales

### 🔒 Seguridad por Capas
1. **Capa 1:** Variables sensibles en `.env` (excluido de git)
2. **Capa 2:** Templates sin credenciales (versionados)
3. **Capa 3:** Configuraciones generadas en runtime (volúmenes efímeros)

### ⚡ Performance
- Init containers **ligeros**: Alpine Linux ~5MB
- **Una sola ejecución**: Los containers terminan después de generar configs
- **Sin overhead**: No consumen recursos después de completar

### �� Ciclo de Vida

```
┌──────────────┐
│  Variables   │──────┐
│    .env      │      │
└──────────────┘      │
                      ▼
┌──────────────┐   ┌─────────────────┐
│  Templates   │──▶│ Alpine Init     │
│  .template   │   │ Container       │
└──────────────┘   │ - Lee vars      │
                   │ - Procesa sed   │
                   │ - Genera config │
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │  Docker Volume  │
                   │  (Config final) │
                   └────────┬────────┘
                            │
                            ▼
                   ┌─────────────────┐
                   │  Service        │
                   │  Container      │
                   │  (Lee config)   │
                   └─────────────────┘
```

### 🔧 Modificabilidad

**Cambio de configuración:**
1. Editar `.env`
2. Ejecutar: `./scripts/manage-configs.sh clean`
3. Ejecutar: `docker compose up -d`
4. ✅ Nuevas configs generadas automáticamente

**Sin necesidad de:**
- Editar múltiples archivos
- Reconstruir imágenes
- Modificar código
- Hacer commits

### 📊 Monitoreo y Debug

**Verificar estado:**
```bash
$ ./scripts/manage-configs.sh status
```

**Ver logs de generación:**
```bash
$ ./scripts/manage-configs.sh logs prometheus
$ ./scripts/manage-configs.sh logs redis
```

**Inspeccionar configuraciones:**
```bash
$ docker run --rm -v proy2_redis-config:/c alpine cat /c/redis.conf
```

---

## Patrones Implementados

### 🎯 Pattern: Init Container
- Inspirado en Kubernetes Init Containers
- Contenedores que se ejecutan antes de los principales
- Preparan el entorno para los servicios

### 🎯 Pattern: Configuration as Code
- Templates versionados en Git
- Configuraciones reproducibles
- Infrastructure as Code (IaC)

### 🎯 Pattern: 12-Factor App
- **Factor III:** Config en variables de entorno
- Separación clara entre código y configuración
- Portabilidad entre entornos

### 🎯 Pattern: Volume Mounting
- Volúmenes compartidos entre containers
- Datos persistentes pero configurables
- Desacoplamiento de servicios

---

## Comparación con Alternativas

| Aspecto | Alpine Init | ConfigMaps | Archivos Estáticos |
|---------|-------------|------------|-------------------|
| **Tamaño** | ~5MB | N/A | 0 |
| **Seguridad** | ✅ Alta | ✅ Alta | ❌ Baja |
| **Portabilidad** | ✅ Total | ⚠️  K8s only | ✅ Total |
| **Complejidad** | 🟢 Baja | 🟡 Media | 🟢 Baja |
| **Versionado** | ✅ Sí (templates) | ✅ Sí | ⚠️  Incluye secrets |
| **Modificabilidad** | ✅ Fácil (.env) | ✅ Fácil | ❌ Manual |
| **Learning Curve** | 🟢 Baja | 🔴 Alta | �� Baja |

---

## Escalabilidad

Este patrón escala fácilmente:

```bash
# Añadir nuevo servicio con config dinámica:

1. Crear template en: scripts/config-templates/miservicio/
2. Crear script en: scripts/init-miservicio.sh
3. Añadir variables en: .env.example
4. Añadir init container en: docker compose.yml
5. Listo! ✅
```

Ejemplo completo en: [docs/CONFIG-INIT-SYSTEM.md#añadir-nuevo-servicio](CONFIG-INIT-SYSTEM.md#añadir-nuevo-servicio)

---

**Autor:** Sistema de Gestión de Causas Judiciales  
**Versión:** 1.0.0  
**Fecha:** 2025-11-10
