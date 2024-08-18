#!/usr/bin/env python3

import sys

import pygame

WIDTH = 256  # ZX Spectrum screen width in pixels
HEIGHT = 192  # ZX Spectrum screen height in pixels
SCALE = 4  # Scale


# Colors
BLACK = 0
BLUE = 1
RED = 2
MAGENTA = 3
GREEN = 4
CYAN = 5
YELLOW = 6
WHITE = 7

BRIGHT_OFFSET = 20
SCREEN_AREA_SIZE = 6144


# PALETTE[<color>] will return the expected color. Add 0x28 to increase bright
PALETTE = [
    (0, 0, 0),
    (0, 0, 0xD7),
    (0xD7, 0, 0),
    (0xD7, 0, 0xD7),
    (0, 0xD7, 0),
    (0, 0xD7, 0xD7),
    (0xD7, 0xD7, 0),
    (0xD7, 0xD7, 0xD7),
]


TABLE: list[list[int]] = []  # Table of bytes to tuple of binaries


def to_bin(x: int) -> list[int]:
    result = []

    for i in range(8):
        result.insert(0, x & 1)
        x >>= 1

    return result


def get_attr(data: list[int], offset: int) -> int:
    """For a given offset in the drawing region, return the attribute.
    This is a bit tricky for the speccy as the screen memory is not linear
    """
    k = (offset >> 3) & 0x300
    r = offset & 0xFF
    return data[SCREEN_AREA_SIZE + k + r]


def get_xy_coord(offset: int) -> tuple[int, int]:
    """Given an offset, return the x, y coordinate
    of that byte in the display"""
    x = (offset & 0x1F) << 3  # mod 32
    y0 = (offset >> 5) & 0xC0  # offset / 2048
    y1 = (offset >> 8) & 0x07  # offset / 256
    y2 = (offset >> 2) & 0x38  # offset / 8
    y = y0 + y1 + y2
    return x * SCALE, y * SCALE


def plot_byte(screen: pygame.Surface, data: list[int], offset: int) -> None:
    """Draws a pixel at the given X, Y coordinate"""
    global TABLE

    byte_ = TABLE[data[offset]]
    attr = get_attr(data, offset)

    ink_ = attr & 0x7
    paper_ = (attr >> 3) & 0x7
    bright = (attr >> 6) & 0x1

    paper = tuple(x + bright for x in PALETTE[paper_])
    ink = tuple(x + bright for x in PALETTE[ink_])
    palette = [paper, ink]

    x0, y0 = get_xy_coord(offset)

    for x, bit_ in enumerate(byte_):
        screen.fill(palette[bit_], pygame.Rect(x0 + x * SCALE, y0, SCALE, SCALE))


def paint(data: list[int]) -> None:
    screen = pygame.display.set_mode([WIDTH * SCALE, HEIGHT * SCALE])

    for i in range(SCREEN_AREA_SIZE):
        plot_byte(screen, data, i)

    pygame.display.flip()

    # Wait for quit
    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

    pygame.quit()


if __name__ == "__main__":
    # initialize Table
    TABLE = [to_bin(x) for x in range(256)]

    with open(sys.argv[1], "rb") as f:
        data = f.read()

    paint(data)
