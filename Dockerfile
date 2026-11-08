# syntax=docker/dockerfile:1

FROM python:3.13.18-slim

WORKDIR /app

RUN useradd --create-home --uid 10001 --user-group --shell /usr/sbin/nologin app

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1

RUN --mount=from=ghcr.io/astral-sh/uv:0.12.22,source=/uv,target=/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy \
    uv sync --locked --no-dev --no-install-project

COPY app/ ./app/

USER 10001

EXPOSE 8000

CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
