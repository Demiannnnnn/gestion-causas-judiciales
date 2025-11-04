from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta
import logging

app = Flask(__name__)
CORS(app)

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuración de email desde variables de entorno
SMTP_HOST = os.getenv('SMTP_HOST', 'smtp.gmail.com')
SMTP_PORT = int(os.getenv('SMTP_PORT', 587))
SMTP_USER = os.getenv('SMTP_USER', '')
SMTP_PASSWORD = os.getenv('SMTP_PASSWORD', '')
MAIL_FROM = os.getenv('MAIL_FROM', SMTP_USER)

# Base de datos simulada de notificaciones
notificaciones_db = [

    #CASOS PRUEBAS, NO SON CASOS CARGADOS, SIRVEN POR EL MOMENTO PARA VER EL FRONTEND
    {
        "id": 1,
        "tipo": "vencimiento",
        "caso_rit": "C-1234-2023",
        "destinatario": "abogado@judicial.cl",
        "asunto": "Vencimiento de Plazo - Caso C-1234-2023",
        "mensaje": "El plazo para presentar alegatos vence en 3 días",
        "fecha_envio": (datetime.now() - timedelta(days=1)).isoformat(),
        "estado": "enviado",
        "leido": False
    },
    {
        "id": 2,
        "tipo": "movimiento",
        "caso_rit": "O-5678-2022",
        "destinatario": "admin@judicial.cl",
        "asunto": "Nuevo Movimiento - Caso O-5678-2022",
        "mensaje": "Se ha registrado un nuevo movimiento en el caso",
        "fecha_envio": (datetime.now() - timedelta(hours=5)).isoformat(),
        "estado": "enviado",
        "leido": True
    }
]
next_id = 3


# ==================== ENDPOINTS DE SALUD ====================

@app.route('/health', methods=['GET'])
def health_check():
    """Health check para Docker"""
    return jsonify({
        "status": "healthy",
        "service": "notificaciones",
        "smtp_configured": bool(SMTP_USER and SMTP_PASSWORD)
    }), 200


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
        # Validar configuración
        if not SMTP_USER or not SMTP_PASSWORD:
            logger.warning("SMTP no configurado. Email no enviado (modo demo).")
            return True  # En modo demo, retornar True para no bloquear el sistema
        
        # Crear mensaje
        msg = MIMEMultipart('alternative')
        msg['From'] = MAIL_FROM
        msg['To'] = destinatario
        msg['Subject'] = asunto
        
        # Adjuntar cuerpo
        if html:
            msg.attach(MIMEText(mensaje, 'html'))
        else:
            msg.attach(MIMEText(mensaje, 'plain'))
        
        # Conectar y enviar
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.send_message(msg)
        
        logger.info(f"Email enviado a {destinatario}: {asunto}")
        return True
        
    except Exception as e:
        logger.error(f"Error al enviar email: {str(e)}")
        return False


