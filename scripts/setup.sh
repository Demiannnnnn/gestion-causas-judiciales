#!/bin/bash
# ============================================
# Script de Inicialización del Proyecto
# Sistema de Gestión de Causas Judiciales
# ============================================

set -e  # Detener en caso de error

# Colores para la terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Inicializando Estructura del Proyecto${NC}"
echo -e "${CYAN}  Sistema de Causas Judiciales${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Crear estructura de directorios
echo -e "${YELLOW}[1/4] Creando estructura de directorios...${NC}"

directories=(
    "docs"
    "docs/diagramas"
    "backend/ai-service/app"
    "infrastructure/database/mysql/init"
    "infrastructure/redis"
    "infrastructure/monitoring/prometheus"
    "infrastructure/monitoring/grafana/provisioning/dashboards"
    "infrastructure/monitoring/grafana/provisioning/datasources"
    "scripts/backup"
    "scripts/init"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "  ${GREEN}✓${NC} Creado: $dir"
    else
        echo -e "  → Ya existe: $dir"
    fi
done

echo ""
echo -e "${YELLOW}[2/4] Creando archivos de configuración para AI Service...${NC}"

# =======================
# AI SERVICE - Dockerfile
# =======================
cat > backend/ai-service/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements
COPY requirements.txt .

# Instalar dependencias Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar proyecto
COPY . .

# Crear usuario no-root
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Exponer puerto
EXPOSE 8004

# Variables de entorno
ENV FLASK_APP=app/app.py
ENV FLASK_ENV=development

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8004/health || exit 1

# Comando de inicio
CMD ["flask", "run", "--host=0.0.0.0", "--port=8004"]
EOF

echo -e "  ${GREEN}✓${NC} Dockerfile de AI Service creado"

# =======================
# AI SERVICE - requirements.txt
# =======================
cat > backend/ai-service/requirements.txt << 'EOF'
# Framework
Flask==3.0.0

# CORS
Flask-CORS==4.0.0

# HTTP requests para llamar a APIs externas
requests==2.31.0

# Variables de entorno
python-dotenv==1.0.0

# Para análisis de logs (opcional)
pandas==2.1.3

# Cliente OpenAI (si usas GPT)
openai==1.3.0
EOF

echo -e "  ${GREEN}✓${NC} requirements.txt de AI Service creado"

# =======================
# AI SERVICE - app.py
# =======================
cat > backend/ai-service/app/app.py << 'EOF'
from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import logging
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuración
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')
AI_MODE = os.getenv('AI_MODE', 'mock')  # 'mock' o 'openai'

# Base de datos simulada de logs para análisis
simulated_logs = [
    {
        "timestamp": datetime.now().isoformat(),
        "service": "casos",
        "level": "INFO",
        "message": "Caso creado exitosamente",
        "user": "admin@judicial.cl"
    },
    {
        "timestamp": (datetime.now() - timedelta(hours=2)).isoformat(),
        "service": "autenticacion",
        "level": "WARNING",
        "message": "Intento de login fallido",
        "user": "unknown@test.com"
    },
    {
        "timestamp": (datetime.now() - timedelta(hours=5)).isoformat(),
        "service": "documentos",
        "level": "INFO",
        "message": "Documento subido correctamente",
        "user": "abogado@judicial.cl"
    }
]

@app.route('/health', methods=['GET'])
def health_check():
    """Health check para Docker"""
    return jsonify({
        "status": "healthy",
        "service": "ai-service",
        "mode": AI_MODE,
        "timestamp": datetime.now().isoformat()
    }), 200

@app.route('/api/ai/analyze-logs', methods=['POST'])
def analyze_logs():
    """
    Analiza logs del sistema en busca de anomalías de seguridad
    
    Body esperado:
    {
        "time_range": "24h",  # 1h, 24h, 7d
        "services": ["casos", "autenticacion"]  # opcional
    }
    """
    try:
        data = request.get_json() or {}
        time_range = data.get('time_range', '24h')
        services = data.get('services', [])
        
        logger.info(f"Analizando logs: time_range={time_range}, services={services}")
        
        # Simulación de análisis de IA
        analysis = {
            "status": "completed",
            "time_range": time_range,
            "total_logs_analyzed": len(simulated_logs),
            "anomalies_detected": 1,
            "incidents": [
                {
                    "severity": "medium",
                    "service": "autenticacion",
                    "description": "Múltiples intentos de login fallidos detectados",
                    "timestamp": simulated_logs[1]["timestamp"],
                    "recommendation": "Revisar origen de las peticiones y considerar bloqueo temporal"
                }
            ],
            "summary": "Se detectó 1 anomalía de seguridad. El sistema está mayormente operando de forma normal.",
            "risk_level": "low"
        }
        
        return jsonify(analysis), 200
        
    except Exception as e:
        logger.error(f"Error al analizar logs: {str(e)}")
        return jsonify({"error": "Error interno del servidor"}), 500

@app.route('/api/ai/security-report', methods=['GET'])
def generate_security_report():
    """
    Genera un reporte consolidado de seguridad usando IA
    """
    try:
        report = {
            "generated_at": datetime.now().isoformat(),
            "period": "last_24_hours",
            "summary": {
                "total_events": 150,
                "security_incidents": 1,
                "failed_logins": 3,
                "suspicious_activity": 0
            },
            "services_status": [
                {"name": "autenticacion", "status": "warning", "issues": 1},
                {"name": "casos", "status": "healthy", "issues": 0},
                {"name": "documentos", "status": "healthy", "issues": 0},
                {"name": "notificaciones", "status": "healthy", "issues": 0}
            ],
            "recommendations": [
                "Implementar rate limiting en servicio de autenticación",
                "Configurar alertas automáticas para intentos de login fallidos",
                "Revisar logs de acceso cada 6 horas"
            ],
            "ai_confidence": 0.87
        }
        
        return jsonify(report), 200
        
    except Exception as e:
        logger.error(f"Error al generar reporte: {str(e)}")
        return jsonify({"error": "Error interno del servidor"}), 500

@app.route('/api/ai/chatbot', methods=['POST'])
def chatbot():
    """
    Chatbot simple para consultas sobre el sistema judicial
    
    Body:
    {
        "question": "¿Cómo crear un nuevo caso?"
    }
    """
    try:
        data = request.get_json() or {}
        question = data.get('question', '').lower()
        
        # Respuestas predefinidas (FAQ)
        faq_responses = {
            "crear caso": "Para crear un nuevo caso: 1) Ve a la sección 'Casos', 2) Haz clic en 'Crear Nuevo Caso', 3) Completa el formulario con RIT, tribunal y partes involucradas.",
            "buscar caso": "Puedes buscar casos usando el campo de búsqueda en la sección 'Casos'. Filtra por RIT o nombre del tribunal.",
            "subir documento": "Para subir documentos: 1) Selecciona un caso, 2) Ve a la pestaña 'Documentos', 3) Haz clic en 'Subir Archivo' y selecciona el PDF.",
            "notificaciones": "Las notificaciones se envían automáticamente cuando hay cambios en los casos. Revisa tu bandeja de entrada o la sección 'Notificaciones'."
        }
        
        # Buscar coincidencia en FAQ
        response_text = "Lo siento, no tengo información específica sobre esa consulta. Por favor, contacta al soporte técnico."
        for key, value in faq_responses.items():
            if key in question:
                response_text = value
                break
        
        response = {
            "question": data.get('question'),
            "answer": response_text,
            "confidence": 0.85 if response_text != "Lo siento" else 0.3,
            "timestamp": datetime.now().isoformat()
        }
        
        return jsonify(response), 200
        
    except Exception as e:
        logger.error(f"Error en chatbot: {str(e)}")
        return jsonify({"error": "Error interno del servidor"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8004, debug=True)
EOF

echo -e "  ${GREEN}✓${NC} app.py de AI Service creado"

echo ""
echo -e "${YELLOW}[3/4] Creando scripts de backup...${NC}"

# =======================
# BACKUP - backup-db.sh
# =======================
cat > scripts/backup/backup-db.sh << 'EOF'
#!/bin/bash
# Script de backup de base de datos MySQL

set -e

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR=${BACKUP_DIR:-/backups}
BACKUP_FILE="${BACKUP_DIR}/db_backup_${TIMESTAMP}.sql.gz"

# Variables de entorno esperadas
MYSQL_HOST=${MYSQL_HOST:-mysql}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-root}
MYSQL_DATABASE=${MYSQL_DATABASE:-causas_judiciales_db}

echo "[$(date)] Iniciando backup de base de datos..."
echo "Host: $MYSQL_HOST"
echo "Database: $MYSQL_DATABASE"
echo "Archivo: $BACKUP_FILE"

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

# Realizar backup
mysqldump -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "[$(date)] ✓ Backup completado exitosamente: $BACKUP_FILE"
    
    # Mostrar tamaño del backup
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "[$(date)] Tamaño del backup: $SIZE"
    
    # Eliminar backups antiguos (mantener últimos 7 días)
    echo "[$(date)] Limpiando backups antiguos..."
    find "$BACKUP_DIR" -name "db_backup_*.sql.gz" -mtime +7 -delete
    
    # Listar backups restantes
    echo "[$(date)] Backups disponibles:"
    ls -lh "$BACKUP_DIR"/db_backup_*.sql.gz 2>/dev/null || echo "  (ninguno)"
else
    echo "[$(date)] ✗ Error al realizar backup"
    exit 1
fi
EOF

chmod +x scripts/backup/backup-db.sh
echo -e "  ${GREEN}✓${NC} backup-db.sh creado"

# =======================
# BACKUP - restore-db.sh
# =======================
cat > scripts/backup/restore-db.sh << 'EOF'
#!/bin/bash
# Script de restauración de base de datos

set -e

if [ -z "$1" ]; then
    echo "Uso: $0 <archivo_backup.sql.gz>"
    echo ""
    echo "Backups disponibles:"
    ls -lh /backups/db_backup_*.sql.gz 2>/dev/null || echo "  (ninguno)"
    exit 1
fi

BACKUP_FILE=$1
MYSQL_HOST=${MYSQL_HOST:-mysql}
MYSQL_USER=${MYSQL_USER:-root}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-root}
MYSQL_DATABASE=${MYSQL_DATABASE:-causas_judiciales_db}

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: El archivo $BACKUP_FILE no existe"
    exit 1
