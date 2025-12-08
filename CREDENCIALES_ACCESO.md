# Credenciales de Acceso - Sistema de Gestión Judicial

Estas son las cuentas de usuario preconfiguradas para pruebas de desarrollo y QA.
Todas las cuentas comparten la misma contraseña por defecto.

## Contraseña Global
**Contraseña:** `Admin123!`

## Usuarios por Rol

| Rol | Correo Electrónico | Descripción |
| :--- | :--- | :--- |
| **ADMINISTRADOR** | `admin@judicial.cl` | Acceso total al sistema, gestión de usuarios y auditoría. |
| **ABOGADO** | `abogado@judicial.cl` | Gestión de causas, escritos y documentos. |
| **ASISTENTE** | `asistente@judicial.cl` | Apoyo administrativo, revisión de estados y carga básica. |
| **SISTEMAS** | `sistemas@judicial.cl` | Acceso técnico, visualización de logs y monitoreo (si aplica). |

> **Nota:** Si necesitas generar nuevas contraseñas, utiliza el script `scripts/generar_hash.py` para obtener el hash bcrypt compatible.
