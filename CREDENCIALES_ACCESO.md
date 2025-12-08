# Credenciales de Acceso - Sistema de Gestión Judicial

Estas son las cuentas de usuario preconfiguradas para pruebas de desarrollo y QA.
Todas las cuentas comparten la misma contraseña por defecto.

## Contraseña Global
**Contraseña:** `Admin123!`

## Usuarios por Rol

| Rol | Correo Electrónico | Nivel de Acceso (Base de Datos) | Descripción |
| :--- | :--- | :--- | :--- |
| **ADMINISTRADOR** | `admin@judicial.cl` | **Total**: `ALL PRIVILEGES` en todas las tablas. | Acceso total al sistema, gestión de usuarios y auditoría. |
| **ABOGADO** | `abogado@judicial.cl` | **Edición Limitada**: `SELECT`, `INSERT`, `UPDATE` en tablas de negocio. Solo `SELECT` en tablas administrativas. | Gestión de causas, escritos y documentos. |
| **ASISTENTE** | `asistente@judicial.cl` | **Operativo**: `SELECT` global. `INSERT` solo en movimientos, documentos y notificaciones. | Apoyo administrativo, revisión de estados y carga básica. |
| **SISTEMAS** | `sistemas@judicial.cl` | **Auditoría**: `SELECT` global. `INSERT`/`UPDATE` solo en logs del sistema. | Acceso técnico, visualización de logs y monitoreo (si aplica). |

> **Nota:** Si necesitas generar nuevas contraseñas, utiliza el script `scripts/generar_hash.py` para obtener el hash bcrypt compatible.