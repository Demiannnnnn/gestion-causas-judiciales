# Presupuesto y Cotización Técnica
## Sistema de Gestión de Causas Judiciales

**Licitación:** 1552-56-LE25  
**Cliente:** Servicio de Salud de Atacama  
**Fecha:** Noviembre 2025  
**Vigencia:** 90 días

---

## 📋 Resumen Ejecutivo

| Concepto | Valor (CLP) |
|----------|-------------|
| **Costo Total de Implementación** | $42.850.000 |
| **Mantenimiento Anual** | $18.600.000 |
| **Hosting e Infraestructura (Año 1)** | $7.200.000 |
| **TOTAL AÑO 1** | **$68.650.000** |

---

## 1. Costos de Desarrollo

### 1.1 Equipo de Desarrollo

| Rol | Horas | Tarifa/Hora | Total |
|-----|-------|-------------|-------|
| **Arquitecto de Software Senior** | 80h | $35.000 | $2.800.000 |
| **Desarrollador Backend Senior** | 320h | $30.000 | $9.600.000 |
| **Desarrollador Frontend Senior** | 240h | $25.000 | $6.000.000 |
| **Especialista DevOps/Infraestructura** | 200h | $32.000 | $6.400.000 |
| **Desarrollador IA/ML** | 120h | $35.000 | $4.200.000 |
| **Especialista en Seguridad** | 80h | $38.000 | $3.040.000 |
| **Analista QA/Testing** | 160h | $22.000 | $3.520.000 |
| **Diseñador UX/UI** | 60h | $28.000 | $1.680.000 |
| **Jefe de Proyecto** | 120h | $40.000 | $4.800.000 |
| | | **SUBTOTAL** | **$42.040.000** |

**Total Horas Estimadas:** 1,380 horas  
**Duración del Proyecto:** 12 semanas (3 meses)

---

### 1.2 Desglose de Actividades

#### Semana 1-2: Análisis y Diseño
- Análisis detallado de requisitos (40h)
- Diseño de arquitectura técnica (60h)
- Diseño de base de datos (40h)
- Diseño UX/UI y prototipos (60h)
- Plan de pruebas y QA (40h)

**Subtotal:** 240 horas

---

#### Semana 3-6: Desarrollo Backend
- Servicio de Autenticación (40h)
- Servicio de Casos (Core) (120h)
- Servicio de Documentos (60h)
- Servicio de Notificaciones (80h)
- Servicio de Reportes (60h)
- Servicio de IA (120h)
- Base de datos y migraciones (80h)

**Subtotal:** 560 horas

---

#### Semana 7-9: Desarrollo Frontend
- Componentes base y layout (40h)
- Módulo de casos (60h)
- Módulo de documentos (40h)
- Módulo de notificaciones (40h)
- Módulo de reportes (40h)
- Integración con backend (60h)

**Subtotal:** 280 horas

---

#### Semana 10-11: Infraestructura y DevOps
- Configuración de contenedores (40h)
- Alta disponibilidad (replicación) (60h)
- Sistema de respaldos (40h)
- Monitoreo (Prometheus/Grafana) (40h)
- Seguridad y certificados SSL (20h)

**Subtotal:** 200 horas

---

#### Semana 12: Testing y Deployment
- Testing funcional (60h)
- Testing de carga y performance (30h)
- Testing de seguridad (30h)
- Deployment a producción (20h)
- Documentación técnica (40h)

**Subtotal:** 180 horas

---

### 1.3 Costos Adicionales de Desarrollo

| Concepto | Costo |
|----------|-------|
| Licencias de desarrollo (IDE, herramientas) | $300.000 |
| Certificados SSL para desarrollo | $150.000 |
| Herramientas de testing (Postman, etc.) | $180.000 |
| Contingencia (5%) | $180.000 |
| | **SUBTOTAL** | **$810.000** |

**TOTAL DESARROLLO:** $42.850.000

---

## 2. Costos de Infraestructura (Año 1)

### 2.1 Hosting y Servidores

#### Opción A: Servidores Dedicados Cloud (Recomendado)