fi

echo "[$(date)] Iniciando restauración de base de datos..."
echo "Archivo: $BACKUP_FILE"
echo "Host: $MYSQL_HOST"
echo "Database: $MYSQL_DATABASE"
echo ""
echo "⚠️  ADVERTENCIA: Esta operación sobrescribirá los datos actuales."
read -p "¿Desea continuar? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Operación cancelada."
    exit 0
fi

echo "[$(date)] Restaurando backup..."
gunzip < "$BACKUP_FILE" | mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"

if [ $? -eq 0 ]; then
    echo "[$(date)] ✓ Restauración completada exitosamente"
else
    echo "[$(date)] ✗ Error durante la restauración"
    exit 1
fi
EOF

chmod +x scripts/backup/restore-db.sh
echo -e "  ${GREEN}✓${NC} restore-db.sh creado"

# =======================
# BACKUP - README.md
# =======================
cat > scripts/backup/README.md << 'EOF'
# Scripts de Backup y Restauración

## Uso

### Ejecutar backup manualmente

```bash
# Desde la raíz del proyecto
docker-compose exec mysql bash -c "mysqldump -uroot -p\$MYSQL_ROOT_PASSWORD causas_judiciales_db | gzip > /backups/backup_manual.sql.gz"
```

O usando el script:

