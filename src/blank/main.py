from structlog import get_logger

from Blank.settings import config

logger = get_logger(__name__)


if __name__ == '__main__':
    logger.info(
        'Application started',
        app=config.name,
        version=config.version,
        port=config.port,
    )
