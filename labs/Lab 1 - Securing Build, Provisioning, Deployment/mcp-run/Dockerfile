# Stage 1: Builder
ARG BUILDKIT_SBOM_SCAN_CONTEXT=true
ARG BUILDKIT_SBOM_SCAN_STAGE=true

# Stage 1: Builder
FROM python:3.13-slim@sha256:b04b5d7233d2ad9c379e22ea8927cd1378cd15c60d4ef876c065b25ea8fb3bf3 AS builder

ENV PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    POETRY_VERSION=2.0.1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_CREATE=true

RUN pip install "poetry==$POETRY_VERSION"

WORKDIR /app

COPY pyproject.toml ./

RUN poetry install --no-root --only main

# Stage 2: Runtime
FROM python:3.13-slim@sha256:b04b5d7233d2ad9c379e22ea8927cd1378cd15c60d4ef876c065b25ea8fb3bf3 AS runtime

WORKDIR /app

COPY --from=builder /app/.venv /app/.venv
COPY main.py .

ENV PATH="/app/.venv/bin:$PATH"
ENV PORT=8080
ENV PYTHONUNBUFFERED=1

EXPOSE 8080

CMD ["sh", "-c", "fastmcp run main.py --transport sse --host 0.0.0.0 --port ${PORT}"]