| Componente | Especificaciones | Costo Mensual | Anual |
|------------|------------------|---------------|-------|
| **Servidor Aplicación 1** | 8 vCPU, 16GB RAM, 200GB SSD | $180.000 | $2.160.000 |
| **Servidor Aplicación 2** | 8 vCPU, 16GB RAM, 200GB SSD | $180.000 | $2.160.000 |
| **Servidor BD Master** | 4 vCPU, 8GB RAM, 500GB SSD | $150.000 | $1.800.000 |
| **Servidor BD Replica** | 4 vCPU, 8GB RAM, 500GB SSD | $150.000 | $1.800.000 |
| **Load Balancer** | Incluido en cloud | $0 | $0 |
| **Ancho de banda** | 2TB/mes | $50.000 | $600.000 |
| | | **SUBTOTAL** | **$8.520.000** |

#### Opción B: Infraestructura On-Premise (Inversión Inicial)

| Componente | Especificaciones | Costo Único |
|------------|------------------|-------------|
| **Servidor Físico x2** | Dell PowerEdge R450 (16 cores, 64GB RAM) | $6.500.000 |
| **Storage NAS** | Synology DS1821+ con 8TB | $2.800.000 |
| **Switch Managed** | 24 puertos Gigabit | $450.000 |
| **UPS** | 2000VA Online | $850.000 |
| **Rack Cabinet** | 12U con refrigeración | $600.000 |
| **Instalación y configuración** | | $1.200.000 |
| | **TOTAL** | **$12.400.000** |

**Recomendación:** Opción A (Cloud) por:
- Menor inversión inicial
- Escalabilidad inmediata
- Mantenimiento incluido
- Alta disponibilidad garantizada

---

### 2.2 Almacenamiento Backup

| Servicio | Capacidad | Costo Mensual | Anual |
|----------|-----------|---------------|-------|
| **Amazon S3 (o similar)** | 500GB + transferencia | $35.000 | $420.000 |
| **Backup en datacenter secundario** | 1TB | $60.000 | $720.000 |
| | | **SUBTOTAL** | **$1.140.000** |

---

### 2.3 Servicios Adicionales

| Servicio | Descripción | Costo Mensual | Anual |
|----------|-------------|---------------|-------|
| **Certificados SSL** | Wildcard SSL (producción) | $8.000 | $96.000 |
| **Dominio** | .cl + DNS gestionado | $2.500 | $30.000 |
| **CDN** | Cloudflare Pro | $17.000 | $204.000 |
| **Email transaccional** | SendGrid (50k emails/mes) | $20.000 | $240.000 |
| **Monitoreo externo** | UptimeRobot Pro | $4.500 | $54.000 |
| | | **SUBTOTAL** | **$624.000** |

---

### 2.4 Componente de IA

| Concepto | Descripción | Costo Mensual | Anual |
|----------|-------------|---------------|-------|
| **OpenAI API GPT-4** | Análisis de seguridad (opcional) | $80.000 | $960.000 |
| **Hosting modelo local** | Ollama en servidor dedicado | $0 | $0 |

**Recomendación:** Iniciar con modelo local (Ollama) y evaluar OpenAI según necesidad.

---

### Resumen Infraestructura Año 1

| Concepto | Costo Anual |
|----------|-------------|
| Hosting Cloud | $8.520.000 |
| Almacenamiento Backup | $1.140.000 |
| Servicios Adicionales | $624.000 |
| IA (opcional) | $960.000 |
| | **SUBTOTAL** | **$11.244.000** |

**Con descuento por pago anual anticipado (-10%):** $10.120.000  
**Sin componente IA:** $9.160.000

---

## 3. Costos de Mantenimiento y Soporte (Anual)

### 3.1 Mantenimiento Correctivo y Preventivo

| Actividad | Horas/Mes | Tarifa | Mensual | Anual |
|-----------|-----------|--------|---------|-------|
| **Monitoreo proactivo** | 20h | $25.000 | $500.000 | $6.000.000 |
| **Actualizaciones de seguridad** | 12h | $30.000 | $360.000 | $4.320.000 |
| **Corrección de bugs** | 16h | $28.000 | $448.000 | $5.376.000 |
| **Optimización de performance** | 8h | $32.000 | $256.000 | $3.072.000 |
| | | | **SUBTOTAL** | **$18.768.000** |

---

### 3.2 Soporte Técnico

