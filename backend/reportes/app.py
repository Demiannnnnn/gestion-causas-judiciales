from flask import Flask, jsonify, request, Response
from flask_cors import CORS
import pandas as pd
from sqlalchemy import text
from common.database import db_manager
from common.models import Causa, Tribunal, Usuario
import datetime

app = Flask(__name__)
CORS(app)

@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "healthy"})

@app.route("/reportes/casos", methods=["GET"])
def reporte_casos():
    tribunal_id = request.args.get("tribunal_id")
    abogado_id = request.args.get("abogado_id")

    with db_manager.get_session() as session:
        query = session.query(Causa)

        if tribunal_id:
            query = query.filter(Causa.tribunal_id == tribunal_id)
        
        # Filtering by lawyer is not directly possible with the current data model

        casos = query.all()

        df = pd.DataFrame([c.to_json() for c in casos])
        csv = df.to_csv(index=False)

        return Response(
            csv,
            mimetype="text/csv",
            headers={"Content-disposition": "attachment; filename=reporte_casos.csv"}
        )

@app.route("/reportes/vencimientos", methods=["GET"])
def reporte_vencimientos():
    with db_manager.get_session() as session:
        today = datetime.date.today()
        thirty_days_from_now = today + datetime.timedelta(days=30)

        query = session.query(Causa).filter(Causa.fecha_inicio != None).filter(Causa.fecha_inicio + datetime.timedelta(days=30) <= thirty_days_from_now)
        casos = query.all()

        df = pd.DataFrame([c.to_json() for c in casos])
        csv = df.to_csv(index=False)

        return Response(
            csv,
            mimetype="text/csv",
            headers={"Content-disposition": "attachment; filename=reporte_vencimientos.csv"}
        )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8004, debug=True)
