"""
app/auth.py

User registration, login, and JWT handling.

Routes
------
POST /register  – create a new user account
POST /login     – authenticate and return a JWT token
"""
import uuid
import datetime
import secrets

import jwt
from flask import Blueprint, request, jsonify, current_app
from werkzeug.security import generate_password_hash, check_password_hash

from app.models import get_user_by_email, get_user_by_username, save_user, update_user_password

auth_bp = Blueprint("auth", __name__)

_RESET_TOKENS = {}


# ---------------------------------------------------------------------------
# Helper – JWT utilities
# ---------------------------------------------------------------------------

def create_token(username: str, secret: str) -> str:
    """Return a signed JWT for *username* valid for 24 hours."""
    now = datetime.datetime.now(datetime.timezone.utc)
    payload = {
        "sub": username,
        "iat": now,
        "exp": now + datetime.timedelta(hours=24),
    }
    return jwt.encode(payload, secret, algorithm="HS256")


def decode_token(token: str, secret: str) -> dict:
    """Decode and verify *token*. Raises jwt.PyJWTError on failure."""
    return jwt.decode(token, secret, algorithms=["HS256"])


def get_current_user(request_obj) -> str | None:
    """Extract and validate the JWT from the Authorization header.

    Returns the username (subject claim) or None if the token is missing /
    invalid.
    """
    auth_header = request_obj.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return None
    token = auth_header.split(" ", 1)[1]
    try:
        payload = decode_token(token, current_app.config["SECRET_KEY"])
        return payload.get("sub")
    except jwt.PyJWTError:
        return None


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@auth_bp.route("/register", methods=["POST"])
def register():
    """Register a new user.

    Expected JSON body:
        { "username": "alice", "password": "s3cr3t", "preferences": ["beach", "food"] }

    Returns 201 on success, 400 on validation errors, 409 if the username is
    already taken.
    """
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")
    preferences = data.get("preferences", [])  # optional list of interest tags

    if not username or not email or not password:
        return jsonify({"error": "username, email and password are required"}), 400

    if get_user_by_username(username):
        return jsonify({"error": "username already exists"}), 409

    if get_user_by_email(email):
        return jsonify({"error": "email already exists"}), 409

    user = {
        "id": str(uuid.uuid4()),
        "username": username,
        "email": email,
        # Store a Werkzeug password hash – never store plain-text passwords.
        "password_hash": generate_password_hash(password),
        "preferences": preferences,
    }
    save_user(user)
    return jsonify({"message": "user registered successfully", "username": username, "email": email}), 201


@auth_bp.route("/login", methods=["POST"])
def login():
    """Authenticate a user and return a JWT.

    Expected JSON body:
        { "email": "alice@example.com", "password": "s3cr3t" }

    Returns 200 with a token on success, 400/401 on failure.
    """
    data = request.get_json(silent=True) or {}
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    if not email or not password:
        return jsonify({"error": "email and password are required"}), 400

    user = get_user_by_email(email)
    if not user or not check_password_hash(user["password_hash"], password):
        return jsonify({"error": "invalid credentials"}), 401

    token = create_token(user["username"], current_app.config["SECRET_KEY"])
    return jsonify({"token": token, "email": user["email"], "username": user["username"]}), 200


@auth_bp.route("/forgot-password", methods=["POST"])
def forgot_password():
    """Issue a password reset token for an existing email address."""
    data = request.get_json(silent=True) or {}
    email = data.get("email", "").strip().lower()

    if not email:
        return jsonify({"error": "email is required"}), 400

    user = get_user_by_email(email)
    if not user:
        return jsonify({"message": "If that email exists, a reset link has been sent."}), 200

    token = secrets.token_urlsafe(24)
    _RESET_TOKENS[token] = email
    return jsonify({
        "message": "Password reset instructions have been sent to your email.",
        "reset_token": token,
    }), 200


@auth_bp.route("/reset-password", methods=["POST"])
def reset_password():
    """Reset the password using a previously issued reset token."""
    data = request.get_json(silent=True) or {}
    token = data.get("token", "").strip()
    new_password = data.get("new_password", "")

    if not token or not new_password:
        return jsonify({"error": "token and new_password are required"}), 400

    email = _RESET_TOKENS.pop(token, None)
    if not email:
        return jsonify({"error": "invalid or expired reset token"}), 400

    update_user_password(email, new_password)
    return jsonify({"message": "Password reset successfully"}), 200
