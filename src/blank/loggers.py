import logging.config
import sys
from collections.abc import Iterable
from functools import partial
from logging import StreamHandler, getLevelName, getLogger, root
from typing import Any, TextIO

import orjson
import structlog
from structlog.dev import ConsoleRenderer
from structlog.processors import (
    CallsiteParameter,
    CallsiteParameterAdder,
    JSONRenderer,
    StackInfoRenderer,
    TimeStamper,
    UnicodeDecoder,
    format_exc_info,
)
from structlog.stdlib import (
    ExtraAdder,
    LoggerFactory,
    PositionalArgumentsFormatter,
    ProcessorFormatter,
    add_log_level,
    add_logger_name,
)
from structlog.types import Processor

# options for orjson, we want to sort keys, serialize dataclasses, numpy and
# uuid objects, and use naive UTC datetimes

DEFAULT_JSON_OPTIONS: int = (
    orjson.OPT_SORT_KEYS |
    orjson.OPT_NAIVE_UTC |
    orjson.OPT_SERIALIZE_DATACLASS |
    orjson.OPT_SERIALIZE_NUMPY |
    orjson.OPT_SERIALIZE_UUID
)

# processors that will be called for each log entry, before the renderer

DEFAULT_PROCESSORS: tuple[Processor, ...] = (
    structlog.contextvars.merge_contextvars,
    add_logger_name,
    add_log_level,
    TimeStamper(fmt='iso'),
    PositionalArgumentsFormatter(),
    ExtraAdder(),
    StackInfoRenderer(),
    UnicodeDecoder(),
    CallsiteParameterAdder(
        parameters=[
            CallsiteParameter.FILENAME,
            CallsiteParameter.FUNC_NAME,
            CallsiteParameter.LINENO,
        ],
    ),
)


def nothing_to_do(*_: Any, **__: Any) -> None: ...


def setup(
    level: int | str = 'info',
    textual: bool = False,
    serializer_options: int = DEFAULT_JSON_OPTIONS,
    processors: Iterable[Processor] = DEFAULT_PROCESSORS,
) -> None:
    # logging level can be passed as integer

    if isinstance(level, int):
        level = getLevelName(level)

    # in development we look for native tracebacks (with better-exceptions too)
    # but in production we want json in the logs

    order: list[Processor] = list(processors)

    # in production we want to serialize exception info as part of the json

    if not textual:
        order.append(format_exc_info)

    # main configuration

    structlog.configure(
        processors=[*order, ProcessorFormatter.wrap_for_formatter],
        logger_factory=LoggerFactory(),
        cache_logger_on_first_use=True,
    )

    # make renderer, json in production, colored console in development

    if textual:
        renderer = ConsoleRenderer(colors=True)

    else:
        # for better performance, we use orjson to serialize log entries

        dumps = partial(orjson.dumps, option=serializer_options)

        def serializer(*args: Any, **kw: Any) -> str:
            return dumps(*args, **kw).decode('utf-8')

        renderer = JSONRenderer(serializer=serializer)

    # formatter for handler, it will call all processors before render

    formatter: ProcessorFormatter = ProcessorFormatter(
        foreign_pre_chain=order,
        processors=[ProcessorFormatter.remove_processors_meta, renderer],
    )

    # override all loggers to use our handler and formatter

    handler: StreamHandler[TextIO] = StreamHandler(sys.stdout)
    handler.setFormatter(fmt=formatter)

    for logger in (getLogger(), *map(getLogger, root.manager.loggerDict)):

        logger.handlers.clear()
        logger.addHandler(handler)
        logger.setLevel(level.upper())
        logger.propagate = False

    # disable logging config dictConfig

    logging.config.dictConfig = nothing_to_do
