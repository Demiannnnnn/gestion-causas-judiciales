from flask import Flask, jsonify, request
from flask_cors import CORS
import datetime
import requests
from sqlalchemy.exc import IntegrityError
import os

from common.database import db_manager
from common.models import Causa, Tribunal, Parte, CausaParte, Movimiento

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'ThatWasEpic')
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
    
    # Parsear fecha_inicio si viene como string
    fecha_inicio = data.get('fecha_inicio')
    if fecha_inicio and isinstance(fecha_inicio, str):
        try:
            fecha_inicio = datetime.datetime.strptime(fecha_inicio, '%Y-%m-%d').date()
        except ValueError:
            fecha_inicio = datetime.date.today()
    elif not fecha_inicio:
        fecha_inicio = datetime.date.today()
    
    nuevo_caso = Causa(
        rit=data['rit'],
        tribunal_id=data['tribunal_id'],
        fecha_inicio=fecha_inicio,
        estado=data.get('estado', 'ACTIVA'),
        descripcion=data.get('descripcion')
    )
    with db_manager.get_session() as session:
        try:
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
        except IntegrityError:
            session.rollback()
            return jsonify({'error': 'Ya existe un caso con el mismo RIT'}), 409

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
        
        # Enviar notificación
        send_notification({
            "tipo": "movimiento",
            "caso_rit": caso.rit,
            "destinatario": "admin@judicial.cl", # Asignar a un usuario específico o obtenerlo de la sesión
            "asunto": f"Caso Actualizado: {caso.rit}",
            "mensaje": f"Se ha actualizado el caso con RIT {caso.rit}."
        })
        
        return jsonify({'mensaje': 'Caso actualizado'})

def send_notification(data):
    try:
        requests.post("http://notificaciones:8003/send", json=data)
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

# Endpoint para obtener partes de un caso
@app.route('/<int:id>/partes', methods=['GET'])
def get_caso_partes(id):
    with db_manager.get_session() as session:
        caso = session.query(Causa).filter(Causa.id_causa == id).first()
        if not caso:
            return jsonify({'error': 'Caso no encontrado'}), 404
        
        partes_data = []
        for cp in caso.partes:
            parte = cp.parte
            representante = cp.representante.nombre if cp.representante else None
            partes_data.append({
                'id_parte': parte.id_parte,
                'nombre': parte.nombre,
                'tipo': parte.tipo,
                'rut': parte.rut,
                'representante': representante
            })
        return jsonify(partes_data)

# Endpoint para obtener movimientos de un caso
@app.route('/<int:id>/movimientos', methods=['GET'])
def get_caso_movimientos(id):
    with db_manager.get_session() as session:
        caso = session.query(Causa).filter(Causa.id_causa == id).first()
        if not caso:
            return jsonify({'error': 'Caso no encontrado'}), 404
        
        movimientos_data = [{
            'id_movimiento': m.id_movimiento,
            'fecha': m.fecha.isoformat() if m.fecha else None,
            'descripcion': m.descripcion,
            'tipo': m.tipo
        } for m in caso.movimientos]
        return jsonify(movimientos_data)

# Endpoint para crear un nuevo movimiento en un caso
@app.route('/<int:id>/movimientos', methods=['POST'])
def create_movimiento(id):
    with db_manager.get_session() as session:
        caso = session.query(Causa).filter(Causa.id_causa == id).first()
        if not caso:
            return jsonify({'error': 'Caso no encontrado'}), 404
        
        data = request.json
        
        # Parsear fecha si viene como string
        fecha = data.get('fecha')
        if fecha and isinstance(fecha, str):
            try:
                fecha = datetime.datetime.strptime(fecha, '%Y-%m-%d').date()
            except ValueError:
                return jsonify({'error': 'Formato de fecha inválido. Usar YYYY-MM-DD'}), 400
        
        nuevo_movimiento = Movimiento(
            id_causa=id,
            fecha=fecha,
            descripcion=data['descripcion'],
            tipo=data['tipo']
        )
        
        session.add(nuevo_movimiento)
        session.flush()
        
        # Enviar notificación
        send_notification({
            "tipo": "movimiento",
            "caso_rit": caso.rit,
            "destinatario": "admin@judicial.cl", # Asignar a un usuario específico o obtenerlo de la sesión
            "asunto": f"Nuevo Movimiento en Caso: {caso.rit}",
            "mensaje": f"Se ha añadido un nuevo movimiento de tipo '{data['tipo']}' en la causa con RIT {caso.rit}."
        })
        
        # Si el movimiento es de tipo 'VENCIMIENTO', llamar al endpoint de notificaciones de vencimiento
        if data['tipo'] == 'VENCIMIENTO':
            try:
                requests.post("http://notificaciones:8003/vencimientos")
            except Exception as e:
                print(f"Error calling vencimientos endpoint: {e}")
        
        return jsonify({'id_movimiento': nuevo_movimiento.id_movimiento}), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)