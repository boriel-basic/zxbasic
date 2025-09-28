#!/usr/bin/env python3

# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import signal
import sys

import zx  # type: ignore[import-untyped]


def signal_handler(sig, frame):
    print("Killed!")
    sys.exit(1)


class Stop(Exception):
    pass


class Tester(zx.Emulator):
    def __init__(self):
        # speed_factor=None results in maximum speed and
        # suppresses showing the emulator window.
        # super().__init__(speed_factor=0.01)
        super().__init__(speed_factor=None)

    def on_breakpoint(self):
        self.stop()

    def run_test(self, tape_filename, ram_filename):
        # Autoload the tape.
        try:
            self._load_file(tape_filename)
        except FileNotFoundError:
            print(f"Tape file '{tape_filename}' not found")
            sys.exit(1)

        # Catch the end of test.
        self.set_breakpoint(8)

        # Run the main loop.
        try:
            self.run()
        except zx.EmulationExit:
            pass

        # Get view to the video memory.
        screen = self.read(0x4000, 6 * 1024 + 768)

        # Compare it with the etalon screenshot.

        with open(ram_filename, "rb") as f:
            if screen != f.read():
                print("FAIL")
                sys.exit(1)


def main():
    signal.signal(signal.SIGTERM, signal_handler)
    with Tester() as t:
        t.run_test(sys.argv[1], sys.argv[2])
    print("OK")


if __name__ == "__main__":
    main()
