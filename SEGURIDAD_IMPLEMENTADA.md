# Medidas de Seguridad Implementadas

## Fecha de Implementación

8 de Diciembre de 2025

## 1. HTTPS/TLS ✅ (15%)

### Certificados Auto-Firmados

- **Ubicación**: `api-gateway/certs-local/`
- **Archivos**:
  - `cert.pem` - Certificado público
  - `key.pem` - Clave privada
- **Comando de generación**:
  ```bash
  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=localhost"
  ```
- **Validez**: 365 días
- **Estado**: ✅ Funcionando en puerto 443

### Configuración Traefik

- **Redirección HTTP → HTTPS**: ✅ Configurada automáticamente
- **Puerto 80**: Redirige a 443
- **Puerto 443**: TLS activo con certificados

### Headers de Seguridad HTTP ✅ (4%)

Implementados en `generated-config/traefik.yml`:

```yaml
security-headers:
  headers:
    # HSTS - Forzar HTTPS por 1 año
    stsSeconds: 31536000
    stsIncludeSubdomains: true
    stsPreload: true

    # Prevenir clickjacking
    customFrameOptionsValue: "SAMEORIGIN"

    # Content Security Policy - Prevenir XSS
    contentSecurityPolicy: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://localhost"

    # Prevenir MIME sniffing
    contentTypeNosniff: true

    # Protección XSS del navegador
    browserXssFilter: true

    # Referrer Policy
    referrerPolicy: "strict-origin-when-cross-origin"

    # Permissions Policy
    permissionsPolicy: "geolocation=(), microphone=(), camera=()"

    # No exponer tecnologías del servidor
    customResponseHeaders:
      X-Powered-By: ""
      Server: ""
```

**Headers protegen contra**:

- ✅ Clickjacking (X-Frame-Options)
- ✅ XSS (Content-Security-Policy, X-XSS-Protection)
- ✅ MIME Sniffing (X-Content-Type-Options)
- ✅ Forzar HTTPS (HSTS)
- ✅ Fugas de información (Referrer-Policy)

## 2. Rate Limiting y WAF ✅ (10%)

### Rate Limiting General

```yaml
rate-limit:
  rateLimit:
    average: 100 # 100 requests por segundo
    period: 1s
    burst: 50 # Permite ráfagas de hasta 50 requests
```

### Rate Limiting Estricto (Autenticación)

```yaml
rate-limit-auth:
  rateLimit:
    average: 10 # 10 requests por segundo
    period: 1s
    burst: 5 # Máximo 5 requests en ráfaga
```

### Servicios Protegidos

Todos los servicios backend aplican rate limiting y security headers:

- ✅ `/api/auth` - Rate limiting estricto (10 req/s)
- ✅ `/api/casos` - Rate limiting general (100 req/s)
- ✅ `/api/documentos` - Rate limiting general
- ✅ `/api/notificaciones` - Rate limiting general
- ✅ `/api/reportes` - Rate limiting general
- ✅ `/api/ia-seguridad` - Rate limiting general
- ✅ Frontend - Security headers

### Protección Contra

- ✅ Ataques de fuerza bruta (login)
- ✅ DDoS básicos
- ✅ Scraping agresivo
- ✅ Enumeración de endpoints

## 3. Gestión de Secretos ✅ (15%)

### Archivo .env

- ✅ Archivo `.env` en `.gitignore`
- ✅ Plantilla `.env.example` disponible
- ✅ Sin credenciales hardcodeadas en código

### Variables Gestionadas

```
JWT_SECRET_KEY=<CHANGE_ME>
CASOS_SECRET_KEY=<CHANGE_ME>
REDIS_PASSWORD=<password>
MYSQL_ROOT_PASSWORD=<password>
MYSQL_PASSWORD=<password>
```

### Script de Rotación ✅ (3%)

**Ubicación**: `scripts/security/rotate-secrets.sh`

**Funcionalidades**:

- Genera secretos criptográficamente seguros (32 bytes hex)
- Crea backup automático antes de rotar
- Permite rotar secretos individuales o todos
- Opción de reiniciar contenedores automáticamente

**Uso**:

```bash
sh scripts/security/rotate-secrets.sh
```

## 4. Hardening de Contenedores (Parcial - 20%)

### Medidas Aplicadas ✅

#### Usuarios No Privilegiados

Servicios que **NO** ejecutan como root (justificados):

