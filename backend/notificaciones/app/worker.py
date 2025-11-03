import time
import os
import smtplib
from email.mime.text import MIMEText

from common.database import db_manager
from common.models import Notificacion, Usuario

# --- Configuración del Worker ---
POLL_INTERVAL = 10  # Segundos entre cada ciclo de búsqueda
SMTP_SERVER = os.environ.get("MAIL_SERVER")
SMTP_PORT = int(os.environ.get("MAIL_PORT", 587))
SMTP_USER = os.environ.get("MAIL_USERNAME")
SMTP_PASSWORD = os.environ.get("MAIL_PASSWORD")

def send_email(destinatario, asunto, cuerpo):
    """
    Función para enviar un email.
    Si no hay un servidor SMTP configurado, simula el envío imprimiendo en consola.
    """
    if not SMTP_SERVER:
        print("\n--- SIMULANDO ENVÍO DE EMAIL ---")
        print(f"Destinatario: {destinatario}")
        print(f"Asunto: {asunto}")
        print(f"Cuerpo: {cuerpo}")
        print("---------------------------------\n")
        return True

    try:
        msg = MIMEText(cuerpo)
        msg['Subject'] = asunto
        msg['From'] = SMTP_USER or 'noreply@judicial.cl'
        msg['To'] = destinatario

        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            # MailHog no requiere TLS ni autenticación
            server.send_message(msg)
            print(f"Email enviado exitosamente a {destinatario} via MailHog")
        return True
    except Exception as e:
        print(f"Error al enviar email a {destinatario}: {e}")
        return False

def procesar_notificaciones_pendientes():
    """
    Busca notificaciones con estado 'PENDIENTE' y las procesa.
    """
    with db_manager.get_session() as session:
        notificaciones = session.query(Notificacion).filter_by(estado='PENDIENTE').all()
        if not notificaciones:
            return

        print(f"\nSe encontraron {len(notificaciones)} notificaciones pendientes.")

        for notif in notificaciones:
            usuario = session.get(Usuario, notif.id_usuario)
            if not usuario:
                print(f"Usuario {notif.id_usuario} no encontrado. Marcando notificación como FALLIDO.")
                notif.estado = 'FALLIDO'
                continue

            asunto = f"Notificación del Sistema: {notif.tipo}"
            cuerpo = notif.mensaje

            print(f"Procesando notificación {notif.id_notificacion} para {usuario.correo}...")
            if send_email(usuario.correo, asunto, cuerpo):
                notif.estado = 'ENVIADA'
            else:
                notif.estado = 'FALLIDO'

def main():
    """
    Bucle principal del worker que se ejecuta indefinidamente.
    """
    print("Iniciando worker de notificaciones...")
    while True:
        try:
            procesar_notificaciones_pendientes()
        except Exception as e:
            print(f"Error en el ciclo principal del worker: {e}")
        
        time.sleep(POLL_INTERVAL)

if __name__ == "__main__":
    main()
