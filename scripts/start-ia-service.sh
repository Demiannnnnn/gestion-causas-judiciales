#!/bin/bash
# Script para iniciar el servicio de IA con las variables de entorno correctas

echo "🤖 Iniciando servicio IA-Seguridad..."

# Cargar variables del .env
if [ -f .env ]; then
    export $(cat .env | grep -E "^(GEMINI_API_KEY|AI_PROVIDER)" | xargs)
    echo "✅ Variables de entorno cargadas desde .env"
else
    echo "❌ Archivo .env no encontrado"
    exit 1
fi

# Detener y eliminar contenedor existente
echo "🛑 Deteniendo contenedor existente..."
docker-compose stop ia-seguridad 2>/dev/null
docker-compose rm -f ia-seguridad 2>/dev/null

# Reconstruir y levantar con variables explícitas
echo "🔨 Reconstruyendo servicio con modelo gemini-2.0-flash-lite..."
GEMINI_API_KEY="${GEMINI_API_KEY}" \
AI_PROVIDER="${AI_PROVIDER}" \
docker-compose up -d --build ia-seguridad

# Verificar que esté corriendo
sleep 3
if docker ps | grep -q "ia-seguridad"; then
    echo "✅ Servicio IA-Seguridad iniciado correctamente"
    echo "📊 Verificando configuración..."
    docker exec ia-seguridad env | grep -E "(GEMINI_API_KEY|AI_PROVIDER)" | sed 's/=.*/=***/' 
    echo ""
    echo "🔍 Logs recientes:"
    docker logs ia-seguridad --tail 5
else
    echo "❌ Error al iniciar el servicio"
    exit 1
fi

echo ""
echo "✨ Servicio listo. Accede a: http://localhost:8081/ia-seguridad"
