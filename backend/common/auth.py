import os
import jwt
from functools import wraps
from flask import request, jsonify
import logging

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        # El token se espera en el encabezado 'Authorization' como 'Bearer <token>'
        if 'Authorization' in request.headers:
            try:
                auth_header = request.headers['Authorization']
                token = auth_header.split(" ")[1]
            except IndexError:
                logger.warning("El encabezado de autorización está mal formado.")
                return jsonify({'message': 'El encabezado de autorización está mal formado.'}), 401

        if not token:
            logger.warning("Falta el token de autenticación.")
            return jsonify({'message': 'Falta el token de autenticación.'}), 401

        try:
            # Decodificar el token usando la clave secreta
            secret_key = os.getenv('SECRET_KEY')
            if not secret_key:
                logger.error("La SECRET_KEY no está configurada en el servidor.")
                return jsonify({'message': 'Error de configuración del servidor.'}), 500

            data = jwt.decode(token, secret_key, algorithms=["HS256"])
            
            # Los datos del usuario (incluyendo el rol) están ahora en 'data'
            # Se los pasamos a la función decorada como un argumento.
            current_user = data
            
        except jwt.ExpiredSignatureError:
            logger.warning("El token ha expirado.")
            return jsonify({'message': 'El token ha expirado.'}), 401
        except jwt.InvalidTokenError as e:
            logger.error(f"El token es inválido: {e}")
            return jsonify({'message': f'El token es inválido: {e}'}), 401
        except Exception as e:
            logger.error(f"Ocurrió un error inesperado al procesar el token: {e}")
            return jsonify({'message': 'Ocurrió un error inesperado al procesar el token.'}), 500

        # Pasa el usuario extraído del token a la función de la ruta
        return f(current_user, *args, **kwargs)

    return decorated
