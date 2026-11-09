import socket
from typing import Annotated

from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from redis.asyncio import Redis
from redis.exceptions import RedisError

from .dependencies import get_redis

router = APIRouter()

RedisDependency = Annotated[Redis, Depends(get_redis)]


@router.get("/")
def index() -> dict[str, str]:
    return {
        "message": "Hello DevOps",
        "host": socket.gethostname(),
    }


@router.get("/visits")
async def read_visits(redis: RedisDependency) -> dict[str, int]:
    visits = await redis.incr("visits")

    return {
        "visits": visits,
    }


@router.get("/health")
async def health(redis: RedisDependency) -> JSONResponse:
    try:
        await redis.ping()
    except RedisError:
        return JSONResponse(
            content={"status": "error"},
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    return JSONResponse(content={"status": "ok"}, status_code=status.HTTP_200_OK)
