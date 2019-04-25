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


def test_HL_unknowns():
    val = helpers.new_tmp_val16()
    assert helpers.is_unknown(val)
    assert len(val.split('|')) == 2
    assert all(helpers.is_unknown(x) for x in val.split('|'))
    assert helpers.is_unknown(helpers.get_H_from_unknown_value(val))
    assert helpers.is_unknown(helpers.get_L_from_unknown_value(val))

    a, b = val.split('|')
    assert a == helpers.get_H_from_unknown_value(val)
    assert b == helpers.get_L_from_unknown_value(val)

