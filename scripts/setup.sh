# ============================================
# Script de Inicialización del Proyecto
# Sistema de Gestión de Causas Judiciales
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Inicializando Estructura del Proyecto" -ForegroundColor Cyan
Write-Host "  Sistema de Causas Judiciales" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Crear estructura de directorios
Write-Host "[1/4] Creando estructura de directorios..." -ForegroundColor Yellow

$directories = @(
    "docs",
    "docs/diagramas",
    "services/frontend/src",
    "services/frontend/public",
    "services/auth-service/app",
    "services/casos-service/app",
    "services/documentos-service/app",
    "services/notificaciones-service/app",
    "services/ai-service/app",
    "infrastructure/database/mysql/master",
    "infrastructure/database/mysql/replica",
    "infrastructure/database/redis",
    "infrastructure/monitoring/prometheus",
    "infrastructure/monitoring/grafana/provisioning/dashboards",
    "infrastructure/monitoring/grafana/provisioning/datasources",
    "scripts/backup",
    "scripts/init"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  ✓ Creado: $dir" -ForegroundColor Green
    } else {
        Write-Host "  → Ya existe: $dir" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "[2/4] Creando archivos de configuración básicos..." -ForegroundColor Yellow

# =======================
# FRONTEND - Dockerfile
# =======================
$frontendDockerfile = @"
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Stage 2: Production
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Crear endpoint de health
RUN echo '<!DOCTYPE html><html><body><h1>OK</h1></body></html>' > /usr/share/nginx/html/health

# Usuario no privilegiado
RUN chown -R nginx:nginx /usr/share/nginx/html
USER nginx

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1
"@
Set-Content -Path "services/frontend/Dockerfile" -Value $frontendDockerfile

# Frontend - nginx.conf
$nginxConf = @"
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files `$uri `$uri/ /index.html;
    }

    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
"@
Set-Content -Path "services/frontend/nginx.conf" -Value $nginxConf

# Frontend - package.json
$packageJson = @"
{
  "name": "frontend-causas-judiciales",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "axios": "^1.6.0"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "devDependencies": {
    "react-scripts": "5.0.1"
  },
  "browserslist": {
    "production": [">0.2%", "not dead", "not op_mini all"],
    "development": ["last 1 chrome version", "last 1 firefox version", "last 1 safari version"]
  }
}
"@
Set-Content -Path "services/frontend/package.json" -Value $packageJson

# =======================
# AUTH SERVICE
# =======================
$authDockerfile = @"
FROM python:3.11-slim
WORKDIR /app

# Usuario no privilegiado
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=appuser:appuser ./app ./app

USER appuser

EXPOSE 5001
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:5001/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "5001"]
"@
Set-Content -Path "services/auth-service/Dockerfile" -Value $authDockerfile

$authRequirements = @"
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
pymysql==1.1.0
redis==5.0.1
python-dotenv==1.0.0
"@
Set-Content -Path "services/auth-service/requirements.txt" -Value $authRequirements

$authMain = @"
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os

app = FastAPI(title="Auth Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class LoginRequest(BaseModel):
    email: str
    password: str

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "auth"}

@app.post("/api/auth/login")
async def login(request: LoginRequest):
    # TODO: Implementar lógica de autenticación real
    if request.email == "admin@judicial.cl" and request.password == "Admin123!":
        return {
            "token": "fake-jwt-token",
            "user": {"email": request.email, "role": "admin"}
        }
    raise HTTPException(status_code=401, detail="Credenciales inválidas")

@app.get("/api/auth/verify")
async def verify_token():
    return {"valid": True}
"@
Set-Content -Path "services/auth-service/app/main.py" -Value $authMain

# =======================
# CASOS SERVICE
# =======================
$casosDockerfile = @"
FROM python:3.11-slim
WORKDIR /app

RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=appuser:appuser ./app ./app

USER appuser

EXPOSE 5002
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:5002/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "5002"]
"@
Set-Content -Path "services/casos-service/Dockerfile" -Value $casosDockerfile

Set-Content -Path "services/casos-service/requirements.txt" -Value $authRequirements

$casosMain = @"
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