- ✅ `autenticacion` - Usuario appuser
- ✅ `casos` - Usuario appuser
- ✅ `documentos` - Usuario appuser
- ✅ `notificaciones` - Usuario appuser
- ✅ `reportes` - Usuario appuser

Servicios que **SÍ** ejecutan como root (justificados técnicamente):

- ✅ `db-master` - MySQL requiere capacidades de sistema
- ✅ `db-slave` - MySQL requiere capacidades de sistema
- ✅ `redis` - Requiere capabilities para AOF/persistencia
- ✅ `frontend` (nginx) - Requiere CHOWN/SETUID/SETGID
- ✅ `ia-seguridad` - Requiere acceso al socket de Docker

#### Security Options

```yaml
security_opt:
  - no-new-privileges # Previene escalación de privilegios
```

Aplicado a **TODOS** los servicios.

#### Capabilities

```yaml
cap_drop:
  - ALL # Elimina todas las capabilities por defecto
```

Aplicado a servicios que no requieren capabilities especiales.

#### ✅ Multi-stage Builds Implementados (8 Dic 2025)

**5 servicios backend optimizados**:

- `autenticacion/Dockerfile` - Builder stage + Runtime stage
- `casos/Dockerfile` - Builder stage + Runtime stage
- `documentos/Dockerfile` - Builder stage + Runtime stage
- `notificaciones/Dockerfile` - Builder stage + Runtime stage
- `reportes/Dockerfile` - Builder stage + Runtime stage

**Beneficios**:

- ✅ Elimina gcc y herramientas de compilación de imagen final
- ✅ Reduce tamaño de imagen ~40% (575MB → ~350MB estimado)
- ✅ Mejora seguridad al no incluir toolchain en producción
- ✅ Frontend ya tenía multi-stage (Node build → Nginx)

#### ✅ Límites de Recursos

Configurados en `docker-compose.yml`:

- db-master, db-slave, redis, frontend, ia-seguridad, notificaciones
- Limits + Reservations para garantizar QoS

### Pendiente ⚠️

- ❌ Versiones específicas (algunos usan `:latest`)
- ❌ Documento `docs/hardening-contenedores.md`

## 5. Hardening de Base de Datos ✅ (20%)

### Autenticación

- ✅ Autenticación obligatoria habilitada
- ✅ Contraseñas fuertes (generadas con openssl)
- ✅ No hay acceso sin contraseña

### Privilegios Mínimos

- ✅ Usuario `appuser` con permisos solo de aplicación
- ✅ **NO** se usa usuario root en la aplicación
- ✅ Permisos limitados: SELECT, INSERT, UPDATE, DELETE
- ✅ **NO** tiene permisos: DROP, CREATE USER, GRANT

### Aislamiento de Red ✅

- ✅ Base de datos en red interna Docker (`database-network`)
- ✅ **NO** expuesta directamente al host
- ✅ Solo servicios autorizados en la misma red

### Logging y Auditoría

- ✅ Logs de conexiones habilitados
- ✅ MySQL error log activo
- ✅ Slow query log configurado

### SSL/TLS

- ✅ Certificados SSL generados en `db/certs/`
- ✅ Conexiones MySQL con TLS

### Pendiente ⚠️

- ❌ Documento `docs/hardening-database.md`

## 6. Análisis de Vulnerabilidades ✅ (10%)

### Herramientas Utilizadas

- ✅ **Trivy** - Escaneo de imágenes Docker

### Script Automatizado ✅

**Ubicación**: `scripts/security/scan-vulnerabilities.sh`

**Funcionalidades**:

- Escanea todas las imágenes del proyecto
- Filtra vulnerabilidades HIGH y CRITICAL
- Genera reporte consolidado con versionado
- Almacena en `docs/reportes/vulnerabilidades/`

**Reportes Generados**:

- ✅ `consolidated-scan-report-2025-11-25-v1.txt`
- ✅ `consolidated-scan-report-2025-12-06-v1.txt`
- ✅ `consolidated-scan-report-2025-12-08-v1.txt`

### Pendiente ⚠️

- ❌ Escaneo de dependencias (npm audit, pip safety)
- ❌ Escaneo de puertos (Nmap)
- ❌ Análisis web (Nikto)
- ❌ Documento `vulnerabilidades-remediadas.md`

## 7. Logging y Auditoría ⚠️ (5%)

### Implementado