```bash
docker-compose exec mysql /scripts/backup/backup-db.sh
```

### Restaurar desde backup

```bash
docker-compose exec mysql /scripts/backup/restore-db.sh /backups/db_backup_FECHA.sql.gz
```

### Configurar backup automático (cron)

Los backups se ejecutan automáticamente cada día a las 2:00 AM según la configuración en `docker-compose.yml`.

## Archivos

- `backup-db.sh`: Realiza backup de la base de datos
- `restore-db.sh`: Restaura desde un archivo de backup
- `README.md`: Esta documentación

## Notas

- Los backups se almacenan en el volumen `backup-data`
- Se mantienen backups de los últimos 7 días
- Los backups están comprimidos con gzip para ahorrar espacio
EOF

echo -e "  ${GREEN}✓${NC} README.md de backups creado"

echo ""
echo -e "${YELLOW}[4/4] Creando script de inicialización rápida...${NC}"

# =======================
# SCRIPT DE INICIO RÁPIDO
# =======================
cat > scripts/start.sh << 'EOF'
#!/bin/bash
# Script de inicio rápido del proyecto

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Sistema de Gestión Judicial${NC}"
echo -e "${CYAN}  Iniciando servicios...${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Verificar que existe docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${YELLOW}Error: No se encontró docker-compose.yml${NC}"
    exit 1
