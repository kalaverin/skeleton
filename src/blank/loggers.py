import logging
import sys
from functools import partial
from typing import TYPE_CHECKING, TextIO

import orjson
import structlog
from structlog.dev import ConsoleRenderer
from structlog.processors import JSONRenderer, TimeStamper
from structlog.stdlib import ProcessorFormatter

if TYPE_CHECKING:
    from structlog.types import Processor

OVERRIDE_LOGGERS = ('sqlalchemy.engine.Engine.postgres',)


def setup(
    level: str,
    textual: bool,  # noqa: FBT001
) -> None:
    timestamper: TimeStamper = TimeStamper(fmt='iso', utc=True)

    shared_processors: list[Processor] = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        timestamper,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.stdlib.ExtraAdder(),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.UnicodeDecoder(),
        structlog.processors.CallsiteParameterAdder(
            parameters=[
                structlog.processors.CallsiteParameter.FILENAME,
                structlog.processors.CallsiteParameter.FUNC_NAME,
                structlog.processors.CallsiteParameter.LINENO,
            ],
        ),
    ]

    # in development we see native tracebacks (with better-exceptions too),
    # but in production we want them in the logs

    if not textual:
        shared_processors.append(structlog.processors.format_exc_info)

    # main configuration

    structlog.configure(
        processors=[
            *shared_processors,
            ProcessorFormatter.wrap_for_formatter,
        ],
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )

    if textual:
        renderer = ConsoleRenderer(colors=True)

    else:
        dumps = partial(
            orjson.dumps,
            option=(
                orjson.OPT_SORT_KEYS
                | orjson.OPT_NAIVE_UTC
                | orjson.OPT_SERIALIZE_DATACLASS
                | orjson.OPT_SERIALIZE_UUID
            ),
        )

        def serializer(*args, **kw) -> str:  # type: ignore[no-untyped-def]
            return dumps(*args, **kw).decode('utf-8')

        renderer = JSONRenderer(serializer=serializer)  # type: ignore[assignment]

    formatter: ProcessorFormatter = ProcessorFormatter(
        foreign_pre_chain=shared_processors,
        processors=[
            ProcessorFormatter.remove_processors_meta,
            renderer,
        ],
    )

    handler: logging.StreamHandler[TextIO] = logging.StreamHandler(sys.stdout)
    handler.setFormatter(fmt=formatter)

    # here we reconfigure the root logger

    root_logger: logging.Logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(hdlr=handler)
    root_logger.setLevel(level=level.upper())

    # and also override some loggers manually

    for logger_name in OVERRIDE_LOGGERS:
        logger: logging.Logger = logging.getLogger(name=logger_name)
        logger.handlers.clear()
        logger.propagate = True
