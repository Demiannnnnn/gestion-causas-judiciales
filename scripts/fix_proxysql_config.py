import os

def main():
    # Rutas dentro del contenedor
    template_path = '/usr/local/bin/proxysql.cnf.template'
    output_path = '/etc/proxysql/proxysql.cnf'

    print(f"Generando configuración de ProxySQL...")
    
    # Obtener variables de entorno directamente del sistema
    # Docker Compose se encarga de inyectarlas desde el archivo .env del host
    env_vars = os.environ.copy()
    
    # Asegurar valores por defecto si faltan en las variables de entorno
    defaults = {
        'MYSQL_MONITOR_USER': 'monitor',
        'MYSQL_MONITOR_PASSWORD': 'monitor',
        'MYSQL_PASSWORD_ADMIN_APP': 'admin_pass',
        'MYSQL_PASSWORD_ABOGADO_APP': 'abogado_pass',
        'MYSQL_PASSWORD_ASISTENTE_APP': 'asistente_pass',
        'MYSQL_PASSWORD_SISTEMAS_APP': 'sistemas_pass',
        'MYSQL_PASSWORD_READONLY_APP': 'readonly_pass',
        'MYSQL_DATABASE': 'causas_judiciales_db'
    }
    
    for key, val in defaults.items():
        if key not in env_vars or not env_vars[key]:
            print(f"Advertencia: {key} no encontrada en variables de entorno, usando valor por defecto.")
            env_vars[key] = val

    print(f"Leyendo plantilla desde: {template_path}")
    try:
        with open(template_path, 'r') as f:
            template_content = f.read()
    except FileNotFoundError:
        print(f"Error: No se encontró la plantilla en {template_path}.")
        return

    # Realizar reemplazos
    content = template_content
    # Usamos .get() para mayor seguridad, aunque el bloque de defaults ya debería cubrirlo
    content = content.replace('__MYSQL_MONITOR_USER__', env_vars.get('MYSQL_MONITOR_USER', ''))
    content = content.replace('__MYSQL_MONITOR_PASSWORD__', env_vars.get('MYSQL_MONITOR_PASSWORD', ''))
    content = content.replace('__MYSQL_PASSWORD_ADMIN_APP__', env_vars.get('MYSQL_PASSWORD_ADMIN_APP', ''))
    content = content.replace('__MYSQL_PASSWORD_ABOGADO_APP__', env_vars.get('MYSQL_PASSWORD_ABOGADO_APP', ''))
    content = content.replace('__MYSQL_PASSWORD_ASISTENTE_APP__', env_vars.get('MYSQL_PASSWORD_ASISTENTE_APP', ''))
    content = content.replace('__MYSQL_PASSWORD_SISTEMAS_APP__', env_vars.get('MYSQL_PASSWORD_SISTEMAS_APP', ''))
    content = content.replace('__MYSQL_PASSWORD_READONLY_APP__', env_vars.get('MYSQL_PASSWORD_READONLY_APP', ''))
    content = content.replace('__DEFAULT_DB__', env_vars.get('MYSQL_DATABASE', ''))

    print(f"Escribiendo configuración en: {output_path}")
    try:
        with open(output_path, 'w') as f:
            f.write(content)
        print("✅ Archivo proxysql.cnf regenerado con éxito.")
    except Exception as e:
        print(f"Error escribiendo el archivo de configuración: {e}")

if __name__ == "__main__":
    main()
