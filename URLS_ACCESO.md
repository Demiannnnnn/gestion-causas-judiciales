# 🌐 URLs de Acceso al Proyecto

## URL Principal del Proyecto

### Producción Local
```
http://causas-judiciales.local:8081
```

### Alternativa (Localhost)
```
http://localhost:8081
```

---

## 📋 Panel de Servicios

| Servicio | URL | Credenciales | Descripción |
|----------|-----|--------------|-------------|
| **🏠 Aplicación Principal** | http://causas-judiciales.local:8081 | Ver abajo | Sistema de Gestión de Causas Judiciales |
| **🔧 Traefik Dashboard** | http://localhost:8080/dashboard/ | - | Monitor del API Gateway |
| **📊 Grafana** | http://localhost:3000 | admin/admin | Dashboards y métricas |
| **🔍 Prometheus** | http://localhost:9090 | - | Motor de métricas |
| **📧 MailHog** | http://localhost:8025 | - | Testing de emails |
| **🗄️ ProxySQL Admin** | http://localhost:6032 | admin/admin | Gestión de MySQL Proxy |

---

## 🔐 Usuarios de Prueba (Aplicación)

### Administrador
```
Usuario: admin@causas.cl
Password: Admin2024!
```

### Abogado
```
Usuario: abogado@causas.cl
Password: Abogado2024!
```

### Asistente
```
Usuario: asistente@causas.cl
Password: Asistente2024!
```

---

## 🛠️ Configuración del Dominio Local

Para que funcione `causas-judiciales.local`, se agregó esta entrada al archivo `/etc/hosts`:

```bash
127.0.0.1    causas-judiciales.local
```

### Ver configuración actual:
```bash
cat /etc/hosts | grep causas-judiciales
```

### Editar manualmente (si es necesario):
```bash
sudo nano /etc/hosts
```

---

## 🌐 Otras Opciones de Dominios Locales

Si quieres cambiar el dominio, puedes usar cualquiera de estos:

### Opción 1: Estilo Empresarial
```
gestion-causas.local
tribunal-digital.local
sistema-judicial.local
```

### Opción 2: Estilo Desarrollo
```
causas.dev.local
app-causas.local
judicial-system.local
```

### Opción 3: Con TLD fake
```
causas.test
tribunal.dev
judicial.app
```

### Para cambiar el dominio:

1. **Edita `/etc/hosts`:**
   ```bash
   sudo nano /etc/hosts
   ```
   Cambia o agrega:
   ```
   127.0.0.1    [tu-nuevo-dominio]
   ```

2. **Edita `docker-compose.yml`:**
   ```yaml
   - "traefik.http.routers.frontend.rule=Host(`[tu-nuevo-dominio]`) || Host(`localhost`)"
   ```

3. **Reinicia los servicios:**
   ```bash
   docker-compose restart gateway frontend
   ```

---

## 🚀 Acceso desde Otros Dispositivos (Red Local)

Si quieres acceder desde tu teléfono o tablet en la misma red WiFi:

1. **Obtén tu IP local:**
   ```bash
   ipconfig getifaddr en0  # WiFi
   # o
   ipconfig getifaddr en1  # Ethernet
   ```
   Ejemplo: `192.168.1.100`

2. **Accede desde otro dispositivo:**
   ```
   http://192.168.1.100:8081
   ```

---

## 📝 Notas Importantes

- ✅ El dominio `.local` solo funciona en tu computadora
- ✅ Mantiene `localhost` como alternativa por compatibilidad
- ✅ No requiere cambios en el código de la aplicación
- ✅ Ideal para demos y presentaciones
- ✅ Se ve más profesional que `localhost`

---

## 🎯 Para la Presentación/Defensa

Cuando presentes tu proyecto, puedes usar:

```
http://causas-judiciales.local:8081
```

Esto se ve más profesional que mostrar "localhost" en pantalla.

---

## 🔄 Comandos Útiles

### Verificar que el dominio funcione:
```bash
ping causas-judiciales.local
curl -I http://causas-judiciales.local:8081
```

### Ver todos los dominios locales configurados:
```bash
cat /etc/hosts
```

### Limpiar cache DNS (si no funciona):
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### Abrir automáticamente en el navegador:
```bash
open http://causas-judiciales.local:8081
```

---

**Configurado**: 10 de noviembre de 2025  
**Dominio Principal**: `causas-judiciales.local:8081`  
**Estado**: ✅ Funcional
