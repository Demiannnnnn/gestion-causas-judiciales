import os
import smtplib
import logging
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from flask import Flask, jsonify, request
from flask_cors import CORS

from common.database import db_manager
from common.models import Notificacion, Usuario

app = Flask(__name__)
CORS(app)

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuración de email desde variables de entorno
SMTP_HOST = os.getenv("MAIL_SERVER", "mailhog")
SMTP_PORT = int(os.getenv("MAIL_PORT", 1025))
SMTP_USER = os.getenv("MAIL_USERNAME", "")
SMTP_PASSWORD = os.getenv("MAIL_PASSWORD", "")
MAIL_FROM = os.getenv("MAIL_FROM", "notificaciones@judicial.cl")


# ==================== ENDPOINTS DE SALUD ====================


@app.route("/health", methods=["GET"])
def health_check():
    """Health check para Docker"""
    return jsonify(
        {
            "status": "healthy",
            "service": "notificaciones",
            "smtp_configured": bool(SMTP_USER and SMTP_PASSWORD),
        }
    ), 200


# ==================== ENVÍO DE NOTIFICACIONES ====================


def enviar_email(destinatario, asunto, mensaje, html=False):
    """
    Función auxiliar para enviar emails

    Args:
        destinatario (str): Email del destinatario
        asunto (str): Asunto del email
        mensaje (str): Cuerpo del mensaje
        html (bool): Si el mensaje es HTML

    Returns:
        bool: True si se envió correctamente, False en caso contrario
    """
    try:
        # Crear mensaje
        msg = MIMEMultipart("alternative")
        msg["From"] = MAIL_FROM
        msg["To"] = destinatario
        msg["Subject"] = asunto

        # Adjuntar cuerpo
        if html:
            msg.attach(MIMEText(mensaje, "html"))
        else:
            msg.attach(MIMEText(mensaje, "plain"))

        # Conectar y enviar
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            if SMTP_USER and SMTP_PASSWORD:
                server.starttls()
                server.login(SMTP_USER, SMTP_PASSWORD)
            server.send_message(msg)

        logger.info(f"Email enviado a {destinatario}: {asunto}")
        return True

    except Exception as e:
        logger.error(f"Error al enviar email: {str(e)}")
        return False


@app.route("/send", methods=["POST"])
def send_notification():
    """
    Envía una notificación por email y la guarda en la base de datos

    Body JSON:
    {
        "tipo": "vencimiento|movimiento|alerta",
        "caso_rit": "C-1234-2023",
        "destinatario": "email@example.com",
        "asunto": "Asunto del mensaje",
        "mensaje": "Cuerpo del mensaje"
    }
    """
    try:
        data = request.get_json()

        # Validar campos requeridos
        required_fields = ["tipo", "destinatario", "asunto", "mensaje"]
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Campo requerido: {field}"}), 400

        # Enviar email
        success = enviar_email(
            destinatario=data["destinatario"],
            asunto=data["asunto"],
            mensaje=data["mensaje"],
        )

        # Guardar en base de datos
        with db_manager.get_session() as session:
            # Buscar usuario por email
            usuario = session.query(Usuario).filter_by(correo=data["destinatario"]).first()
            id_usuario = usuario.id_usuario if usuario else None

            nueva_notificacion = Notificacion(
                id_usuario=id_usuario,
                tipo=data["tipo"],
                caso_rit=data.get("caso_rit", "N/A"),
                destinatario=data["destinatario"],
                asunto=data["asunto"],
                mensaje=data["mensaje"],
                fecha_envio=datetime.now(),
                estado="ENVIADA" if success else "ERROR",
                leido=False,
            )
            session.add(nueva_notificacion)
            session.flush()
            notificacion_json = nueva_notificacion.to_json()

        return jsonify({"success": success, "notificacion": notificacion_json}), 201

    except Exception as e:
        logger.error(f"Error al enviar notificación: {str(e)}")
        return jsonify({"error": "Error interno del servidor"}), 500


# ==================== GESTIÓN DE NOTIFICACIONES ====================


@app.route("/vencimientos", methods=["POST"])
def crear_notificaciones_vencimiento():
    """
    Busca vencimientos próximos y crea notificaciones para los usuarios asociados.
    """
    print("--- Ejecutando crear_notificaciones_vencimiento ---")
    with db_manager.get_session() as session:
        today = datetime.now().date()
        deadline_date = today + timedelta(days=7)

        # Buscar movimientos de tipo 'VENCIMIENTO' en el rango de fechas
        vencimientos = session.query(Movimiento).filter(
            Movimiento.tipo == 'VENCIMIENTO',
            Movimiento.fecha >= today,
            Movimiento.fecha <= deadline_date
        ).all()

        if not vencimientos:
            print("No se encontraron vencimientos próximos.")
            return jsonify({"message": "No se encontraron vencimientos próximos."}), 200

        print(f"Se encontraron {len(vencimientos)} vencimientos próximos.")

        for vencimiento in vencimientos:
            causa = session.get(Causa, vencimiento.id_causa)
            if not causa:
                continue

            # Encontrar los usuarios asociados a la causa (abogados representantes)
            causa_partes = session.query(CausaParte).filter_by(id_causa=causa.id_causa).all()
            for cp in causa_partes:
                if cp.representado_por:
                    usuario = session.get(Usuario, cp.representado_por)
                    if usuario:
                        # Verificar si ya existe una notificación para este vencimiento y usuario
                        notif_existente = session.query(Notificacion).filter_by(
                            id_usuario=usuario.id_usuario,
                            caso_rit=causa.rit,
                            tipo='VENCIMIENTO',
                            mensaje=f"El plazo para '{vencimiento.descripcion}' en la causa {causa.rit} vence el {vencimiento.fecha.strftime('%Y-%m-%d')}."
                        ).first()

                        if not notif_existente:
                            nueva_notificacion = Notificacion(
                                id_usuario=usuario.id_usuario,
                                tipo='VENCIMIENTO',
                                destinatario=usuario.correo,
                                asunto=f"Alerta de Vencimiento: Causa {causa.rit}",
                                mensaje=f"El plazo para '{vencimiento.descripcion}' en la causa {causa.rit} vence el {vencimiento.fecha.strftime('%Y-%m-%d')}.",
                                caso_rit=causa.rit,
                                estado='PENDIENTE'
                            )
                            session.add(nueva_notificacion)
                            print(f"Notificación de vencimiento creada para {usuario.correo} en causa {causa.rit}")
        
        return jsonify({"message": f"Se crearon notificaciones para {len(vencimientos)} vencimientos."}), 200


