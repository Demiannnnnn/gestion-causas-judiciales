from flask import Flask, jsonify, request, Response, make_response
from flask_cors import CORS
import pandas as pd
from sqlalchemy import text, func, or_
from common.database import db_manager
from common.models import Causa, Tribunal, Usuario, Movimiento, Documento, CausaParte
import datetime


# ReportLab imports
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.enums import TA_CENTER
from io import BytesIO

app = Flask(__name__)
CORS(app)

@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "healthy"})

@app.route("/casos", methods=["GET"])
def reporte_casos():
    """
    RF6.1: Generar reportes de estado de causas por tribunal o abogado.
    Query params: tribunal_id, abogado_id
    """
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
        csv = df.to_csv(index=False)

        return Response(
            csv,
            mimetype="text/csv",
            headers={"Content-disposition": "attachment; filename=reporte_casos.csv"}
        )

@app.route("/vencimientos", methods=["GET"])
def reporte_vencimientos():
    """
    RF6.2: Generar un reporte de vencimiento de plazos para los próximos 30 días.
    """
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
        csv = df.to_csv(index=False)

        return Response(
            csv,
            mimetype="text/csv",
            headers={"Content-disposition": "attachment; filename=reporte_vencimientos.csv"}
        )

@app.route('/reportes/causa-history/<string:caso_rit>/pdf', methods=['GET'])
def get_causa_history_pdf(caso_rit):
    """
    RF6.3: Exportar el historial completo de una causa en formato PDF.
    """
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
        story.append(Paragraph(f"<b>Tribunal:</b> {causa.tribunal.nombre}", styles['Normal']))
        story.append(Paragraph(f"<b>Fecha de Inicio:</b> {causa.fecha_inicio.isoformat()}", styles['Normal']))
        story.append(Paragraph(f"<b>Estado:</b> {causa.estado}", styles['Normal']))
        story.append(Paragraph(f"<b>Descripción:</b> {causa.descripcion}", styles['Normal']))
        story.append(Spacer(1, 0.2 * inch))

        # Documentos
        story.append(Paragraph("<b>Documentos Asociados:</b>", styles['h2']))
        documentos = session.query(Documento).filter_by(id_causa=causa.id_causa).all()
        if documentos:
            for doc_item in documentos:
                story.append(Paragraph(f"<b>- Nombre:</b> {doc_item.nombre_archivo} (Tipo: {doc_item.tipo}, Subido: {doc_item.fecha_subida.isoformat()})", styles['Normal']))
        else:
            story.append(Paragraph("No hay documentos asociados.", styles['Normal']))
        story.append(Spacer(1, 0.2 * inch))

        # Movimientos
        story.append(Paragraph("<b>Movimientos del Caso:</b>", styles['h2']))
        movimientos = session.query(Movimiento).filter_by(id_causa=causa.id_causa).order_by(Movimiento.fecha).all()
        if movimientos:
            for mov_item in movimientos:
                story.append(Paragraph(f"<b>- Fecha:</b> {mov_item.fecha.isoformat()} (Tipo: {mov_item.tipo}): {mov_item.descripcion}", styles['Normal']))
        else:
            story.append(Paragraph("No hay movimientos registrados.", styles['Normal']))
        story.append(Spacer(1, 0.2 * inch))

    doc.build(story)
    buffer.seek(0)

    response = make_response(buffer.getvalue())
    response.headers['Content-Type'] = 'application/pdf'
    response.headers['Content-Disposition'] = f'attachment; filename=historial_causa_{caso_rit}.pdf'
    return response


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8004, debug=True)