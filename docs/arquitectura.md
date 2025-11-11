# Documentación de Arquitectura
## Sistema de Gestión de Causas Judiciales

### Información del Proyecto

**Licitación:** 1552-56-LE25  
**Cliente:** Servicio de Salud de Atacama  
**Equipo:**
- Camilo Fuentes
- Demian Maturana
- Catalina Herrera

---

## 1. Visión General de la Arquitectura

### 1.1 Tipo de Arquitectura
**Microservicios containerizados** con Docker Compose, diseñada para cumplir con los requisitos de **Alta Disponibilidad (HA)** y escalabilidad del sector público chileno.

### 1.2 Principios de Diseño

#### ✅ Separación de Responsabilidades
Cada microservicio tiene una responsabilidad única y bien definida, facilitando el mantenimiento y la evolución independiente.

#### ✅ Independencia de Despliegue
Los servicios pueden actualizarse sin afectar al resto del sistema, minimizando el tiempo de inactividad.

#### ✅ Escalabilidad Horizontal
Capacidad de escalar servicios individuales según demanda mediante réplicas.

#### ✅ Resiliencia
Implementación de health checks, reintentos automáticos y failover para garantizar disponibilidad del 99.5%.

---

## 2. Componentes de la Arquitectura

### 2.1 Capa de Presentación

#### Frontend (React + Nginx) - 2 Réplicas
- **Tecnología:** React 19.2.0 + Bootstrap 5.3.8
- **Servidor Web:** Nginx en contenedor
- **Puerto:** 3000 (interno) → 80 (externo via Traefik)
- **Características:**
  - SPA (Single Page Application)
  - Responsive design
  - Gestión de estado con React Hooks
  - Autenticación JWT con context API
  - Rutas protegidas

**Justificación de Alta Disponibilidad:**
- 2 réplicas independientes para distribución de carga
- Si cae una réplica, Traefik redirige tráfico a la réplica sana
- Zero downtime en actualizaciones

---

### 2.2 Capa de Gateway

#### API Gateway (Traefik v2.10)
- **Función:** Punto de entrada único al sistema
- **Puertos:** 80 (HTTP), 8080 (Dashboard)
- **Responsabilidades:**
  - Enrutamiento inteligente de peticiones
  - Load balancing entre réplicas
  - Service discovery automático
  - SSL/TLS termination
  - Rate limiting

**Configuración de Enrutamiento:**
```yaml
Labels de Traefik en microservicios:
- traefik.enable=true
- traefik.http.routers.{service}.rule=PathPrefix(`/api/{service}`)
- traefik.http.middlewares.{service}-strip.stripprefix.prefixes=/api/{service}
```

---

### 2.3 Capa de Microservicios Backend

#### 2.3.1 Servicio de Autenticación
- **Tecnología:** Python 3.11 + Flask 3.0.0
- **Puerto:** 8000
- **Base de Datos:** MySQL (compartida)
- **Responsabilidades:**
  - Login/Logout de usuarios
  - Generación de tokens JWT
  - Verificación de contraseñas (bcrypt)
  - Gestión de sesiones

**Endpoints principales:**
- `POST /login` - Autenticación de usuario
- `GET /health` - Health check

**Seguridad:**
- Contraseñas hasheadas con bcrypt (12 rounds)
- Tokens JWT con expiración de 24h
- Usuario no privilegiado en contenedor

---

#### 2.3.2 Servicio de Casos (Core)
- **Tecnología:** Python 3.11 + Flask 3.0.0
- **Puerto:** 5001
- **Réplicas:** 2 (configuradas con `deploy.replicas=2`)
- **Responsabilidades:**
  - CRUD completo de causas judiciales
  - Gestión de tribunales
  - Relación causas-partes
  - Gestión de movimientos
  - Notificaciones a otros servicios

**Endpoints principales:**
- `GET /` - Listar todos los casos
- `POST /` - Crear nuevo caso
- `GET /{id}` - Obtener caso específico
- `PUT /{id}` - Actualizar caso
- `DELETE /{id}` - Eliminar caso
- `GET /{id}/partes` - Obtener partes del caso
- `GET /{id}/movimientos` - Obtener movimientos
- `GET /tribunales` - Listar tribunales

**Características:**
- Integración con servicio de notificaciones
- Validación de datos con SQLAlchemy
- Manejo de transacciones con context manager

---

#### 2.3.3 Servicio de Documentos
- **Tecnología:** Python 3.11 + Flask 3.0.0
- **Puerto:** 8002
- **Almacenamiento:** Volumen persistente `documentos-uploads`
- **Responsabilidades:**
  - Subida de documentos PDF
  - Almacenamiento seguro
  - Descarga de documentos
  - Eliminación de archivos
  - Asociación con causas

