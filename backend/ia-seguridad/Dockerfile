FROM python:3.11-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código de la aplicación
COPY ./app .

# Exponer puerto
EXPOSE 8005

# Nota: Se ejecuta como root para acceder al socket de Docker
# El socket está montado en modo solo lectura (ro) para seguridad

# Comando por defecto
CMD ["python", "app.py"]
