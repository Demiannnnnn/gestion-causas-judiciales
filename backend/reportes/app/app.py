from flask import Flask, jsonify, send_file
from flask_cors import CORS
import csv
import io
from datetime import datetime
from common.database import db_manager
from common.models import Causa, Documento, Movimiento, Tribunal
from sqlalchemy import func

app = Flask(__name__)
CORS(app)

@app.route('/health', methods=['GET'])
def health_check():
    """Health check para Docker"""
    return jsonify({"status": "healthy", "service": "reportes"}), 200

@app.route('/casos', methods=['GET'])
def generar_reporte_casos():
    """
    Genera un reporte CSV con todos los casos del sistema
    """
    try:
        with db_manager.get_session() as session:
            # Obtener todos los casos con información del tribunal
            casos = session.query(
                Causa.id_causa,
                Causa.rit,
                Causa.estado,
                Causa.fecha_inicio,
                Causa.descripcion,
                Tribunal.nombre.label('tribunal_nombre')
            ).join(Tribunal).all()
            
            # Crear CSV en memoria
            output = io.StringIO()
            writer = csv.writer(output)
            
            # Escribir encabezados
            writer.writerow([
                'ID Causa',
                'RIT',
                'Estado',
                'Fecha Inicio',
                'Tribunal',
                'Descripción'
            ])
            
            # Escribir datos
            for caso in casos:
                writer.writerow([
                    caso.id_causa,
                    caso.rit,
                    caso.estado,
                    caso.fecha_inicio.strftime('%Y-%m-%d') if caso.fecha_inicio else 'N/A',
                    caso.tribunal_nombre,
                    caso.descripcion or 'Sin descripción'
                ])
            
            # Preparar respuesta
            output.seek(0)
            response = app.response_class(
                output.getvalue(),
                mimetype='text/csv',
                headers={
                    'Content-Disposition': f'attachment; filename=reporte_casos_{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv'
                }
            )
            
            return response
            
    except Exception as e:
        return jsonify({'error': f'Error al generar reporte: {str(e)}'}), 500

@app.route('/documentos', methods=['GET'])
def generar_reporte_documentos():
    """
    Genera un reporte CSV con todos los documentos del sistema
    """
    try:
        with db_manager.get_session() as session:
            # Obtener documentos con información de la causa
            documentos = session.query(
                Documento.id_documento,
                Documento.nombre_archivo,
                Documento.tipo,
                Documento.fecha_subida,
                Causa.rit,
                Tribunal.nombre.label('tribunal_nombre')
            ).join(Causa).join(Tribunal).all()
            
            # Crear CSV en memoria
            output = io.StringIO()
            writer = csv.writer(output)
            
            # Escribir encabezados
            writer.writerow([
                'ID Documento',
                'Nombre Archivo',
                'Tipo',
                'Fecha Subida',
                'RIT Causa',
                'Tribunal'
            ])
            
            # Escribir datos
            for doc in documentos:
                writer.writerow([
                    doc.id_documento,
                    doc.nombre_archivo,
                    doc.tipo,
                    doc.fecha_subida.strftime('%Y-%m-%d %H:%M:%S') if doc.fecha_subida else 'N/A',
                    doc.rit,
                    doc.tribunal_nombre
                ])
            
            # Preparar respuesta
            output.seek(0)
            response = app.response_class(
                output.getvalue(),
                mimetype='text/csv',
                headers={
                    'Content-Disposition': f'attachment; filename=reporte_documentos_{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv'
                }
            )
            
            return response
            
    except Exception as e:
        return jsonify({'error': f'Error al generar reporte: {str(e)}'}), 500

@app.route('/estadisticas', methods=['GET'])
def obtener_estadisticas():
    """
    Obtiene estadísticas generales del sistema
    """
    try:
        with db_manager.get_session() as session:
            # Contar casos por estado
            casos_por_estado = session.query(
                Causa.estado,
                func.count(Causa.id_causa).label('cantidad')
            ).group_by(Causa.estado).all()
            
            # Contar documentos por tipo
            docs_por_tipo = session.query(
                Documento.tipo,
                func.count(Documento.id_documento).label('cantidad')
            ).group_by(Documento.tipo).all()
            
            # Contar movimientos por tipo
            movs_por_tipo = session.query(
                Movimiento.tipo,
                func.count(Movimiento.id_movimiento).label('cantidad')
            ).group_by(Movimiento.tipo).all()
            
            # Total de casos por tribunal
            casos_por_tribunal = session.query(
                Tribunal.nombre,
                func.count(Causa.id_causa).label('cantidad')
            ).join(Causa).group_by(Tribunal.nombre).all()
            
            estadisticas = {
                'casos_por_estado': [
                    {'estado': item.estado, 'cantidad': item.cantidad}
                    for item in casos_por_estado
                ],
                'documentos_por_tipo': [
                    {'tipo': item.tipo, 'cantidad': item.cantidad}
                    for item in docs_por_tipo
                ],
                'movimientos_por_tipo': [
                    {'tipo': item.tipo, 'cantidad': item.cantidad}
                    for item in movs_por_tipo
                ],
                'casos_por_tribunal': [
                    {'tribunal': item.nombre, 'cantidad': item.cantidad}
                    for item in casos_por_tribunal
                ],
                'totales': {
                    'casos': session.query(func.count(Causa.id_causa)).scalar(),
                    'documentos': session.query(func.count(Documento.id_documento)).scalar(),
                    'movimientos': session.query(func.count(Movimiento.id_movimiento)).scalar(),
                }
            }
            
            return jsonify(estadisticas), 200
            
    except Exception as e:
        return jsonify({'error': f'Error al obtener estadísticas: {str(e)}'}), 500

@app.route('/vencimientos', methods=['GET'])
def reporte_vencimientos():
    """
    Genera reporte de casos con próximos vencimientos (próximos 30 días)
    """
    try:
        with db_manager.get_session() as session:
            # Obtener movimientos de tipo VENCIMIENTO en los próximos 30 días
            from datetime import timedelta
            fecha_limite = datetime.now() + timedelta(days=30)
            
            vencimientos = session.query(
                Causa.rit,
                Tribunal.nombre.label('tribunal'),
                Movimiento.fecha,
                Movimiento.descripcion
            ).join(Causa, Movimiento.id_causa == Causa.id_causa)\
             .join(Tribunal, Causa.tribunal_id == Tribunal.id_tribunal)\
             .filter(Movimiento.tipo == 'VENCIMIENTO')\
             .filter(Movimiento.fecha <= fecha_limite)\
             .filter(Movimiento.fecha >= datetime.now())\
             .order_by(Movimiento.fecha).all()
            
            # Crear CSV
            output = io.StringIO()
            writer = csv.writer(output)
            
            writer.writerow([
                'RIT',
                'Tribunal',
                'Fecha Vencimiento',
                'Descripción'
            ])
            
            for v in vencimientos:
                writer.writerow([
                    v.rit,
                    v.tribunal,
                    v.fecha.strftime('%Y-%m-%d'),
                    v.descripcion
                ])
            
            output.seek(0)
            response = app.response_class(
                output.getvalue(),
                mimetype='text/csv',
                headers={
                    'Content-Disposition': f'attachment; filename=reporte_vencimientos_{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv'
                }
            )
            
            return response
            
    except Exception as e:
        return jsonify({'error': f'Error al generar reporte: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8005, debug=True)