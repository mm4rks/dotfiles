#!/bin/env python3

""" SCRIPT DESCRIPTION """
import argparse
import logging
import sys
from pathlib import Path

LOGGER = logging.getLogger(__name__)


def existing_file(file_path) -> Path:
    """Check if file exists and return Path object"""
    path = Path(file_path)
    if not path.is_file():
        raise argparse.ArgumentTypeError(f"'{path}' does not exist")
    return path


def get_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="PROGRAM DESCRIPTION")
    parser.add_argument("--input", "-i", type=existing_file, help="Path to input")
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        action="store",
        dest="output",
        default="DEFAUT.OUT",
        help=f"Output file",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        dest="verbose",
        action="store_true",
        help="Utilize verbose logging",
    )
    return parser.parse_args()


def setup_logging(verbose_logging: bool = False):
    """Configure logging"""
    level = logging.DEBUG if verbose_logging else logging.WARNING
    logging.basicConfig(level=level, stream=sys.stderr)


def main(arguments):
    """Run based on command line arguments"""
    LOGGER.debug("debug log")
    LOGGER.info("info log")
    LOGGER.warning("warning log")
    return 0


if __name__ == "__main__":
    arguments = get_args()
    setup_logging(verbose_logging=arguments.verbose)
    sys.exit(main(arguments))
