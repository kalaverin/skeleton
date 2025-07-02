ARG BASE_IMAGE=python:3.11-slim-bookworm
FROM ${BASE_IMAGE}

# prepare application environment

USER root
ENV ROOT=/src/ \
    USER=somebody \
    GROUP=somebody \
    PORT=80

RUN \
    groupadd \
        --gid 1337 $GROUP && \
    useradd \
        --create-home \
        --uid 1337 \
        --gid $GROUP \
        --shell /bin/bash $USER && \
    mkdir -p $ROOT && \
    chown -R $USER:$GROUP $ROOT

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# install and setting up project dependencies

WORKDIR /root
COPY pyproject.toml packages.txt ./

ARG UV_INDEX_CUSTOM_USERNAME
ARG UV_INDEX_CUSTOM_PASSWORD
ARG GITLAB_PYPI_INDEX_URL="https://pypi.org/simple"

RUN \
    --mount=type=cache,id=uv,target=/root/.cache/ \
    uv pip sync \
        --index $GITLAB_PYPI_INDEX_URL \
        --compile-bytecode \
        --link-mode copy \
        --refresh \
        --require-hashes \
        --strict \
        --system \
    packages.txt

# copy project sources

COPY --chown=root:root \
    src/ $ROOT

RUN uv pip list --format=json > $ROOT/packages.json

# entrypoint lives here

USER $USER
WORKDIR $ROOT

ENTRYPOINT [ \
    "uvicorn", \
    "main:Application", \
    "--app-dir", \
    "$ROOT", \
    "--host", \
    ""127.0.0.1"", \
    "--port", \
    "$PORT", \
    "--env-file", \
    ".env", \
    "--log-level", \
    "debug", \
    "--access-log", \
    "--date-header", \
    "--no-server-header", \
    "--proxy-headers", \
    "--use-colors" \
]
