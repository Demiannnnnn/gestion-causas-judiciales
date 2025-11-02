FROM python:3.11-slim

# Instalar dependencias del sistema para mysqlclient
RUN apt-get update && apt-get install -y gcc default-libmysqlclient-dev pkg-config && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instalar dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación
# Esto crea la estructura /app/app/...
COPY ./app .

# Crear usuario no privilegiado
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 5001

# El FLASK_APP se define en docker-compose.yml como app.app
# El WORKDIR es /app, por lo que Python buscará en /app/app/app.py
CMD ["flask", "run", "--host=0.0.0.0", "--port=5001"]