from fastapi import status
from fastapi.testclient import TestClient

from app.dependencies import get_redis
from app.main import app


class FakeRedis:
    def __init__(self) -> None:
        self.visits = 0

    async def incr(self, key: str) -> int:
        assert key == "visits"
        self.visits += 1
        return self.visits


def test_visits_increment_success() -> None:
    fake_redis = FakeRedis()

    app.dependency_overrides[get_redis] = lambda: fake_redis

    try:
        with TestClient(app) as client:
            first_response = client.get("/visits")
            second_response = client.get("/visits")
    finally:
        app.dependency_overrides.clear()

    assert first_response.status_code == status.HTTP_200_OK
    assert first_response.json() == {"visits": 1}

    assert second_response.status_code == status.HTTP_200_OK
    assert second_response.json() == {"visits": 2}
