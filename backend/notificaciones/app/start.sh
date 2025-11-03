#!/bin/sh

# Iniciar Gunicorn en segundo plano
echo "Iniciando Gunicorn..."
gunicorn --bind 0.0.0.0:8003 app:app &

# Iniciar el worker de notificaciones
echo "Iniciando el worker de notificaciones..."
python worker.py
