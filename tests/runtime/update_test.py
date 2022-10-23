#!/usr/bin/env python3
# -*- coding: utf-8 -*-

__doc__ = "Creates or update a test result"


import sys

import zx


class Stop(Exception):
    pass


class TakeSnapshot(zx.Emulator):
    def __init__(self):
        # speed_factor=None results in maximum speed and
        # suppresses showing the emulator window.
        # super().__init__(speed_factor=0.01)
        super().__init__(speed_factor=None)

    def on_breakpoint(self):
        raise Stop()

    def run_test(self, filename):
        # Auto-load the tape.
        self.load_tape(filename)

        # Catch the end of test.
        self.set_breakpoint(8)

        # Run the main loop.
        try:
            self.run()
        except Stop:
            pass

        # Get view to the video memory.
        screen = self.get_memory_view(0x4000, 6 * 1024 + 768)

        # Take screenshot.
        with open(filename + ".scr", "wb") as f:
            f.write(screen)


def main():
    with TakeSnapshot() as t:
        t.run_test(sys.argv[1])
    print("OK")


if __name__ == "__main__":
    main()
