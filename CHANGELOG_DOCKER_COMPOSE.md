# Changelog: Migración a Docker Compose V2

## Fecha: 2025-11-10

## Cambio Realizado

Actualización de todos los scripts y documentación para usar la sintaxis moderna de Docker Compose V2.

### Antes
```bash
docker-compose up -d
docker-compose down
docker-compose ps
```

### Después
```bash
docker compose up -d
docker compose down
docker compose ps
```

## Archivos Modificados

### Scripts (7 archivos)
- ✅ `start.sh` - 11 referencias actualizadas
- ✅ `scripts/manage-configs.sh` - 8 referencias actualizadas
- ✅ `scripts/validate-env.sh` - Referencias actualizadas

### Documentación (4 archivos)
- ✅ `QUICKSTART.md` - Referencias actualizadas
- ✅ `ALPINE_CONFIGS_SUMMARY.md` - Referencias actualizadas
- ✅ `docs/CONFIG-INIT-SYSTEM.md` - Referencias actualizadas
- ✅ `docs/ALPINE_ARCHITECTURE.md` - Referencias actualizadas

## Motivo del Cambio

Docker Compose V2 es ahora el estándar oficial:
- **V1 (docker-compose)**: Python-based, obsoleto
- **V2 (docker compose)**: Go-based, integrado en Docker CLI

## Compatibilidad

✅ **Compatible hacia adelante**: V2 es compatible con archivos V1
✅ **Mejor rendimiento**: V2 es más rápido
✅ **Mejor soporte**: V2 es activamente mantenido

## Verificación

Para verificar que tienes Docker Compose V2:
```bash
docker compose version
```

Salida esperada:
```
Docker Compose version v2.x.x
```

## Impacto

**Sin impacto** en la funcionalidad:
- Mismos comandos, diferente sintaxis
- Mismos archivos docker-compose.yml
- Mismas capacidades

## Comandos Actualizados

| Comando Antiguo | Comando Nuevo |
|----------------|---------------|
| `docker-compose up` | `docker compose up` |
| `docker-compose down` | `docker compose down` |
| `docker-compose ps` | `docker compose ps` |
| `docker-compose logs` | `docker compose logs` |
| `docker-compose restart` | `docker compose restart` |

## Instrucciones de Uso

Los scripts funcionan exactamente igual:

```bash
# Inicio del sistema
./start.sh

# Gestión de configuraciones
./scripts/manage-configs.sh status
./scripts/manage-configs.sh logs

# Validación
./scripts/validate-env.sh
```

## Notas Adicionales

- Los archivos `docker-compose.yml` **NO** necesitan cambios
- La funcionalidad permanece **idéntica**
- Los scripts detectan automáticamente si Docker Compose está disponible

---

**Versión**: 1.0.0  
**Autor**: Sistema de Gestión de Causas Judiciales  
**Estado**: ✅ Completado
