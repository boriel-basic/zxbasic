TESTING
-------

This instructions are for TDD (Test Drive Development) the compiler and are intended
for developing the compiler internals, and checks for bugs in it.

You **DONT** need to do this to compile BASIC.

You are required to be familiar not only with python, but also with the python 
ecosystem (virtualenvs, tox, py.test).

You will need to get Tox in order to run the project tests. Normally it is done
by calling:

~~~~
$ pip install tox
~~~~

Inside a Virtual Environment of your choice ( https://virtualenv.pypa.io/en/stable/ ).

Please, see https://tox.readthedocs.io/en/latest/install.html for more
information about installing Tox.

Once you have installed Tox, just call:

~~~~
$ tox
~~~~

to get your tests running.

This tox config also supports detox (parallel tox testing).