| Nivel | Descripción | Costo Mensual | Anual |
|-------|-------------|---------------|-------|
| **Soporte Básico** | Email, 48h respuesta | $250.000 | $3.000.000 |
| **Soporte Premium** | Email + teléfono, 8h respuesta | $450.000 | $5.400.000 |
| **Soporte Enterprise** | 24/7, 2h respuesta críticos | $800.000 | $9.600.000 |

**Recomendado:** Soporte Premium

---

### 3.3 Capacitación

| Tipo | Duración | Participantes | Costo Total |
|------|----------|---------------|-------------|
| **Capacitación Usuarios** | 2 días | Hasta 20 | $1.200.000 |
| **Capacitación Administradores** | 3 días | Hasta 5 | $1.800.000 |
| **Material de apoyo** | Manuales y videos | - | $400.000 |
| | | **SUBTOTAL** | **$3.400.000** |

---

### 3.4 Actualizaciones y Mejoras

| Concepto | Descripción | Costo Anual |
|----------|-------------|-------------|
| **Actualizaciones menores** | Mejoras funcionales, 4 releases/año | $4.500.000 |
| **Actualización de dependencias** | Librerías, frameworks, seguridad | $1.800.000 |
| **Nuevas funcionalidades** | Hasta 80 horas/año | $2.400.000 |
| | **SUBTOTAL** | **$8.700.000** |

---

### Resumen Mantenimiento Anual

| Concepto | Costo |
|----------|-------|
| Mantenimiento Correctivo/Preventivo | $18.768.000 |
| Soporte Premium | $5.400.000 |
| Capacitación (año 1) | $3.400.000 |
| Actualizaciones y Mejoras | $8.700.000 |
| | **SUBTOTAL** | **$36.268.000** |

**Con descuento por contrato anual (-15%):** $30.828.000

---

## 4. Resumen de Costos

### 4.1 Inversión Inicial (Una vez)

| Concepto | Costo (CLP) |
|----------|-------------|
| **Desarrollo del Sistema** | $42.850.000 |
| **Capacitación Inicial** | $3.400.000 |
| **Migración de datos (si aplica)** | $2.500.000 |
| **Puesta en marcha** | $1.800.000 |
| | **TOTAL IMPLEMENTACIÓN** | **$50.550.000** |

---

### 4.2 Costos Recurrentes Anuales

| Concepto | Año 1 | Años 2-5 |
|----------|-------|----------|
| **Hosting e Infraestructura** | $9.160.000 | $9.160.000 |
| **Mantenimiento y Soporte** | $30.828.000 | $25.428.000* |
| **Licencias** | $624.000 | $624.000 |
| | **TOTAL ANUAL** | **$40.612.000** | **$35.212.000** |

*Sin capacitación inicial

---

### 4.3 Costo Total de Propiedad (TCO) - 5 años

| Año | Concepto | Costo |
|-----|----------|-------|
| **Año 0** | Implementación | $50.550.000 |
| **Año 1** | Operación | $40.612.000 |
| **Año 2** | Operación | $35.212.000 |
| **Año 3** | Operación | $35.212.000 |
| **Año 4** | Operación | $35.212.000 |
| **Año 5** | Operación | $35.212.000 |
| | **TOTAL 5 AÑOS** | **$232.010.000** |

**Costo mensual promedio (5 años):** $3.867.000

---

## 5. Comparación con Alternativas del Mercado

### 5.1 Soluciones Comerciales

| Proveedor | Costo Implementación | Costo Anual | Total 5 años |
|-----------|----------------------|-------------|--------------|
| **Sistema A (Internacional)** | $85.000.000 | $52.000.000 | $293.000.000 |
| **Sistema B (Nacional)** | $68.000.000 | $45.000.000 | $248.000.000 |
| **Nuestra Propuesta** | $50.550.000 | $40.612.000 | $232.010.000 |

**Ahorro:** $16.000.000 vs Sistema B (7% más económico)

---

### 5.2 Ventajas Competitivas de Nuestra Solución

#### ✅ Tecnología Open Source
- Sin costos de licencias propietarias
- Libertad para modificar y adaptar
- Comunidad activa de soporte
- Actualizaciones sin costo adicional

#### ✅ Arquitectura Moderna
- Microservicios escalables
- Alta disponibilidad incluida
- Docker/containerización
- Fácil actualización y mantenimiento

