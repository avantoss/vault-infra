import os, sys
import logging

TRACE = logging.DEBUG - 1
logging.addLevelName(TRACE, "TRACE")

level = logging.INFO

def add_options(cli):
    cli.add_argument('--debug', action='store_true', help="debug level logging")
    cli.add_argument('--trace', action='store_true', help="trace level logging")

def init(options):
    global level
    level = level_option(options)

    logging.basicConfig(
        level=level,
        format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
        datefmt='%m-%d %H:%M:%S',
        stream=sys.stderr)

def level_option(options):
    ret = logging.INFO
    if options.trace:
        ret = TRACE
    elif options.debug:
        ret = logging.DEBUG
    else:
        el = os.environ.get('LOG_LEVEL')
        if el == 'DEBUG':
            ret = logging.DEBUG
        elif el == 'TRACE':
            ret = TRACE
    return ret


def lower_unless_trace(logger_name):
    logger = logging.getLogger(logger_name)
    if level == logging.DEBUG:
        logger.setLevel(logging.WARNING)