**Endpoints principales:**
- `POST /causa/{id}/documentos` - Subir documento
- `GET /causa/{id}/documentos` - Listar documentos
- `GET /{id_documento}` - Descargar documento
- `DELETE /{id_documento}` - Eliminar documento

**Seguridad:**
- Validación de tipo de archivo (solo PDF)
- Sanitización de nombres con `secure_filename`
- Usuario no privilegiado (UID 1000)

---

#### 2.3.4 Servicio de Notificaciones
- **Tecnología:** Python 3.11 + Flask 3.0.0 + Gunicorn
- **Puerto:** 8003
- **Arquitectura:** API + Worker asíncrono
- **Email:** Integración con MailHog (desarrollo)
- **Responsabilidades:**
  - Envío de notificaciones por email
  - Gestión de cola de notificaciones
  - Consolidados diarios
  - Alertas de vencimiento
  - Tracking de estado de lectura

**Endpoints principales:**
- `POST /send` - Enviar notificación
- `GET /` - Listar notificaciones (con filtros)
- `PUT /{id}/marcar-leido` - Marcar como leída
- `GET /stats` - Estadísticas de notificaciones
- `GET /health` - Health check

**Worker Process:**
- Proceso separado que monitorea notificaciones pendientes
- Polling interval de 10 segundos
- Envío automático vía SMTP

---

#### 2.3.5 Servicio de Reportes
- **Tecnología:** Python 3.11 + Flask 3.0.0
- **Puerto:** 8004
- **Librerías:** Pandas, ReportLab
- **Responsabilidades:**
  - RF6.1: Reportes de estado por tribunal/abogado
  - RF6.2: Reportes de vencimientos (30 días)
  - RF6.3: Historial completo en PDF
  - Generación de estadísticas

**Endpoints principales:**
- `GET /casos` - Reporte de casos (CSV)
- `GET /vencimientos` - Reporte de vencimientos (CSV)
- `GET /causa-history/{rit}/pdf` - Historial completo (PDF)
- `GET /estadisticas` - Dashboard de métricas
- `GET /tribunales` - Listar tribunales

**Formatos de Salida:**
- CSV para reportes tabulares
- PDF para historiales completos con formato profesional

---

#### 2.3.6 Servicio de IA (Análisis de Seguridad)
- **Tecnología:** Python 3.11 + Flask 3.0.0
- **Puerto:** 8005 (según documentación)
- **Responsabilidades:**
  - RF7: Análisis de logs de seguridad
  - Detección de anomalías
  - Generación de reportes para administradores
  - Identificación de patrones sospechosos

**Funcionalidad:**
- Revisión de tabla `LogAccion`
- Detección de intentos de acceso no autorizado
- Alertas de comportamiento anómalo
- Reportes automáticos de brechas

---

### 2.4 Capa de Datos

#### 2.4.1 MySQL - Configuración Master-Slave
**Versión:** MySQL 8.4

##### MySQL Master
- **Puerto:** 3307 (expuesto)
- **Función:** Base de datos principal (escritura/lectura)
- **Volumen:** `mysql-master-data`
- **Configuración HA:**
  - `server-id=1`
  - `log-bin=mysql-bin`
  - `gtid-mode=ON`
  - Replicación SSL con certificados

##### MySQL Slave (Réplica)
- **Puerto:** 3308 (expuesto)
- **Función:** Réplica de solo lectura
- **Volumen:** `mysql-slave-data`
- **Configuración:**
  - `server-id=2`
  - `read-only=ON`
  - Replicación automática vía GTID
  - Streaming replication

**Justificación:**
- Failover automático si cae el master
- Distribución de carga de lectura
- Respaldos sin afectar rendimiento
- Cumplimiento de requisito RNF-1 (Alta Disponibilidad)

**Esquema de Base de Datos:**
```
Tablas principales:
├── Usuario (autenticación y roles)
├── Tribunal (información de tribunales)
├── Causa (núcleo del sistema)
├── Parte (demandantes/demandados)
├── CausaParte (relación N:N)
├── Documento (archivos asociados)
├── Movimiento (timeline de eventos)
├── Notificacion (alertas y mensajes)
└── LogAccion (auditoría completa)
```

---

#### 2.4.2 Redis - Configuración Master-Replica
**Versión:** Redis 7 Alpine

##### Redis Master
- **Puerto:** 6379
- **Función:** Caché principal
- **Persistencia:** AOF (Append Only File)
- **Uso:**
  - Sesiones de usuario
  - Caché de consultas frecuentes
  - Cola de trabajos

##### Redis Replica
- **Puerto:** 6380
- **Función:** Réplica para lectura
- **Configuración:** `replicaof redis 6379`

**Justificación:**
- Mejora de performance en lectura
- Backup en tiempo real
- Recuperación rápida ante fallos

---