#### ✅ Cumplimiento Normativo
- Ley N°19.628 (Protección de Datos)
- ISO/IEC 27001 (Seguridad)
- Auditoría completa con logs
- IA para detección de brechas

#### ✅ Flexibilidad
- Hosting flexible (cloud o on-premise)
- Escalabilidad según demanda
- Integración con sistemas existentes
- Personalización sin costos exorbitantes

---

## 6. Formas de Pago

### Opción 1: Pago Completo (Recomendado)
- **Descuento:** 10% sobre implementación
- **Total Implementación:** $45.495.000
- **Condiciones:** 50% al firmar contrato, 50% al entregar

### Opción 2: Pago en Hitos
| Hito | % | Monto |
|------|---|-------|
| Firma de contrato | 30% | $15.165.000 |
| Entrega diseño y prototipos | 20% | $10.110.000 |
| Finalización backend | 25% | $12.637.500 |
| Entrega final y puesta en marcha | 25% | $12.637.500 |

### Opción 3: Leasing Tecnológico
- **Cuotas mensuales:** $8.500.000 x 12 meses
- **Total:** $102.000.000 (incluye implementación + año 1)
- **Ventaja:** Menor impacto presupuestario inicial

---

## 7. Garantías y Compromisos

### 7.1 Garantía de Calidad
- ✅ **3 meses** de garantía post-implementación
- ✅ Corrección de bugs sin costo
- ✅ Soporte prioritario durante garantía

### 7.2 Acuerdos de Nivel de Servicio (SLA)

| Métrica | Objetivo | Garantía |
|---------|----------|----------|
| **Disponibilidad** | 99.5% | Crédito si < 99.0% |
| **Tiempo de respuesta críticos** | 2 horas | Crédito si > 4 horas |
| **Tiempo resolución bugs críticos** | 24 horas | Crédito si > 48 horas |
| **Tiempo respuesta consultas** | 8 horas | 12 horas máximo |

### 7.3 Penalizaciones
- **Por incumplimiento de SLA:** Descuento 5% mensualidad
- **Por retraso en entrega:** $500.000 por semana
- **Máximo penalizable:** 20% del valor total

---

## 8. Cronograma de Implementación

### Fase 1: Planificación (Semana 1-2)
- Kick-off meeting
- Análisis detallado de requisitos
- Diseño de arquitectura
- Diseño UX/UI
- Aprobación del cliente

### Fase 2: Desarrollo (Semana 3-9)
- Sprint 1: Backend core y autenticación
- Sprint 2: Gestión de casos y documentos
- Sprint 3: Notificaciones y reportes
- Sprint 4: Frontend y integración
- Sprint 5: Componente IA

### Fase 3: Testing (Semana 10-11)
- Testing funcional
- Testing de carga
- Testing de seguridad
- Corrección de issues

### Fase 4: Deployment (Semana 12)
- Migración de datos
- Capacitación usuarios
- Puesta en producción
- Monitoreo intensivo inicial

**Entrega final:** 12 semanas desde inicio

---

## 9. Riesgos y Mitigación

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| **Cambios de alcance** | Media | Alto | Proceso formal de change requests |
| **Retrasos en información** | Media | Medio | SLA de respuesta del cliente |
| **Problemas de integración** | Baja | Alto | Pruebas de integración tempranas |
| **Fallas de infraestructura** | Baja | Alto | Alta disponibilidad + backups |
| **Bugs post-producción** | Media | Medio | Garantía de 3 meses + SLA |

---

## 10. Beneficios Esperados

### 10.1 Beneficios Cuantitativos (Año 1)

| Concepto | Ahorro Estimado |
|----------|-----------------|
| **Reducción tiempo gestión casos** | 40% → $18.000.000 |
| **Automatización notificaciones** | 60% → $8.500.000 |
| **Reducción errores documentación** | 50% → $6.200.000 |
| **Optimización reportes** | 70% → $4.800.000 |
| | **TOTAL AHORROS** | **$37.500.000** |

**ROI Año 1:** -7% (inversión inicial)  
**ROI Año 2:** +61% (recuperación + beneficios)

---

### 10.2 Beneficios Cualitativos

