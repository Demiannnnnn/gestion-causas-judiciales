from flask import Flask, jsonify, request
from flask_cors import CORS
import datetime
import requests

from common.database import db_manager
from common.models import Causa, Tribunal

app = Flask(__name__)
CORS(app)  # Habilitar CORS para todas las rutas

# Endpoint para obtener todos los casos
@app.route('/', methods=['GET'])
def get_casos():
    with db_manager.get_session() as session:
        casos = session.query(Causa).all()
        return jsonify([c.to_json() for c in casos])

# Endpoint para obtener todos los tribunales
@app.route('/tribunales', methods=['GET'])
def get_tribunales():
    with db_manager.get_session() as session:
        tribunales = session.query(Tribunal).all()
        return jsonify([
            {
                "id_tribunal": t.id_tribunal,
                "nombre": t.nombre
            } for t in tribunales
        ])

# Endpoint para obtener un caso por ID
@app.route('/<int:id>', methods=['GET'])
def get_caso(id):
    with db_manager.get_session() as session:
        caso = session.query(Causa).filter(Causa.id_causa == id).first()
        if caso:
            return jsonify(caso.to_json())
        return jsonify({'error': 'Caso no encontrado'}), 404

# Endpoint para crear un nuevo caso
@app.route('/', methods=['POST'])
def create_caso():
    data = request.json
    nuevo_caso = Causa(
        rit=data['rit'],
        tribunal_id=data['tribunal_id'],
        fecha_inicio=datetime.date.today(),  # Fecha actual automática
        estado='ACTIVA',
        descripcion=data.get('descripcion')  # Nuevo campo de descripción
    )
    with db_manager.get_session() as session:
        session.add(nuevo_caso)
        session.flush() # Para obtener el ID antes del commit
        
        # Enviar notificación
        send_notification({
            "tipo": "movimiento",
            "caso_rit": nuevo_caso.rit,
            "destinatario": "admin@judicial.cl", # Asignar a un usuario específico o obtenerlo de la sesión
            "asunto": f"Nuevo Caso Creado: {nuevo_caso.rit}",
            "mensaje": f"Se ha creado un nuevo caso con RIT {nuevo_caso.rit}."
        })
        
        return jsonify({'id_causa': nuevo_caso.id_causa}), 201
    
# Nueva función para enviar notificación al servicio 'notificaciones'
def notify_status_change(caso):
    # Usamos el nombre del servicio 'notificaciones' como host (gracias a Docker network)
    NOTIF_URL = "http://notificaciones:8003/alerta-movimiento"
    
    # Se asume un destinatario de prueba, en un sistema real se consultaría a la BD de usuarios
    destinatarios_prueba = ["abogado@judicial.cl"] 
    
    payload = {
        "caso_rit": caso.rit,
        "destinatarios": destinatarios_prueba,
        "movimiento": f"El estado del caso ha cambiado a: {caso.estado}"
    }
    
    try:
        # Enviar la solicitud POST
        response = requests.post(NOTIF_URL, json=payload, timeout=5)
        response.raise_for_status() # Lanza excepción para errores 4xx/5xx
        print(f"Notificación de cambio de estado enviada: {response.status_code}")
    except requests.exceptions.RequestException as e:
        # Esto evita que una falla en 'notificaciones' detenga el servicio 'casos'
        print(f"ERROR al enviar notificación al servicio 'notificaciones': {e}")

# Endpoint para actualizar un caso
@app.route('/<int:id>', methods=['PUT'])
def update_caso(id):
    with db_manager.get_session() as session:
        caso = session.query(Causa).filter(Causa.id_causa == id).first()
        if not caso:
            return jsonify({'error': 'Caso no encontrado'}), 404
        
        data = request.json
        estado_anterior = caso.estado 
        
        # Actualizar campos
        caso.rit = data.get('rit', caso.rit)
        caso.tribunal_id = data.get('tribunal_id', caso.tribunal_id)
        caso.fecha_inicio = data.get('fecha_inicio', caso.fecha_inicio)
        nuevo_estado = data.get('estado', caso.estado)
        caso.descripcion = data.get('descripcion', caso.descripcion)

        # Lógica de notificación
        if nuevo_estado != estado_anterior:
            # Actualizar el estado antes de notificar
            caso.estado = nuevo_estado
            session.add(caso) 
            session.flush() # Guardar el cambio inmediatamente
            
            # Enviar notificación de forma no bloqueante (dentro de lo posible en un microservicio síncrono)
            notify_status_change(caso)
        else:
            caso.estado = nuevo_estado
        
        return jsonify(caso.to_json())

def send_notification(data):
    try:
        requests.post("http://notificaciones:8003/notificaciones/send", json=data)
    except Exception as e:
        print(f"Error sending notification: {e}")

# Endpoint para eliminar un caso
@app.route('/<int:id>', methods=['DELETE'])
def delete_caso(id):
    with db_manager.get_session() as session:
        caso = session.query(Causa).filter(Causa.id_causa == id).first()
        if not caso:
            return jsonify({'error': 'Caso no encontrado'}), 404
        
        session.delete(caso)
        return jsonify({'mensaje': 'Caso eliminado'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)