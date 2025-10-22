ARG BASE_IMAGE=python:3.12-slim-bookworm
FROM ${BASE_IMAGE}

# prepare application environment

USER root
ENV ROOT=/src \
    USER=somebody \
    GROUP=somebody \
    UID=1337 \
    GID=1337

RUN \
    groupadd \
        --gid $GID $GROUP && \
    useradd \
        --create-home \
        --uid $UID \
        --gid $GROUP \
        --shell /bin/bash $USER && \
    mkdir -p $ROOT/ && \
    chown -R $USER:$GROUP $ROOT/

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# install and setting up project dependencies

USER root
WORKDIR $ROOT/

# copy dependency definitions

COPY --chown=root:root \
    pyproject.toml uv.lock ./

ARG UV_INDEX_CUSTOM_USERNAME
ARG UV_INDEX_CUSTOM_PASSWORD

RUN \
    uv sync \
        --locked \
        --compile-bytecode \
        --link-mode copy \
        --no-default-groups \
        --no-progress \
        --no-python-downloads && \
    rm -rf /root/.cache/

# copy project sources

COPY --chown=root:root \
    entrypoint.sh main.py ./

COPY --chown=root:root \
    app/ $ROOT/app/

# store installed packages list

RUN uv pip list --format=json > $ROOT/packages.json

# entrypoint lives here

USER $USER
WORKDIR $ROOT

ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["./main.sh"]
CMD ["run"]
