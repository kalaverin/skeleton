help:
	@just default

install:
	@mise trust --yes .mise.toml
	@mise install

%:
	@just $@

.DEFAULT_GOAL := default
