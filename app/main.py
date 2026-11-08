import logging
import sys
from collections.abc import Awaitable, Callable

from fastapi import FastAPI, Request, Response, status
from fastapi.responses import JSONResponse

from .router import router

logger = logging.getLogger(name=__name__)
logger.setLevel(level=logging.INFO)

if not logger.handlers:
    handler = logging.StreamHandler(stream=sys.stdout)
    handler.setFormatter(
        fmt=logging.Formatter(fmt="%(asctime)s %(levelname)s %(name)s: %(message)s")
    )
    logger.addHandler(hdlr=handler)

logger.propagate = False

app = FastAPI(title="Visit Counter")
app.include_router(router=router)


@app.exception_handler(Exception)
async def global_exception_handler(
    request: Request, exception: Exception
) -> JSONResponse:
    logger.exception("%s %s", request.method, request.url.path)

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "Internal Server Error",
            "error_code": "INTERNAL_SERVER_ERROR",
        },
    )


@app.middleware("http")
async def request_logger(
    request: Request, call_next: Callable[[Request], Awaitable[Response]]
) -> Response:
    logger.info("%s %s", request.method, request.url.path)

    return await call_next(request)
