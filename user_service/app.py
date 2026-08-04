from flask import Flask, jsonify, request, current_app
from pathlib import Path
import json
import os
import uuid
import datetime
import secrets
import jwt
from werkzeug.security import generate_password_hash, check_password_hash

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


def _write_json(filepath: str, data):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as fh:
        json.dump(data, fh, indent=2)


# User helpers (copied/adapted from monolith)
USERS_FILE = str(project_root() / 'data' / 'users.json')


def get_all_users():
    return _read_json(USERS_FILE)


def get_user_by_username(username):
    for user in get_all_users():
        if user.get('username') == username:
            return user
    return None


def get_user_by_email(email):
    for user in get_all_users():
        if user.get('email') == email:
            return user
    return None


def save_user(user):
    users = get_all_users()
    users.append(user)
    _write_json(USERS_FILE, users)


def update_user_password(email, new_password):
    users = get_all_users()
    for user in users:
        if user.get('email') == email:
            user['password_hash'] = generate_password_hash(new_password)
            break
    _write_json(USERS_FILE, users)


# JWT helpers (adapted)
_RESET_TOKENS = {}


def create_token(username: str, secret: str) -> str:
    now = datetime.datetime.now(datetime.timezone.utc)
    payload = {"sub": username, "iat": now, "exp": now + datetime.timedelta(hours=24)}
    return jwt.encode(payload, str(secret), algorithm='HS256')


def decode_token(token: str, secret: str) -> dict:
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
    return jsonify({"service": "user-service", "endpoints": ["/health", "/users", "/register", "/login", "/me"]})


@app.get('/health')
def health():
    return jsonify({"status": "ok"})


@app.get('/users')
def list_users():
    return jsonify(get_all_users())


@app.route('/register', methods=['POST'])
def register():
    data = request.get_json(silent=True) or {}
    username = data.get('username', '').strip()
    email = data.get('email', '').strip().lower()
    password = data.get('password', '')
    preferences = data.get('preferences', [])

    if not username or not email or not password:
        return jsonify({'error': 'username, email and password are required'}), 400

    if get_user_by_username(username):
        return jsonify({'error': 'username already exists'}), 409

    if get_user_by_email(email):
        return jsonify({'error': 'email already exists'}), 409

    user = {
        'id': str(uuid.uuid4()),
        'username': username,
        'email': email,
        'password_hash': generate_password_hash(password),
        'preferences': preferences,
    }
    save_user(user)
    return jsonify({'message': 'user registered successfully', 'username': username, 'email': email}), 201


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip().lower()
    password = data.get('password', '')

    if not email or not password:
        return jsonify({'error': 'email and password are required'}), 400

    user = get_user_by_email(email)
    if not user or not check_password_hash(user['password_hash'], password):
        return jsonify({'error': 'invalid credentials'}), 401

    token = create_token(user['username'], current_app.config.get('SECRET_KEY', 'globetrotter-secret-change-in-prod'))
    return jsonify({'token': token, 'email': user['email'], 'username': user['username']}), 200


@app.route('/me', methods=['GET'])
def me():
    username = get_current_user(request)
    if not username:
        return jsonify({'error': 'authentication required'}), 401

    user = get_user_by_username(username)
    if not user:
        return jsonify({'error': 'user not found'}), 404

    return jsonify({'username': user['username'], 'email': user['email'], 'preferences': user.get('preferences', [])}), 200


@app.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip().lower()
    if not email:
        return jsonify({'error': 'email is required'}), 400
    user = get_user_by_email(email)
    if not user:
        return jsonify({'message': 'If that email exists, a reset link has been sent.'}), 200
    token = secrets.token_urlsafe(24)
    _RESET_TOKENS[token] = email
    return jsonify({'message': 'Password reset instructions have been sent to your email.', 'reset_token': token}), 200


@app.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json(silent=True) or {}
    token = data.get('token', '').strip()
    new_password = data.get('new_password', '')
    if not token or not new_password:
        return jsonify({'error': 'token and new_password are required'}), 400
    email = _RESET_TOKENS.pop(token, None)
    if not email:
        return jsonify({'error': 'invalid or expired reset token'}), 400
    update_user_password(email, new_password)
    return jsonify({'message': 'Password reset successfully'}), 200


if __name__ == '__main__':
    app.run(port=5100, host='0.0.0.0')
