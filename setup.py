# -*- coding: utf-8 -*-
import pathlib
from setuptools import setup

packages = [
    'src'
]

# The directory containing this file
HERE = pathlib.Path(__file__).parent

# The text of the README file
README = (HERE / "README.md").read_text()

package_data = {'': ['*'], 'arch.zx48k.peephole': ['opts/*']}

entry_points = {
    'console_scripts': ['zxb = src.libzxbc.zxb:main',
                        'zxbasm = src.libzxbasm.zxbasm:main',
                        'zxbc = src.libzxbc.zxb:main',
                        'zxbpp = src.libzxbpp.zxbpp:entry_point']
}

setup_kwargs = {
    'name': 'zxbasic',
    'version': '1.13.2',
    'description': "Boriel's ZX BASIC Compiler",
    'classifiers': [
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
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.8',
    ],
    'long_description_content_type': "text/markdown",
    'long_description': README,
    'author': 'Jose Rodriguez',
    'author_email': 'boriel@gmail.com',
    'maintainer': None,
    'maintainer_email': None,
    'url': 'http://zxbasic.net',
    'packages': packages,
    'package_data': package_data,
    'entry_points': entry_points,
    'python_requires': '>=3.6,<4.0',
}

setup(**setup_kwargs)