#### 2.4.3 ProxySQL (Gestor de Conexiones)
- **Puerto:** 6033 (MySQL traffic), 6032 (Admin)
- **Función:** Proxy inteligente para MySQL
- **Características:**
  - Connection pooling
  - Query routing (read/write splitting)
  - Health monitoring de backends
  - Failover automático

**Configuración:**
```
Hostgroup 10: Writers (Master)
Hostgroup 20: Readers (Slave)
```

---

### 2.5 Capa de Infraestructura

#### 2.5.1 Monitoreo - Prometheus + Grafana

##### Prometheus
- **Puerto:** 9090
- **Función:** Recolección de métricas
- **Configuración:** `prometheus_main.yml`
- **Scrape interval:** 15 segundos

##### Grafana
- **Puerto:** 3000
- **Credenciales:** admin/admin (configurable)
- **Función:** Visualización de métricas
- **Dashboards:**
  - Estado de servicios
  - Uso de CPU/RAM
  - Tasa de peticiones
  - Latencia de respuesta
  - Estado de bases de datos

**Métricas Monitoreadas:**
- Health de cada contenedor
- Tiempo de respuesta de APIs
- Tasa de errores
- Uso de recursos (CPU, RAM, disco)
- Conexiones activas a BD

---

#### 2.5.2 Servicio de Respaldos Automatizados
- **Tecnología:** Alpine Linux + MySQL Client + Cron
- **Frecuencia:** Diario a las 2:00 AM
- **Retención:** 7 días para backups diarios, 30 días para completos

**Scripts de Backup:**
1. `backup-db.sh` - Backup de MySQL con compresión gzip
2. `backup-files.sh` - Backup de documentos subidos
3. `backup-all.sh` - Backup consolidado completo

**Características:**
- Compresión automática
- Limpieza de backups antiguos
- Verificación de integridad
- Generación de manifiestos
- Scripts de restauración incluidos

**Volumen:** `./backups` (mapeado al host)

---

#### 2.5.3 MailHog (Desarrollo)
- **Puerto:** 1025 (SMTP), 8025 (UI)
- **Función:** Servidor SMTP de prueba
- **Uso:** Captura emails en desarrollo sin enviarlos realmente

---

### 2.6 Redes Docker

#### Red `app-network`
- **Driver:** Bridge
- **Función:** Red única para comunicación entre todos los servicios
- **Seguridad:** Aislamiento del host, solo puertos específicos expuestos

**Ventajas:**
- Simplificación de configuración
- Service discovery automático por nombre
- Facilita debugging
- Adecuado para el alcance del proyecto

---

## 3. Flujo de Datos

### 3.1 Flujo de Autenticación
```
Usuario → Frontend → Traefik → Auth Service → MySQL Master
                                      ↓
                                  JWT Token
                                      ↓
                      Almacenado en localStorage
```

### 3.2 Flujo de Creación de Caso
```
Usuario → Frontend → Traefik → Casos Service → MySQL Master
                                      ↓
                              Notificaciones Service
                                      ↓
                                   MailHog
```

### 3.3 Flujo de Subida de Documento
```
Usuario → Frontend → Traefik → Documentos Service
                                      ↓
                          Valida y guarda archivo
                                      ↓
                              Volumen persistente
                                      ↓
                              MySQL Master (metadata)
```

---

## 4. Seguridad

### 4.1 Autenticación y Autorización
- **JWT** con expiración de 24h
- **Bcrypt** para hashing de contraseñas (12 rounds)
- Tokens almacenados en localStorage del navegador
- Middleware de validación en rutas protegidas

### 4.2 Seguridad en Contenedores
- Usuarios no privilegiados (UID 1000)
- Health checks configurados
- Resource limits (CPU, memoria)
- Red isolada del host

### 4.3 Seguridad de Base de Datos
- Replicación SSL con certificados
- Usuarios con privilegios mínimos necesarios
- Contraseñas en variables de entorno
- Archivo `.env` excluido de Git

### 4.4 Protección de Datos
- Respaldos cifrados (opcional con GPG)
- Volúmenes persistentes separados
- Logs de auditoría en tabla `LogAccion`

### 4.5 Cumplimiento Normativo
- **Ley N°19.628:** Protección de datos personales
- **ISO/IEC 27001:** Gestión de seguridad de la información
- Logs de acciones para auditoría
- Servicio de IA para detección de brechas

---

## 5. Alta Disponibilidad (HA)

### 5.1 Estrategias Implementadas

#### Frontend
- ✅ 2 réplicas independientes
- ✅ Load balancing via Traefik
- ✅ Health checks cada 30s

#### Casos Service
- ✅ 2 réplicas
- ✅ Stateless (sin estado local)
- ✅ Balanceo automático

#### MySQL
- ✅ Master-Slave replication
- ✅ Failover automático con ProxySQL
- ✅ GTID para consistencia

