from src.api.config import OPTIONS
from src.api.options import Action
from src.arch.z80.backend import Backend as Z80Backend
from src.arch.z80.backend import ICInfo, common
from src.arch.z80.backend.icinstruction import ICInstruction
from src.arch.z80.backend.runtime import NAMESPACE
from src.arch.z80.peephole import engine
from src.arch.zxnext.peephole import OPTS_PATH

from ._8bit import Bits8
from .generic import _end


class Backend(Z80Backend):
    def init(self):
        # ZXNext asm enabled by default for this arch
        super().init()
        OPTIONS.zxnext = True
        """Initializes this module"""

        # Overrides z80 generic implementation with ZX Next ones
        self._QUAD_TABLE.update(
            {
                ICInstruction.MULI8: ICInfo(3, Bits8.mul8),
                ICInstruction.MULU8: ICInfo(3, Bits8.mul8),
                ICInstruction.END: ICInfo(1, _end),
            }
        )

        # Default code ORG
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="org", type=int, default=32768)
        # Default HEAP SIZE (Dynamic memory) in bytes
        OPTIONS(
            Action.ADD_IF_NOT_DEFINED, name="heap_size", type=int, default=4768, ignore_none=True
        )  # A bit more than 4K
        # Default HEAP ADDRESS (Dynamic memory) address
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_address", type=int, default=None, ignore_none=False)
        # Labels for HEAP START (might not be used if not needed)
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_start_label", type=str, default=f"{NAMESPACE}.ZXBASIC_MEM_HEAP")
        # Labels for HEAP SIZE (might not be used if not needed)
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_size_label", type=str, default=f"{NAMESPACE}.ZXBASIC_HEAP_SIZE")
        # Flag for headerless mode (No prologue / epilogue)
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="headerless", type=bool, default=False, ignore_none=True)

        engine.main([engine.OPTS_PATH, OPTS_PATH], force=True)  # inits the optimizer

    @staticmethod
    def emit_prologue() -> list[str]:
        """Program Start routine for ZX Next arch"""
        heap_init = [f"{common.DATA_LABEL}:"]
        output = [f"org {OPTIONS.org}"]

        if common.REQUIRES.intersection(common.MEMINITS) or f"{NAMESPACE}.__MEM_INIT" in common.INITS:
            heap_init.append("; Defines HEAP SIZE\n" + OPTIONS.heap_size_label + " EQU " + str(OPTIONS.heap_size))
            if OPTIONS.heap_address is None:
                heap_init.append(OPTIONS.heap_start_label + ":")
                heap_init.append("DEFS %s" % str(OPTIONS.heap_size))
            else:
                heap_init.append(
                    "; Defines HEAP ADDRESS\n" + OPTIONS.heap_start_label + " EQU %s" % OPTIONS.heap_address
                )

        heap_init.append(
            "; Defines USER DATA Length in bytes\n"
            + f"{NAMESPACE}.ZXBASIC_USER_DATA_LEN EQU {common.DATA_END_LABEL} - {common.DATA_LABEL}"
        )
        heap_init.append(f"{NAMESPACE}.__LABEL__.ZXBASIC_USER_DATA_LEN EQU {NAMESPACE}.ZXBASIC_USER_DATA_LEN")
        heap_init.append(f"{NAMESPACE}.__LABEL__.ZXBASIC_USER_DATA EQU {common.DATA_LABEL}")

        output.append("%s:" % common.START_LABEL)
        if OPTIONS.headerless:
            output.extend(heap_init)
            return output

        output.append("di")
        output.append("push iy")
        output.append("ld iy, 0x5C3A  ; ZX Spectrum ROM variables address")
        output.append("ld hl, 0")
        output.append("add hl, sp")
        output.append(f"ld ({common.CALL_BACK}), hl")
        output.append("ei")

        output.extend(f"call {x}" for x in sorted(common.INITS))

        output.append(f"jp {common.MAIN_LABEL}")
        output.append(f"{common.CALL_BACK}:")
        output.append("DEFW 0")
        output.extend(heap_init)

        return output
