#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
from distutils.core import setup
from setuptools import find_packages

import version


def get_files(folder):
    result = []
    for dir_, subdirs, files_ in os.walk(folder):
        result.extend(os.path.join(dir_, f) for f in files_)
    return result

file_dirs = 'library', 'library-asm'


setup(
    name='zxbasic',
    scripts=['zxb.py', 'zxbasm.py', 'zxbpp.py'],
    py_modules=['asm', 'asmlex', 'asmparse', 'keywords', 'optimizer', 'version', 'identityset',
                'parsetab', 'zxbpptab', 'zxbasmtab',
                'z80', 'zxblex', 'zxbparser', 'zxbpplex', 'zxbasmpplex'],
    packages=find_packages(exclude='test'),
    version=version.VERSION,
    description='The ZX Basic compiler',
    long_description="A BASIC to Z80 cpu asm / machine code compiler.\n"
                     "It mostly targets ZX Spectrum vintage machine but can be\n"
                     "used for other purposes.",
    author='Jose Rodriguez',
    author_email='boriel@gmail.com',
    url='https://bitbucket.org/boriel/zxbasic',
    download_url='http://boriel.com/files/zxb/zxbasic-1.4.0.tar.gz',
    keywords=['compiler', 'zxspectrum', 'BASIC', 'z80'],  # arbitrary keywords
    data_files=[(os.path.join('bin', x), get_files(x)) for x in file_dirs] + ['README', 'LICENSE.txt'],
    license='GPL3',
    entry_points={
        'console_scripts': [
            'zxb = zxb',
            'zxbasm = zxbasm',
            'zxbpp = zxbpp:entry_point'
        ],
    },
    classifiers=[],
    tags=['BASIC', 'zxspectrum', 'compiler', 'z80']
)
