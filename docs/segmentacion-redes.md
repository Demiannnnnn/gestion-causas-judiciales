# Segmentación de Redes del Proyecto

## Resumen
El proyecto implementa **5 subredes aisladas** para mejorar la seguridad y el rendimiento mediante la segmentación de red.

## Arquitectura de Redes

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SEGMENTACIÓN DE REDES                            │
└─────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│  frontend-network (172.20.0.0/24) - DMZ                               │
│  ┌──────────┐  ┌──────────────────┐                                   │
│  │ Gateway  │──│ Frontend x2      │                                   │
│  │ (Traefik)│  │ (React + Nginx)  │                                   │
│  └────┬─────┘  └──────────────────┘                                   │
└───────┼─────────────────────────────────────────────────────────────────┘
        │
┌───────┼─────────────────────────────────────────────────────────────────┐
│  backend-network (172.21.0.0/24) - Capa de Aplicación                 │
│       │                                                                 │
│  ┌────┴──────────────────────────────────────────────────┐            │
│  │ Gateway  │ Microservicios Backend:                    │            │
│  │          ├── autenticacion                            │            │
│  │          ├── casos (x2 replicas)                      │            │
│  │          ├── documentos                               │            │
│  │          ├── notificaciones                           │            │
│  │          ├── reportes                                 │            │
│  │          ├── ia-seguridad                             │            │
│  │          ├── mailhog                                  │            │
│  └──────────┴────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────────────┘
        │
┌───────┼─────────────────────────────────────────────────────────────────┐
│  database-network (172.22.0.0/24) - Capa de Datos                     │
│       │                                                                 │
│  ┌────┴───────────────────────────────────────┐                       │
│  │ db-proxy (ProxySQL)                        │                       │
│  │    ├── db-master  (MySQL 8.4 - R/W)        │                       │
│  │    └── db-slave   (MySQL 8.4 - R/O)        │                       │
│  │ backup-service                             │                       │
│  └────────────────────────────────────────────┘                       │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│  cache-network (172.23.0.0/24) - Capa de Caché                        │
│  ┌──────────────────────────────────────────┐                         │
│  │ redis (master)                           │                         │
│  │ redis-replica                            │                         │
│  │   └─ Conectado desde: autenticacion,    │                         │
│  │      casos, notificaciones               │                         │
│  └──────────────────────────────────────────┘                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│  monitoring-network (172.24.0.0/24) - Observabilidad                  │
│  ┌──────────────────────────────────────────┐                         │
│  │ prometheus                               │                         │
│  │ grafana                                  │                         │
│  │ ia-seguridad (acceso a Docker socket)    │                         │
│  │ backup-service                           │                         │
│  └──────────────────────────────────────────┘                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Tabla de Segmentación

| Servicio | Frontend | Backend | Database | Cache | Monitoring | Justificación |
|----------|----------|---------|----------|-------|------------|---------------|
| **gateway (Traefik)** | ✅ | ✅ | ❌ | ❌ | ❌ | Conecta frontend con backend |
| **frontend (x2)** | ✅ | ❌ | ❌ | ❌ | ❌ | Solo accesible vía gateway |
| **autenticacion** | ❌ | ✅ | ✅ | ✅ | ❌ | Necesita DB, cache y backend |
| **casos (x2)** | ❌ | ✅ | ✅ | ✅ | ❌ | Necesita DB, cache y backend |
| **documentos** | ❌ | ✅ | ✅ | ❌ | ❌ | Necesita DB y backend |
| **notificaciones** | ❌ | ✅ | ✅ | ✅ | ❌ | Necesita DB, cache y backend |
| **reportes** | ❌ | ✅ | ✅ | ❌ | ❌ | Necesita DB y backend |
| **ia-seguridad** | ❌ | ✅ | ❌ | ❌ | ✅ | Backend + monitoreo contenedores |
| **mailhog** | ❌ | ✅ | ❌ | ❌ | ❌ | Solo backend |
| **db-master** | ❌ | ❌ | ✅ | ❌ | ❌ | **Aislado** - solo database |
| **db-slave** | ❌ | ❌ | ✅ | ❌ | ❌ | **Aislado** - solo database |
| **db-proxy** | ❌ | ✅ | ✅ | ❌ | ❌ | Puente backend ↔ database |
| **redis** | ❌ | ❌ | ❌ | ✅ | ❌ | **Aislado** - solo cache |
| **redis-replica** | ❌ | ❌ | ❌ | ✅ | ❌ | **Aislado** - solo cache |
| **prometheus** | ❌ | ❌ | ❌ | ❌ | ✅ | **Aislado** - solo monitoring |
| **grafana** | ❌ | ❌ | ❌ | ❌ | ✅ | **Aislado** - solo monitoring |
| **backup-service** | ❌ | ❌ | ✅ | ❌ | ✅ | Necesita DB y monitoring |

