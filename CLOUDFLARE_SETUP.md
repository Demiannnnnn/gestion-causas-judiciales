# 🔐 Guía de Configuración de Cloudflare Tunnel con HTTPS

Esta guía te ayudará a exponer tu aplicación de forma segura usando Cloudflare Tunnel con certificado HTTPS automático.

## 📋 Prerrequisitos

- Dominio registrado en Cloudflare (ya lo tienes)
- Cloudflare CLI instalado (cloudflared) ✅
- Registros DNS antiguos eliminados ✅
- Cuenta de Cloudflare con el dominio activo

---

## 🚀 Paso 1: Autenticación en Cloudflare

Primero necesitas autenticarte con tu cuenta de Cloudflare:

```bash
cloudflared tunnel login
```

Esto abrirá tu navegador y te pedirá que:
1. Inicies sesión en Cloudflare
2. Selecciones el dominio que quieres usar
3. Autorices el acceso

Después de completar el proceso, se creará un archivo de certificado en:
- **macOS/Linux**: `~/.cloudflared/cert.pem`
- **Windows**: `%USERPROFILE%\.cloudflared\cert.pem`

---

## 🔧 Paso 2: Crear el Tunnel

Ejecuta este comando para crear un nuevo tunnel (reemplaza `mi-app-judicial` con el nombre que prefieras):

```bash
cloudflared tunnel create mi-app-judicial
```

Este comando:
- Creará un nuevo tunnel en tu cuenta de Cloudflare
- Generará un **Tunnel ID** (guárdalo, lo necesitarás)
- Creará un archivo de credenciales en `~/.cloudflared/TUNNEL_ID.json`

**Ejemplo de output:**
```
Created tunnel mi-app-judicial with id 12345678-abcd-1234-efgh-1234567890ab
```

**Copia el Tunnel ID que aparece en el output.**

---

## 📁 Paso 3: Copiar el Archivo de Credenciales

El archivo de credenciales está en tu home directory. Necesitas copiarlo al directorio del proyecto:

```bash
# Encuentra el archivo (reemplaza TUNNEL_ID con tu ID real)
ls ~/.cloudflared/*.json

# Cópialo al directorio cloudflare del proyecto
cp ~/.cloudflared/TUNNEL_ID.json /Users/demianmaturana/Desktop/ProyectoLicitacion_Admin2025_2/cloudflare/credentials.json
```

**Ejemplo práctico:**
```bash
# Si tu tunnel ID es 12345678-abcd-1234-efgh-1234567890ab
cp ~/.cloudflared/12345678-abcd-1234-efgh-1234567890ab.json /Users/demianmaturana/Desktop/ProyectoLicitacion_Admin2025_2/cloudflare/credentials.json
```

---

## ⚙️ Paso 4: Configurar el archivo config.yml

Edita el archivo `/Users/demianmaturana/Desktop/ProyectoLicitacion_Admin2025_2/cloudflare/config.yml`:

```yaml
tunnel: TU_TUNNEL_ID_AQUI
credentials-file: /etc/cloudflared/credentials.json

ingress:
  # Ruta principal - Frontend
  - hostname: tudominio.com
    service: http://gateway:80
    originRequest:
      noTLSVerify: true

  # Dashboard de Traefik (opcional)
  - hostname: dashboard.tudominio.com
    service: http://gateway:8080
    originRequest:
      noTLSVerify: true

  # Grafana para monitoreo (opcional)
  - hostname: grafana.tudominio.com
    service: http://grafana:3000
    originRequest:
      noTLSVerify: true

  # Regla catch-all (obligatoria)
  - service: http_status:404
```

**Reemplaza:**
- `TU_TUNNEL_ID_AQUI` → con tu Tunnel ID real
- `tudominio.com` → con tu dominio real (ejemplo: `licitaciones.com`)

---

## 🌐 Paso 5: Configurar DNS en Cloudflare Dashboard

