import os
import jwt
from datetime import datetime, timedelta, timezone
from passlib.context import CryptContext

# Configuración de Passlib para hashear contraseñas
# Se usará bcrypt como el algoritmo principal
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Configuración de JWT
JWT_SECRET = os.getenv("JWT_SECRET", "a-very-secret-key")
ALGORITHM = "HS256"

def verify_password(plain_password, hashed_password):
    """Verifica una contraseña en texto plano contra un hash."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    """Genera el hash de una contraseña."""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: timedelta = timedelta(hours=24)):
    """Crea un nuevo token de acceso JWT."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + expires_delta
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET, algorithm=ALGORITHM)
    return encoded_jwt
