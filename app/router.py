import socket
from typing import Annotated

from fastapi import APIRouter, Depends
from redis.asyncio import Redis

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