✅ **Mejora en atención ciudadana**
- Tiempos de respuesta más rápidos
- Transparencia en procesos
- Acceso 24/7 a información

✅ **Cumplimiento normativo**
- Auditoría completa
- Protección de datos personales
- Certificación ISO 27001

✅ **Modernización tecnológica**
- Sistema escalable y moderno
- Preparado para futuras integraciones
- Independencia tecnológica

✅ **Productividad del personal**
- Menos tareas manuales
- Alertas automáticas
- Búsquedas más eficientes

---

## 11. Opciones de Expansión Futura

### 11.1 Módulos Adicionales (Opcionales)

| Módulo | Descripción | Costo Desarrollo |
|--------|-------------|------------------|
| **Portal Ciudadano** | Consulta pública de causas | $12.000.000 |
| **App Móvil** | iOS + Android | $18.500.000 |
| **Integración Poder Judicial** | API con sistemas nacionales | $8.500.000 |
| **Business Intelligence** | Dashboard ejecutivo avanzado | $9.800.000 |
| **Firma Electrónica Avanzada** | Integración con SRCEI | $11.200.000 |

---

### 11.2 Escalamiento de Infraestructura

| Escenario | Usuarios | Casos/Año | Costo Adicional Mensual |
|-----------|----------|-----------|-------------------------|
| **Actual** | 20-50 | 5,000 | $0 |
| **Crecimiento 2x** | 100 | 10,000 | $150.000 |
| **Crecimiento 5x** | 250 | 25,000 | $450.000 |
| **Regional** | 500+ | 50,000+ | $950.000 |

---

## 12. Términos y Condiciones

### 12.1 Vigencia de la Oferta
- **Validez:** 90 días desde la fecha de emisión
- **Precios:** En pesos chilenos (CLP)
- **Actualización:** IPC + 2% anual

### 12.2 Condiciones de Pago
- **Método:** Transferencia bancaria
- **Plazo:** 30 días desde facturación
- **Retención:** 10% hasta cierre de garantía

### 12.3 Propiedad Intelectual
- **Código fuente:** Propiedad del cliente
- **Documentación:** Incluida sin costo adicional
- **Licencias:** Open source, sin restricciones

### 12.4 Confidencialidad
- NDA firmado antes de inicio
- Protección de datos según Ley 19.628
- Compromiso de confidencialidad del equipo

---

## 13. Contacto y Soporte

### Equipo del Proyecto
**Jefe de Proyecto:** Camilo Fuentes  
**Email:** cfuentes@judicial-tech.cl  
**Teléfono:** +56 9 XXXX XXXX

**Arquitecto Técnico:** Demian Maturana  
**Email:** dmaturana@judicial-tech.cl

**Líder Frontend:** Catalina Herrera  
**Email:** cherrera@judicial-tech.cl

### Soporte Post-Venta
**Email:** soporte@judicial-tech.cl  
**Teléfono:** +56 2 XXXX XXXX  
**Horario:** Lunes a Viernes, 9:00 - 18:00

---

## 14. Resumen Final

| CONCEPTO | VALOR (CLP) |
|----------|-------------|
| **IMPLEMENTACIÓN (Una vez)** | $50.550.000 |
| **OPERACIÓN AÑO 1** | $40.612.000 |
| **TOTAL AÑO 1** | **$91.162.000** |
| | |
| **Con descuento 10% pago anticipado** | **$82.046.000** |

### Costo Mensual Promedio (Año 1)
**$6.837.000** (con descuento)

### Retorno de Inversión
- **Año 1:** -$53.546.000
- **Año 2:** +$1.788.000 (break-even)
- **Año 3:** +$37.500.000
- **Año 5 acumulado:** +$113.288.000

---

## Conclusión

Esta propuesta ofrece:

✅ **Mejor precio** del mercado (-7% vs competencia)  
✅ **Tecnología moderna** y escalable  
✅ **Alta disponibilidad** garantizada (99.5%)  
✅ **Cumplimiento normativo** completo  
✅ **Equipo experimentado** con casos de éxito  
✅ **Soporte integral** post-implementación  
✅ **ROI positivo** desde año 2  

Estamos comprometidos con la calidad, plazos y presupuesto acordados.

---

**Firma y Timbre**

______________________________  
Jefe de Proyecto  

Fecha: 11-11-2025