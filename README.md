# 🏛️ Sistema de Gestión de Causas Judiciales

## 📋 Información del Proyecto

### Licitación
- **Código**: 1552-56-LE25
- **Nombre**: Sistema Informático de Gestión de Causas Judiciales
- **Link**: [Ver licitación en Mercado Público](http://www.mercadopublico.cl/Procurement/Modules/RFB/DetailsAcquisition.aspx?qs=tyy5Bzwfkbwk7fVwIC5aDA==)

### Integrantes del Equipo
- Camilo Fuentes
- Demian Maturana
- Catalina Herrera

### ¿Qué resuelve este sistema?
El sistema moderniza y digitaliza la gestión integral de causas judiciales, proporcionando una plataforma web centralizada que permite:
- ✅ Registro y seguimiento de procesos judiciales
- ✅ Gestión documental completa
- ✅ Notificaciones automáticas a las partes
- ✅ Generación de reportes y estadísticas
- ✅ Control de acceso según roles y permisos
- ✅ Análisis de seguridad con IA

---

## 🏗️ Arquitectura del Sistema

### Diagrama de Arquitectura
```
                    ┌─────────────────┐
                    │   USUARIOS      │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   FRONTEND      │
                    │ (React + Nginx) │
                    │   2 Réplicas    │
                    └────────┬────────┘
                             │
┌────────────────────────────▼─────────────────────────────┐
│                     API GATEWAY (Traefik)                 │
│                    Load Balancer + Routing                │
└──┬────────┬────────┬────────┬────────┬────────┬─────────┘
   │        │        │        │        │        │
   ▼        ▼        ▼        ▼        ▼        ▼
┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐
│ Auth │ │Casos │ │ Docs │ │Notif │ │  AI  │ │Report│
│Service│ │Service│ │Service│ │Service│ │Service│ │Service│
└───┬──┘ └───┬──┘ └───┬──┘ └───┬──┘ └──┬─┘ └───┬──┘
    │        │        │        │       │       │
    └────────┴────────┴────────┴───────┴───────┘
                      │
         ┌────────────┼────────────┐
         │            │            │
    ┌────▼────┐  ┌───▼────┐  ┌───▼────┐
    │  MySQL  │  │ Redis  │  │ MinIO  │
    │ Master  │  │ Master │  │(Docs)  │
    └────┬────┘  └───┬────┘  └────────┘
         │           │
    ┌────▼────┐  ┌───▼────┐
    │  MySQL  │  │ Redis  │
    │ Replica │  │Replica │
    └─────────┘  └────────┘
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

## 🚀 Alta Disponibilidad (HA)

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
Durante la presentación mostraremos:
1. Sistema funcionando con todas las réplicas activas
2. Detener manualmente una réplica de MySQL
3. Sistema continúa operando sin interrupciones
4. Réplica se recupera automáticamente

---

## 🤖 Componente de Inteligencia Artificial

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

## 📦 Instalación y Uso

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

# Editar el archivo .env con tus credenciales
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

#### Usuarios de Prueba
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

## 💾 Sistema de Respaldos

### Scripts de Backup

#### Ejecución Manual
```bash
# Backup de base de datos
docker exec backup-service /app/backup-db.sh

# Backup de documentos
docker exec backup-service /app/backup-files.sh
```

#### Automatización
Los backups se ejecutan automáticamente:
- **Frecuencia**: Diariamente a las 2:00 AM
- **Retención**: Se mantienen los últimos 7 días
- **Ubicación**: Volumen `backup-storage`

#### Listar Backups Disponibles
```bash
docker exec backup-service ls -lh /backups
```

### Restauración de Datos

#### Restaurar Base de Datos
```bash
# Listar backups disponibles
docker exec backup-service ls /backups

# Restaurar un backup específico
docker exec backup-service /app/restore-db.sh causas_judiciales_2024-10-31.sql.gz
```

#### Restaurar Documentos
```bash
docker exec backup-service /app/restore-files.sh documentos_2024-10-31.tar.gz
```

### Documentación Completa
Ver: [docs/backup-recovery.md](docs/backup-recovery.md)

---

## 📊 Monitoreo del Sistema

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

## 🧪 Testing y Validación

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

## 📁 Estructura del Proyecto

```
sistema-causas-judiciales/
│
├── docker-compose.yml           # Configuración principal de Docker
├── .env.example                 # Template de variables
├── .env                         # Variables reales (NO commitear)
├── .gitignore                   # Archivos ignorados por Git
├── README.md                    # Este archivo
│
├── docs/                        # Documentación técnica
│   ├── arquitectura.md          # Detalles de arquitectura
│   ├── backup-recovery.md       # Guía de respaldos
│   ├── deployment.md            # Guía de despliegue
│   └── diagramas/               # Diagramas visuales
│       ├── arquitectura.png
│       ├── redes-docker.png
│       └── alta-disponibilidad.png
│
├── services/                    # Código de microservicios
│   ├── frontend/                # React + Nginx
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   └── src/
│   │
│   ├── auth-service/            # Autenticación
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── app/
│   │
│   ├── casos-service/           # Gestión de causas
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── app/
│   │
│   ├── documentos-service/      # Gestión de documentos
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── app/
│   │
│   ├── notificaciones-service/  # Notificaciones
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── app/
│   │
│   └── ai-service/              # Análisis con IA
│       ├── Dockerfile
│       ├── requirements.txt
│       └── app/
│
├── infrastructure/              # Configuraciones de infraestructura
│   ├── database/
│   │   ├── mysql/
│   │   │   ├── master/
│   │   │   │   ├── init.sql
│   │   │   │   └── my.cnf
│   │   │   └── replica/
│   │   │       └── my.cnf
│   │   └── redis/
│   │       └── redis.conf
│   │
│   └── monitoring/
│       ├── prometheus/
│       │   └── prometheus.yml
│       └── grafana/
│           └── provisioning/
│
└── scripts/                     # Scripts de utilidad
    ├── backup/
    │   ├── Dockerfile
    │   ├── backup-db.sh
    │   ├── backup-files.sh
    │   ├── restore-db.sh
    │   └── restore-files.sh
    │
    └── init/
        └── setup-replication.sh
```

---

## 👥 Roles del Equipo

### Camilo Fuentes - Infraestructura
- Docker Compose
- Redes y volúmenes
- Alta disponibilidad
- Sistema de respaldos

### Demian Maturana - Backend
- Microservicios
- Bases de datos
- Replicación de BD
- APIs REST

### Catalina Herrera - Frontend y AI
- Interfaz React
- Componente IA
- Documentación
- Testing

---

## 🐛 Troubleshooting

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

## 📞 Contacto

Para preguntas sobre el proyecto:
- Camilo Fuentes: [email]
- Demian Maturana: [email]
- Catalina Herrera: [email]

**Profesor**: Ricardo Pérez (riperez@utalca.cl)