fi

# Verificar que existe .env
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  No se encontró archivo .env${NC}"
    echo -e "Creando .env desde .env.example..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}✓ Archivo .env creado${NC}"
        echo -e "${YELLOW}⚠️  Por favor, edita .env con tus configuraciones${NC}"
    else
        echo -e "${YELLOW}Error: No se encontró .env.example${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}[1/3] Construyendo imágenes...${NC}"
docker-compose build

echo ""
echo -e "${YELLOW}[2/3] Iniciando servicios...${NC}"
docker-compose up -d

echo ""
echo -e "${YELLOW}[3/3] Verificando estado de servicios...${NC}"
sleep 5
docker-compose ps

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ Sistema iniciado correctamente${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Accesos:${NC}"
echo -e "  • Frontend:           ${GREEN}http://localhost:8081${NC}"
echo -e "  • Traefik Dashboard:  ${GREEN}http://localhost:8080${NC}"
echo -e "  • Prometheus:         ${GREEN}http://localhost:9090${NC}"
echo -e "  • Grafana:            ${GREEN}http://localhost:3000${NC}"
echo ""
echo -e "${CYAN}Para ver los logs:${NC}"
echo -e "  ${YELLOW}docker-compose logs -f${NC}"
echo ""
echo -e "${CYAN}Para detener:${NC}"
echo -e "  ${YELLOW}docker-compose down${NC}"
echo ""
EOF

chmod +x scripts/start.sh
echo -e "  ${GREEN}✓${NC} start.sh creado"

# =======================
# SCRIPT DE LIMPIEZA
# =======================
cat > scripts/clean.sh << 'EOF'
#!/bin/bash
# Script de limpieza del proyecto

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}  LIMPIEZA DEL PROYECTO${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "${YELLOW}⚠️  Esta operación:${NC}"
echo "  • Detendrá todos los contenedores"
echo "  • Eliminará volúmenes (¡PERDERÁS DATOS!)"
echo "  • Eliminará redes"
echo "  • Limpiará imágenes"
echo ""
read -p "¿Desea continuar? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Operación cancelada."
    exit 0
fi

echo ""
echo -e "${YELLOW}Deteniendo contenedores...${NC}"
docker-compose down -v

echo ""
echo -e "${YELLOW}Limpiando imágenes no utilizadas...${NC}"
docker image prune -f

echo ""
echo -e "${GREEN}✓ Limpieza completada${NC}"
EOF

chmod +x scripts/clean.sh
echo -e "  ${GREEN}✓${NC} clean.sh creado"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Configuración completada exitosamente${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}📁 Archivos creados:${NC}"
echo "   • backend/ai-service/ (Dockerfile, requirements.txt, app.py)"
echo "   • scripts/backup/ (backup-db.sh, restore-db.sh, README.md)"
echo "   • scripts/start.sh"
echo "   • scripts/clean.sh"
echo ""
echo -e "${CYAN}🚀 Próximos pasos:${NC}"
echo "   1. Revisar/crear archivo .env"
echo "   2. Ejecutar: ${YELLOW}./scripts/start.sh${NC}"
echo "   3. Para backups: ${YELLOW}docker-compose exec mysql /scripts/backup/backup-db.sh${NC}"
echo ""
echo -e "${CYAN}💡 Comandos útiles:${NC}"
echo "   • Iniciar:  ${YELLOW}./scripts/start.sh${NC}"
echo "   • Limpiar:  ${YELLOW}./scripts/clean.sh${NC}"
echo "   • Ver logs: ${YELLOW}docker-compose logs -f${NC}"
echo ""