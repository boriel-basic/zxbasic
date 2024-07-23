from src.arch.interface.quad import Quad as BaseQuad

from .icinstruction import ICInstruction


class Quad(BaseQuad):
    def __init__(self, instr: ICInstruction, *args):
        ICInstruction.check(instr)
        super().__init__(instr, *args)