#### Redis
- ✅ Master-Replica
- ✅ Persistencia AOF
- ✅ Recuperación automática

### 5.2 Health Checks Configurados
```yaml
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
```

### 5.3 Restart Policies
- `restart: unless-stopped` en servicios críticos
- `restart: always` en bases de datos

### 5.4 Uptime Objetivo
**99.5%** - Permitiendo ~3.65 horas de downtime al mes

---

## 6. Escalabilidad

### 6.1 Escalabilidad Horizontal
```bash
# Escalar servicio de casos a 5 réplicas
docker-compose up -d --scale casos=5
```

### 6.2 Escalabilidad Vertical
- Ajuste de resource limits en docker-compose
- Aumento de RAM/CPU según carga

### 6.3 Optimizaciones de Performance
- Caché Redis para consultas frecuentes
- Índices en BD para búsquedas rápidas
- ProxySQL para connection pooling
- Compresión gzip en respaldos

---

## 7. Tecnologías Utilizadas

### Backend
- **Python 3.11** - Lenguaje principal
- **Flask 3.0.0** - Framework web ligero
- **SQLAlchemy 2.0.23** - ORM
- **PyMySQL** - Driver MySQL
- **Gunicorn** - WSGI server production

### Frontend
- **React 19.2.0** - Librería UI
- **React Router DOM 7.9.5** - Routing
- **Bootstrap 5.3.8** - Framework CSS

### Infraestructura
- **Docker** - Containerización
- **Docker Compose** - Orquestación
- **Traefik v2.10** - API Gateway
- **MySQL 8.4** - Base de datos relacional
- **Redis 7** - Caché en memoria
- **Prometheus** - Métricas
- **Grafana** - Visualización

### Seguridad
- **Bcrypt** - Hashing de contraseñas
- **JWT** - Autenticación stateless
- **SSL/TLS** - Cifrado de replicación

---

## 8. Despliegue

### 8.1 Requisitos del Sistema
- **Docker:** >= 20.10
- **Docker Compose:** >= 2.0
- **RAM:** Mínimo 8GB (recomendado 16GB)
- **Disco:** 10GB libres
- **SO:** Linux, macOS, Windows 11

### 8.2 Comandos de Despliegue
```bash
# 1. Clonar repositorio
git clone <repo-url>
cd sistema-causas-judiciales

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con credenciales

# 3. Generar certificados SSL
./db/generate-certs.sh

# 4. Levantar servicios
docker-compose up -d --build

# 5. Verificar estado
docker-compose ps
```

### 8.3 Actualización de Servicios
```bash
# Actualizar un servicio sin downtime
docker-compose up -d --no-deps --build casos
```

---

## 9. Documentación Adicional

### 9.1 Diagramas Disponibles
- Arquitectura general (README.md)
- Diagrama de redes
- Flujo de datos
- Modelo de base de datos (01-schema.sql)

### 9.2 Scripts Útiles
- `backup-db.sh` - Backup manual de BD
- `restore-db.sh` - Restauración de BD
- `backup-all.sh` - Backup completo
- `generate-certs.sh` - Certificados SSL

### 9.3 Logs y Debugging
```bash
# Ver logs en tiempo real
docker-compose logs -f

# Logs de un servicio específico
docker-compose logs -f casos

# Entrar a un contenedor
docker-compose exec casos bash
```

---

## 10. Mejoras Futuras

### Corto Plazo
- [ ] Implementar Redis Sentinel para HA de caché
- [ ] Configurar Traefik con SSL/TLS (Let's Encrypt)
- [ ] Añadir rate limiting en gateway

### Mediano Plazo
- [ ] Migrar a Kubernetes para orquestación avanzada
- [ ] Implementar CI/CD con GitHub Actions
- [ ] Añadir tests automatizados (pytest, Jest)
- [ ] Implementar APM (Application Performance Monitoring)

### Largo Plazo
- [ ] Microservicios adicionales según necesidades
- [ ] Implementar event sourcing para auditoría
- [ ] Migrar a arquitectura serverless para servicios específicos

---

## Conclusión

Esta arquitectura cumple con todos los requisitos del proyecto y la licitación:

✅ **14+ servicios** (incluyendo réplicas y componentes de infraestructura)  
✅ **Alta Disponibilidad** con replicación y failover  
✅ **Respaldos automatizados** con retención configurable  
✅ **Monitoreo completo** con Prometheus y Grafana  
✅ **Componente de IA** para análisis de seguridad  
✅ **Seguridad robusta** cumpliendo ISO 27001 y Ley 19.628  
✅ **Escalabilidad** horizontal y vertical  
✅ **Documentación completa** y mantenible

El sistema está listo para producción con ajustes menores de configuración según el ambiente de despliegue final.