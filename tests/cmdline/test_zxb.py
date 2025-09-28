# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import os

import pytest

from src.zxbc import zxbc

PATH = os.path.realpath(os.path.dirname(os.path.abspath(__file__)))


class EnsureRemoveFile:
    """Ensures a filename is removed if exists after
    a block of code is executed
    """

    def __init__(self, output_file_name):
        self.fname = output_file_name

    def remove_file(self):
        if os.path.isfile(self.fname):
            os.unlink(self.fname)

    def __enter__(self):
        self.remove_file()

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.remove_file()


@pytest.fixture
def file_bas():
    return os.path.join(PATH, "empty.bas")


@pytest.fixture
def config_file():
    return os.path.join(PATH, "config_sample.ini")


@pytest.fixture
def file_bin():
    return os.path.join(PATH, "empty.bin")


def test_compile_only(file_bas, file_bin):
    """Should not generate a file"""
    with EnsureRemoveFile(file_bin):
        zxbc.main(["--parse-only", file_bas, "-o", file_bin])
        assert not os.path.isfile(file_bin), 'Should not create file "empty.bin"'


def test_org_allows_0xnnnn_format(file_bas, file_bin):
    """Should allow hexadecimal format 0x in org"""
    with EnsureRemoveFile(file_bin):
        zxbc.main(["--parse-only", "--org", "0xC000", file_bas, "-o", file_bin])
        assert zxbc.OPTIONS.org == 0xC000, "Should set ORG to 0xC000"


def test_org_loads_ok_from_config_file_format(file_bas, file_bin, config_file):
    """Should allow hexadecimal format 0x in org"""
    with EnsureRemoveFile(file_bin):
        zxbc.main(["--parse-only", "-F", config_file, file_bas, "-o", file_bin])
        assert zxbc.OPTIONS.org == 31234, "Should set ORG to 31234"


def test_cmdline_should_override_config_file(file_bas, file_bin, config_file):
    """Should allow hexadecimal format 0x in org"""
    with EnsureRemoveFile(file_bin):
        zxbc.main(["--parse-only", "-F", config_file, "--org", "1234", file_bas, "-o", file_bin])
        assert zxbc.OPTIONS.org == 1234, "Commandline should override config file"
        assert zxbc.OPTIONS.optimization_level == 3, "Commandline should override config file"
