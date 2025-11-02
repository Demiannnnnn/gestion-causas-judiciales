from flask import Flask, jsonify, request
from flask_cors import CORS
from database import db_manager
from models import Causa

app = Flask(__name__)
CORS(app)  # Habilitar CORS para todas las rutas


# Endpoint para obtener todos los casos
@app.route("/", methods=["GET"])
def get_casos():
    with db_manager.get_session() as session:
        casos = session.query(Causa).all()
        return jsonify(
            [
                {
                    "id_causa": c.id_causa,
                    "rit": c.rit,
                    "tribunal_id": c.tribunal_id,
                    "fecha_inicio": c.fecha_inicio.isoformat()
                    if c.fecha_inicio
                    else None,
                    "estado": c.estado,
                    "descripcion": c.descripcion,
                }
                for c in casos
            ]
        )


# Endpoint para obtener un caso por ID
@app.route("/<int:id>", methods=["GET"])
def get_caso(id):
    with db_manager.get_session() as session:
        caso = session.query(Causa).filter(Causa.id_causa == id).first()
        if caso:
            return jsonify(
                {
                    "id_causa": caso.id_causa,
                    "rit": caso.rit,
                    "tribunal_id": caso.tribunal_id,
                    "fecha_inicio": caso.fecha_inicio.isoformat()
                    if caso.fecha_inicio
                    else None,
                    "estado": caso.estado,
                    "descripcion": caso.descripcion,
                }
            )
        return jsonify({"error": "Caso no encontrado"}), 404


# Endpoint para crear un nuevo caso
@app.route("/", methods=["POST"])
def create_caso():
    data = request.json
    nuevo_caso = Causa(
        rit=data["rit"],
        tribunal_id=data["tribunal_id"],
        fecha_inicio=data.get("fecha_inicio"),
        estado=data.get("estado", "ACTIVA"),
        descripcion=data.get("descripcion"),
    )
    with db_manager.get_session() as session:
        session.add(nuevo_caso)
        session.flush()  # Para obtener el ID antes del commit
        return jsonify({"id_causa": nuevo_caso.id_causa}), 201


# Endpoint para actualizar un caso
@app.route("/<int:id>", methods=["PUT"])
def update_caso(id):
    with db_manager.get_session() as session:
        caso = session.query(Causa).filter(Causa.id_causa == id).first()
        if not caso:
            return jsonify({"error": "Caso no encontrado"}), 404

        data = request.json
        caso.rit = data.get("rit", caso.rit)
        caso.tribunal_id = data.get("tribunal_id", caso.tribunal_id)
        caso.fecha_inicio = data.get("fecha_inicio", caso.fecha_inicio)
        caso.estado = data.get("estado", caso.estado)
        caso.descripcion = data.get("descripcion", caso.descripcion)

        return jsonify({"mensaje": "Caso actualizado"})


# Endpoint para eliminar un caso
@app.route("/<int:id>", methods=["DELETE"])
def delete_caso(id):
    with db_manager.get_session() as session:
        caso = session.query(Causa).filter(Causa.id_causa == id).first()
        if not caso:
            return jsonify({"error": "Caso no encontrado"}), 404

        session.delete(caso)
        return jsonify({"mensaje": "Caso eliminado"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
