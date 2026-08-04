from flask import Flask, jsonify, request, current_app
from pathlib import Path
import json
import os
import jwt

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'globetrotter-secret-change-in-prod')


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


DESTINATIONS_FILE = str(project_root() / 'data' / 'destinations.json')
USERS_FILE = str(project_root() / 'data' / 'users.json')


def get_all_destinations():
    return _read_json(DESTINATIONS_FILE)


def get_user_by_username(username: str):
    users = _read_json(USERS_FILE)
    for u in users:
        if u.get('username') == username:
            return u
    return None


def decode_token(token: str, secret: str):
    return jwt.decode(token, str(secret), algorithms=['HS256'])


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
    return jsonify({"service": "recommendation-service", "endpoints": ["/health", "/recommendations"]})


@app.get('/health')
def health():
    return jsonify({"status": "ok"})


@app.route('/recommendations', methods=['GET'])
def recommendations():
    username = get_current_user(request)
    if not username:
        return jsonify({"error": "authentication required"}), 401

    user = get_user_by_username(username)
    if not user:
        return jsonify({"error": "user not found"}), 404

    preferences = [p.lower() for p in user.get('preferences', [])]

    try:
        limit = int(request.args.get('limit', 5))
    except ValueError:
        return jsonify({'error': 'limit must be an integer'}), 400

    destinations = get_all_destinations()
    scored = []
    for dest in destinations:
        dest_tags = [t.lower() for t in dest.get('tags', [])]
        score = sum(1 for pref in preferences if pref in dest_tags)
        scored.append((score, dest))
    scored.sort(key=lambda x: (-x[0], x[1].get('name', '')))
    results = []
    for score, dest in scored[:limit]:
        entry = dict(dest)
        entry['match_score'] = score
        results.append(entry)
    return jsonify(results), 200


if __name__ == '__main__':
    app.run(port=5300, host='0.0.0.0')
