# Configuración HTTPS con Certificados Auto-Firmados

## Resumen

Se ha implementado HTTPS en toda la aplicación usando certificados auto-firmados, eliminando todas las referencias a Cloudflare.

## Cambios Realizados

### 1. Certificados SSL Auto-Firmados

- **Ubicación**: `api-gateway/certs-local/`
- **Archivos generados**:
  - `cert.pem`: Certificado público
  - `key.pem`: Clave privada
- **Comando usado**:
  ```bash
  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=localhost"
  ```
- **Validez**: 365 días

### 2. Configuración de Traefik (`generated-config/traefik.yml`)

```yaml
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: default

tls:
  certificates:
    - certFile: /certs/cert.pem
      keyFile: /certs/key.pem
```

### 3. Servicios Backend Actualizados

Todos los servicios backend ahora usan HTTPS:

- ✅ `autenticacion` - https://localhost/api/auth
- ✅ `casos` - https://localhost/api/casos
- ✅ `documentos` - https://localhost/api/documentos
- ✅ `notificaciones` - https://localhost/api/notificaciones
- ✅ `reportes` - https://localhost/api/reportes
- ✅ `ia-seguridad` - https://localhost/api/ia-seguridad

### 4. Labels de Traefik

Todos los routers ahora incluyen:

```yaml
- "traefik.http.routers.<servicio>.entrypoints=websecure"
- "traefik.http.routers.<servicio>.tls=true"
- "traefik.docker.network=licitacion_sistemacausasjudiciales_backend-network"
```

### 5. Corrección de Nombres de Red

Se corrigieron todas las referencias de red incorrectas:

- ❌ `proyectolicitacion_admin2025_2_backend-network`
- ✅ `licitacion_sistemacausasjudiciales_backend-network`

### 6. Conexión a Base de Datos

Se cambió la conexión de todos los servicios:

- ❌ Anterior: `db-proxy:6033` (ProxySQL con problemas de replicación)
- ✅ Actual: `db-master:3306` (conexión directa)

## Cloudflare Removido

- No hay referencias a Cloudflare en la configuración
- No se requiere configuración externa
- Todo funciona localmente con certificados auto-firmados

## Pruebas de Funcionamiento

### Frontend HTTPS

```bash
curl -k https://localhost
# Respuesta: HTML de React App
```

### API de Autenticación

```bash
curl -k -X POST https://localhost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"correo":"admin@judicial.cl","password":"admin123"}'
# Respuesta: {"access_token":"eyJ..."}
```

## Estado de Servicios

```
✅ gateway          - Up, TLS configurado
✅ frontend         - Up, accesible por HTTPS
✅ autenticacion    - Up, API funcional
✅ casos            - Up (2 réplicas)
✅ documentos       - Up
✅ notificaciones   - Up (healthy)
✅ reportes         - Up
✅ ia-seguridad     - Up (healthy)
✅ db-master        - Up (healthy)
```

## Notas de Seguridad

### Certificados Auto-Firmados

Los navegadores mostrarán advertencias de seguridad porque el certificado no está firmado por una CA confiable. Esto es **normal** para certificados auto-firmados en desarrollo.

**Para acceder desde el navegador**:

1. Navegar a `https://localhost`
2. Aceptar el riesgo de seguridad
3. Continuar al sitio

**Para curl/scripts**:

- Usar flag `-k` o `--insecure` para ignorar validación de certificado
- Ejemplo: `curl -k https://localhost`

### Hardening de Seguridad

Todas las configuraciones de hardening se mantienen:

- `no-new-privileges` en servicios
- `cap_drop: ALL` donde es apropiado
- Remoción justificada de restricciones donde se requieren capacidades específicas

## Próximos Pasos (Producción)

Para despliegue en producción, reemplazar certificados auto-firmados con:

1. **Let's Encrypt** (Recomendado para servidores públicos):

   ```yaml
   certificatesResolvers:
     letsencrypt:
       acme:
         email: admin@ejemplo.cl
         storage: /letsencrypt/acme.json
         httpChallenge:
           entryPoint: web
   ```

2. **Certificados comerciales** (Para dominios corporativos)

3. **Certificados internos de CA empresarial** (Para redes internas)

## Archivos Modificados

- `docker-compose.yml` - Labels de servicios y conexión a DB
- `generated-config/traefik.yml` - Configuración TLS
- `api-gateway/certs-local/cert.pem` - Certificado generado
- `api-gateway/certs-local/key.pem` - Clave privada generada

---

**Fecha**: 8 de diciembre de 2025  
**Estado**: ✅ HTTPS Completamente Funcional  
**Certificados**: Auto-firmados, válidos por 365 días
