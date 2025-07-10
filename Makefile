env:
	@make install
	@make sync

install:
	@mise trust --yes .mise.toml && mise install

sync:
	@uv venv --refresh
	@uv sync
	@make freeze

freeze:
	@uv lock
	@uv pip list --format=json > packages.json
	@uv pip compile \
		--output-file packages.txt \
		--generate-hashes pyproject.toml \
		--quiet

check:
	@uv sync --group linting

	@uv run --quiet vulture \
		--min-confidence 66 \
		'contrib/' 'src/' 'tests/'

	@uv run --quiet black \
		--check \
		--diff \
		'contrib/' 'src/' 'tests/'

	@uv run --quiet mypy \
		--config-file etc/lint/mypy.toml \
		'contrib/' 'src/' 'tests/'

	@uv run --quiet flakeheaven lint \
		--config etc/lint/flakeheaven.toml \
		'contrib/' 'src/' 'tests/'

	@uv run --quiet ruff check \
		'contrib/' 'src/' 'tests/'

	@uv run --quiet bandit \
		--quiet \
		--recursive \
		--severity-level all \
		--confidence-level all \
		--configfile pyproject.toml \
		'contrib/' 'src/'

	@uv run --quiet bandit \
		--quiet \
		--recursive \
		--severity-level all \
		--confidence-level all \
		--configfile pyproject.toml \
		--skip B101,B105,B106 \
		'tests/'

	@uv run --quiet yamllint \
		--format parsable \
		--config-file etc/lint/yamllint.yaml \
		.

lint:
	@uv sync --group linting

	@uv run --quiet black 'contrib' 'src/' 'tests/'

	@uv run --quiet ruff check \
		--fix \
		'contrib' 'src/' 'tests/'

	@uv run --quiet yamlfix \
		--exclude '.venv/' \
		.

	@uv run --quiet pre-commit run \
		--config etc/pre-commit.yaml \
		--show-diff-on-failure \
		--color always \
		--all

	@make check

upgrade:
	@uv sync \
		--upgrade \
		--group development \
		--group linting \
		--group testing

	@uv lock --upgrade
	@make freeze
	@uv pip list

.DEFAULT_GOAL := install
