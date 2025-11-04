import os
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

OLLAMA_API_URL = os.environ.get('OLLAMA_API_URL', 'http://localhost:11434')

@app.route('/analyze', methods=['POST'])
def analyze():
    data = request.json
    prompt = data.get('prompt')

    if not prompt:
        return jsonify({'error': 'Prompt is required'}), 400

    try:
        response = requests.post(
            f'{OLLAMA_API_URL}/api/generate',
            json={
                'model': 'llama2', # O el modelo que desees usar
                'prompt': prompt,
                'stream': False
            }
        )
        response.raise_for_status()

        return jsonify(response.json())

    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002, debug=True)
