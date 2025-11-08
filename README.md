<<<<<<< HEAD
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