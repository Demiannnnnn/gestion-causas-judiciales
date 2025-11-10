# 🔧 INSTALACIÓN DEL AUTO-FAILOVER (VERSIÓN CORRECTA)

## ❌ Problema con la versión anterior:
- Docker-in-Docker es complejo y tiene problemas de permisos
- Los contenedores Alpine no pueden ejecutar `docker exec` fácilmente contra el host

## ✅ Solución: Ejecutar como servicio systemd en el HOST

### Opción 1: Servicio systemd (RECOMENDADO para producción)

```bash
# 1. Copiar el archivo de servicio
sudo cp scripts/systemd/auto-failover.service /etc/systemd/system/

# 2. Ajustar la ruta en el archivo si es necesario
sudo nano /etc/systemd/system/auto-failover.service
# Cambiar WorkingDirectory a la ruta real de tu proyecto

# 3. Recargar systemd
sudo systemctl daemon-reload

# 4. Habilitar e iniciar el servicio
sudo systemctl enable auto-failover
sudo systemctl start auto-failover

# 5. Ver logs
sudo journalctl -u auto-failover -f

# 6. Ver estado
sudo systemctl status auto-failover
```

### Opción 2: Screen/Tmux (Para desarrollo/testing)

```bash
# Iniciar en una sesión screen
screen -S failover-daemon
cd /home/lambda/Trabajos_UwU/admin/proy2
sudo ./scripts/auto-failover-host.sh

# Detach: Ctrl+A, luego D
# Reattach: screen -r failover-daemon
```

### Opción 3: nohup (Simple background)

```bash
cd /home/lambda/Trabajos_UwU/admin/proy2
nohup sudo ./scripts/auto-failover-host.sh &

# Ver logs
tail -f logs/failover-daemon.log
```

## 📋 Configuración

Las mismas variables del `.env` funcionan:

```bash
FAILOVER_CHECK_INTERVAL=30
FAILOVER_FAILURE_THRESHOLD=3
FAILOVER_NOTIFICATION_WEBHOOK=
FAILOVER_LOG_FILE=./logs/failover-daemon.log
```

## 🧪 Probar

```bash
# Ver logs en tiempo real
tail -f logs/failover-daemon.log

# Simular caída
docker stop db-master

# Ver que el daemon detecta y ejecuta failover
```

## 🛑 Detener

```bash
# Con systemd
sudo systemctl stop auto-failover

# Con screen
screen -r failover-daemon
# Luego Ctrl+C

# Con nohup
sudo pkill -f auto-failover-host.sh
```

## ✅ Ventajas de esta solución:

1. **Funciona realmente** - No hay problemas de Docker-in-Docker
2. **Más simple** - Un solo script en el host
3. **Mejor rendimiento** - No overhead de contenedores extra
4. **Logs claros** - En archivo o systemd journal
5. **Más confiable** - El daemon no depende de Docker compose

## 🔄 Migración desde docker-compose

Si ya iniciaste con docker-compose, puedes:

```bash
# Detener los contenedores de failover
docker-compose stop failover-daemon failback-daemon

# Iniciar el servicio del host
sudo systemctl start auto-failover
```

## 📊 Comparación:

| Aspecto | Contenedor | Host (systemd) |
|---------|------------|----------------|
| Complejidad | Alta | Baja |
| Permisos | Problemático | Simple |
| Funciona | ❌ Dudoso | ✅ Sí |
| Logs | docker logs | journalctl/file |
| Performance | Media | Alta |
| Dependencias | Docker-in-Docker | Solo Docker |

## 💡 Recomendación:

**USA LA VERSIÓN SYSTEMD** (`auto-failover-host.sh`) para que realmente funcione sin problemas.
