from contextlib import contextmanager

from src.api.config import OPTIONS


@contextmanager
def mock_options_level(level: int):
    initial_level = OPTIONS.optimization_level

    try:
        OPTIONS.optimization_level = level
        yield
    finally:
        OPTIONS.optimization_level = initial_level
