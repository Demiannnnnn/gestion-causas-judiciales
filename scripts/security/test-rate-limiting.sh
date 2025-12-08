#!/bin/bash

# Script para demostrar Rate Limiting en funcionamiento
# Hace múltiples requests rápidos para activar el límite

echo "=========================================="
echo "Test de Rate Limiting - Sistema Judicial"
echo "=========================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# URL base
BASE_URL="https://localhost"

echo -e "${YELLOW}Test 1: Rate Limiting en endpoint de autenticación (10 req/s)${NC}"
echo "Enviando 20 requests consecutivos..."
echo ""

SUCCESS=0
BLOCKED=0

for i in {1..20}; do
    RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" \
        -X POST "${BASE_URL}/api/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"correo":"test@test.com","password":"test"}' \
        2>/dev/null)
    
    if [ "$RESPONSE" == "429" ]; then
        echo -e "${RED}Request $i: BLOQUEADO (429 Too Many Requests)${NC}"
        ((BLOCKED++))
    else
        echo -e "${GREEN}Request $i: Permitido ($RESPONSE)${NC}"
        ((SUCCESS++))
    fi
    
    # Pequeña pausa para simular requests rápidos
    sleep 0.05
done

echo ""
echo "=========================================="
echo -e "Resultados:"
echo -e "${GREEN}Permitidos: $SUCCESS${NC}"
echo -e "${RED}Bloqueados: $BLOCKED${NC}"
echo "=========================================="
echo ""

echo -e "${YELLOW}Test 2: Rate Limiting en endpoint general (100 req/s)${NC}"
echo "Enviando 150 requests consecutivos al endpoint /api/casos..."
echo ""

SUCCESS2=0
BLOCKED2=0

for i in {1..150}; do
    RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" \
        -X GET "${BASE_URL}/api/casos" \
        2>/dev/null)
    
    if [ "$RESPONSE" == "429" ]; then
        if [ $((i % 10)) -eq 0 ]; then
            echo -e "${RED}Request $i: BLOQUEADO${NC}"
        fi
        ((BLOCKED2++))
    else
        if [ $((i % 10)) -eq 0 ]; then
            echo -e "${GREEN}Request $i: Permitido${NC}"
        fi
        ((SUCCESS2++))
    fi
    
    # Sin pausa para saturar el límite de 100/s
done

echo ""
echo "=========================================="
echo -e "Resultados:"
echo -e "${GREEN}Permitidos: $SUCCESS2${NC}"
echo -e "${RED}Bloqueados: $BLOCKED2${NC}"
echo "=========================================="
echo ""

echo -e "${YELLOW}Verificando logs de Traefik...${NC}"
echo ""

# Mostrar últimas líneas del log de gateway que muestren 429
echo "Últimas respuestas 429 (Rate Limit) en los logs:"
docker logs gateway 2>/dev/null | grep -i "429" | tail -n 5

echo ""
echo "=========================================="
echo "Test completado"
echo "=========================================="
