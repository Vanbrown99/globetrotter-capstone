import os
import subprocess
import sys
import time
from pathlib import Path

from app import create_app


def test_root_route_returns_api_info():
    app = create_app()
    client = app.test_client()

    response = client.get("/")

    assert response.status_code == 200
    payload = response.get_json()
    assert payload["message"] == "Globetrotter API"
    assert "/destinations" in payload["available_endpoints"]


def test_main_script_starts_without_import_error():
    repo_root = Path(__file__).resolve().parents[1]
    env = os.environ.copy()
    env["PYTHONUNBUFFERED"] = "1"
    env["FLASK_DEBUG"] = "0"

    process = subprocess.Popen(
        [sys.executable, "app/main.py"],
        cwd=repo_root,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=env,
    )

    try:
        time.sleep(1)
        assert process.poll() is None, process.stderr.read()
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=5)
