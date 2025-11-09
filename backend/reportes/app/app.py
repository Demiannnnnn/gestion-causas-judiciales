from flask import Flask, jsonify, request, Response, make_response
from flask_cors import CORS
import pandas as pd
from sqlalchemy import func
from common.database import db_manager
from common.models import Causa, Tribunal, Usuario, Movimiento, Documento, CausaParte
import datetime
from io import BytesIO, StringIO
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import inch

app = Flask(__name__)
CORS(app)

@app.route("/tribunales", methods=["GET"])
def get_tribunales():
    with db_manager.get_session() as session:
        tribunales = session.query(Tribunal).all()
        return jsonify([
            {
                "id_tribunal": t.id_tribunal,
                "nombre": t.nombre
            } for t in tribunales
        ])

@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "healthy"})

@app.route("/estadisticas", methods=["GET"])
def get_estadisticas():
    with db_manager.get_session() as session:
        total_casos = session.query(Causa).count()
        casos_activos = session.query(Causa).filter(Causa.estado == 'ACTIVA').count()
        total_documentos = session.query(Documento).count()
        
        thirty_days_ago = datetime.date.today() - datetime.timedelta(days=30)
        movimientos_ultimos_30_dias = session.query(Movimiento).filter(Movimiento.fecha >= thirty_days_ago).count()

        return jsonify({
            "casos": {
                "total": total_casos,
                "activos": casos_activos
            },
            "documentos_total": total_documentos,
            "movimientos_ultimos_30_dias": movimientos_ultimos_30_dias
        })

@app.route("/casos", methods=["GET"])
def reporte_casos():
    """
    RF6.1: Generar reportes de estado de causas por tribunal o abogado.
    """
    try:
        tribunal_id = request.args.get("tribunal_id", type=int)
        abogado_id = request.args.get("abogado_id", type=int)

        with db_manager.get_session() as session:
            query = session.query(
                Causa.rit,
                Causa.estado,
                Causa.fecha_inicio,
                Tribunal.nombre.label('nombre_tribunal'),
                Usuario.nombre.label('nombre_abogado')
            ).join(Tribunal, Causa.tribunal_id == Tribunal.id_tribunal)\
            .outerjoin(CausaParte, Causa.id_causa == CausaParte.id_causa)\
            .outerjoin(Usuario, CausaParte.representado_por == Usuario.id_usuario)

            if tribunal_id:
                query = query.filter(Causa.tribunal_id == tribunal_id)
            
            if abogado_id:
                query = query.filter(CausaParte.representado_por == abogado_id)
            
            casos_data = query.distinct(Causa.id_causa).all()

            report_data = []
            for rit, estado, fecha_inicio, nombre_tribunal, nombre_abogado in casos_data:
                report_data.append({
                    "rit": rit,
                    "estado": estado,
                    "fecha_inicio": fecha_inicio.isoformat() if fecha_inicio else None,
                    "tribunal": nombre_tribunal,
                    "abogado_responsable": nombre_abogado if nombre_abogado else "N/A"
                })
            
            df = pd.DataFrame(report_data)
            
            stream = StringIO()
            df.to_csv(stream, index=False)
            
            return Response(
                stream.getvalue(),
                mimetype="text/csv",
                headers={"Content-disposition": "attachment; filename=reporte_casos.csv"}
            )
    except Exception as e:
        return jsonify({"error": f"Error al generar el reporte: {e}"}), 500


