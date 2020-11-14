# -*- coding: utf-8 -*-

import pytest
from src.libzxbc import zxbc
import os

PATH = os.path.realpath(os.path.dirname(os.path.abspath(__file__)))


class EnsureRemoveFile(object):
    """ Ensures a filename is removed if exists after
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
    return os.path.join(PATH, 'empty.bas')


@pytest.fixture
def file_bin():
    return os.path.join(PATH, 'empty.bin')


def test_compile_only(file_bas, file_bin):
    """ Should not generate a file
    """
    with EnsureRemoveFile(file_bin):
        zxbc.main(['--parse-only', file_bas, '-o', file_bin])
        assert not os.path.isfile(file_bin), 'Should not create file "empty.bin"'


def test_org_allows_0xnnnn_format(file_bas, file_bin):
    """ Should allow hexadecimal format 0x in org
    """
    with EnsureRemoveFile(file_bin):
        zxbc.main(['--parse-only', '--org', '0xC000', file_bas, '-o', file_bin])
        assert zxbc.OPTIONS.org == 0xC000, 'Should set ORG to 0xC000'
