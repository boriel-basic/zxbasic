# -*- coding: utf-8 -*-

import unittest
from arch.zx48k.optimizer import basicblock


class TestBasicBlock(unittest.TestCase):
    """ Tests basic blocks implementation
    """
    def setUp(self):
        self.blk = basicblock.BasicBlock([])

    def test_block_partition_jp(self):
        code = """
        nop
        jp __UNKNOWN
        nop
        """
        self.blk.code = [x for x in code.split('\n') if x.strip()]
        blks = basicblock.get_basic_blocks(self.blk)
        self.assertEqual(len(blks), 2)
        self.assertEqual(blks[0].code, ['nop', 'jp __UNKNOWN'])
        self.assertEqual(blks[1].code, ['nop'])
        self.assertFalse(blks[1] in blks[0].goes_to)
        self.assertFalse(blks[0] in blks[1].comes_from)

    def test_block_partition_call(self):
        code = """
        nop
        call __UNKNOWN
        nop
        """
        self.blk.code = [x for x in code.split('\n') if x.strip()]
        blks = basicblock.get_basic_blocks(self.blk)
        self.assertEqual(len(blks), 2)
        self.assertEqual(blks[0].code, ['nop', 'call __UNKNOWN'])
        self.assertEqual(blks[1].code, ['nop'])
        self.assertFalse(blks[1] in blks[0].goes_to)
        self.assertFalse(blks[0] in blks[1].comes_from)

    def test_block_partition_jp_flag(self):
        code = """
        nop
        jp z, __UNKNOWN
        nop
        """
        self.blk.code = [x for x in code.split('\n') if x.strip()]
        blks = basicblock.get_basic_blocks(self.blk)
        self.assertEqual(len(blks), 2)
        self.assertEqual(blks[0].code, ['nop', 'jp z, __UNKNOWN'])
        self.assertEqual(blks[1].code, ['nop'])
        self.assertTrue(blks[1] in blks[0].goes_to)
        self.assertTrue(blks[0] in blks[1].comes_from)

    def test_block_partition_call_flag(self):
        code = """
        nop
        call z, __UNKNOWN
        nop
        """
        self.blk.code = [x for x in code.split('\n') if x.strip()]
        blks = basicblock.get_basic_blocks(self.blk)
        self.assertEqual(len(blks), 2)
        self.assertEqual(blks[0].code, ['nop', 'call z, __UNKNOWN'])
        self.assertEqual(blks[1].code, ['nop'])
        self.assertTrue(blks[1] in blks[0].goes_to)
        self.assertTrue(blks[0] in blks[1].comes_from)
