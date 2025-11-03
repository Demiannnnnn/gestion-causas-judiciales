from flask import Flask, jsonify, request
from flask_cors import CORS
from common.database import db_manager
from common.models import Notificacion, Usuario

app = Flask(__name__)
CORS(app)

@app.route("/", methods=["POST"])
def crear_notificacion():
    data = request.json
    id_usuario = data.get("id_usuario")
    tipo = data.get("tipo")
    mensaje = data.get("mensaje")

    if not all([id_usuario, tipo, mensaje]):
        return jsonify({"error": "Faltan datos (id_usuario, tipo, mensaje)"}), 400

    with db_manager.get_session() as session:
        # Verificar que el usuario existe
        usuario = session.get(Usuario, id_usuario)
        if not usuario:
            return jsonify({"error": f"Usuario con id {id_usuario} no encontrado"}), 404

        nueva_notificacion = Notificacion(
            id_usuario=id_usuario,
            tipo=tipo,
            mensaje=mensaje,
            estado='PENDIENTE'
        )
        session.add(nueva_notificacion)
        session.flush()
        result = {
            "id_notificacion": nueva_notificacion.id_notificacion,
            "mensaje": "Notificación encolada para envío"
        }

    return jsonify(result), 201

if __name__ == "__main__":
    # Este bloque no se ejecutará cuando se use Gunicorn,
    # pero es útil para pruebas locales.
    app.run(host='0.0.0.0', port=8003, debug=True)