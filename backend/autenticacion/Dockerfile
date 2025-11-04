FROM python:3.11-slim

# Instalar dependencias del sistema para mysqlclient y bcrypt
RUN apt-get update && apt-get install -y gcc default-libmysqlclient-dev pkg-config && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instalar dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación
COPY ./app .

# Crear usuario no privilegiado
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# El FLASK_APP se define en docker-compose.yml
CMD ["flask", "run", "--host=0.0.0.0", "--port=8000"]