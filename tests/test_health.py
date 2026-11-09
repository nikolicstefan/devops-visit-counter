from fastapi import status
from fastapi.testclient import TestClient
from redis.exceptions import RedisError

from app.dependencies import get_redis
from app.main import app


class HealthyRedis:
    async def ping(self) -> bool:
        return True


class UnavailableRedis:
    async def ping(self) -> bool:
        raise RedisError("Redis is unavailable")


def test_health_available() -> None:
    app.dependency_overrides[get_redis] = lambda: HealthyRedis()

    try:
        with TestClient(app) as client:
            response = client.get("/health")
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == status.HTTP_200_OK
    assert response.json() == {"status": "ok"}


def test_health_unavailable() -> None:
    app.dependency_overrides[get_redis] = lambda: UnavailableRedis()

    try:
        with TestClient(app) as client:
            response = client.get("/health")
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == status.HTTP_503_SERVICE_UNAVAILABLE
    assert response.json() == {"status": "error"}
