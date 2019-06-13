#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
from distutils.core import setup
from setuptools import find_packages
from collections import defaultdict

import version


def get_files(folders):
    result = defaultdict(list)

    for folder in folders:
        for dir_, subdirs, files_ in os.walk(folder):
            for fpath in [os.path.join(dir_, f) for f in files_]:
                result[os.path.dirname(fpath)].append(fpath)

    return result


file_dirs = 'library', 'library-asm'
data_files = [(os.path.join('bin', dir_), fpath) for dir_, fpath in get_files(file_dirs).items()]

setup(
    name='zxbasic',
    scripts=['zxb.py', 'zxbasm.py', 'zxbpp.py'],
    py_modules=['asm', 'asmlex', 'asmparse', 'keywords', 'optimizer', 'version', 'identityset',
                'parsetab', 'zxbpptab', 'zxbasmtab', 'basic',
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
    download_url='http://boriel.com/files/zxb/zxbasic-%s.tar.gz' % version.VERSION,
    keywords=['compiler', 'zxspectrum', 'BASIC', 'z80'],  # arbitrary keywords
    data_files=data_files,
    license='GPL3',
    entry_points={
        'console_scripts': [
            'zxb = zxb:main',
            'zxbasm = zxbasm:main',
            'zxbpp = zxbpp:entry_point'
        ],
    },
    classifiers=[
        # How mature is this project? Common values are
        #   3 - Alpha
        #   4 - Beta
        #   5 - Production/Stable
        'Development Status :: 5 - Production/Stable',

        # Indicate who your project is intended for
        'Intended Audience :: Developers',
        'Topic :: Software Development :: Build Tools',

        # Pick your license as you wish (should match "license" above)
        'License :: OSI Approved :: GNU Affero General Public License v3',

        # Specify the Python versions you support here. In particular, ensure
        # that you indicate whether you support Python 2, Python 3 or both.
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
    ],
    install_requires=['six', 'ply'],
    tags=['BASIC', 'zxspectrum', 'compiler', 'z80']
)
