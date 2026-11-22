# syntax=docker/dockerfile:1

# Build stage
FROM python:3.13.18-alpine AS builder

WORKDIR /app

RUN --mount=from=ghcr.io/astral-sh/uv:0.12.22,source=/uv,target=/bin/uv \
    --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy \
    uv sync --locked --no-dev --no-install-project

COPY app/ ./app/

# Runtime stage
FROM python:3.13.18-alpine AS runtime

WORKDIR /app

RUN addgroup -g 10001 -S app && \
    adduser -u 10001 -S app -G app -s /sbin/nologin

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1

COPY --from=builder --chown=10001:10001 /app/.venv /app/.venv
COPY --from=builder --chown=10001:10001 /app/app /app/app

USER 10001

ARG APP_PORT=8000
ENV APP_PORT=${APP_PORT}

EXPOSE ${APP_PORT}

CMD ["sh", "-c", "exec python -m uvicorn app.main:app --host 0.0.0.0 --port ${APP_PORT}"]
