from contextlib import suppress
from pathlib import Path
from re import search
from typing import Any

from orjson import loads
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from structlog import get_logger

from Blank import glossary, loggers

logger = get_logger(__name__)

KEY = 'BLANK'


class Database(BaseSettings):
    model_config: SettingsConfigDict = SettingsConfigDict(  # type: ignore[misc]
        env_prefix=f'{KEY}_DB_',
    )
    dsn: str = ''

    echo: bool = False
    pool_size: int = 5


class Logging(BaseSettings):
    model_config: SettingsConfigDict = SettingsConfigDict(  # type: ignore[misc]
        env_prefix=f'{KEY}_LOG_',
    )

    level: str = 'info'
    textual: bool = False


class Settings(BaseSettings):
    model_config: SettingsConfigDict = SettingsConfigDict(  # type: ignore[misc]
        env_file='.env',
        env_prefix=f'{KEY}_',
        validate_assignment=True,
        extra='ignore',
    )

    # predefined service name and version
    version: str = '0.0.0'
    name: str = 'Blank'

    # service configuration
    port: int = 8000
    debug: bool = False

    # sections

    db: Database = Field(default_factory=Database)
    log: Logging = Field(default_factory=Logging)


def show_environment(config: Settings, regex: str | None = None) -> None:
    log = logger.bind(
        app=config.name,
        version=config.version,
    )

    with suppress(Exception):
        path: Path = Path('packages.json').resolve()
        if path.is_file():
            with path.open('r') as fd:
                packages: list[str] = [
                    '{name}={version}'.format(**x)
                    for x in loads(fd.read().strip())
                ]
                log.info(glossary.Service.UsedLibraries, versions=packages)

    if config.debug:
        model: dict[str, Any] = config.model_dump()
        if regex:
            data: dict[str, Any] = {
                k: v
                for k, v in model.items()
                if search(pattern=regex, string=k)
            }
            log.info(glossary.Service.UsedVariables, variables=data)

        else:
            log.info(glossary.Service.UsedVariables, variables=model)


config: Settings = Settings()

loggers.setup(
    level=config.log.level,
    textual=config.log.textual and config.debug,
)

show_environment(config)
