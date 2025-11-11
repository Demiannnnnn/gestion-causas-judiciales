# 🤖 Sistema de Failover/Failback Automático

## 📋 Descripción

Sistema de alta disponibilidad automática para MySQL con detección de fallos y recuperación automática.

## 🎯 Características

### 1. **Auto-Failover Daemon**
- Monitorea la salud del master cada 30 segundos
- Ejecuta failover automático tras 3 fallos consecutivos
- Promueve el slave a master automáticamente
- Reconfigura ProxySQL sin intervención manual

### 2. **Auto-Failback Daemon** (Opcional)
- Detecta cuándo el master original se recupera
- Puede notificar para failback manual O ejecutarlo automáticamente
- Espera 5 checks exitosos antes de actuar

### 3. **Notificaciones**
- Soporte para webhooks (Slack, Discord, Teams)
- Notifica eventos críticos: failover, failback, recuperaciones

## 🚀 Uso

### Configuración Inicial

1. **Añadir variables al `.env`:**
```bash
# Auto-Failover
FAILOVER_CHECK_INTERVAL=30
FAILOVER_FAILURE_THRESHOLD=3

# Auto-Failback
FAILBACK_CHECK_INTERVAL=60
FAILBACK_HEALTHY_THRESHOLD=5
AUTO_FAILBACK_ENABLED=false  # true para automático

# Notificaciones (opcional)
FAILOVER_NOTIFICATION_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK
```

2. **Iniciar el sistema:**
```bash
# Con failover automático únicamente
docker-compose up -d

# Con failover Y failback automático
docker-compose --profile failback up -d
```

### Ver Logs

```bash
# Ver logs del daemon de failover
docker logs -f failover-daemon

# Ver logs del daemon de failback
docker logs -f failback-daemon
```

## 📊 Monitoreo

### Ver estado actual
```bash
./scripts/check-replication-status.sh
```

### Verificar que los daemons están corriendo
```bash
docker ps | grep -E "failover|failback"
```

## ⚙️ Configuración Avanzada

### Ajustar Sensibilidad de Failover

Más conservador (menos sensible):
```bash
FAILOVER_CHECK_INTERVAL=60        # Check cada minuto
FAILOVER_FAILURE_THRESHOLD=5      # 5 fallos antes de actuar
```

Más agresivo (más sensible):
```bash
FAILOVER_CHECK_INTERVAL=15        # Check cada 15 segundos
FAILOVER_FAILURE_THRESHOLD=2      # 2 fallos antes de actuar
```

### Habilitar Failback Automático

**⚠️ PRECAUCIÓN:** Solo habilita esto si estás seguro de que el master original está completamente recuperado.

```bash
AUTO_FAILBACK_ENABLED=true
FAILBACK_HEALTHY_THRESHOLD=10     # Más checks = más seguro
```

## 🔧 Comandos Manuales

Los scripts originales siguen disponibles:

```bash
# Failover manual
sudo ./scripts/failover-promote-slave.sh

# Failover automático (sin confirmación)
sudo ./scripts/failover-promote-slave.sh -y

# Failback manual
sudo ./scripts/failback-restore-master.sh

# Failback automático (sin confirmación)
sudo ./scripts/failback-restore-master.sh -y
```

## 🎛️ Detener Auto-Failover

```bash
# Detener solo failover automático
docker stop failover-daemon

# Detener ambos
docker stop failover-daemon failback-daemon

# Deshabilitar permanentemente
docker-compose stop failover-daemon failback-daemon
```

## 📝 Logs y Eventos

Los daemons registran:
- ✅ Checks de salud exitosos
- ⚠️ Advertencias de fallos
- 🔥 Inicio de failover/failback
- ✅ Completación exitosa
- ❌ Errores

## 🧪 Probar el Sistema

### Simular caída del master
```bash
docker stop db-master
# Espera ~90 segundos (3 checks × 30s)
# El failover debería ejecutarse automáticamente
```

### Verificar failover
```bash
docker exec db-proxy mysql -h127.0.0.1 -P6032 -uadmin -padmin \
  -e "SELECT hostgroup_id, hostname, status FROM mysql_servers;"
```

### Restaurar master
```bash
docker start db-master
# Si AUTO_FAILBACK_ENABLED=true, esperará 5 checks exitosos
# Si es false, recibirás una notificación para failback manual
```

## 🚨 Troubleshooting

### El daemon no inicia
```bash
# Verificar logs
docker logs failover-daemon

# Verificar que tiene acceso a Docker socket
docker exec failover-daemon docker ps
```

### Failover no se ejecuta
- Verifica `FAILOVER_FAILURE_THRESHOLD` en `.env`
- Revisa logs: `docker logs failover-daemon`
- Comprueba que el slave esté saludable

### Notificaciones no llegan
- Prueba el webhook manualmente con `curl`
- Verifica la variable `FAILOVER_NOTIFICATION_WEBHOOK`

## 🏗️ Arquitectura

```
┌─────────────────┐
│ Failover Daemon │──┐
└─────────────────┘  │
                     ├──> Check Master Health (30s)
┌─────────────────┐  │         │
│ Failback Daemon │──┘         │
└─────────────────┘            ├─> Master DOWN × 3
                               │
                               ├─> Execute Failover
                               │
                               ├─> Promote Slave
                               │
                               └─> Update ProxySQL
```

## 📚 Referencias

- Scripts base: `failover-promote-slave.sh`, `failback-restore-master.sh`
- Configuración: `.env`
- Monitoreo: `check-replication-status.sh`
