from contextlib import suppress
from pathlib import Path
from re import search
from typing import Any, ClassVar

from orjson import loads
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from structlog import get_logger

from blank import assets
from blank.loggers import setup
from blank.version import __version__

logger = get_logger(__name__)

KEY = "BLANK"


class BaseConfig(BaseSettings):
    model_config: ClassVar[SettingsConfigDict] = SettingsConfigDict(
        env_prefix=f"{KEY}_",
    )


class Database(BaseConfig):
    model_config: ClassVar[SettingsConfigDict] = SettingsConfigDict(
        env_prefix=f"{KEY}_DB_",
    )

    dsn: str = ""
    echo: bool = False
    pool_size: int = 5


class Logging(BaseConfig):
    model_config: ClassVar[SettingsConfigDict] = SettingsConfigDict(
        env_prefix=f"{KEY}_LOG_",
    )

    level: str = "info"
    textual: bool = False


class Settings(BaseConfig):
    model_config: ClassVar[SettingsConfigDict] = SettingsConfigDict(
        env_file=".env",
        env_prefix=f"{KEY}_",
        validate_assignment=True,
        validate_default=True,
        extra="ignore",
    )

    # predefined service name and version
    version: str = __version__
    name: str = "Blank"

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
        path: Path = Path("packages.json").resolve()
        if path.is_file():
            with path.open() as fd:
                packages: list[str] = [
                    "{name}={version}".format(**x)
                    for x in loads(fd.read().strip())
                ]
                log.info(assets.Service.UsedLibraries, versions=packages)

    if config.debug:
        model: dict[str, Any] = config.model_dump()
        if regex:
            data: dict[str, Any] = {
                k: v
                for k, v in model.items()
                if search(pattern=regex, string=k)
            }
            log.info(assets.Service.UsedVariables, variables=data)

        else:
            log.info(assets.Service.UsedVariables, variables=model)


config: Settings = Settings()

setup(
    level=config.log.level,
    textual=config.log.textual and config.debug,
)

show_environment(config)
