FROM python:3.11-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar requirements
COPY ia-seguridad/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar módulo común
COPY common/ /app/common/

# Copiar código de la aplicación
COPY ia-seguridad/app/ /app/

# NOTA: Este servicio requiere acceso root para interactuar con Docker socket
# Justificación técnica: ia-seguridad necesita acceso al daemon de Docker
# para monitorear y analizar contenedores del sistema

# Exponer puerto
EXPOSE 8005

# Comando por defecto
CMD ["python", "app.py"]
