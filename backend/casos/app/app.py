from flask import Flask, jsonify, request
from flask_cors import CORS
import datetime

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

# Endpoint para obtener las partes de un caso
@app.route('/<int:id>/partes', methods=['GET'])
def get_partes_caso(id):
    with db_manager.get_session() as session:
        caso = session.query(Causa).filter(Causa.id_causa == id).first()
        if not caso:
            return jsonify({'error': 'Caso no encontrado'}), 404
        
        partes = []
        for causa_parte in caso.partes:
            parte_info = {
                'nombre': causa_parte.parte.nombre,
                'tipo': causa_parte.parte.tipo,
                'representante': causa_parte.representante.nombre if causa_parte.representante else 'No asignado'
            }
            partes.append(parte_info)
            
        return jsonify(partes)

# Endpoint para obtener los movimientos de un caso
@app.route('/<int:id>/movimientos', methods=['GET'])
def get_movimientos_caso(id):
    with db_manager.get_session() as session:
        caso = session.query(Causa).filter(Causa.id_causa == id).first()
        if not caso:
            return jsonify({'error': 'Caso no encontrado'}), 404
        
        movimientos = []
        for movimiento in caso.movimientos:
            movimiento_info = {
                'fecha': movimiento.fecha.isoformat() if movimiento.fecha else None,
                'descripcion': movimiento.descripcion,
                'tipo': movimiento.tipo
            }
            movimientos.append(movimiento_info)
            
        return jsonify(movimientos)

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
        
        return jsonify(caso.to_json())

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