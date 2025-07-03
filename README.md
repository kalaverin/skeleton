##### All-in-one kickstart repository with supervisord, crontab, linters and many useful tools.

Version control is handled using [Astral UV](https://docs.astral.sh/uv/getting-started/installation/#standalone-installer) tool. When building the image, uv is sourced from the official repository by copying the binary. Installation on a developer's machine can be done in various ways, which we'll cover shortly.

Managing the interpreter version, project environment variables, and setting up the virtual environment is done with the [Mise](https://mise.jdx.dev/installing-mise.html) tool. It can automatically install any interpreter version by reading it from the project description and/or the version bound by uv. It can also fetch the appropriate uv binary for the platform and architecture.

### Tooling preparation, two variants:

#### A. Quick start for test

Therefore, the quickest and most minimal way to get touch is to install mise on your system and prepare tools with mise:

1. `brew install mise`

#### B. Engineer full-featured setup

True engineer way it's prepare rust environment, build mise and configure shell:

1. Install Cargo via [Rustup](https://doc.rust-lang.org/book/ch01-01-installation.html).
1. Do not forget add cargo path for your shell:
   - `export PATH="~/.cargo/bin:$PATH"`
1. Install sccache to avoid electricity bills:
   - `cargo install sccache`
1. Activate sccache:
   - `export RUSTC_WRAPPER="~/.cargo/bin/sccache"` (and add it to your shell)
1. Install cargo packages updater and mise:
   - `cargo install cargo-update mise`
1. Install uv:
   - `mise install uv@latest && mise use -g uv@latest`
1. That's all, you have last version of optimized tools; for update all packages just run sometime:
   - `rustup update && cargo install-update --all`

#### Shell configuration

1. Mise provide dotenv functionality from the box with batteries, but your shell must have entry hook, add to your shell it, example for zsh (your can replace it for bash, fish, etc):
   - `eval "$(mise activate zsh)"`
1. Also you can want using autocompletion, same story for zsh:
   - `eval "$(mise completion zsh && uv generate-shell-completion zsh)"`
1. Restart your shell session:
   - `exec "$SHELL"`

#### Kickstart

1. Go to project root.
1. Just run `make env`
   - mise mark this directory as trusted
   - mise copy sample developmnt environment variables to .env
   - mise grab environment variables defined in project .env, evaluate it and provide to current shell session
   - mise checks what project python versions is installed, otherwise download and install it
   - mise make virtual environment in project root with uv
   - uv read project packages list, download, install and link it (via `uv sync` run, read Makefile)
   - mise install pre-commit and pre-push hooks

#### Work with project

## Warning about pip

**NEVER DO NOT CALL pip!**, use native uv command, read manual, it's very easy, for example:

1. Just add new dependency:

   - `uv add fast api`

1. Add some development library:

   - `uv add --group development memtrace`

1. Work with locally cloned repository:

   - `uv add --editable ~/src/libraries/myexlab-grpc`

## Common workflow

1. `make env`:

   - same as `mise install`, but also call `mise trust --yes` for initial deployment
   - call `make sync`

1. `make sync`

   - drop and recreate .venv
   - call `make sync`
   - read project dependencies graph from pyproject.toml
   - install it to virtual environment
   - call `make freeze`

1. `make freeze`:

   - dump state to uv.lock
   - save all used packages in current virtual environment to `packages.json` (with all development packages!)
   - save project dependencies to `packages.txt` with hashes for release builds strict version checks, read Dockerfile example (only project dependencies!)

1. `make upgrade`:

   - read project dependencies graph from pyproject.toml
   - fetch information about all updated packages, recreate dependencies graph
   - install it to virtual environment
   - update `uv.lock` with updated packages version
   - call `make freeze`
   - show all installed packages in local virtual environment
   - just manually update versions in pyproject.toml

1. `make check`:
   It's non-destructive action, just run all checks and stop at first fail.

1. `make lint`:
   Destructive action, always commit all changes before run it. Runs all compatible linters with --fix and --edit mode, after it call `make check` for final polishing.