Ve al [Dashboard de Cloudflare](https://dash.cloudflare.com) y sigue estos pasos:

### 5.1 Acceder a tu dominio
1. Inicia sesión en Cloudflare
2. Selecciona tu dominio de la lista

### 5.2 Ir a DNS Records
1. Click en el menú lateral: **DNS** → **Records**
2. Aquí configurarás los registros CNAME

### 5.3 Crear Registros CNAME

**Necesitas crear un registro CNAME por cada hostname que configuraste:**

#### Registro Principal (Frontend)
- **Type**: CNAME
- **Name**: `@` (o tu dominio raíz)
- **Target**: `TU_TUNNEL_ID.cfargotunnel.com`
- **Proxy status**: ✅ Proxied (nube naranja)
- **TTL**: Auto

#### Dashboard de Traefik (Opcional)
- **Type**: CNAME
- **Name**: `dashboard`
- **Target**: `TU_TUNNEL_ID.cfargotunnel.com`
- **Proxy status**: ✅ Proxied
- **TTL**: Auto

#### Grafana (Opcional)
- **Type**: CNAME
- **Name**: `grafana`
- **Target**: `TU_TUNNEL_ID.cfargotunnel.com`
- **Proxy status**: ✅ Proxied
- **TTL**: Auto

**Ejemplo con un Tunnel ID real:**
Si tu Tunnel ID es `12345678-abcd-1234-efgh-1234567890ab`, el target sería:
```
12345678-abcd-1234-efgh-1234567890ab.cfargotunnel.com
```

---

## 🎯 Paso 6: Vincular el Tunnel con DNS (Método Alternativo)

También puedes vincular el tunnel usando el CLI (más rápido):

```bash
# Para el dominio principal
cloudflared tunnel route dns mi-app-judicial tudominio.com

# Para subdominios
cloudflared tunnel route dns mi-app-judicial dashboard.tudominio.com
cloudflared tunnel route dns mi-app-judicial grafana.tudominio.com
```

Este comando crea automáticamente los registros CNAME en Cloudflare.

---

## 🐳 Paso 7: Actualizar Variables de Entorno

Edita tu archivo `.env` y añade:

```bash
# Cloudflare Tunnel
CLOUDFLARE_TUNNEL_ID=tu-tunnel-id-real
CLOUDFLARE_DOMAIN=tudominio.com
```

---

## 🚀 Paso 8: Levantar el Sistema con Cloudflare

```bash
# Detener el sistema si está corriendo
docker-compose down

# Levantar todos los servicios incluyendo cloudflared
docker-compose up -d

# Ver los logs de cloudflared
docker-compose logs -f cloudflared
```

**Deberías ver en los logs:**
```
INF Connection established connIndex=0
INF Registered tunnel connection connIndex=0
```

---

## ✅ Paso 9: Verificar que Todo Funciona

### Verificar el Tunnel
```bash
# Ver el estado del tunnel
cloudflared tunnel info mi-app-judicial

# Listar todos tus tunnels
cloudflared tunnel list
```

### Probar en el Navegador
1. Abre tu navegador
2. Ve a: `https://tudominio.com`
3. Deberías ver tu aplicación con HTTPS ✅
4. Click en el candado del navegador para verificar el certificado SSL

### Verificar Subdominios (si los configuraste)
- Dashboard: `https://dashboard.tudominio.com`
- Grafana: `https://grafana.tudominio.com`

---

## 🔍 Verificación de Contenedores

Verifica que el contenedor de cloudflared esté corriendo:

```bash
docker-compose ps cloudflared
```

**Output esperado:**
```
NAME          IMAGE                          STATUS
cloudflared   cloudflare/cloudflared:latest  Up X minutes
```

---

## 🐛 Solución de Problemas

### ❌ Error: "credentials file not found"
**Solución:**
```bash
# Verifica que el archivo existe
ls -la /Users/demianmaturana/Desktop/ProyectoLicitacion_Admin2025_2/cloudflare/credentials.json

# Si no existe, cópialo desde ~/.cloudflared/
cp ~/.cloudflared/TU_TUNNEL_ID.json cloudflare/credentials.json
```

### ❌ Error: "tunnel with name already exists"
**Solución:**
```bash
# Lista tus tunnels existentes
cloudflared tunnel list

# Elimina el tunnel duplicado
cloudflared tunnel delete TUNNEL_ID

# O usa el existente (obtén el ID y úsalo en config.yml)
```

### ❌ Error: "no such host"
**Causa**: Los registros DNS no están configurados correctamente.

**Solución:**
1. Ve al Dashboard de Cloudflare → DNS
2. Verifica que existan los registros CNAME
3. Verifica que apunten a `TUNNEL_ID.cfargotunnel.com`
4. Espera 2-5 minutos para propagación DNS

### ❌ El sitio no carga (ERR_CONNECTION_REFUSED)
**Solución:**
```bash
# Verifica que todos los servicios estén corriendo
docker-compose ps

# Verifica logs de cloudflared
docker-compose logs -f cloudflared

# Verifica logs del gateway
docker-compose logs -f gateway

# Reinicia cloudflared
docker-compose restart cloudflared
```

### ⚠️ Certificado SSL no válido
**Causa**: Cloudflare aún no ha emitido el certificado.

**Solución:**
1. Ve a Cloudflare Dashboard → SSL/TLS
2. Verifica que el modo SSL sea "Full" o "Full (strict)"
3. Espera 5-10 minutos para que Cloudflare emita el certificado
4. Limpia caché del navegador

---

## 🔐 Configuración de Seguridad Adicional (Opcional)

### Habilitar WAF (Web Application Firewall)
1. Dashboard de Cloudflare → Security → WAF
2. Activa las reglas de seguridad recomendadas

### Configurar SSL/TLS
1. Dashboard → SSL/TLS → Overview
2. Modo recomendado: **Full (strict)**
3. Habilita: Always Use HTTPS
4. Habilita: Automatic HTTPS Rewrites

### Rate Limiting
1. Dashboard → Security → Rate Limiting
2. Crea reglas para proteger endpoints críticos

---

## 📊 Monitoreo del Tunnel

### Ver estadísticas en Cloudflare
1. Dashboard → Traffic → Analytics
2. Verás requests, bandwidth, y errores

### Ver logs en tiempo real
```bash
docker-compose logs -f cloudflared
```

### Ver conexiones activas
```bash
cloudflared tunnel info mi-app-judicial
```

---

## 🔄 Actualizar Configuración

Si cambias el archivo `config.yml`:

```bash
# Reinicia el servicio cloudflared
docker-compose restart cloudflared

# Ver los logs para verificar
docker-compose logs -f cloudflared
```

---

## 🛑 Detener o Eliminar el Tunnel

### Detener temporalmente
```bash
docker-compose stop cloudflared
```

### Eliminar el tunnel completamente
```bash
# Detener el servicio
docker-compose stop cloudflared

# Eliminar el tunnel de Cloudflare
cloudflared tunnel delete mi-app-judicial

# Eliminar registros DNS desde Cloudflare Dashboard
```

---

## 📞 Resumen de Comandos Importantes

```bash
# Autenticación
cloudflared tunnel login

# Crear tunnel
cloudflared tunnel create mi-app-judicial

# Listar tunnels
cloudflared tunnel list

# Info de un tunnel
cloudflared tunnel info TUNNEL_NAME

# Configurar DNS
cloudflared tunnel route dns TUNNEL_NAME tudominio.com

# Copiar credenciales
cp ~/.cloudflared/TUNNEL_ID.json cloudflare/credentials.json

# Levantar sistema
docker-compose up -d

# Ver logs
docker-compose logs -f cloudflared

# Reiniciar
docker-compose restart cloudflared
```

---

## ✅ Checklist de Setup Exitoso

- [ ] Ejecutaste `cloudflared tunnel login`
- [ ] Creaste el tunnel con `cloudflared tunnel create`
- [ ] Copiaste el archivo de credenciales a `cloudflare/credentials.json`
- [ ] Actualizaste `cloudflare/config.yml` con tu Tunnel ID y dominio
- [ ] Configuraste los registros CNAME en Cloudflare Dashboard
- [ ] Actualizaste el archivo `.env` con las variables de Cloudflare
- [ ] Levantaste el sistema con `docker-compose up -d`
- [ ] Verificaste que cloudflared está corriendo: `docker-compose ps cloudflared`
- [ ] Probaste acceder a `https://tudominio.com` en el navegador
- [ ] Verificaste el certificado SSL (candado verde)

**Si completaste todo ✅, tu aplicación está en producción con HTTPS!**

---

## 🎯 ¿Necesitas Ayuda?

- **Documentación oficial**: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **Revisar logs**: `docker-compose logs -f cloudflared`
- **Estado de Cloudflare**: https://www.cloudflarestatus.com/