@app.route("/vencimientos", methods=["GET"])
def reporte_vencimientos():
    """
    RF6.2: Generar un reporte de vencimiento de plazos para los próximos 30 días.
    """
    try:
        today = datetime.date.today()
        thirty_days_later = today + datetime.timedelta(days=30)

        with db_manager.get_session() as session:
            upcoming_deadlines = session.query(
                Movimiento.descripcion,
                Movimiento.fecha,
                Causa.rit,
                Tribunal.nombre.label('nombre_tribunal')
            ).join(Causa, Movimiento.id_causa == Causa.id_causa)\
            .join(Tribunal, Causa.tribunal_id == Tribunal.id_tribunal)\
            .filter(Movimiento.tipo == 'VENCIMIENTO')\
            .filter(func.date(Movimiento.fecha) >= today)\
            .filter(func.date(Movimiento.fecha) <= thirty_days_later)\
            .order_by(Movimiento.fecha).all()
            
            report_data = []
            for descripcion, fecha, rit, nombre_tribunal in upcoming_deadlines:
                report_data.append({
                    "causa_rit": rit,
                    "tribunal": nombre_tribunal,
                    "descripcion_vencimiento": descripcion,
                    "fecha_vencimiento": fecha.isoformat()
                })
            
            df = pd.DataFrame(report_data)
            
            stream = StringIO()
            df.to_csv(stream, index=False)
            
            return Response(
                stream.getvalue(),
                mimetype="text/csv",
                headers={"Content-disposition": "attachment; filename=reporte_vencimientos.csv"}
            )
    except Exception as e:
        return jsonify({"error": f"Error al generar el reporte: {e}"}), 500

@app.route('/causa-history/<string:caso_rit>/pdf', methods=['GET'])
def get_causa_history_pdf(caso_rit):
    """
    RF6.3: Exportar el historial completo de una causa en formato PDF.
    """
    try:
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter)
        styles = getSampleStyleSheet()
        story = []

        # Title
        story.append(Paragraph(f"Historial Completo de Causa: {caso_rit}", styles['h1']))
        story.append(Spacer(1, 0.2 * inch))

        with db_manager.get_session() as session:
            causa = session.query(Causa).filter_by(rit=caso_rit).first()
            if not causa:
                return jsonify({'error': 'Causa no encontrada'}), 404
            
            # Causa Details
            story.append(Paragraph("<b>Detalles de la Causa:</b>", styles['h2']))
            story.append(Paragraph(f"<b>RIT:</b> {causa.rit}", styles['Normal']))
            story.append(Paragraph(f"<b>Tribunal:</b> {causa.tribunal.nombre if causa.tribunal else 'N/A'}", styles['Normal']))
            story.append(Paragraph(f"<b>Fecha de Inicio:</b> {causa.fecha_inicio.isoformat() if causa.fecha_inicio else 'N/A'}", styles['Normal']))
            story.append(Paragraph(f"<b>Estado:</b> {causa.estado}", styles['Normal']))
            story.append(Paragraph(f"<b>Descripción:</b> {causa.descripcion}", styles['Normal']))
            story.append(Spacer(1, 0.2 * inch))

            # Documentos
            story.append(Paragraph("<b>Documentos Asociados:</b>", styles['h2']))
            documentos = session.query(Documento).filter_by(id_causa=causa.id_causa).all()
            if documentos:
                for doc_item in documentos:
                    story.append(Paragraph(f"<b>- Nombre:</b> {doc_item.nombre_archivo} (Tipo: {doc_item.tipo}, Subido: {doc_item.fecha_subida.isoformat() if doc_item.fecha_subida else 'N/A'})", styles['Normal']))
            else:
                story.append(Paragraph("No hay documentos asociados.", styles['Normal']))
            story.append(Spacer(1, 0.2 * inch))

            # Movimientos
            story.append(Paragraph("<b>Movimientos del Caso:</b>", styles['h2']))
            movimientos = session.query(Movimiento).filter_by(id_causa=causa.id_causa).order_by(Movimiento.fecha).all()
            if movimientos:
                for mov_item in movimientos:
                    story.append(Paragraph(f"<b>- Fecha:</b> {mov_item.fecha.isoformat() if mov_item.fecha else 'N/A'} (Tipo: {mov_item.tipo}): {mov_item.descripcion}", styles['Normal']))
            else:
                story.append(Paragraph("No hay movimientos registrados.", styles['Normal']))
            story.append(Spacer(1, 0.2 * inch))

        doc.build(story)
        buffer.seek(0)

        response = make_response(buffer.getvalue())
        response.headers['Content-Type'] = 'application/pdf'
        response.headers['Content-Disposition'] = f'attachment; filename=historial_causa_{caso_rit}.pdf'
        return response
    except Exception as e:
        return jsonify({'error': f'Error al generar el reporte: {e}'}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8004, debug=True)
