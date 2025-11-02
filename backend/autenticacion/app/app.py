from flask import Flask, jsonify, request
from flask_cors import CORS

from database import db_manager
from models import Usuario
from auth import verify_password, create_access_token

app = Flask(__name__)
CORS(app)

@app.route("/login", methods=["POST"])
def login():
    data = request.json
    correo = data.get("correo")
    password = data.get("password")

    if not correo or not password:
        return jsonify({"msg": "Faltan correo o contraseña"}), 400

    with db_manager.get_session() as session:
        user = session.query(Usuario).filter(Usuario.correo == correo).first()

        if not user or not verify_password(password, user.password_hash):
            return jsonify({"msg": "Credenciales incorrectas"}), 401
        
        if not user.activo:
            return jsonify({"msg": "Usuario inactivo"}), 403

        # Crear el token con datos del usuario
        access_token = create_access_token(
            data={"id_usuario": user.id_usuario, "rol": user.rol}
        )
        return jsonify(access_token=access_token)

@app.route("/health")
def health_check():
    return jsonify({"status": "healthy"})