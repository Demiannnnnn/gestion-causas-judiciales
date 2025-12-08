from flask import Flask, jsonify, request
from flask_cors import CORS

from common.database import db_manager
from common.models import Usuario
from auth import verify_password, create_access_token
from common.logging_utils import get_logger

logger = get_logger(__name__)

app = Flask(__name__)
CORS(app)

@app.route("/login", methods=["POST"])
def login():
    data = request.json
    correo = data.get("correo")
    password = data.get("password")

    if not correo or not password:
        logger.warning(f"Login failed: Missing credentials from {request.remote_addr}")
        return jsonify({"msg": "Faltan correo o contraseña"}), 400

    with db_manager.get_session() as session:
        user = session.query(Usuario).filter(Usuario.correo == correo).first()

        if not user or not verify_password(password, user.password_hash):
            logger.warning(f"Login failed: Invalid credentials for user {correo} from {request.remote_addr}")
            return jsonify({"msg": "Credenciales incorrectas"}), 401
        
        if not user.activo:
            logger.warning(f"Login failed: Inactive user {correo} from {request.remote_addr}")
            return jsonify({"msg": "Usuario inactivo"}), 403

        # Crear el token con datos del usuario
        access_token = create_access_token(
            data={"id_usuario": user.id_usuario, "rol": user.rol}
        )
        logger.info(f"Login successful: User {correo} ({user.rol}) logged in from {request.remote_addr}")
        return jsonify(access_token=access_token)

@app.route("/health")
def health_check():
    return jsonify({"status": "healthy"})