## Beneficios de Seguridad

### 1. **Aislamiento de Base de Datos**
- ✅ Las bases de datos (master/slave) están en su propia red
- ✅ Solo accesibles vía `db-proxy` (ProxySQL)
- ✅ No hay acceso directo desde frontend o servicios no autorizados

### 2. **Separación de Capas**
- ✅ **Frontend**: Solo puede comunicarse con Gateway
- ✅ **Gateway**: Actúa como punto de entrada único (single point of entry)
- ✅ **Backend**: Aislado del frontend, solo accesible vía Gateway
- ✅ **Database**: Completamente aislada, acceso solo mediante proxy

### 3. **Principio de Menor Privilegio**
- ✅ Cada servicio solo tiene acceso a las redes que necesita
- ✅ Redis aislado - solo servicios que lo requieren pueden acceder
- ✅ Monitoring aislado - métricas no expuestas a servicios de aplicación

### 4. **Defensa en Profundidad**
```
Usuario → Frontend → Gateway → Backend → Proxy → Database
         [Red 1]    [Red 1+2]  [Red 2]   [Red 2+3] [Red 3]
```

## Comandos de Verificación

### Ver todas las redes
```bash
docker network ls | grep proyectolicitacion
```

### Inspeccionar subredes
```bash
docker network inspect proyectolicitacion_admin2025_2_frontend-network \
  --format='{{.Name}}: {{range .IPAM.Config}}{{.Subnet}}{{end}}'
```

### Ver servicios en una red específica
```bash
docker network inspect proyectolicitacion_admin2025_2_database-network \
  --format='{{range .Containers}}{{.Name}} {{end}}'
```

### Verificar conectividad entre capas
```bash
# Desde backend a database (debe funcionar)
docker exec autenticacion ping -c 1 db-proxy

# Desde frontend a database (debe fallar - aislado)
docker exec proyectolicitacion_admin2025_2-frontend-1 ping -c 1 db-master
```

## Cumplimiento con Requisitos

✅ **Segmentación de Redes**: 5 subredes aisladas con diferentes rangos IP  
✅ **Principio de Menor Privilegio**: Cada servicio solo en redes necesarias  
✅ **Aislamiento de Datos Sensibles**: BD aislada en subnet privada  
✅ **Gateway Único**: Traefik como único punto de entrada  
✅ **Alta Disponibilidad**: No afectada por segmentación de redes  

## Notas Técnicas

- **Rango IP Base**: 172.20.0.0/16
- **Subredes /24**: Permite 254 hosts por red
- **Driver**: bridge (por defecto en Docker)
- **DNS Interno**: Docker provee resolución automática de nombres entre contenedores en la misma red
- **Overhead**: Mínimo - Docker maneja routing entre redes eficientemente

## Diagrama Simplificado de Flujo de Datos

```
[Usuario] 
    ↓
[Navegador:8081] 
    ↓
[Traefik Gateway] ←→ frontend-network
    ↓
[Backend Services] ←→ backend-network
    ↓
[ProxySQL] ←→ backend-network + database-network
    ↓
[MySQL Master/Slave] ←→ database-network
```

---
**Implementado**: 10 de noviembre de 2025  
**Estado**: ✅ Completamente funcional  
**Contenedores**: 19 activos en 5 subredes  
