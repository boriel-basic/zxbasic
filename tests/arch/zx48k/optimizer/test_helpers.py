# -*- coding: utf-8 -*-

import arch.zx48k.optimizer.helpers as helpers


def test_new_tmp_val():
    """ Test new tmp val is different each time, and starts with the
    UNKNOWN_PREFIX
    """
    a, b = helpers.new_tmp_val(), helpers.new_tmp_val()
    assert a != b, "Values must be different"
    assert all(helpers.RE_UNK_PREFIX.match(x) for x in (a, b)), "Values do not conform the Reg.Exp."


def test_is_unknown():
    assert helpers.is_unknown(None)
    assert not helpers.is_unknown(helpers.UNKNOWN_PREFIX)
    assert not helpers.is_unknown(helpers.UNKNOWN_PREFIX + 'a0')
    assert helpers.is_unknown(helpers.UNKNOWN_PREFIX + '0')
    assert helpers.is_unknown('{0}000|{0}001'.format(helpers.UNKNOWN_PREFIX))
