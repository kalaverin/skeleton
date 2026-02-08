from structlog import get_logger

from blank import assets, config

logger = get_logger(__name__)

if __name__ == "__main__":
    logger.info(
        assets.Service.Started,
        app=config.name,
        version=config.version,
        port=config.port,
    )
