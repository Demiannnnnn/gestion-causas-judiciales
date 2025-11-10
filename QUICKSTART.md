# 🚀 Guía de Inicio Rápido - Configuraciones Dinámicas con Alpine

## ⚡ Inicio en 3 Pasos

### 1️⃣ Preparar Variables de Entorno
```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Validar que todas las variables estén configuradas
./scripts/validate-env.sh
```

### 2️⃣ Iniciar Sistema
```bash
# Opción A: Script automatizado (recomendado)
./start.sh

# Opción B: Docker Compose directo
docker compose up -d
```

### 3️⃣ Verificar Estado
```bash
# Ver estado de contenedores
docker compose ps

# Ver logs de inicialización de configs
./scripts/manage-configs.sh logs
```

---

## 📦 ¿Qué Incluye?

Este sistema implementa **configuración dinámica** usando contenedores Alpine para:

- ✅ **Prometheus** - Métricas y monitoreo
- ✅ **Redis** - Caché con autenticación
- ✅ **ProxySQL** - Proxy de base de datos con routing
- ✅ **Traefik** - API Gateway y reverse proxy

---

## 🔧 Comandos Útiles

### Gestión de Configuraciones
```bash
# Ver estado de init containers
./scripts/manage-configs.sh status

# Ver logs detallados
./scripts/manage-configs.sh logs

# Ver logs de un servicio específico
./scripts/manage-configs.sh logs prometheus
./scripts/manage-configs.sh logs redis

# Regenerar todas las configuraciones
./scripts/manage-configs.sh clean
docker compose up -d
```

### Administración del Sistema
```bash
# Ver servicios en ejecución
docker compose ps

# Ver logs en tiempo real
docker compose logs -f [servicio]

# Reiniciar un servicio
docker compose restart [servicio]

# Detener todo el sistema
docker compose down

# Detener y eliminar volúmenes
docker compose down -v
```

### Inspeccionar Configuraciones Generadas
```bash
# Ver config de Prometheus
docker run --rm -v proy2_prometheus-config:/c alpine cat /c/prometheus.yml

# Ver config de Redis (sin contraseñas)
docker run --rm -v proy2_redis-config:/c alpine grep -v "password" /c/redis.conf

# Ver config de ProxySQL
docker run --rm -v proy2_proxysql-config:/c alpine cat /c/proxysql.cnf
```

---

## 🌐 Servicios Disponibles

Una vez iniciado el sistema, accede a:

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **Frontend** | http://localhost:8081 | - |
| **API** | http://localhost:8081/api | - |
| **Traefik Dashboard** | http://localhost:8080 | - |
| **Prometheus** | http://localhost:9090 | - |
| **Grafana** | http://localhost:3000 | admin / admin |
| **MailHog** | http://localhost:8025 | - |
| **MySQL Master** | localhost:3307 | Ver .env |
| **MySQL Slave** | localhost:3308 | Ver .env |
| **Redis** | localhost:6379 | Ver .env |
| **ProxySQL Admin** | localhost:6032 | Ver .env |

---

## 🔄 Flujo de Trabajo Típico

### Modificar Configuración
```bash
# 1. Editar variables
nano .env

# 2. Limpiar configs anteriores  
./scripts/manage-configs.sh clean

# 3. Reiniciar sistema (regenera configs)
docker compose up -d

# 4. Verificar nueva configuración
./scripts/manage-configs.sh logs
```

### Troubleshooting
```bash
# Ver estado completo
docker compose ps
./scripts/manage-configs.sh status

# Ver logs de error
docker compose logs [servicio]

# Reinicio completo
docker compose down
docker volume prune -f
./start.sh
```

---

## 📋 Variables Importantes

### Base de Datos
```bash
MYSQL_ROOT_PASSWORD=...
MYSQL_DATABASE=...
MYSQL_USER=...
MYSQL_PASSWORD=...
```

### Redis
```bash
REDIS_PASSWORD=...
REDIS_MAX_MEMORY=256mb
REDIS_DATABASES=16
```

### Prometheus
```bash
PROMETHEUS_SCRAPE_INTERVAL=15s
PROMETHEUS_EVALUATION_INTERVAL=15s
```

### ProxySQL
```bash
PROXYSQL_ADMIN_USER=admin
PROXYSQL_ADMIN_PASSWORD=...
MYSQL_MASTER_HOST=db-master
MYSQL_SLAVE_HOST=db-slave
```

Ver archivo `.env.example` para la lista completa.

---

## 📚 Documentación Detallada

- **Arquitectura Completa:** [docs/ALPINE_ARCHITECTURE.md](docs/ALPINE_ARCHITECTURE.md)
- **Sistema de Configuración:** [docs/CONFIG-INIT-SYSTEM.md](docs/CONFIG-INIT-SYSTEM.md)
- **Resumen de Implementación:** [ALPINE_CONFIGS_SUMMARY.md](ALPINE_CONFIGS_SUMMARY.md)

---

## ❓ Preguntas Frecuentes

**P: ¿Por qué usar Alpine containers?**  
R: Son ultra ligeros (~5MB), seguros, y perfectos para tareas de inicialización.

**P: ¿Qué pasa si cambio una variable en .env?**  
R: Debes regenerar las configuraciones ejecutando `clean` y luego `up -d`.

**P: ¿Puedo ver las configuraciones generadas?**  
R: Sí, usa los comandos de inspección de volúmenes mostrados arriba.

**P: ¿Los init containers siguen ejecutándose?**  
R: No, terminan automáticamente después de generar las configuraciones.

**P: ¿Es seguro versionar los templates?**  
R: Sí, los templates no contienen credenciales, solo placeholders.

---

## 🆘 Soporte

Si encuentras problemas:

1. Revisa los logs: `./scripts/manage-configs.sh logs`
2. Valida las variables: `./scripts/validate-env.sh`
3. Verifica el estado: `docker compose ps`
4. Consulta la documentación completa en `docs/`

---

**¡Listo para empezar! 🎉**

Ejecuta `./start.sh` y el sistema se configurará automáticamente.
