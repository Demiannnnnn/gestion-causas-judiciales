cd /app/app
gunicorn --bind 0.0.0.0:8003 app:app &
python worker.py
