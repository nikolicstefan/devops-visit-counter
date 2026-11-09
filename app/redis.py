from redis.asyncio import Redis

from .config import settings


def create_redis() -> Redis:
    return Redis(
        host=settings.redis_host,
        port=settings.redis_port,
        decode_responses=True,
    )