@app.route('/notificaciones/send', methods=['POST'])
def send_notification():
    """
    Envía una notificación por email
    
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
        required_fields = ['tipo', 'destinatario', 'asunto', 'mensaje']
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Campo requerido: {field}"}), 400
        
        # Enviar email
        success = enviar_email(
            destinatario=data['destinatario'],
            asunto=data['asunto'],
            mensaje=data['mensaje']
        )
        
        # Guardar en base de datos
        global next_id
        nueva_notificacion = {
            "id": next_id,
            "tipo": data['tipo'],
            "caso_rit": data.get('caso_rit', 'N/A'),
            "destinatario": data['destinatario'],
            "asunto": data['asunto'],
            "mensaje": data['mensaje'],
            "fecha_envio": datetime.now().isoformat(),
            "estado": "enviado" if success else "error",
            "leido": False
        }
        notificaciones_db.append(nueva_notificacion)
        next_id += 1
        
        return jsonify({
            "success": success,
            "notificacion": nueva_notificacion
        }), 201
        
    except Exception as e:
        logger.error(f"Error al enviar notificación: {str(e)}")
        return jsonify({"error": "Error interno del servidor"}), 500


# ==================== NOTIFICACIONES AUTOMÁTICAS ====================

@app.route('/notificaciones/alerta-vencimiento', methods=['POST'])
def alerta_vencimiento():
    """
    Envía alerta de vencimiento de plazo para un caso
    
    Body JSON:
    {
        "caso_rit": "C-1234-2023",
        "destinatario": "email@example.com",
        "dias_restantes": 3,
        "descripcion": "Presentar alegatos"
    }
    """
    try:
        data = request.get_json()
        
        caso_rit = data.get('caso_rit')
        destinatario = data.get('destinatario')
        dias = data.get('dias_restantes', 0)
        descripcion = data.get('descripcion', 'plazo')
        
        asunto = f"⚠️ Vencimiento de Plazo - Caso {caso_rit}"
        mensaje = f"""
        Estimado/a,
        
        Le recordamos que el plazo para "{descripcion}" del caso {caso_rit} vence en {dias} día(s).
        
        Fecha límite: {(datetime.now() + timedelta(days=dias)).strftime('%d/%m/%Y')}
        
        Por favor, tome las acciones necesarias antes del vencimiento.
        
        Saludos cordiales,
        Sistema de Gestión Judicial
        """
        
        success = enviar_email(destinatario, asunto, mensaje)
        
        # Guardar notificación
        global next_id
        notificacion = {
            "id": next_id,
            "tipo": "vencimiento",
            "caso_rit": caso_rit,
            "destinatario": destinatario,
            "asunto": asunto,
            "mensaje": mensaje,
            "fecha_envio": datetime.now().isoformat(),
            "estado": "enviado" if success else "error",
            "leido": False
        }
        notificaciones_db.append(notificacion)
        next_id += 1
        
        return jsonify({
            "success": success,
            "notificacion": notificacion
        }), 201
        
    except Exception as e:
        logger.error(f"Error al enviar alerta de vencimiento: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/notificaciones/alerta-movimiento', methods=['POST'])
def alerta_movimiento():
    """
    Envía alerta de nuevo movimiento en un caso
    
    Body JSON:
    {
        "caso_rit": "C-1234-2023",
        "destinatarios": ["email1@example.com", "email2@example.com"],
        "movimiento": "Sentencia definitiva dictada"
    }
    """
    try:
        data = request.get_json()
        
        caso_rit = data.get('caso_rit')
        destinatarios = data.get('destinatarios', [])
        movimiento = data.get('movimiento', 'Nuevo movimiento')
        
        if not destinatarios:
            return jsonify({"error": "No se especificaron destinatarios"}), 400
        
        asunto = f"📋 Nuevo Movimiento - Caso {caso_rit}"
        mensaje = f"""
        Estimado/a,
        
        Se ha registrado un nuevo movimiento en el caso {caso_rit}:
        
        "{movimiento}"
        
        Fecha: {datetime.now().strftime('%d/%m/%Y %H:%M')}
        
        Puede revisar los detalles en el sistema.
        
        Saludos cordiales,
        Sistema de Gestión Judicial
        """
        
        resultados = []
        for destinatario in destinatarios:
            success = enviar_email(destinatario, asunto, mensaje)
            
            global next_id
            notificacion = {
                "id": next_id,
                "tipo": "movimiento",
                "caso_rit": caso_rit,
                "destinatario": destinatario,
                "asunto": asunto,
                "mensaje": mensaje,
                "fecha_envio": datetime.now().isoformat(),
                "estado": "enviado" if success else "error",
                "leido": False
            }
            notificaciones_db.append(notificacion)
            next_id += 1
            
            resultados.append({
                "destinatario": destinatario,
                "success": success
            })
        
        return jsonify({
            "caso_rit": caso_rit,
            "resultados": resultados
        }), 201
        
    except Exception as e:
        logger.error(f"Error al enviar alerta de movimiento: {str(e)}")
        return jsonify({"error": str(e)}), 500


# ==================== CONSOLIDADO DIARIO ====================

@app.route('/notificaciones/consolidado-diario', methods=['POST'])
def consolidado_diario():
    """
    Envía consolidado diario de casos a un usuario
    
    Body JSON:
    {
        "destinatario": "email@example.com",
        "casos": [
            {
                "rit": "C-1234-2023",
                "estado": "Activo",
                "proxima_accion": "Presentar alegatos",
                "fecha_limite": "2024-11-15"
            }
        ]
    }
    """
    try:
        data = request.get_json()
        
        destinatario = data.get('destinatario')
        casos = data.get('casos', [])
        
        if not destinatario:
            return jsonify({"error": "Destinatario requerido"}), 400
        
        # Construir mensaje HTML
        asunto = f"📊 Consolidado Diario - {datetime.now().strftime('%d/%m/%Y')}"
        
        casos_html = ""
        for caso in casos:
            casos_html += f"""
            <tr>
                <td style="padding: 10px; border: 1px solid #ddd;">{caso.get('rit', 'N/A')}</td>
                <td style="padding: 10px; border: 1px solid #ddd;">{caso.get('estado', 'N/A')}</td>
                <td style="padding: 10px; border: 1px solid #ddd;">{caso.get('proxima_accion', 'N/A')}</td>
                <td style="padding: 10px; border: 1px solid #ddd;">{caso.get('fecha_limite', 'N/A')}</td>
            </tr>
            """
        
        mensaje_html = f"""
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; }}
                table {{ border-collapse: collapse; width: 100%; }}
                th {{ background-color: #4CAF50; color: white; padding: 12px; text-align: left; }}
                tr:nth-child(even) {{ background-color: #f2f2f2; }}
            </style>
        </head>
        <body>
            <h2>Consolidado Diario de Casos</h2>
            <p>Fecha: {datetime.now().strftime('%d/%m/%Y')}</p>
            <p>Estimado/a,</p>
            <p>A continuación se presenta el resumen de sus casos activos:</p>
            
            <table>
                <thead>
                    <tr>
                        <th>RIT</th>
                        <th>Estado</th>
                        <th>Próxima Acción</th>
                        <th>Fecha Límite</th>
                    </tr>
                </thead>
                <tbody>
                    {casos_html}
                </tbody>
            </table>
            
            <p>Total de casos: <strong>{len(casos)}</strong></p>
            
            <hr>
            <p style="color: #666; font-size: 12px;">
                Este es un mensaje automático del Sistema de Gestión Judicial.
            </p>
        </body>
        </html>
        """
        
        success = enviar_email(destinatario, asunto, mensaje_html, html=True)
        
        # Guardar notificación
        global next_id
        notificacion = {
            "id": next_id,
            "tipo": "consolidado",
            "caso_rit": "MÚLTIPLES",
            "destinatario": destinatario,
            "asunto": asunto,
            "mensaje": f"Consolidado diario con {len(casos)} casos",
            "fecha_envio": datetime.now().isoformat(),
            "estado": "enviado" if success else "error",
            "leido": False
        }
        notificaciones_db.append(notificacion)
        next_id += 1
        
        return jsonify({
            "success": success,
            "casos_enviados": len(casos),
            "notificacion": notificacion
        }), 201
        
    except Exception as e:
        logger.error(f"Error al enviar consolidado diario: {str(e)}")
        return jsonify({"error": str(e)}), 500


# ==================== GESTIÓN DE NOTIFICACIONES ====================

@app.route('/', methods=['GET'])
def get_notificaciones():
    """
    Obtiene todas las notificaciones (con filtros opcionales)
    
    Query params:
    - destinatario: filtrar por email
    - tipo: filtrar por tipo (vencimiento, movimiento, alerta, consolidado)
    - leido: filtrar por estado de lectura (true/false)
    """
    try:
        destinatario = request.args.get('destinatario')
        tipo = request.args.get('tipo')
        leido = request.args.get('leido')
        
        resultado = notificaciones_db.copy()
        
        # Aplicar filtros
        if destinatario:
            resultado = [n for n in resultado if n['destinatario'] == destinatario]
        
        if tipo:
            resultado = [n for n in resultado if n['tipo'] == tipo]
        
        if leido is not None:
            leido_bool = leido.lower() == 'true'
            resultado = [n for n in resultado if n['leido'] == leido_bool]
        
        # Ordenar por fecha (más recientes primero)
        resultado.sort(key=lambda x: x['fecha_envio'], reverse=True)
        
        return jsonify(resultado), 200
        
    except Exception as e:
        logger.error(f"Error al obtener notificaciones: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/notificaciones/<int:notif_id>', methods=['GET'])
def get_notificacion(notif_id):
    """Obtiene una notificación por ID"""
    try:
        notificacion = next((n for n in notificaciones_db if n['id'] == notif_id), None)
        
        if not notificacion:
            return jsonify({"error": "Notificación no encontrada"}), 404
        
        return jsonify(notificacion), 200
        
    except Exception as e:
        logger.error(f"Error al obtener notificación: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/notificaciones/<int:notif_id>/marcar-leido', methods=['PUT'])
def marcar_leido(notif_id):
    """Marca una notificación como leída"""
    try:
        notificacion = next((n for n in notificaciones_db if n['id'] == notif_id), None)
        
        if not notificacion:
            return jsonify({"error": "Notificación no encontrada"}), 404
        
        notificacion['leido'] = True
        
        return jsonify(notificacion), 200
        
    except Exception as e:
        logger.error(f"Error al marcar notificación como leída: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/notificaciones/<int:notif_id>', methods=['DELETE'])
def delete_notificacion(notif_id):
    """Elimina una notificación"""
    try:
        global notificaciones_db
        
        notificacion = next((n for n in notificaciones_db if n['id'] == notif_id), None)
        
        if not notificacion:
            return jsonify({"error": "Notificación no encontrada"}), 404
        
        notificaciones_db = [n for n in notificaciones_db if n['id'] != notif_id]
        
        return jsonify({"mensaje": "Notificación eliminada", "id": notif_id}), 200
        
    except Exception as e:
        logger.error(f"Error al eliminar notificación: {str(e)}")
        return jsonify({"error": str(e)}), 500


# ==================== ESTADÍSTICAS ====================

@app.route('/notificaciones/stats', methods=['GET'])
def get_stats():
    """Obtiene estadísticas de notificaciones"""
    try:
        total = len(notificaciones_db)
        enviadas = len([n for n in notificaciones_db if n['estado'] == 'enviado'])
        errores = len([n for n in notificaciones_db if n['estado'] == 'error'])
        leidas = len([n for n in notificaciones_db if n['leido']])
        no_leidas = total - leidas
        
        # Notificaciones por tipo
        por_tipo = {}
        for notif in notificaciones_db:
            tipo = notif['tipo']
            por_tipo[tipo] = por_tipo.get(tipo, 0) + 1
        
        return jsonify({
            "total": total,
            "enviadas": enviadas,
            "errores": errores,
            "leidas": leidas,
            "no_leidas": no_leidas,
            "por_tipo": por_tipo
        }), 200
        
    except Exception as e:
        logger.error(f"Error al obtener estadísticas: {str(e)}")
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8003, debug=True)