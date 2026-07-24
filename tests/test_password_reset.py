import pytest
from werkzeug.security import check_password_hash, generate_password_hash

from app import create_app
from app.models import get_user_by_email, save_user


@pytest.fixture()
def client():
    app = create_app()
    app.config.update(TESTING=True)
    with app.test_client() as client:
        yield client


def test_forgot_password_and_reset_password_flow(client):
    email = "reset-test@example.com"
    save_user(
        {
            "id": "reset-user",
            "username": "reset-user",
            "email": email,
            "password_hash": generate_password_hash("old-secret"),
            "preferences": ["food"],
        }
    )

    response = client.post(
        "/forgot-password",
        json={"email": email},
    )

    assert response.status_code == 200
    body = response.get_json()
    assert "reset" in body["message"].lower()
    assert body["reset_token"]

    reset_response = client.post(
        "/reset-password",
        json={"token": body["reset_token"], "new_password": "new-secret"},
    )

    assert reset_response.status_code == 200

    updated_user = get_user_by_email(email)
    assert updated_user is not None
    assert check_password_hash(updated_user["password_hash"], "new-secret")

    login_response = client.post(
        "/login",
        json={"email": email, "password": "new-secret"},
    )

    assert login_response.status_code == 200
