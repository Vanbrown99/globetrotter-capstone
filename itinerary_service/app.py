from flask import Flask, jsonify, request
from pathlib import Path
import json

app = Flask(__name__)

def data_path(name):
    project_root = Path(__file__).resolve().parent.parent
    return project_root / 'data' / name

@app.get('/')
def index():
    return jsonify({"service": "itinerary-service", "endpoints": ["/health", "/itineraries"]})

@app.get('/health')
def health():
    return jsonify({"status": "ok"})

@app.get('/itineraries')
def list_itineraries():
    try:
        with open(data_path('itineraries.json'), 'r', encoding='utf-8') as f:
            itins = json.load(f)
    except FileNotFoundError:
        itins = []
    return jsonify(itins)

@app.post('/itineraries')
def create_itinerary():
    payload = request.get_json() or {}
    # Append to file (simplified, no locking)
    path = data_path('itineraries.json')
    try:
        with open(path, 'r', encoding='utf-8') as f:
            itins = json.load(f)
    except FileNotFoundError:
        itins = []
    itins.append(payload)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(itins, f, indent=2)
    return jsonify(payload), 201

if __name__ == '__main__':
    app.run(port=5200, host='0.0.0.0')
