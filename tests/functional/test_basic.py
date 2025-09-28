# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# Licensed under the GNU Affero General Public License v3.0 or later.
# Author: Jose M. Rodriguez-Rosa (a.k.a. Boriel) - https://boriel.com
# See https://www.gnu.org/licenses/agpl-3.0.html for details.
# --------------------------------------------------------------------

import glob
import os
import sys

import pytest
import test

TEST_PATH = os.path.dirname(os.path.realpath(__file__))


@pytest.mark.parametrize(
    "fname",
    reversed([os.path.join(TEST_PATH, f) for f in glob.glob(os.path.join(TEST_PATH, "**", "*.bas"), recursive=True)]),
)
@pytest.mark.xdist_group(name="test_basic")
def test_basic(fname):
    test.main(["-d", fname])
    if test.COUNTER == 0:
        return
    sys.stderr.write(
        "Total: %i, Failed: %i (%3.2f%%)\n" % (test.COUNTER, test.FAILED, 100.0 * test.FAILED / float(test.COUNTER))
    )

    assert test.EXIT_CODE == 0, "BASIC program test failed"
