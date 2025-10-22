from structlog import get_logger

from Blank import glossary
from Blank.settings import config

logger = get_logger(__name__)


if __name__ == '__main__':
    logger.info(
        glossary.Service.Started,
        app=config.name,
        version=config.version,
        port=config.port,
    )
