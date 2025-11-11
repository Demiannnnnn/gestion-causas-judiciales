# 🤖 Servicio IA-Seguridad - Guía de Uso

## ✅ Estado Actual

- **Modelo**: `gemini-2.0-flash-lite` (el más económico, más requests gratuitos)
- **Modo**: Análisis manual únicamente (no automático)
- **API**: Google Gemini AI

## 🚀 Iniciar el Servicio

### Opción 1: Script automatizado (RECOMENDADO)
```bash
./scripts/start-ia-service.sh
```

### Opción 2: Manual
```bash
# Detener servicio existente
docker-compose stop ia-seguridad
docker-compose rm -f ia-seguridad

# Iniciar con variables explícitas
GEMINI_API_KEY="$(grep GEMINI_API_KEY .env | cut -d '=' -f2)" \
AI_PROVIDER="gemini" \
docker-compose up -d --build ia-seguridad
```

### Opción 3: Con docker-compose normal
```bash
# Si el .env tiene problemas, usar este comando cada vez
docker-compose --env-file .env up -d ia-seguridad
```

## 📊 Cómo Usar

1. **Acceder a la interfaz**: http://localhost:8081/ia-seguridad

2. **Ver estadísticas** (sin gastar API):
   - CPU, Memoria, Estado de contenedores
   - Se actualiza cada 30 segundos automáticamente
   - **NO usa créditos de IA**

3. **Análisis con IA** (usa API de Gemini):
   - Presionar botón "🔍 Analizar Todos los Contenedores"
   - O seleccionar un contenedor específico y presionar "Analizar Seleccionado"
   - Esperar 5-15 segundos (dependiendo de cuántos contenedores)
   - Ver resultados con análisis inteligente

## 💰 Optimización de Uso de API

### Modelo Actual: gemini-2.0-flash-lite
- ✅ **Más requests gratuitos** que otros modelos
- ✅ Rápido (5-6 segundos por contenedor)
- ✅ Análisis detallado de logs

### Estrategia de Ahorro:
1. **NO hay análisis automático** - solo cuando lo solicitas
2. **Estadísticas actualizadas sin IA** cada 30 segundos
3. **Analizar solo cuando sea necesario**
4. **Analizar contenedores específicos** en lugar de todos

## 🔍 Qué Hace el Análisis con IA

Cuando presionas el botón de análisis, Gemini AI:

1. ✅ Analiza los logs de cada contenedor
2. ✅ Detecta errores, warnings y problemas
3. ✅ Identifica patrones sospechosos de seguridad
4. ✅ Da recomendaciones específicas
5. ✅ Clasifica severidad (bajo, medio, alto, crítico)
6. ✅ Genera alertas automáticas para problemas críticos

## ⚠️ Solución de Problemas

### Si el análisis muestra "logs básicos" en lugar de análisis con IA:

1. Verificar que la API key sea correcta:
```bash
docker exec ia-seguridad env | grep GEMINI_API_KEY
```

2. Si muestra "tu-api-key-aqui", reiniciar con el script:
```bash
./scripts/start-ia-service.sh
```

3. Verificar logs del servicio:
```bash
docker logs ia-seguridad --tail 20
```

Debe mostrar: `Gemini configurado con modelo: gemini-2.0-flash-lite`

### Si hay errores de API key:

1. Verificar que la key en `.env` sea válida
2. Obtener nueva key en: https://aistudio.google.com/app/apikey
3. Actualizar en `.env`:
```properties
GEMINI_API_KEY=tu_nueva_key_aqui
```
4. Reiniciar con el script: `./scripts/start-ia-service.sh`

## 📈 Ejemplo de Uso Eficiente

**Escenario**: Quieres verificar que todo esté bien

1. **Ver estadísticas generales** (gratis):
   - Abrir http://localhost:8081/ia-seguridad
   - Ver CPU, memoria, contenedores UP
   - ✅ Sin gastar créditos

2. **Si algo se ve raro**:
   - Seleccionar solo ese contenedor específico
   - Presionar "Analizar Seleccionado"
   - ✅ Gasta mínimo de créditos

3. **Para auditoría completa** (ocasional):
   - Presionar "Analizar Todos los Contenedores"
   - Revisar el informe completo
   - ✅ Usar solo cuando sea necesario

## 🎯 Resumen

- **Estadísticas**: Gratis, cada 30 segundos
- **Análisis con IA**: Manual, solo cuando lo necesites
- **Modelo**: gemini-2.0-flash-lite (el más económico)
- **Sin análisis automático**: Ahorra créditos de API
