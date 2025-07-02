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
	@uvx ruff check \
		'contrib/' 'src/' 'tests/'

	@uvx black \
		--check \
		--diff \
		'contrib/' 'src/' 'tests/'

	@uvx vulture \
		--min-confidence 66 \
		'contrib/' 'src/' 'tests/'

	@uvx mypy \
		--config-file etc/lint/mypy.toml \
		'contrib/' 'src/' 'tests/'

	@uvx flakeheaven lint \
		--config etc/lint/flakeheaven.toml \
		'contrib/' 'src/' 'tests/'

	@uvx bandit \
		--quiet \
		--recursive \
		--severity-level all \
		--confidence-level all \
		--configfile pyproject.toml \
		'contrib/' 'src/'

	@uvx bandit \
		--quiet \
		--recursive \
		--severity-level all \
		--confidence-level all \
		--configfile pyproject.toml \
		--skip B101,B105,B106 \
		'tests/'

lint:
	@uvx ruff check \
		--fix \
		'contrib' 'src/' 'tests/'

	@uvx black 'contrib' 'src/' 'tests/'

	@uvx yamlfix \
		--exclude '.venv/' \
		.

	@uvx yamllint \
		--format parsable \
		--config-file etc/lint/yamllint.yaml \
		.

	@uvx pre-commit run \
		--config etc/pre-commit.yaml \
		--show-diff-on-failure \
		--color always \
		--all

	@make check

.DEFAULT_GOAL := freeze