- ✅ Docker logs configurado
- ✅ Traefik access log: `/var/log/traefik/access.log`
- ✅ Logs de servicios Flask
- ✅ Logs de MySQL

### Eventos Registrados

- ✅ Peticiones HTTP (Traefik)
- ✅ Autenticación (Flask)
- ✅ Conexiones a base de datos
- ✅ Errores de aplicación

### ✅ Rotación Automática Implementada (8 Dic 2025)

```yaml
# Configuración global en docker-compose.yml
x-logging: &default-logging
  driver: "json-file"
  options:
    max-size: "10m" # Máximo 10MB por archivo
    max-file: "3" # Mantiene últimos 3 archivos (30MB total)
    compress: "true" # Compresión automática
```

**Servicios con rotación**: gateway, db-master, redis, autenticacion, casos, documentos, notificaciones, ia-seguridad, cron, reportes, frontend

### Pendiente

- ❌ Sistema centralizado (Loki/ELK)
- ❌ Dashboard de logs de seguridad
- ❌ Script para consultar logs de seguridad

## 8. Documentación y Políticas ❌ (5%)

### Faltante (CRÍTICO para aprobar)

Todos estos documentos son **OBLIGATORIOS** según el enunciado:

1. ❌ `docs/politica-seguridad.md`
2. ❌ `docs/matriz-riesgos.md`
3. ❌ `docs/owasp-top10.md`
4. ❌ `docs/plan-incidentes.md`
5. ❌ `docs/cumplimiento-normativo.md`
6. ❌ `docs/hardening-contenedores.md`
7. ❌ `docs/hardening-database.md`
8. ❌ `docs/vulnerabilidades-remediadas.md`

## ✅ Implementaciones del 8 de Diciembre 2025

### 1. Trivy Scan Corregido y Ejecutado (5%)

- Corregido `PROJECT_NAME` en `scripts/security/scan-vulnerabilities.sh`
- Scan exitoso en 11 servicios (autenticacion, casos, notificaciones, ia-seguridad, cron, frontend, backup-service, failover-daemon, db-slave)
- **Vulnerabilidades encontradas**: 6 HIGH en urllib3 y gosu
- Reporte: `docs/reportes/vulnerabilidades/consolidated-scan-report-2025-12-08-v2.txt`

### 2. Límites de Recursos (2%)

Agregados a servicios críticos:

- **db-master**: 2 CPUs / 2GB RAM (reserva: 0.5 CPU / 512MB)
- **db-slave**: 1.5 CPUs / 1.5GB RAM (reserva: 0.5 CPU / 512MB)
- **redis**: 1 CPU / 512MB RAM (reserva: 0.25 CPU / 128MB)
- **frontend**: 1 CPU / 512MB RAM (reserva: 0.25 CPU / 128MB)
- **ia-seguridad**: 1.5 CPUs / 1GB RAM (reserva: 0.5 CPU / 256MB)
- **notificaciones**: 0.5 CPU / 512MB RAM (reserva: 0.25 CPU / 256MB)

### 3. Rotación Automática de Logs (2%)

```yaml
x-logging: &default-logging
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
    compress: "true"
```

Aplicado a 11 servicios principales

### 4. Multi-stage Builds (4%)

- ✅ 5 servicios backend optimizados
- ✅ Separación builder/runtime
- ✅ Reducción ~40% tamaño imágenes

### 5. Script Test Rate Limiting (1%)

- ✅ `scripts/security/test-rate-limiting.sh`
- ✅ Prueba límite 10 req/s en /api/auth
- ✅ Prueba límite 100 req/s en /api/casos
- ✅ Captura logs con respuestas 429

### 6. Versiones Específicas en Imágenes (1%)

- ✅ `traefik:v2.10` → `traefik:v2.10.7`
- ✅ `alpine:3.18` → `alpine:3.18.12`
- ✅ `redis:7-alpine` → `redis:7.4.1-alpine3.20`
- ✅ `mailhog/mailhog` → `mailhog/mailhog:v1.0.1`
- ✅ Prometheus y Grafana ya tenían versiones fijas

### Total Esta Sesión: +15% (de 77% → 92%)

---

## Resumen de Puntos

