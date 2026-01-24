from structlog import get_logger

from Blank import glossary, loggers
from Blank.settings import Settings, show_environment


if __name__ == '__main__':
    config: Settings = Settings()

    loggers.setup(
        level=config.log.level,
        textual=config.log.textual and config.debug,
    )
    show_environment(config)

    # log service start

    logger = get_logger(__name__)
    logger.info(
        glossary.Service.Started,
        app=config.name,
        version=config.version,
        port=config.port,
    )
