# Simple project for Python 3.12+

#### All-in-one repository with supervisor, crontab, linters and many useful tools

## Overview

**Version control** is handled using [Astral UV](https://docs.astral.sh/uv/getting-started/installation/#standalone-installer) tool. When building the image, uv is sourced from the official repository by copying the binary. Installation on a developer's machine can be done in various ways, which we'll cover shortly.

**Managing the interpreter version project tools**, project environment variables, and setting up the virtual environment is done with the [Mise](https://mise.jdx.dev/installing-mise.html) tool. It install any interpreter version by reading it from the project description and/or the version bound by uv, it also run the appropriate uv & just binary for user platform and architecture.

### Kickstart or how to run?

(after you have installed `mise`, read below for details, read [INSTALL.md](./INSTALL.md) for details how to install and configure required tools)

1. Go to project root.
2. Copy .env.sample to .env, add your personal settings, tokens, passwords, etc
3. Run `make install`:

    - mise will mark project directory as trusted
    - mise copy sample development environment variables to .env (if .env not exists)
    - mise grab environment variables defined in project .env, evaluate it and provide to current shell session (dotenv functionality, if mise activated in your shell)
    - mise checks what project python versions is installed, otherwise download and install it
    - uv make virtual environment in project root (by `uv venv`)
    - uv read project packages list, download, install and link it (via `uv sync` run, read _justfile_)
    - uv install pre-commit hooks

4. Run `make ports` if service required access to another services in kubernetes cluster.

5. Run `make develop`, that's all, have fun!

### Filesystem hierarchy

#### Project have many directories

- `app/` or `src/` application or module sources root
- `etc/` linter and checker configurations, pre-commit, etc
- `migrations/` database alembic migrations
- `tests/` it's tests

#### ..and files

- `.env` git-ignored for local development, autoexpanded to current sheel environment by tooling; feel free to use it
- `.mise.toml` mise config, contains all used development tooling and maintain python installations

- `README.md` this file
- `INSTALL.md` how to install and configure required tools

- `Dockerfile` per se docker file
- `Makefile` back compatible fallback to make utility, but it's just a wrapper for justfile
- `justfile` project development workflow scenarios

- `pyproject.toml` main project configuration file
- `uv.lock` main project dependencies graph state lockfile