| Aspecto                   | Puntos Totales | Implementado | Pendiente |
| ------------------------- | -------------- | ------------ | --------- |
| HTTPS/TLS                 | 15%            | 15% ✅       | 0%        |
| Hardening Contenedores    | 20%            | 19% ✅       | 1%        |
| Hardening BD              | 20%            | 19% ⚠️       | 1%        |
| Gestión Secretos          | 15%            | 15% ✅       | 0%        |
| WAF/Rate Limiting         | 10%            | 10% ✅       | 0%        |
| Análisis Vulnerabilidades | 10%            | 9% ⚠️        | 1%        |
| Logging/Auditoría         | 5%             | 5% ✅        | 0%        |
| Documentación             | 5%             | 0% ❌        | 5%        |
| **TOTAL**                 | **100%**       | **92%**      | **8%**    |

## Próximos Pasos (Orden de Prioridad)

### ✅ COMPLETADO HOY - IMPLEMENTACIÓN TÉCNICA

1. ✅ **Trivy scan corregido** - 5%
2. ✅ **Límites de recursos** - 2%
3. ✅ **Rotación de logs** - 2%
4. ✅ **Multi-stage builds** - 4%
5. ✅ **Script test rate limiting** - 1%
6. ✅ **Versiones específicas en imágenes** - 1%

### FALTA IMPLEMENTACIÓN TÉCNICA (3%)

7. ⚠️ **urllib3 vulnerable en db-slave** - 1%
   - Vulnerabilidad en imagen base Oracle MySQL 9.7
   - NO controlable por nosotros (requiere actualización de Oracle)
8. ⚠️ **gosu vulnerable en db-slave** - 1%
   - Vulnerabilidad en imagen base Oracle MySQL 9.7
   - NO controlable por nosotros
9. ❌ **Documento vulnerabilidades-remediadas.md** - 1%

### DOCUMENTACIÓN OBLIGATORIA (5%)

9. ❌ **8 documentos obligatorios** - 5% - 3 horas
   - politica-seguridad.md
   - matriz-riesgos.md
   - owasp-top10.md
   - plan-incidentes.md
   - cumplimiento-normativo.md
   - hardening-contenedores.md
   - hardening-database.md
   - vulnerabilidades-remediadas.md

## Archivos Modificados en Esta Sesión (8 Dic 2025)

### Primera Ronda (Rate Limiting)

1. `generated-config/traefik.yml` - Rate limiting y security headers
2. `docker-compose.yml` - Middlewares a servicios
3. `scripts/security/rotate-secrets.sh` - Script rotación secretos

### Segunda Ronda (Optimizaciones + Hardening)

4. `scripts/security/scan-vulnerabilities.sh` - Corregido PROJECT_NAME
5. `docker-compose.yml` - Límites de recursos + logging rotation + versiones fijas
6. `backend/autenticacion/Dockerfile` - Multi-stage build
7. `backend/casos/Dockerfile` - Multi-stage build
8. `backend/documentos/Dockerfile` - Multi-stage build
9. `backend/notificaciones/Dockerfile` - Multi-stage build
10. `backend/reportes/Dockerfile` - Multi-stage build
11. `scripts/security/test-rate-limiting.sh` - Test automatizado

**Cambios en docker-compose.yml**:

- Traefik: v2.10 → v2.10.7
- Alpine: 3.18 → 3.18.12
- Redis: 7-alpine → 7.4.1-alpine3.20
- Mailhog: latest → v1.0.1

## Evidencias de Funcionamiento

### HTTPS Funcionando

```bash
curl -k https://localhost
# Respuesta: HTML de React App
```

### Login con JWT

```bash
curl -k -X POST https://localhost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"correo":"admin@judicial.cl","password":"admin123"}'
# Respuesta: {"access_token":"eyJ..."}
```

### Rate Limiting

**Probar con script automatizado**:

```bash
sh scripts/security/test-rate-limiting.sh
```

Los servicios están protegidos contra:

- Intentos de fuerza bruta en `/api/auth` (10 req/s)
- Abuso de APIs en otros endpoints (100 req/s)

**Prueba manual con curl**:

```bash
# Enviar 15 requests rápidos al login
for i in {1..15}; do curl -k -X POST https://localhost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"correo":"test","password":"test"}' \
  -w "\nStatus: %{http_code}\n"; done
# Después del request 10-11 verás respuestas 429
```

### Security Headers

Verificables en navegador (F12 → Network → Headers):

- `Strict-Transport-Security`
- `X-Frame-Options`
- `Content-Security-Policy`
- `X-Content-Type-Options`
- `Referrer-Policy`
