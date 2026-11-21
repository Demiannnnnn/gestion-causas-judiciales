# AGENTS.md — Guía para Agentes y Desarrolladores

## 1. Descripción General del Sistema

**Sistema de Gestión de Causas Judiciales** es una plataforma web basada en microservicios contenerizados con Docker Compose para la gestión integral de causas judiciales, documentos asociados, notificaciones, reportes estadísticos/PDF y monitoreo de seguridad asistido por IA.

---

## 2. Arquitectura Real del Repositorio

El sistema se orquesta desde `docker-compose.yml` y está dividido en las siguientes capas:

### 2.1. API Gateway y Frontend
- **`gateway` (Traefik v2.11)**: Reverse proxy, terminación TLS (`:80` → `:443`), rate limiting y cabeceras de seguridad (`generated-config/dynamic-config.yml`). Dashboard en `:8080`.
- **`frontend` (React 19 + Bootstrap 5 + Nginx)**: SPA construida con `react-scripts` (`frontend/src/`), servida detrás de Traefik. Rutas protegidas por rol (`ADMINISTRADOR`, `ABOGADO`, `ASISTENTE`, `SISTEMAS`).

### 2.2. Microservicios Backend (`backend/`, Python 3.11 + Flask + SQLAlchemy)
Todos los microservicios comparten el paquete `backend/common/` (`database.py`, `models.py`, `auth.py`, `logging_utils.py`), el cual gestiona pools de conexiones SQLAlchemy por rol de base de datos y validación de JWT (`@token_required`):
- **`autenticacion` (`:8000`, ruta `/api/auth`)**: Inicio de sesión (`POST /login`), verificación de hashes bcrypt (`passlib`) y emisión de tokens JWT HS256 (`backend/autenticacion/app/`).
- **`casos` (`:5001`, ruta `/api/casos`, 2 réplicas)**: CRUD de causas judiciales, consulta de tribunales, partes y movimientos, e invocación de alertas al servicio de notificaciones (`backend/casos/app/`).
- **`documentos` (`:8002`, ruta `/api/documentos`)**: Subida, listado, descarga y eliminación de archivos asociados a causas en el volumen `documentos-uploads` (`backend/documentos/app/`).
- **`notificaciones` (`:8003`, ruta `/api/notificaciones`)**: API Flask + `worker.py` en segundo plano para despacho de correos vía SMTP/MailHog, alertas de vencimientos y resumen diario (`backend/notificaciones/app/`).
- **`reportes` (`:8004`, ruta `/api/reportes`)**: Estadísticas generales, exportación CSV (`pandas`) de causas y vencimientos, y generación de historial de causa en PDF (`reportlab`) (`backend/reportes/app/`).
- **`ia-seguridad` (`:8005`, ruta `/api/ia-seguridad`)**: Análisis de logs de contenedores Docker (con Gemini / OpenAI o modo básico de respaldo sin API key), detección de anomalías de recursos (`psutil`, `docker`) y gestión de alertas (`backend/ia-seguridad/app/`).

### 2.3. Capa de Datos, Alta Disponibilidad y Caché
- **`db-init` (Alpine)**: Procesa plantillas SQL (`db/master/mysql/02-grants.sql.template` y `db/slave/01-create-replication-user.sql.template`) inyectando las credenciales definidas en `.env`.
- **`db-master` (`:3307->3306`)**: Nodo primario MySQL 8 con GTID y TLS habilitado (`db/master/`). Inicializa esquema desde `db/master/mysql/01-schema.sql` y triggers de auditoría desde `03-triggers.sql`.
- **`db-slave` y `db-slave-2`**: Réplicas MySQL de lectura con GTID y replicación SSL (`db/slave/`).
- **`db-proxy` (ProxySQL `:6033` / admin `:6032`)**: Balanceador y punto de entrada SQL para los microservicios (`db/proxy/`).
- **`orchestrator` (`:3030->3000`)**: Gestión de topología y failover MySQL (`orchestrator/`).
- **`redis` (`:6379`) y `redis-replica`**: Almacenamiento en caché con persistencia AOF.

### 2.4. Monitoreo y Tareas Programadas
- **`prometheus` (`:9090`), `grafana` (`:3000`), `loki` (`:3100`), `promtail`**: Observabilidad, métricas y agregación de logs (`monitoring/`).
- **`mailhog` (`:1025` SMTP / `:8025` Web UI)**: Servidor de correo local para pruebas.
- **`cron` y `backup-service`**: Ejecución periódica de alertas/resúmenes y respaldos automatizados hacia `./backups` (ignorado en git).

---

## 3. Variables de Entorno Requeridas

Antes de iniciar el sistema, copie `.env.example` a `.env` y configure valores seguros (nunca versione `.env` ni credenciales reales):

