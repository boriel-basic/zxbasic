from contextlib import contextmanager

from src.arch.z80 import optimizer
from src.arch.z80.peephole import engine


@contextmanager
def mock_options_level(level: int):
    initial_level = optimizer.OPTIONS.optimization_level

    try:
        optimizer.OPTIONS.optimization_level = level
        yield
    finally:
        optimizer.OPTIONS.optimization_level = initial_level


class TestOptimizer:
    def setup_class(cls):
        engine.main()

    def test_unrequired_or_a(self):
        code_src = """
        call .core.__LTI8
        or a
        ld bc, 0
        di
        ld hl, (.core.__CALL_BACK__)
        ld sp, hl
        exx
        pop hl
        pop iy
        pop ix
        exx
        ei
        ret
        """
        code = [x.strip() for x in code_src.split("\n") if x.strip()]

        with mock_options_level(4):
            optimized_code = optimizer.optimize(code)
            assert optimized_code.split("\n")[:2] == ["call .core.__LTI8", "ld bc, 0"]
