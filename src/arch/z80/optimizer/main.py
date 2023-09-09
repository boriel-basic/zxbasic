from collections import defaultdict
from typing import Type

from src.api.config import OPTIONS
from src.api.debug import __DEBUG__
from src.api.utils import flatten_list
from src.arch.interface.optimizer import OptimizerInterface
from src.arch.z80.peephole import engine

from . import helpers
from .basicblock import BasicBlock, DummyBasicBlock
from .flow_graph import get_basic_blocks
from .helpers import ALL_REGS, END_PROGRAM_LABEL
from .labelinfo import LabelInfo
from .labels_dict import LabelsDict
from .memcell import MemCell
from .patterns import RE_LABEL, RE_PRAGMA

__all__ = ("Optimizer",)


class Optimizer(OptimizerInterface):
    """Implements the Peephole Optimizer"""

    PROC_COUNTER: int = 0  # PROC labels name space counter
    LABELS: LabelsDict = LabelsDict()  # Label -> LabelInfo object
    RAND_COUNT: int = 0

    # Labels which must start a basic block, because they're used in a JP/CALL
    JUMP_LABELS: set[str] = set()

    MEMORY: list[MemCell] = []  # Instructions emitted by the backend
    BLOCKS: list[BasicBlock] = []  # Memory blocks

    _BASICBLOCK_TYPE: Type[BasicBlock] = BasicBlock

    def __init__(self) -> None:
        self.init()

    def init(self) -> None:
        helpers.init()

        self.JUMP_LABELS = set()
        self.RAND_COUNT = 0
        self.MEMORY = []
        self.BLOCKS = []
        self.PROC_COUNTER = 0

        self.LABELS = LabelsDict(
            {
                "*START*": LabelInfo("*START*", 0, DummyBasicBlock(ALL_REGS, ALL_REGS, self)),  # Special START BLOCK
                "*__END_PROGRAM*": LabelInfo("__END_PROGRAM", 0, DummyBasicBlock(ALL_REGS, list("bc"), self)),
                # SOME Global modules initialization
                "__ADDF": LabelInfo("__ADDF", 0, DummyBasicBlock(ALL_REGS, list("aedbc"), self)),
                "__SUBF": LabelInfo("__SUBF", 0, DummyBasicBlock(ALL_REGS, list("aedbc"), self)),
                "__DIVF": LabelInfo("__DIVF", 0, DummyBasicBlock(ALL_REGS, list("aedbc"), self)),
                "__MULF": LabelInfo("__MULF", 0, DummyBasicBlock(ALL_REGS, list("aedbc"), self)),
                "__GEF": LabelInfo("__GEF", 0, DummyBasicBlock(ALL_REGS, list("aedbc"), self)),
                "__GTF": LabelInfo("__GTF", 0, DummyBasicBlock(ALL_REGS, list("aedbc"), self)),
                "__EQF": LabelInfo("__EQF", 0, DummyBasicBlock(ALL_REGS, list("aedbc"), self)),
                "__STOREF": LabelInfo("__STOREF", 0, DummyBasicBlock(ALL_REGS, list("hlaedbc"), self)),
                "PRINT_AT": LabelInfo("PRINT_AT", 0, DummyBasicBlock(ALL_REGS, list("a"), self)),
                "INK": LabelInfo("INK", 0, DummyBasicBlock(ALL_REGS, list("a"), self)),
                "INK_TMP": LabelInfo("INK_TMP", 0, DummyBasicBlock(ALL_REGS, list("a"), self)),
                "PAPER": LabelInfo("PAPER", 0, DummyBasicBlock(ALL_REGS, list("a"), self)),
                "PAPER_TMP": LabelInfo("PAPER_TMP", 0, DummyBasicBlock(ALL_REGS, list("a"), self)),
                "RND": LabelInfo("RND", 0, DummyBasicBlock(ALL_REGS, [], self)),
                "INKEY": LabelInfo("INKEY", 0, DummyBasicBlock(ALL_REGS, [], self)),
                "PLOT": LabelInfo("PLOT", 0, DummyBasicBlock(ALL_REGS, ["a"], self)),
                "DRAW": LabelInfo("DRAW", 0, DummyBasicBlock(ALL_REGS, ["h", "l"], self)),
                "DRAW3": LabelInfo("DRAW3", 0, DummyBasicBlock(ALL_REGS, list("abcde"), self)),
                "__ARRAY": LabelInfo("__ARRAY", 0, DummyBasicBlock(ALL_REGS, ["h", "l"], self)),
                "__MEMCPY": LabelInfo("__MEMCPY", 0, DummyBasicBlock(list("bcdefhl"), list("bcdehl"), self)),
                "__PLOADF": LabelInfo("__PLOADF", 0, DummyBasicBlock(ALL_REGS, ALL_REGS, self)),
                "__PSTOREF": LabelInfo("__PSTOREF", 0, DummyBasicBlock(ALL_REGS, ALL_REGS, self)),
            }
        )

    @staticmethod
    def _cleanup_mem(initial_memory: list[str]) -> None:
        """Cleans up initial memory. Each label must be
        ALONE. Each instruction must have an space, etc...
        """
        i = 0
        while i < len(initial_memory):
            tmp = initial_memory[i]
            match = RE_LABEL.match(tmp)

            if match and tmp.rstrip() != match.group():
                initial_memory[i] = tmp[match.end() :].strip()
                initial_memory.insert(i, match.group()[:-1].strip() + ":")

            i += 1

    def cleanup_local_labels(self, block: BasicBlock) -> None:
        """Traverses memory, to make any local label a unique
        global one. At this point there's only a single code
        block
        """
        stack: list[list[str]] = [[]]
        hashes: list[dict[str, str]] = [{}]
        stackprc: list[int] = [self.PROC_COUNTER]
        used: list[dict[str, list[MemCell]]] = [defaultdict(list)]  # List of hashes of unresolved labels per scope

        self.MEMORY[:] = block.mem[:]

        for cell in self.MEMORY:
            if cell.inst.upper() == "PROC":
                stack.append([])
                hashes.append({})
                stackprc.append(self.PROC_COUNTER)
                used.append(defaultdict(list))
                self.PROC_COUNTER += 1
                continue

            if cell.inst.upper() == "ENDP":
                if len(stack) > 1:  # There might be unbalanced stack due to syntax errors
                    for label in used[-1].keys():
                        if label in stack[-1]:
                            newlabel = hashes[-1][label]
                            for cell in used[-1][label]:
                                cell.replace_label(label, newlabel)

                    stack.pop()
                    hashes.pop()
                    stackprc.pop()
                    used.pop()
                continue

            tmp = cell.asm.asm
            if tmp.upper().startswith("LOCAL"):
                tmp = tmp[5:].split(",")
                for lbl in tmp:
                    lbl = lbl.strip()
                    if lbl in stack[-1]:
                        continue

                    stack[-1].append(lbl)
                    hashes[-1][lbl] = f"PROC{stackprc[-1]}.{lbl}"

                cell.asm = f";{str(cell.asm)}"  # Remove it
                continue

            if cell.is_label:
                label = cell.inst
                for i in range(len(stack) - 1, -1, -1):
                    if label in stack[i]:
                        label = hashes[i][label]
                        cell.asm = f"{label}:"
                        break
                continue

            for label in cell.used_labels:
                labelUsed = False
                for i in range(len(stack) - 1, -1, -1):
                    if label in stack[i]:
                        newlabel = hashes[i][label]
                        cell.replace_label(label, newlabel)
                        labelUsed = True
                        break

                if not labelUsed:
                    used[-1][label].append(cell)

        for i in range(len(self.MEMORY) - 1, -1, -1):
            if self.MEMORY[i].asm.asm[0] == ";":
                self.MEMORY.pop(i)

        block.mem = self.MEMORY
        block.asm = [x.asm for x in self.MEMORY if len(x.asm)]

    def get_labels(self, basic_block: BasicBlock) -> None:
        """Traverses memory, to annotate all the labels in the global
        LABELS table
        """
        for i, cell in enumerate(basic_block):
            if cell.is_label:
                label = cell.inst
                self.LABELS[label] = LabelInfo(label, cell.addr, basic_block, i)  # Stores it globally

    def initialize_memory(self, basic_block: BasicBlock) -> None:
        """Initializes global memory array with the one in the main (initial) basic_block"""
        self.init()
        self.MEMORY[:] = basic_block.mem[:]
        self.get_labels(basic_block)

    def optimize(self, initial_memory: list[str]) -> str:
        """This will remove useless instructions"""
        self.MEMORY.clear()
        self.PROC_COUNTER = 0

        self._cleanup_mem(initial_memory)
        if OPTIONS.optimization_level <= 2:  # if -O2 or lower, do nothing and return
            return "\n".join(x for x in initial_memory if not RE_PRAGMA.match(x))

        self._BASICBLOCK_TYPE.clean_asm_args = OPTIONS.optimization_level > 3
        bb = self._BASICBLOCK_TYPE(initial_memory, self)
        self.cleanup_local_labels(bb)
        self.initialize_memory(bb)

        # 1st partition the Basic Blocks
        self.BLOCKS = basic_blocks = get_basic_blocks(bb)

        for b in basic_blocks:
            __DEBUG__("--- BASIC BLOCK: {} ---".format(b.id), 1)
            __DEBUG__("Code:\n" + "\n".join("    {}".format(x) for x in b.code), 1)
            __DEBUG__("Requires: {}".format(b.requires()), 1)
            __DEBUG__("Destroys: {}".format(b.destroys()), 1)
            __DEBUG__("Comes from: {}".format([x.id for x in b.comes_from]), 1)
            __DEBUG__("Goes to: {}".format([x.id for x in b.goes_to]), 1)
            __DEBUG__("Next: {}".format(b.next.id if b.next is not None else None), 1)
            __DEBUG__("Size: {}  Time: {}".format(b.sizeof, b.max_tstates), 1)
            __DEBUG__("--- END ---", 1)

        self.LABELS["*START*"].basic_block.add_goes_to(basic_blocks[0])
        self.LABELS["*START*"].basic_block.next = basic_blocks[0]

        basic_blocks[0].prev = self.LABELS["*START*"].basic_block
        if END_PROGRAM_LABEL in self.LABELS:
            self.LABELS[END_PROGRAM_LABEL].basic_block.add_goes_to(self.LABELS["*__END_PROGRAM*"].basic_block)

        # In O3 we simplify the graph by reducing jumps over jumps
        for label in self.JUMP_LABELS:
            block = self.LABELS[label].basic_block
            if isinstance(block, DummyBasicBlock):
                continue

            # The instruction that starts this block must be one of jr / jp
            first = block.get_next_exec_instruction()
            if first is None or first.inst not in ("jp", "jr"):
                continue

            for blk in list(self.LABELS[label].used_by):
                if not first.condition_flag or blk[-1].condition_flag == first.condition_flag:
                    new_label = first.opers[0]
                    blk[-1].asm = blk[-1].code.replace(label, new_label)
                    block.delete_comes_from(blk)
                    self.LABELS[label].used_by.remove(blk)
                    self.LABELS[new_label].used_by.add(blk)
                    blk.add_goes_to(self.LABELS[new_label].basic_block)

        for x in basic_blocks:
            x.compute_cpu_state()

        filtered_patterns_list = [p for p in engine.PATTERNS if OPTIONS.optimization_level >= p.level >= 3]
        for x in basic_blocks:
            x.optimize(filtered_patterns_list)

        for x in basic_blocks:
            if x.comes_from == [] and len([y for y in self.JUMP_LABELS if x is self.LABELS[y].basic_block]):
                x.ignored = True

        return "\n".join(
            y for y in flatten_list(x.code for x in basic_blocks if not x.ignored) if not RE_PRAGMA.match(y)
        )
