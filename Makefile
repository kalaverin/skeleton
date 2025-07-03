env:
	@mise install
	@make sync

sync:
	@uv venv --refresh
	@uv sync
	@make freeze

freeze:
	@uv pip list --format=json > packages.json
	@uv pip compile \
		--output-file packages.txt \
		--generate-hashes pyproject.toml

check:
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

.DEFAULT_GOAL := freeze
