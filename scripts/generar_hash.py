# Script de utilidad para generar un hash bcrypt de contraseña.
import getpass
import os
import sys
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def main():
    password_plana = (
        sys.argv[1]
        if len(sys.argv) > 1
        else os.getenv("PASSWORD_TO_HASH") or getpass.getpass("Ingrese contraseña a hashear: ")
    )
    if not password_plana:
        raise SystemExit("Error: Debe proporcionar una contraseña por argumento, PASSWORD_TO_HASH o stdin.")
    hashed_password = pwd_context.hash(password_plana)
    print(f"Hash Generado: {hashed_password}")


if __name__ == "__main__":
    main()