app = FastAPI(title="Casos Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Caso(BaseModel):
    id: Optional[int] = None
    rit: str
    tribunal: str
    partes: str
    estado: str
    fecha_inicio: datetime

# Base de datos simulada
casos_db = [
    {"id": 1, "rit": "RIT-123-2024", "tribunal": "1° Juzgado Civil", 
     "partes": "Juan Pérez vs María González", "estado": "En tramitación",
     "fecha_inicio": "2024-01-15T10:00:00"},
]

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "casos"}

@app.get("/api/casos", response_model=List[dict])
async def get_casos():
    return casos_db

@app.post("/api/casos")
async def create_caso(caso: Caso):
    nuevo_caso = caso.dict()
    nuevo_caso["id"] = len(casos_db) + 1
    casos_db.append(nuevo_caso)
    return nuevo_caso

@app.get("/api/casos/{caso_id}")
async def get_caso(caso_id: int):
    for caso in casos_db:
        if caso["id"] == caso_id:
            return caso
    return {"error": "Caso no encontrado"}
"@
Set-Content -Path "services/casos-service/app/main.py" -Value $casosMain

# =======================
# DOCUMENTOS SERVICE
# =======================
Copy-Item "services/casos-service/Dockerfile" "services/documentos-service/Dockerfile"
Copy-Item "services/casos-service/requirements.txt" "services/documentos-service/requirements.txt"

$documentosMain = @"
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import os

app = FastAPI(title="Documentos Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "documentos"}

@app.post("/api/documentos/upload")
async def upload_documento(file: UploadFile = File(...)):
    # TODO: Guardar archivo en storage
    return {
        "filename": file.filename,
        "size": file.size,
        "status": "uploaded"
    }

@app.get("/api/documentos")
async def list_documentos():
    return [
        {"id": 1, "nombre": "Demanda.pdf", "fecha": "2024-10-01"},
        {"id": 2, "nombre": "Resolución.pdf", "fecha": "2024-10-15"}
    ]
"@
Set-Content -Path "services/documentos-service/app/main.py" -Value $documentosMain

# =======================
# NOTIFICACIONES SERVICE
# =======================
Copy-Item "services/casos-service/Dockerfile" "services/notificaciones-service/Dockerfile"
Copy-Item "services/casos-service/requirements.txt" "services/notificaciones-service/requirements.txt"

$notificacionesMain = @"
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="Notificaciones Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Notificacion(BaseModel):
    destinatario: str
    asunto: str
    mensaje: str

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "notificaciones"}

@app.post("/api/notificaciones/send")
async def send_notification(notif: Notificacion):
    # TODO: Implementar envío real de email
    print(f"Enviando notificación a {notif.destinatario}")
    return {"status": "sent", "destinatario": notif.destinatario}
"@
Set-Content -Path "services/notificaciones-service/app/main.py" -Value $notificacionesMain

# =======================
# AI SERVICE
# =======================
Copy-Item "services/casos-service/Dockerfile" "services/ai-service/Dockerfile"

$aiRequirements = @"
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
requests==2.31.0
python-dotenv==1.0.0
"@
Set-Content -Path "services/ai-service/requirements.txt" -Value $aiRequirements

$aiMain = @"
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import requests
import os

app = FastAPI(title="AI Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class SecurityAnalysisRequest(BaseModel):
    service: str
    time_range: str

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "ai"}

@app.post("/api/ai/analyze-security")
async def analyze_security(request: SecurityAnalysisRequest):
    # Análisis simulado con IA
    return {
        "status": "ok",
        "service": request.service,
        "incidents": 0,
        "summary": "No se detectaron anomalías en el periodo analizado",
        "recommendation": "Continuar con el monitoreo habitual"
    }

@app.get("/api/ai/report")
async def get_security_report():
    return {
        "period": "last_24h",
        "total_requests": 1250,
        "suspicious_activity": 0,
        "alerts": []
    }
"@
Set-Content -Path "services/ai-service/app/main.py" -Value $aiMain

# =======================
# MYSQL CONFIGURATION
# =======================
$mysqlMasterConf = @"
[mysqld]
server-id = 1
log_bin = mysql-bin
binlog_format = ROW
binlog_do_db = causas_judiciales
"@
Set-Content -Path "infrastructure/database/mysql/master/my.cnf" -Value $mysqlMasterConf

$mysqlReplicaConf = @"
[mysqld]
server-id = 2
relay-log = relay-bin
read_only = 1
"@
Set-Content -Path "infrastructure/database/mysql/replica/my.cnf" -Value $mysqlReplicaConf

