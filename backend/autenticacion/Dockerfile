# Stage 1: Build dependencies
FROM python:3.11-slim AS builder

# Update OS packages
RUN apt-get update && apt-get upgrade -y

# Instalar dependencias de compilación
RUN apt-get install -y \
    gcc \
WORKDIR /app

# Instalar dependencias en un directorio temporal
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim

# Update OS packages
RUN apt-get update && apt-get upgrade -y

# Instalar solo librerías runtime necesarias (sin compiladores)
RUN apt-get install -y \
    default-libmysqlclient-dev \

WORKDIR /app

# Copiar dependencias instaladas desde builder
COPY --from=builder /install /usr/local

# Copiar el código de la aplicación
COPY ./app .

# Crear usuario no privilegiado
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# El FLASK_APP se define en docker-compose.yml
CMD ["flask", "run", "--host=0.0.0.0", "--port=8000"]