# Hardening de Contenedores Docker

Este documento detalla las medidas de hardening aplicadas a los contenedores Docker del proyecto, siguiendo las mejores prácticas de seguridad para minimizar la superficie de ataque.

## 1. Medidas en Dockerfiles

### 1.1. Usuario no privilegiado

**Medida:** Todos los contenedores se ejecutan con un usuario no privilegiado (`appuser`) en lugar de `root`.

**Justificación:** Ejecutar como `root` es un riesgo de seguridad. Si un atacante compromete la aplicación, obtendría privilegios de `root` dentro del contenedor, lo que le permitiría escalar privilegios o causar más daño.

**Implementación:**
En cada `Dockerfile`, se agrega un usuario `appuser` con un UID fijo y se cambia al contexto de ese usuario.

```dockerfile
# Crear usuario no privilegiado
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser
```

### 1.2. Imágenes base con versión específica

**Medida:** Se utilizan imágenes base con versiones exactas (e.g., `python:3.11-slim`) en lugar de la etiqueta `:latest`.

**Justificación:** La etiqueta `:latest` es impredecible, ya que puede apuntar a diferentes versiones con el tiempo. Esto puede introducir cambios inesperados o vulnerabilidades en el futuro. Especificar una versión exacta asegura compilaciones reproducibles y un mejor control sobre las dependencias.

**Implementación:**
```dockerfile
FROM python:3.11-slim AS builder
```

### 1.3. Multi-stage builds

**Medida:** Se utilizan compilaciones multi-etapa para separar el entorno de compilación del entorno de ejecución.

**Justificación:** El entorno de compilación a menudo contiene herramientas y dependencias innecesarias para la ejecución de la aplicación (e.g., compiladores, librerías de desarrollo). Un atacante podría usar estas herramientas para comprometer el sistema. Las compilaciones multi-etapa producen imágenes de producción más ligeras y seguras, conteniendo solo lo estrictamente necesario para ejecutar la aplicación.

**Implementación:**
```dockerfile
# Stage 1: Build dependencies
FROM python:3.11-slim AS builder
...
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim
...
COPY --from=builder /install /usr/local
```

### 1.4. Escaneo de vulnerabilidades

**Medida:** Todas las imágenes se escanean en busca de vulnerabilidades conocidas.

**Justificación:** Las imágenes base y las dependencias pueden contener vulnerabilidades de seguridad que exponen el sistema a ataques. El escaneo regular permite identificar y remediar estas vulnerabilidades antes de que lleguen a producción.

**Implementación:**
Se utiliza `Trivy` para escanear todas las imágenes del proyecto. El script `scripts/security/scan-vulnerabilities.sh` automatiza este proceso.

```bash
docker run --rm -v ///var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --format table --no-progress --severity HIGH,CRITICAL "$IMAGE_NAME"
```

## 2. Medidas en Docker Compose

### 2.1. `security_opt` con `no-new-privileges`

**Medida:** Se configura `security_opt: [no-new-privileges]` en todos los servicios del `docker-compose.yml`.

**Justificación:** Esta opción impide que un proceso dentro del contenedor obtenga privilegios adicionales a través de `setuid` o `setgid`. Esto es una defensa crucial contra ataques de escalada de privilegios.

**Implementación:**
```yaml
services:
  autenticacion:
    ...
    security_opt:
      - no-new-privileges
```

### 2.2. `cap_drop` para eliminar capabilities innecesarias

**Medida:** Se utiliza `cap_drop: [ALL]` para eliminar todas las capabilities de Linux por defecto, y se añaden solo las necesarias con `cap_add`.

**Justificación:** Los contenedores de Docker se ejecutan con un conjunto de capabilities por defecto que pueden no ser necesarias para la aplicación. Un atacante podría abusar de estas capabilities. La mejor práctica es eliminar todas y añadir solo las que la aplicación necesita explícitamente.

**Implementación:**
```yaml
services:
  autenticacion:
    ...
    cap_drop:
      - ALL
```

### 2.3. Límites de recursos (memoria y CPU)

**Medida:** Se configuran límites de recursos de memoria y CPU para cada servicio.

**Justificación:** Sin límites de recursos, un servicio comprometido o con errores podría consumir toda la memoria o CPU del host, causando una denegación de servicio (DoS) a otros servicios.

**Implementación:**
```yaml
services:
  autenticacion:
    ...
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: '256M'
```

### 2.4. Políticas de reinicio

**Medida:** Se utiliza `restart: unless-stopped` para asegurar que los servicios se reinicien automáticamente en caso de fallo, a menos que se detengan manualmente.

**Justificación:** Esto aumenta la disponibilidad de los servicios, recuperándolos automáticamente de fallos inesperados.

**Implementación:**
```yaml
services:
  autenticacion:
    ...
    restart: unless-stopped
```

### 2.5. Configuración de logging con rotación

**Medida:** Se centraliza la configuración de logging con rotación de logs para evitar que los archivos de log crezcan indefinidamente.

**Justificación:** Los logs no controlados pueden consumir todo el espacio en disco del host, causando una denegación de servicio. La rotación de logs asegura que los logs antiguos se compriman y eliminen.

**Implementación:**
```yaml
x-logging: &default-logging
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
    compress: "true"

services:
  autenticacion:
    ...
    logging: *default-logging
```
