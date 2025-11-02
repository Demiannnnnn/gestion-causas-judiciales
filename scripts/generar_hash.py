# Este es un script de un solo uso para generar un hash de contraseña.
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

password_plana = "Admin123!"
hashed_password = pwd_context.hash(password_plana)

print(f"Contraseña Plana: {password_plana}")
print(f"Hash Generado: {hashed_password}")
