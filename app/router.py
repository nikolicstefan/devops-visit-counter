import socket

from fastapi import APIRouter

router = APIRouter()


@router.get("/")
def index() -> dict[str, str]:
    return {
        "message": "Hello DevOps",
        "host": socket.gethostname(),
    }
