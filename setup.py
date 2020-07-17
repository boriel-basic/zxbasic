# -*- coding: utf-8 -*-
from setuptools import setup

packages = [
    'api',
    'arch',
    'arch.zx48k',
    'arch.zx48k.backend',
    'arch.zx48k.optimizer',
    'arch.zx48k.peephole',
    'ast_',
    'libzxbasm',
    'libzxbc',
    'libzxbpp',
    'libzxbpp.prepro',
    'outfmt',
    'parsetab',
    'ply',
    'symbols'
]

package_data = {'': ['*'], 'arch.zx48k.peephole': ['opts/*']}

entry_points = {
    'console_scripts': ['zxb = libzxbc.zxb:main',
                        'zxbasm = libzxbasm.zxbasm:main',
                        'zxbc = libzxbc.zxb:main',
                        'zxbpp = libzxbpp.zxbpp:entry_point']
}

setup_kwargs = {
    'name': 'zxbasic',
    'version': '1.11.1',
    'description': "Boriel's ZX BASIC Compiler",
    'long_description': None,
    'author': 'Jose Rodriguez',
    'author_email': 'boriel@gmail.com',
    'maintainer': None,
    'maintainer_email': None,
    'url': 'https://github.com/boriel/zxbasic',
    'packages': packages,
    'package_data': package_data,
    'entry_points': entry_points,
    'python_requires': '>=3.6,<4.0',
}

setup(**setup_kwargs)
