from flask import Flask, jsonify, request
from pathlib import Path
import json

app = Flask(__name__)

def data_path(name):
    project_root = Path(__file__).resolve().parent.parent
    return project_root / 'data' / name

@app.get('/')
def index():
    return jsonify({"service": "recommendation-service", "endpoints": ["/health", "/recommendations"]})

@app.get('/health')
def health():
    return jsonify({"status": "ok"})

@app.get('/recommendations')
def recommendations():
    # very small example: return top 3 destinations
    try:
        with open(data_path('destinations.json'), 'r', encoding='utf-8') as f:
            dests = json.load(f)
    except FileNotFoundError:
        dests = []
    return jsonify(dests[:3])

if __name__ == '__main__':
    app.run(port=5300, host='0.0.0.0')
