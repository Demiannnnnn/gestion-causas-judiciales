import os
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from common.database import db_manager
from common.models import Documento
from werkzeug.utils import secure_filename

app = Flask(__name__)
CORS(app)

# Configuración de la carpeta de subida
app.config['UPLOAD_FOLDER'] = os.environ.get('UPLOAD_FOLDER', '/app/uploads')

# --- Endpoints de la API ---

@app.route('/causa/<int:id_causa>/documentos', methods=['POST'])
def upload_documento(id_causa):
    if 'file' not in request.files:
        return jsonify({'error': 'No se encontró el archivo'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No se seleccionó ningún archivo'}), 400

    tipo = request.form.get('tipo', 'OTRO')
    # Placeholder para el ID de usuario (debería venir de un token JWT)
    subido_por_id = 1

    if file:
        filename = secure_filename(file.filename)
        if not os.path.exists(app.config['UPLOAD_FOLDER']):
            os.makedirs(app.config['UPLOAD_FOLDER'])
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)

        with db_manager.get_session() as session:
            nuevo_documento = Documento(
                id_causa=id_causa,
                tipo=tipo,
                nombre_archivo=filename,
                ruta_storage=filepath,
                subido_por=subido_por_id
            )
            session.add(nuevo_documento)
            session.flush()  # Para obtener el ID antes del commit
            result = nuevo_documento.to_json()
        
        return jsonify(result), 201

@app.route('/causa/<int:id_causa>/documentos', methods=['GET'])
def get_documentos_por_causa(id_causa):
    with db_manager.get_session() as session:
        documentos = session.query(Documento).filter_by(id_causa=id_causa).all()
        return jsonify([d.to_json() for d in documentos]), 200

@app.route('/<int:id_documento>', methods=['GET'])
def descargar_documento(id_documento):
    with db_manager.get_session() as session:
        documento = session.query(Documento).get(id_documento)
        if not documento:
            return jsonify({'error': 'Documento no encontrado'}), 404
        
        nombre_archivo = os.path.basename(documento.ruta_storage)
        directorio = os.path.dirname(documento.ruta_storage)

        return send_from_directory(
            directorio,
            nombre_archivo,
            as_attachment=True
        )

@app.route('/<int:id_documento>', methods=['DELETE'])
def eliminar_documento(id_documento):
    with db_manager.get_session() as session:
        documento = session.query(Documento).get(id_documento)
        if not documento:
            return jsonify({'error': 'Documento no encontrado'}), 404
        
        # Eliminar archivo físico
        try:
            if os.path.exists(documento.ruta_storage):
                os.remove(documento.ruta_storage)
            else:
                print(f"Advertencia: No se encontró el archivo {documento.ruta_storage} para eliminar.")
        except OSError as e:
            print(f"Error eliminando archivo {documento.ruta_storage}: {e}")

        session.delete(documento)
    
    return jsonify({'message': f'Documento {id_documento} eliminado'}), 200

if __name__ == '__main__':
    # Crear la carpeta de uploads si no existe
    if not os.path.exists(app.config['UPLOAD_FOLDER']):
        os.makedirs(app.config['UPLOAD_FOLDER'])
    app.run(host='0.0.0.0', port=8002, debug=True)