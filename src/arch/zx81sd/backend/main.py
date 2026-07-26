# --------------------------------------------------------------------
# SPDX-License-Identifier: AGPL-3.0-or-later
# ZX81 + SD81 Booster backend — program prologue / epilogue
# --------------------------------------------------------------------

from src.api.config import OPTIONS
from src.api.options import Action
from src.arch.z80.backend import Backend as Z80Backend
from src.arch.z80.backend import ICInfo, common
from src.arch.z80.backend.icinstruction import ICInstruction
from src.arch.z80.backend.runtime import NAMESPACE
from src.arch.z80.peephole import engine

from .generic import _end

# ---------------------------------------------------------------------------
# ZX81 + SD81 Booster architecture constants
# ---------------------------------------------------------------------------

# Memory map (flat, ORG $0000):
#   $0000-$00FF   RST vector table, emitted directly below (emit_prologue)
#                 + padding up to $0100
#   $0100-$0FFF   stage 2 bootstrap (prologue) + system routines
#   $1000-$7FFF   ZX BASIC runtime + user code (28 KB)
#   $8000-$80FF   runtime sysvars
#   $8100-$BFFF   heap + user data (~15.75 KB)
#   $C000-$D7FF   Spectrum screen bitmap (block 6, dedicated page)
#   $D800-$DAFF   screen attributes
#   $E000-$FFFF   block 7 — data banking (maps, sprites...)

_ORG = 0x0000  # the binary starts at $0000 (RST vectors pad up to $0100)
_STAGE2_ENTRY = 0x0100  # stage 2 bootstrap's entry point

_HEAP_ADDR = 0x8100  # heap in the data area ($8100-$BFFF)
_HEAP_SIZE = 0x3EFF  # ~15.75 KB

# SD81 pages assigned to each block (loaded by BASIC before the jump)
#   Page 8  -> block 0 ($0000-$1FFF) <- stage 1 only maps this one
#   Page 9  -> block 1 ($2000-$3FFF) ┐
#   Page 10 -> block 2 ($4000-$5FFF) │ stage 2 (here) maps these
#   Page 11 -> block 3 ($6000-$7FFF) │
#   Page 12 -> block 4 ($8000-$9FFF) │ (data, not executable without MC45)
#   Page 13 -> block 5 ($A000-$BFFF) ┘

_PAGE_MAP = [
    (1, 9),  # block 1 -> page 9
    (2, 10),  # block 2 -> page 10
    (3, 11),  # block 3 -> page 11
    (4, 12),  # block 4 -> page 12
    (5, 13),  # block 5 -> page 13
    (7, 15),  # block 7 -> page 15 (data banking: large static tables via explicit ORG)
]

_SD81_PAGE_PORT = 0xE7  # memory mapper port (full mode: OUT (C), A)
_STACK_TOP = 0x7FFF  # stack at the top of the executable area


def _map_block(block: int, page: int) -> list[str]:
    """Emits OUT (C), A to map a page to a block (full mode, 64 pages)."""
    return [
        f"ld   b, {page}",
        f"ld   a, {block}",
        f"ld   c, {_SD81_PAGE_PORT:#04x}",
        "out  (c), a",
    ]


