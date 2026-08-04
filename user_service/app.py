from flask import Flask, jsonify, request
from pathlib import Path
import json

app = Flask(__name__)

def data_path(name):
    project_root = Path(__file__).resolve().parent.parent
    return project_root / 'data' / name

@app.get('/')
def index():
    return jsonify({"service": "user-service", "endpoints": ["/health", "/users"]})

@app.get('/health')
def health():
    return jsonify({"status": "ok"})

@app.get('/users')
def list_users():
    try:
        with open(data_path('users.json'), 'r', encoding='utf-8') as f:
            users = json.load(f)
    except FileNotFoundError:
        users = []
    return jsonify(users)

if __name__ == '__main__':
    app.run(port=5100, host='0.0.0.0')
