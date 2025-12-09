import os

def load_env_file(filepath):
    """Carga variables del archivo .env en un diccionario."""
    env_vars = {}
    try:
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key] = value
    except FileNotFoundError:
        print(f"Advertencia: Archivo .env no encontrado en {filepath}. Usando valores por defecto/vacíos.")
    except Exception as e:
        print(f"Error leyendo .env: {e}")
    return env_vars

def main():
    # Rutas dentro del contenedor
    env_path = '/usr/local/bin/.env'
    template_path = '/usr/local/bin/proxysql.cnf.template'
    output_path = '/etc/proxysql/proxysql.cnf'

    print(f"Leyendo .env desde: {env_path}")
    env_vars = load_env_file(env_path)
    
    # Asegurar valores por defecto si faltan en .env o si no se cargó el archivo
    defaults = {
        'MYSQL_MONITOR_USER': 'monitor',
        'MYSQL_MONITOR_PASSWORD': 'monitor',
        'MYSQL_PASSWORD_ADMIN_APP': 'admin_pass',
        'MYSQL_PASSWORD_ABOGADO_APP': 'abogado_pass',
        'MYSQL_PASSWORD_ASISTENTE_APP': 'asistente_pass',
        'MYSQL_PASSWORD_SISTEMAS_APP': 'sistemas_pass',
        'MYSQL_PASSWORD_READONLY_APP': 'readonly_pass',
        'MYSQL_DATABASE': 'causas_judiciales_db' # También se usa en la plantilla original
    }
    
    for key, val in defaults.items():
        if key not in env_vars or not env_vars[key]: # Verificar también si el valor está vacío
            print(f"Advertencia: {key} no encontrado o vacío en .env, usando valor por defecto '{val}'.")
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
    content = content.replace('__MYSQL_MONITOR_USER__', env_vars['MYSQL_MONITOR_USER'])
    content = content.replace('__MYSQL_MONITOR_PASSWORD__', env_vars['MYSQL_MONITOR_PASSWORD'])
    content = content.replace('__MYSQL_PASSWORD_ADMIN_APP__', env_vars['MYSQL_PASSWORD_ADMIN_APP'])
    content = content.replace('__MYSQL_PASSWORD_ABOGADO_APP__', env_vars['MYSQL_PASSWORD_ABOGADO_APP'])
    content = content.replace('__MYSQL_PASSWORD_ASISTENTE_APP__', env_vars['MYSQL_PASSWORD_ASISTENTE_APP'])
    content = content.replace('__MYSQL_PASSWORD_SISTEMAS_APP__', env_vars['MYSQL_PASSWORD_SISTEMAS_APP'])
    content = content.replace('__MYSQL_PASSWORD_READONLY_APP__', env_vars['MYSQL_PASSWORD_READONLY_APP'])
    content = content.replace('__DEFAULT_DB__', env_vars['MYSQL_DATABASE']) # Nuevo reemplazo para la plantilla

    print(f"Escribiendo configuración en: {output_path}")
    try:
        with open(output_path, 'w') as f:
            f.write(content)
        print("✅ Archivo proxysql.cnf regenerado con éxito.")
    except Exception as e:
        print(f"Error escribiendo el archivo de configuración: {e}")

if __name__ == "__main__":
    main()