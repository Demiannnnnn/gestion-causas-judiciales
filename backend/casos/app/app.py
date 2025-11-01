
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Habilitar CORS para todas las rutas

# Datos de ejemplo en memoria
casos = [
    {
        "id": 1,
        "rit": "C-1234-2023",
        "tribunal": "1er Juzgado de Letras de Santiago",
        "partes": "Demandante A vs. Demandado B",
        "fecha_inicio": "2023-01-15",
        "estado": "Activo"
    },
    {
        "id": 2,
        "rit": "O-5678-2022",
        "tribunal": "Juzgado de Familia de Puente Alto",
        "partes": "Solicitante X vs. Solicitado Y",
        "fecha_inicio": "2022-11-20",
        "estado": "Archivado"
    }
]
next_id = 3

# Endpoint para obtener todos los casos (con búsqueda)
@app.route('/casos', methods=['GET'])
def get_casos():
    query = request.args.get('query', '').lower()
    if query:
        resultados = [caso for caso in casos if query in caso['rit'].lower() or query in caso['tribunal'].lower()]
        return jsonify(resultados)
    return jsonify(casos)

# Endpoint para obtener un caso por ID
@app.route('/casos/<int:id>', methods=['GET'])
def get_caso(id):
    caso = next((c for c in casos if c['id'] == id), None)
    if caso:
        return jsonify(caso)
    return jsonify({'error': 'Caso no encontrado'}), 404

# Endpoint para crear un nuevo caso
@app.route('/casos', methods=['POST'])
def create_caso():
    global next_id
    data = request.json
    nuevo_caso = {
        "id": next_id,
        "rit": data['rit'],
        "tribunal": data['tribunal'],
        "partes": data['partes'],
        "fecha_inicio": data['fecha_inicio'],
        "estado": data['estado']
    }
    casos.append(nuevo_caso)
    next_id += 1
    return jsonify(nuevo_caso), 201

# Endpoint para actualizar un caso
@app.route('/casos/<int:id>', methods=['PUT'])
def update_caso(id):
    caso = next((c for c in casos if c['id'] == id), None)
    if not caso:
        return jsonify({'error': 'Caso no encontrado'}), 404
    data = request.json
    caso.update({
        "rit": data.get('rit', caso['rit']),
        "tribunal": data.get('tribunal', caso['tribunal']),
        "partes": data.get('partes', caso['partes']),
        "fecha_inicio": data.get('fecha_inicio', caso['fecha_inicio']),
        "estado": data.get('estado', caso['estado'])
    })
    return jsonify(caso)

# Endpoint para eliminar un caso
@app.route('/casos/<int:id>', methods=['DELETE'])
def delete_caso(id):
    global casos
    caso = next((c for c in casos if c['id'] == id), None)
    if not caso:
        return jsonify({'error': 'Caso no encontrado'}), 404
    casos = [c for c in casos if c['id'] != id]
    return jsonify({'mensaje': 'Caso eliminado'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
