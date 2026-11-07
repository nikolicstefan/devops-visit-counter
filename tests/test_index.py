import socket

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app=app)


def test_index_success() -> None:
    response = client.get(url="/")

    assert response.status_code == 200
    assert response.json() == {
        "message": "Hello DevOps",
        "host": socket.gethostname(),
    }
