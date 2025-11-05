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

# Endpoint para actualizar un caso
@app.route('/<int:id>', methods=['PUT'])
def update_caso(id):
    with db_manager.get_session() as session:
        caso = session.query(Causa).filter(Causa.id_causa == id).first()
        if not caso:
            return jsonify({'error': 'Caso no encontrado'}), 404
        
        data = request.json
        caso.rit = data.get('rit', caso.rit)
        caso.tribunal_id = data.get('tribunal_id', caso.tribunal_id)
        caso.fecha_inicio = data.get('fecha_inicio', caso.fecha_inicio)
        caso.estado = data.get('estado', caso.estado)
        caso.descripcion = data.get('descripcion', caso.descripcion)
        
<<<<<<< HEAD
<<<<<<< HEAD
        # Enviar notificación
        send_notification({
            "tipo": "movimiento",
            "caso_rit": caso.rit,
            "destinatario": "admin@judicial.cl", # Asignar a un usuario específico o obtenerlo de la sesión
            "asunto": f"Caso Actualizado: {caso.rit}",
            "mensaje": f"Se ha actualizado el caso con RIT {caso.rit}."
        })
        
        return jsonify({'mensaje': 'Caso actualizado'})
=======
        return jsonify(caso.to_json())
>>>>>>> master
=======
        return jsonify(caso.to_json())
>>>>>>> 32a54c76400ffb5b286a99b00821929ec2447f25

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