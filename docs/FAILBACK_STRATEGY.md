# 🔄 AUTO-FAILBACK: ¿Debería ser automático o manual?

## 🎯 Diferencias clave: Failover vs Failback

### FAILOVER (Master → Slave)
**Situación:** ⚠️ EMERGENCIA - Master caído
```
Master MUERTO → Slave VIVO y sincronizado → Promover Slave
```
**Riesgo:** BAJO - El slave tiene todos los datos
**Decisión:** ✅ DEBE ser automático (es una emergencia)

---

### FAILBACK (Slave → Master original)
**Situación:** 🔄 RESTAURACIÓN - Master se recuperó
```
Master se recupera → ¿Devolver todo al master original?
```
**Riesgo:** MEDIO-ALTO - Pueden haber inconsistencias
**Decisión:** ⚠️ Normalmente MANUAL (no es emergencia)

---

## ❌ Por qué el FAILBACK automático es PELIGROSO:

### Escenario problemático:

```
1. [03:00] Master falla → Failover automático ✅
2. [03:02] Slave es ahora master (recibiendo escrituras)
3. [03:05] Master original vuelve (pero está DESACTUALIZADO)
4. [03:10] Daemon detecta "master está vivo"
5. [03:15] ⚠️ Failback automático SIN verificar datos
6. [03:16] 💥 PÉRDIDA DE DATOS - Se perdieron las escrituras de 03:02-03:15
```

### El problema:
- El master original NO tiene los datos escritos mientras estuvo caído
- Si lo promueves automáticamente, pierdes esos datos
- Necesitas **SINCRONIZACIÓN** primero

---

## ✅ Estrategia recomendada: FAILBACK SEMI-AUTOMÁTICO

### Modo 1: Solo notificación (RECOMENDADO)
```bash
AUTO_FAILBACK_ENABLED=false  # El daemon SOLO notifica
```

**Flujo:**
```
1. Master original se recupera
2. Daemon detecta que está vivo por 5 checks consecutivos
3. Daemon configura el master como SLAVE del slave actual
4. Espera sincronización completa
5. Envía notificación: "Master listo para failback manual"
6. TÚ decides cuándo hacer el failback
```

**Ventajas:**
- ✅ No pierdes datos
- ✅ Tienes control
- ✅ Puedes hacerlo en horario de bajo tráfico
- ✅ Verificas todo antes de cambiar

---

### Modo 2: Totalmente automático (ARRIESGADO)
```bash
AUTO_FAILBACK_ENABLED=true  # El daemon ejecuta failback solo
```

**Solo usar si:**
- ⚠️ Tienes MUCHA confianza en tu replicación
- ⚠️ El threshold es MUY alto (10+ checks)
- ⚠️ Hay verificación de sincronización completa
- ⚠️ Es un ambiente de desarrollo/testing

---

## 📊 Comparación de estrategias:

| Aspecto | Failback Manual | Failback Semi-Auto | Failback Auto |
|---------|----------------|-------------------|---------------|
| Seguridad datos | ✅ ALTA | ✅ ALTA | ⚠️ MEDIA |
| Velocidad | 🐌 Lenta | 🐇 Media | 🚀 Rápida |
| Riesgo pérdida | ✅ Mínimo | ✅ Bajo | ⚠️ Medio |
| Requiere persona | ❌ Sí | ⚠️ Solo decisión | ✅ No |
| Recomendado para | Producción crítica | **Producción normal** | Dev/Testing |

---

## 🎓 Recomendación por entorno:

### Desarrollo/Testing:
```bash
AUTO_FAILBACK_ENABLED=true
FAILBACK_HEALTHY_THRESHOLD=5
```
- Puedes perder datos sin problema
- Quieres probar el flujo completo

### Producción (Recomendado):
```bash
AUTO_FAILBACK_ENABLED=false
FAILBACK_HEALTHY_THRESHOLD=5
```
- El daemon prepara todo (sincronización)
- Tú ejecutas el failback cuando decidas
- Control total, sin riesgo

### Producción Alta Disponibilidad:
```bash
AUTO_FAILBACK_ENABLED=true
FAILBACK_HEALTHY_THRESHOLD=10  # Más conservador
FAILBACK_CHECK_INTERVAL=120     # Checks más espaciados
```
- Solo si NECESITAS failback automático
- Con checks MUY estrictos
- Monitoreo exhaustivo

---

## 🔄 Flujo completo RECOMENDADO:

### 1. Failover (Automático) ✅
```
Master DOWN → Daemon ejecuta failover → Slave es master
```

### 2. Preparación failback (Semi-automático) ⚙️
```
Master UP → Daemon detecta → Configura como slave → Sincroniza datos
         → Notifica: "Listo para failback"
```

### 3. Failback (Manual con opción -y) 🖱️
```
Tú decides cuándo → ./scripts/failback-restore-master.sh -y
```

---

## 💡 Implementación práctica:

### Crear script de failback semi-automático:

```bash
#!/bin/bash
# auto-failback-prepare.sh
# Este script PREPARA pero NO ejecuta el failback

while true; do
    if master_is_healthy && master_was_down_before; then
        # Configurar master como slave
        configure_master_as_slave_of_current_master
        
        # Esperar sincronización
        wait_for_sync_complete
        
        # Notificar
        notify "✅ Master original sincronizado y listo para failback"
        notify "Ejecuta: sudo ./scripts/failback-restore-master.sh -y"
        
        # Esperar 1 hora antes de notificar de nuevo
        sleep 3600
    fi
    
    sleep 60
done
```

---

## 🎯 Decisión rápida:

**¿Tu sistema puede tolerar 2-5 minutos para decidir un failback?**

- ✅ **SÍ** → Usa `AUTO_FAILBACK_ENABLED=false` (semi-automático)
- ❌ **NO** → Usa `AUTO_FAILBACK_ENABLED=true` (con threshold alto)

**Para el 99% de casos: `false` es la mejor opción**

---

## 📝 Resumen ejecutivo:

```
FAILOVER = Emergencia → DEBE ser automático
FAILBACK = Restauración → PUEDE ser manual

Recomendación:
- Failover: Automático (daemon activo)
- Failback: Semi-automático (daemon prepara, tú decides)
```

Es como:
- **Airbag**: Se activa SOLO (failover)
- **Reparación del carro**: Vas al taller cuando TÚ decidas (failback)

---

## ⚙️ Configuración recomendada final:

```bash
# En tu .env
FAILOVER_CHECK_INTERVAL=30
FAILOVER_FAILURE_THRESHOLD=3
AUTO_FAILBACK_ENABLED=false          # ← IMPORTANTE

FAILBACK_CHECK_INTERVAL=60
FAILBACK_HEALTHY_THRESHOLD=5
```

Con esto:
- Failover: Automático en ~90s
- Failback: Preparado automáticamente, ejecutado manualmente