$mysqlInit = @"
CREATE DATABASE IF NOT EXISTS causas_judiciales;
USE causas_judiciales;

CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('admin', 'abogado') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS casos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rit VARCHAR(50) NOT NULL UNIQUE,
    tribunal VARCHAR(255) NOT NULL,
    partes TEXT NOT NULL,
    estado VARCHAR(50) NOT NULL,
    fecha_inicio DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar usuarios de prueba
INSERT IGNORE INTO usuarios (email, password_hash, rol) VALUES
('admin@judicial.cl', 'hashed_password', 'admin'),
('abogado@judicial.cl', 'hashed_password', 'abogado');
"@
Set-Content -Path "infrastructure/database/mysql/master/init.sql" -Value $mysqlInit

# =======================
# PROMETHEUS
# =======================
$prometheusYml = @"
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'docker'
    static_configs:
      - targets: ['gateway:8080']
"@
Set-Content -Path "infrastructure/monitoring/prometheus/prometheus.yml" -Value $prometheusYml

# =======================
# BACKUP SCRIPTS
# =======================
$backupDockerfile = @"
FROM alpine:latest

RUN apk add --no-cache \
    mysql-client \
    bash \
    gzip \
    tar \
    dcron

COPY *.sh /app/
RUN chmod +x /app/*.sh

CMD ["crond", "-f", "-l", "2"]
"@
Set-Content -Path "scripts/backup/Dockerfile" -Value $backupDockerfile

$backupDb = @"
#!/bin/bash
set -e

TIMESTAMP=`$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="/backups/db_`${TIMESTAMP}.sql.gz"

echo "[`$(date)] Iniciando backup de base de datos..."

mysqldump -h`$MYSQL_HOST -u`$MYSQL_USER -p`$MYSQL_PASSWORD `$MYSQL_DATABASE | gzip > `$BACKUP_FILE

echo "[`$(date)] Backup completado: `$BACKUP_FILE"

# Eliminar backups antiguos (mantener últimos 7 días)
find /backups -name "db_*.sql.gz" -mtime +7 -delete
"@
Set-Content -Path "scripts/backup/backup-db.sh" -Value $backupDb

Write-Host "  ✓ Archivos de configuración creados" -ForegroundColor Green

Write-Host ""
Write-Host "[3/4] Creando archivos de documentación..." -ForegroundColor Yellow

# Crear .gitignore
$gitignore = @"
# Variables de entorno
.env

# Node modules
node_modules/
**/node_modules/

# Builds
build/
dist/
**/build/
**/dist/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
ENV/
env/

# IDEs
.vscode/
.idea/
*.swp
*.swo

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db

# Docker
*.pid
*.seed
*.seed.*

# Backups
backups/
*.sql
*.sql.gz
"@
Set-Content -Path ".gitignore" -Value $gitignore

Write-Host "  ✓ Archivos de documentación creados" -ForegroundColor Green

Write-Host ""
Write-Host "[4/4] Resumen de la estructura creada" -ForegroundColor Yellow
Write-Host ""

Write-Host "✅ Estructura del proyecto creada exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Directorios principales:" -ForegroundColor Cyan
Write-Host "   - services/          (6 microservicios)" -ForegroundColor White
Write-Host "   - infrastructure/    (Configuraciones de BD y monitoreo)" -ForegroundColor White
Write-Host "   - scripts/           (Scripts de backup)" -ForegroundColor White
Write-Host "   - docs/              (Documentación)" -ForegroundColor White
Write-Host ""
Write-Host "📄 Archivos de configuración:" -ForegroundColor Cyan
Write-Host "   - docker-compose.yml (CREAR MANUALMENTE)" -ForegroundColor Yellow
Write-Host "   - .env.example       (CREAR MANUALMENTE)" -ForegroundColor Yellow
Write-Host "   - README.md          (CREAR MANUALMENTE)" -ForegroundColor Yellow
Write-Host ""
Write-Host "🚀 Próximos pasos:" -ForegroundColor Cyan
Write-Host "   1. Copiar docker-compose.yml del artefacto" -ForegroundColor White
Write-Host "   2. Copiar .env.example del artefacto" -ForegroundColor White
Write-Host "   3. Crear .env desde .env.example" -ForegroundColor White
Write-Host "   4. Ejecutar: docker-compose up -d" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ¡Proyecto inicializado!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
"@