@app.route("/resumen-diario", methods=["POST"])
def generar_resumen_diario():
    """
    Genera y envía un resumen diario de notificaciones no leídas a cada usuario.
    """
    print("--- Ejecutando generar_resumen_diario ---")
    with db_manager.get_session() as session:
        usuarios = session.query(Usuario).all()

        for usuario in usuarios:
            notificaciones_no_leidas = session.query(Notificacion).filter_by(
                id_usuario=usuario.id_usuario,
                leido=False
            ).all()

            if not notificaciones_no_leidas:
                continue

            print(f"Generando resumen para {usuario.correo} con {len(notificaciones_no_leidas)} notificaciones no leídas.")

            # Construir el cuerpo del email
            cuerpo_html = "<h1>Resumen Diario de Notificaciones</h1>"
            cuerpo_html += f"<p>Hola {usuario.nombre}, aquí tienes un resumen de tus notificaciones no leídas:</p>"
            cuerpo_html += "<ul>"
            for notif in notificaciones_no_leidas:
                cuerpo_html += f"<li><b>{notif.asunto}</b>: {notif.mensaje} <i>(Recibido: {notif.fecha_envio.strftime('%Y-%m-%d %H:%M')})</i></li>"
            cuerpo_html += "</ul>"
            cuerpo_html += "<p>Puedes ver más detalles en el sistema.</p>"

            asunto = "Resumen Diario de Notificaciones"
            if enviar_email(usuario.correo, asunto, cuerpo_html, html=True):
                # Marcar notificaciones como leídas para no volver a enviarlas en el resumen
                for notif in notificaciones_no_leidas:
                    notif.leido = True
                print(f"Resumen diario enviado a {usuario.correo}")

    return jsonify({"message": "Resumen diario generado y enviado."}), 200


@app.route("/", methods=["GET"])
def get_notificaciones():
    """
    Obtiene todas las notificaciones (con filtros opcionales)

    Query params:
    - destinatario: filtrar por email
    - tipo: filtrar por tipo (vencimiento, movimiento, alerta, consolidado)
    - leido: filtrar por estado de lectura (true/false)
    """
    try:
        with db_manager.get_session() as session:
            query = session.query(Notificacion)

            # Aplicar filtros
            if request.args.get("destinatario"):
                query = query.filter(Notificacion.destinatario == request.args.get("destinatario"))
            if request.args.get("tipo"):
                query = query.filter(Notificacion.tipo == request.args.get("tipo"))
            if request.args.get("leido") is not None:
                leido_bool = request.args.get("leido").lower() == "true"
                query = query.filter(Notificacion.leido == leido_bool)

            # Ordenar por fecha (más recientes primero)
            notificaciones = query.order_by(Notificacion.fecha_envio.desc()).all()

            return jsonify([n.to_json() for n in notificaciones]), 200

    except Exception as e:
        logger.error(f"Error al obtener notificaciones: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route("/<int:notif_id>/marcar-leido", methods=["PUT"])
def marcar_leido(notif_id):
    """Marca una notificación como leída"""
    try:
        with db_manager.get_session() as session:
            notificacion = session.query(Notificacion).filter_by(id=notif_id).first()

            if not notificacion:
                return jsonify({"error": "Notificación no encontrada"}), 404

            notificacion.leido = True
            return jsonify(notificacion.to_json()), 200

    except Exception as e:
        logger.error(f"Error al marcar notificación como leída: {str(e)}")
        return jsonify({"error": str(e)}), 500


# ==================== ESTADÍSTICAS ====================


@app.route("/stats", methods=["GET"])
def get_stats():
    """Obtiene estadísticas de notificaciones"""
    try:
        with db_manager.get_session() as session:
            total = session.query(Notificacion).count()
            enviadas = session.query(Notificacion).filter_by(estado="enviado").count()
            errores = session.query(Notificacion).filter_by(estado="error").count()
            leidas = session.query(Notificacion).filter_by(leido=True).count()
            no_leidas = total - leidas

            return jsonify(
                {
                    "total": total,
                    "enviadas": enviadas,
                    "errores": errores,
                    "leidas": leidas,
                    "no_leidas": no_leidas,
                }
            ), 200

    except Exception as e:
        logger.error(f"Error al obtener estadísticas: {str(e)}")
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8003, debug=True)

