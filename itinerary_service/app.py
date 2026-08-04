from flask import Flask, jsonify, request, current_app
from pathlib import Path
import json
import os
import uuid
import datetime
import jwt
from werkzeug.security import generate_password_hash

app = Flask(__name__)


def project_root():
    return Path(__file__).resolve().parent.parent


def data_path(name):
    return project_root() / 'data' / name


def _read_json(filepath: str):
    if not os.path.exists(filepath):
        return []
    with open(filepath, 'r', encoding='utf-8') as fh:
        content = fh.read().strip()
        if not content:
            return []
        return json.loads(content)


def _write_json(filepath: str, data):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as fh:
        json.dump(data, fh, indent=2)


# Itinerary helpers (adapted)
ITINERARIES_FILE = str(project_root() / 'data' / 'itineraries.json')


def get_all_itineraries():
    return _read_json(ITINERARIES_FILE)


def get_itineraries_for_user(username: str):
    return [it for it in get_all_itineraries() if it.get('username') == username]


def save_itinerary(itinerary: dict):
    itins = get_all_itineraries()
    itins.append(itinerary)
    _write_json(ITINERARIES_FILE, itins)


# JWT helper (decode only)
def decode_token(token: str, secret: str):
    return jwt.decode(token, secret, algorithms=['HS256'])


def get_current_user(request_obj) -> str | None:
    auth_header = request_obj.headers.get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return None
    token = auth_header.split(' ', 1)[1]
    try:
        payload = decode_token(token, current_app.config.get('SECRET_KEY', 'globetrotter-secret-change-in-prod'))
        return payload.get('sub')
    except jwt.PyJWTError:
        return None


@app.get('/')
def index():
    return jsonify({"service": "itinerary-service", "endpoints": ["/health", "/itineraries"]})


@app.get('/health')
def health():
    return jsonify({"status": "ok"})


@app.route('/itineraries', methods=['GET'])
def list_itineraries():
    username = get_current_user(request)
    if not username:
        return jsonify({"error": "authentication required"}), 401
    return jsonify(get_itineraries_for_user(username)), 200


@app.route('/itineraries', methods=['POST'])
def create_itinerary():
    username = get_current_user(request)
    if not username:
        return jsonify({"error": "authentication required"}), 401

    data = request.get_json(silent=True) or {}
    title = data.get('title', '').strip()
    destinations = data.get('destinations', [])
    if not title:
        return jsonify({'error': 'title is required'}), 400
    if not isinstance(destinations, list):
        return jsonify({'error': 'destinations must be a list'}), 400

    itinerary = {
        'id': str(uuid.uuid4()),
        'username': username,
        'title': title,
        'destinations': destinations,
        'start_date': data.get('start_date', ''),
        'end_date': data.get('end_date', ''),
        'notes': data.get('notes', ''),
        'created_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
    save_itinerary(itinerary)
    return jsonify(itinerary), 201


if __name__ == '__main__':
    app.run(port=5200, host='0.0.0.0')