| Categoría | Variables Requeridas | Descripción |
| :--- | :--- | :--- |
| **MySQL Core** | `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` | Credenciales administrativas y base de datos principal (`causas_judiciales_db`). |
| **MySQL HA / Monitor** | `MYSQL_MONITOR_USER`, `MYSQL_MONITOR_PASSWORD`, `MYSQL_REPLICATION_USER`, `MYSQL_REPLICATION_PASSWORD`, `MYSQL_PASSWORD_ORCHESTRATOR_APP` | Usuarios para ProxySQL, replicación GTID y Orchestrator. |
| **MySQL Roles App** | `MYSQL_PASSWORD_ADMIN_APP`, `MYSQL_PASSWORD_ABOGADO_APP`, `MYSQL_PASSWORD_ASISTENTE_APP`, `MYSQL_PASSWORD_SISTEMAS_APP`, `MYSQL_PASSWORD_READONLY_APP` | Contraseñas por rol utilizadas por `backend/common/database.py` y ProxySQL. |
| **Seguridad / JWT** | `JWT_SECRET_KEY`, `CASOS_SECRET_KEY` | Claves secretas obligatorias para firma/verificación de tokens JWT HS256 y sesiones Flask. |
| **Caché y ProxySQL** | `REDIS_PASSWORD`, `PROXYSQL_ADMIN_USER`, `PROXYSQL_ADMIN_PASSWORD` | Autenticación de Redis y consola administrativa de ProxySQL. |
| **Monitoreo / Gateway** | `GRAFANA_ADMIN_USER`, `GRAFANA_ADMIN_PASSWORD`, `TRAEFIK_DASHBOARD_USER`, `TRAEFIK_DASHBOARD_PASSWORD`, `PROMETHEUS_SCRAPE_INTERVAL`, `PROMETHEUS_EVALUATION_INTERVAL` | Configuración de observabilidad y dashboard de Traefik. |
| **Opcionales (IA / SMTP)** | `AI_PROVIDER`, `GEMINI_API_KEY`, `OPENAI_API_KEY`, `MAIL_SERVER`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD` | Proveedores de IA para `ia-seguridad` y servidor SMTP para `notificaciones`. |

Puede generar secretos aleatorios ejecutando:
```bash
openssl rand -hex 32
```

---

## 4. Comandos Verificados de Inicialización, Arranque y Verificación

### 4.1. Preparación de Entorno, Certificados TLS y Archivos Generados
Los certificados TLS (`*.pem`) y archivos de configuración generados (`generated-config/proxysql.cnf`, `redis.conf`, `prometheus.yml`, `traefik.yml`) **no se versionan en Git** por seguridad. Para generarlos localmente:

```bash
# 1. Crear archivo .env desde la plantilla y configurar secretos
cp .env.example .env

# 2. Validar que todas las variables requeridas estén presentes en .env
./scripts/validate-env.sh

# 3. Generar certificados TLS autofirmados (MySQL en db/certs/ y Gateway en api-gateway/certs-local/)
./db/generate-certs.sh
```

### 4.2. Arranque del Sistema con Docker Compose
```bash
# Inicio asistido (valida .env, inicializa configs y levanta servicios)
./start.sh

# O manualmente con Docker Compose:
docker compose up -d
```

### 4.3. Verificación de Sintaxis, Build y Tests Locales
Comandos verificados para validar el código sin levantar toda la infraestructura:

```bash
# 1. Compilación y verificación de sintaxis Python en todos los microservicios backend
python3 -m py_compile \
  backend/common/*.py \
  backend/autenticacion/app/*.py \
  backend/casos/app/*.py \
  backend/documentos/app/*.py \
  backend/notificaciones/app/*.py \
  backend/reportes/app/*.py \
  backend/ia-seguridad/app/*.py \
  scripts/fix_proxysql_config.py \
  scripts/generar_hash.py

# 2. Validación de sintaxis de scripts Bash
for s in start.sh VALIDAR_CAMBIOS.sh db/generate-certs.sh scripts/*.sh backup-service/scripts/*.sh; do
  bash -n "$s"
done

# 3. Build y tests de Frontend (React)
cd frontend && npm test -- --watchAll=false && npm run build
```

---

## 5. Reglas de Higiene y Seguridad del Repositorio

1. **Prohibido versionar secretos o llaves privadas**: Nunca hacer commit de `.env`, `*.pem`, `*.key`, `token.txt`, `login_response.json`, ni configuraciones renderizadas en `generated-config/` (`proxysql.cnf`, `redis.conf`, `prometheus.yml`, `traefik.yml`).
2. **Prohibido hardcodear secretos en código fuente**: Los microservicios deben leer `JWT_SECRET_KEY`, `CASOS_SECRET_KEY` y `DATABASE_URL*` exclusivamente desde variables de entorno.
3. **Prohibido versionar respaldos o artefactos temporales**: Los dumps SQL y archivos comprimidos bajo `backups/`, reportes temporales de escaneo y archivos `.DS_Store` / `*.bak` deben permanecer excluidos mediante `.gitignore`.
