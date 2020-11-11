# -*- coding: utf-8 -*-

import src.arch.zx48k.optimizer.helpers as helpers


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


def test_is_unknown16():
    assert helpers.is_unknown16(None)
    assert not helpers.is_unknown16(helpers.new_tmp_val())
    assert helpers.is_unknown16(helpers.new_tmp_val16())


def test_is_unknown16_half():
    a = '{}|3'.format(helpers.new_tmp_val())
    assert helpers.is_unknown16(a)


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


def test_L16_val():
    """ Test low value of an integer or unknown val is ok
    """
    # For an unknown 8 bit val, the high part is always 0
    assert helpers.is_unknown8(helpers.LO16_val(None))
    tmp8 = helpers.new_tmp_val()
    lo16 = helpers.LO16_val(tmp8)
    assert lo16 == tmp8

    # For integers, it's just the high part
    assert helpers.LO16_val('255') == '255'
    assert helpers.LO16_val('256') == '0'

    # For normal unknowns16, the high part must be returned
    tmp16 = helpers.new_tmp_val16()
    assert helpers.LO16_val(tmp16) == tmp16.split(helpers.HL_SEP)[1]
    assert helpers.is_unknown8(helpers.LO16_val(tmp16))
    assert helpers.is_unknown8(helpers.LO16_val('_unknown'))  # An unknown expression


def test_H16_val():
    """ Test high value of an integer or unknown val is ok
    """
    # For an unknown 8 bit val, the high part is always 0
    assert helpers.is_unknown8(helpers.HI16_val(None))
    tmp8 = helpers.new_tmp_val()
    hi16 = helpers.HI16_val(tmp8)
    assert hi16 == '0'

    # For integers, it's just the high part
    assert helpers.HI16_val('255') == '0'
    assert helpers.HI16_val('256') == '1'

    # For normal unknowns16, the high part must be returned
    tmp16 = helpers.new_tmp_val16()
    assert helpers.HI16_val(tmp16) == tmp16.split(helpers.HL_SEP)[0]
    assert helpers.is_unknown8(helpers.HI16_val(tmp16))
    assert helpers.is_unknown8(helpers.HI16_val('_unknown'))  # An unknown expression


def test_dict_intersection():
    """ Test dict intersection works ok
    """
    assert not helpers.dict_intersection({}, {'a': 1})
    assert helpers.dict_intersection({'a': 1}, {'c': 1, 1: 2, 'a': 1}) == {'a': 1}
    assert not helpers.dict_intersection({'a': 1}, {'c': 1, 1: 2, 'a': 2})


def test_single_registers():
    """ Flags also for f must be passed
    """
    assert helpers.single_registers('af') == ['a', 'f']
    assert helpers.single_registers(['f', 'sp']) == ['f', 'sp']