class Backend(Z80Backend):
    def init(self):
        super().init()

        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="org", type=int, default=_ORG)

        # The generic Z80 backend (super().init(), right above) already
        # registers "heap_size" (4768) and "heap_address" (None) with
        # ADD_IF_NOT_DEFINED, so an ADD_IF_NOT_DEFINED here would be a
        # no-op and the heap would end up reserved inline (DEFS) with
        # 4768 bytes inside the executable area. Assigned directly so
        # the heap lives in the data area $8100-$BFFF; the CLI's
        # --heap-address/-H flags are applied afterward and can still
        # override these values.
        OPTIONS.heap_size = _HEAP_SIZE
        OPTIONS.heap_address = _HEAP_ADDR

        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_start_label", type=str, default=f"{NAMESPACE}.ZXBASIC_MEM_HEAP")
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_size_label", type=str, default=f"{NAMESPACE}.ZXBASIC_HEAP_SIZE")
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="headerless", type=bool, default=False, ignore_none=True)

        self._QUAD_TABLE.update(
            {
                ICInstruction.END: ICInfo(1, _end),
            }
        )

        engine.main()

    @staticmethod
    def emit_prologue() -> list[str]:
        """
        Program prologue for ZX81 + SD81 Booster.

        Structure of the generated binary (ORG $0000):
          $0000-$00FF  RST vector table (emitted directly below)
          $0100        START_LABEL  (stage 2 bootstrap's entry point)
                       - mapping blocks 1-5 to their final pages
                       - SP = $7FFF
                       - CALL <#init routines> (SD81_INIT_SYSVARS, etc.)
                       - JP __MAIN_LABEL__

        The (external) stage 1 bootstrap, in the BASIC loader at $6000,
        has already:
          - Set HFILE=$C000 and activated Spectrum mode (POKE 2045, 172)
          - Disabled memory-mapped IO (POKE 2056)
          - Disabled interrupts (DI)
          - Mapped block 0 -> page 8  (JP $0100 now runs on clean RAM)
        """
        # -- Heap definitions ------------------------------------------
        heap_init = [f"{common.DATA_LABEL}:"]

        if common.REQUIRES.intersection(common.MEMINITS) or f"{NAMESPACE}.__MEM_INIT" in common.INITS:
            heap_init.append("; Defines HEAP SIZE\n" + OPTIONS.heap_size_label + " EQU " + str(OPTIONS.heap_size))
            if OPTIONS.heap_address is None:
                heap_init.append(OPTIONS.heap_start_label + ":")
                heap_init.append(f"DEFS {OPTIONS.heap_size}")
            else:
                heap_init.append("; Defines HEAP ADDRESS\n" + OPTIONS.heap_start_label + f" EQU {OPTIONS.heap_address}")

        heap_init.append(
            "; Defines USER DATA Length in bytes\n"
            + f"{NAMESPACE}.ZXBASIC_USER_DATA_LEN"
            + f" EQU {common.DATA_END_LABEL} - {common.DATA_LABEL}"
        )
        heap_init.append(f"{NAMESPACE}.__LABEL__.ZXBASIC_USER_DATA_LEN" + f" EQU {NAMESPACE}.ZXBASIC_USER_DATA_LEN")
        heap_init.append(f"{NAMESPACE}.__LABEL__.ZXBASIC_USER_DATA EQU {common.DATA_LABEL}")

        # -- RST vector table ($0000-$00FF) ---------------------------------
        # Must be the very first thing in the binary. Each RST takes 8 bytes.
        # An absolute org is used for every entry: the assembler fills the
        # gaps with zeros, which is correct for a non-executable area.
        output = ["org $0000"]
        output.append("jp $0100")  # $0000: reset / RST 0 -> stage 2
        output.append("org $0008")
        output.append("di")  # $0008: RST $08 (Spectrum error handler)
        output.append("halt")
        output.append("org $0010")
        output.append("di")  # $0010-$0037: unused RSTs
        output.append("halt")
        output.append("org $0018")
        output.append("di")
        output.append("halt")
        output.append("org $0020")
        output.append("di")
        output.append("halt")
        output.append("org $0028")
        output.append("jp .core.FP_CALC_ENTRY")  # $0028: RST $28 -> our own FP calculator
        output.append("org $0030")
        output.append("di")
        output.append("halt")
        output.append("org $0038")
        # $0038: RST $38 (IM1 interrupt). Interrupts stay disabled for the
        # whole program, so this should never really be reached; if
        # something did reactivate them, behave like a real Z80 HALT
        # instead of hanging forever (di+halt): wait for the next VSYNC
        # pulse (port $AF, bits 6-1 = pulse counter, reset on read) and
        # return, resuming right after the RST $38 that got us here.
        # AF must be preserved: ported code that executes EI (Spectrum
        # habit) makes stray ZX81 INTs land here mid-computation, and
        # clobbering A/F corrupted arithmetic at random (see MAP.md,
        # oilpanic sprite(13,2) bug).
        output.append("push af")
        output.append(".core.__RST38_WAIT:")
        output.append("in   a, ($AF)")
        output.append("and  $7E")
        output.append("jr   z, .core.__RST38_WAIT")
        output.append("pop  af")
        output.append("ret")
        output.append("org $0066")
        output.append("retn")  # $0066: NMI disabled, but the vector must exist

        # -- Stage 2 bootstrap at $0100 ------------------------------------
        output.append(f"org {_STAGE2_ENTRY}")
        output.append(f"{common.START_LABEL}:")

        if OPTIONS.headerless:
            output.extend(heap_init)
            return output

        # Mapping blocks 1-5 to their final pages.
        # Block 0 was already mapped to page 8 by the external stage 1.
        for block, page in _PAGE_MAP:
            output.extend(_map_block(block, page))

        # Stack at the top of the executable area
        output.append(f"ld   sp, {_STACK_TOP:#06x}")

        # Calls to initialization routines registered with #init
        # (SD81_INIT_SYSVARS and any other one from the included runtime)
        output.extend(f"call {label}" for label in sorted(common.INITS))

        # Jump to the user's program
        output.append(f"jp   {common.MAIN_LABEL}")

        output.extend(heap_init)
        return output

    @staticmethod
    def emit_epilogue() -> list[str]:
        output = list(common.AT_END)
        if OPTIONS.autorun:
            output.append(f"END {common.START_LABEL}")
        else:
            output.append("END")
        return output
