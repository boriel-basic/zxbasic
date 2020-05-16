#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import zx


class Tester(zx.Emulator):
    def __init__(self):
        # speed_factor=None results in maximum speed and
        # suppresses showing the emulator window.
        # super().__init__(speed_factor=0.01)
        super().__init__(speed_factor=None)

    def on_breakpoint(self):
        self.done = True

    def run_test(self, tape_filename, ram_filename):
        # Auto-load the tape.
        self.load_tape(tape_filename)

        # Catch the end of test.
        self.set_breakpoint(8)

        # Run the main loop until self.done is raised.
        self.main()

        # Get view to the video memory.
        screen = self.get_memory_view(0x4000, 6 * 1024 + 768)

        # Compare it with the etalon screenshot.
        with open(ram_filename, 'rb') as f:
            if screen != f.read():
                print('FAIL')
                sys.exit(1)


def main():
    with Tester() as t:
        t.run_test(sys.argv[1], sys.argv[2])
    print('OK')


if __name__ == "__main__":
    main()
