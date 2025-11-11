# Servicio de IA para Seguridad y Análisis de Logs

Este servicio implementa un sistema de inteligencia artificial para análisis automático de logs, detección de anomalías y monitoreo de seguridad de todos los contenedores del sistema.

## Características

### 1. Análisis de Logs con IA
- Utiliza Gemini AI (Google) para analizar logs de contenedores
- Detecta errores, warnings y problemas automáticamente
- Genera resúmenes y recomendaciones
- Identifica patrones sospechosos de seguridad

### 2. Detección de Anomalías
- Monitorea uso de CPU y memoria
- Detecta contenedores caídos o con problemas
- Identifica reinicios frecuentes
- Compara con métricas base

### 3. Sistema de Alertas
- Genera alertas automáticas para problemas críticos
- Clasifica por severidad (low, medium, high, critical)
- Permite resolver alertas con notas
- Historial de alertas

### 4. Monitoreo en Tiempo Real
- Estadísticas del sistema host
- Estado de salud de todos los contenedores
- Métricas de CPU, memoria y disco
- Actualización automática cada 5 minutos

## Configuración

### Variables de Entorno

```bash
# API Key de Gemini (Google AI)
GEMINI_API_KEY=tu-api-key-aqui

# API Key de OpenAI (opcional)
OPENAI_API_KEY=sk-tu-api-key-aqui

# Proveedor de IA por defecto
AI_PROVIDER=gemini
```

### Obtener API Key de Gemini

1. Visita [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Inicia sesión con tu cuenta de Google
3. Crea un nuevo API key
4. Copia el key y agrégalo al archivo `.env`

## API Endpoints

### Análisis de Logs

```bash
# Analizar todos los contenedores
POST /api/ia-seguridad/api/analyze/logs
Body: {
  "since": "1h",
  "ai_provider": "gemini"
}

# Analizar un contenedor específico
GET /api/ia-seguridad/api/analyze/container/{container_name}?since=1h
```

### Detección de Anomalías

```bash
# Detectar anomalías
POST /api/ia-seguridad/api/anomalies/detect
Body: {
  "containers": ["frontend", "backend-casos"]
}
```

### Alertas

```bash
# Obtener alertas
GET /api/ia-seguridad/api/alerts?severity=critical&status=open

# Resolver alerta
PUT /api/ia-seguridad/api/alerts/{id}/resolve
Body: {
  "note": "Problema resuelto"
}
```

### Estadísticas

```bash
# Estadísticas del sistema
GET /api/ia-seguridad/api/stats/system

# Estado de contenedores
GET /api/ia-seguridad/api/stats/containers
```

### Control de Análisis Automático

```bash
# Iniciar análisis automático
POST /api/ia-seguridad/api/analysis/start

# Detener análisis automático
POST /api/ia-seguridad/api/analysis/stop
```

## Uso desde el Frontend

El dashboard web está disponible en `/ia-seguridad` y proporciona:

- Vista en tiempo real de alertas y estado de contenedores
- Botones para ejecutar análisis manual
- Visualización de resultados de análisis de IA
- Gestión de alertas (resolver, filtrar)
- Estadísticas del sistema

## Análisis Automático

El servicio ejecuta análisis automáticos cada 5 minutos:

1. Recopila logs de todos los contenedores
2. Analiza con IA (Gemini)
3. Detecta anomalías en métricas
4. Genera alertas para problemas críticos
5. Envía notificaciones si es necesario

## Patrones de Errores Detectados

El sistema detecta automáticamente:

- **Connection Errors**: Problemas de conexión
- **Memory Errors**: Falta de memoria (OOM)
- **Permission Errors**: Problemas de permisos
- **Database Errors**: Errores de BD
- **Timeout Errors**: Timeouts y deadlines
- **Crash Errors**: Crashes y segfaults

## Estructura del Código

```
backend/ia-seguridad/
├── Dockerfile
├── requirements.txt
└── app/
    ├── app.py              # API principal
    ├── log_analyzer.py     # Análisis de logs con IA
    ├── alert_manager.py    # Gestión de alertas
    └── health_monitor.py   # Monitoreo de salud
```

## Ejemplos de Uso

### Desde Python

```python
import requests

# Analizar logs
response = requests.post('http://localhost:8005/api/analyze/logs', json={
    "since": "30m",
    "ai_provider": "gemini"
})
analysis = response.json()

# Detectar anomalías
response = requests.post('http://localhost:8005/api/anomalies/detect')
anomalies = response.json()
```

### Desde curl

```bash
# Analizar contenedor específico
curl -X GET "http://localhost:8005/api/analyze/container/frontend?since=1h"

# Obtener alertas críticas
curl -X GET "http://localhost:8005/api/alerts?severity=critical"
```

## Logs del Servicio

Para ver los logs del servicio de IA:

```bash
docker logs ia-seguridad -f
```

## Troubleshooting

### El análisis no funciona

1. Verifica que `GEMINI_API_KEY` esté configurada
2. Revisa los logs del contenedor
3. Asegúrate de que Docker socket esté montado

### No se detectan contenedores

1. Verifica que `/var/run/docker.sock` esté montado en el contenedor
2. Revisa permisos del socket de Docker

### Errores de memoria

El análisis de logs puede consumir memoria. Para logs muy grandes:
- Se limita automáticamente a 10KB por contenedor
- Ajusta el parámetro `max_log_size` en `log_analyzer.py`

## Seguridad

- El servicio tiene acceso de solo lectura al socket de Docker
- Las API keys se pasan como variables de entorno
- No se almacenan logs completos, solo análisis
- Las alertas contienen solo información resumida

## Mejoras Futuras

- [ ] Soporte para múltiples proveedores de IA simultáneos
- [ ] Almacenamiento persistente de alertas en BD
- [ ] Integración con Grafana para visualizaciones
- [ ] Machine Learning para detección de patrones
- [ ] Webhooks para notificaciones externas
- [ ] Exportación de reportes en PDF
