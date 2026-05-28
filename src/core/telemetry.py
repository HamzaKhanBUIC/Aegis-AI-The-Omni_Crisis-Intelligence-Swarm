"""
src/core/telemetry.py
Structured JSON logging and distributed tracing telemetry.
"""

import logging


def get_telemetry_logger(name: str):
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    # Configure structured JSON logging here for production telemetry
    return logger
