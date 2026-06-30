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
# Constantes de arquitectura ZX81 + SD81 Booster
# ---------------------------------------------------------------------------

# Mapa de memoria (flat, ORG $0000):
#   $0000-$00FF   vectors.asm  — vectores RST + relleno hasta $0100
#   $0100-$0FFF   stage 2 bootstrap (prólogo) + rutinas de sistema
#   $1000-$7FFF   runtime ZX BASIC + código del usuario (28 KB)
#   $8000-$80FF   sysvars del runtime
#   $8100-$BFFF   heap + datos del usuario (~15.75 KB)
#   $C000-$D7FF   bitmap pantalla Spectrum (bloque 6, página dedicada)
#   $D800-$DAFF   atributos pantalla
#   $E000-$FFFF   bloque 7 — banking de datos (mapas, sprites...)

_ORG = 0x0000           # el binario comienza en $0000 (vectors.asm lo rellena hasta $0100)
_STAGE2_ENTRY = 0x0100  # punto de entrada del stage 2 bootstrap

_HEAP_ADDR = 0x8100     # heap en zona de datos ($8100-$BFFF)
_HEAP_SIZE = 0x3EFF     # ~15.75 KB

# Páginas SD81 asignadas a cada bloque (las carga el BASIC antes del salto)
#   Página 8  → bloque 0 ($0000-$1FFF) ← el stage 1 solo mapea este
#   Página 9  → bloque 1 ($2000-$3FFF) ┐
#   Página 10 → bloque 2 ($4000-$5FFF) │ el stage 2 (aquí) mapea estos
#   Página 11 → bloque 3 ($6000-$7FFF) │
#   Página 12 → bloque 4 ($8000-$9FFF) │ (datos, no ejecutable sin MC45)
#   Página 13 → bloque 5 ($A000-$BFFF) ┘

_PAGE_MAP = [
    (1, 9),   # bloque 1 → página 9
    (2, 10),  # bloque 2 → página 10
    (3, 11),  # bloque 3 → página 11
    (4, 12),  # bloque 4 → página 12
    (5, 13),  # bloque 5 → página 13
]

_SD81_PAGE_PORT = 0xE7  # puerto mapeador de memoria (modo full: OUT (C), A)
_STACK_TOP = 0x7FFF     # pila al tope de la zona ejecutable


def _map_block(block: int, page: int) -> list[str]:
    """Emite OUT (C), A para mapear una página a un bloque (modo full, 64 pág.)."""
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
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_size", type=int,
                default=_HEAP_SIZE, ignore_none=True)
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_address", type=int,
                default=_HEAP_ADDR, ignore_none=False)
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_start_label", type=str,
                default=f"{NAMESPACE}.ZXBASIC_MEM_HEAP")
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="heap_size_label", type=str,
                default=f"{NAMESPACE}.ZXBASIC_HEAP_SIZE")
        OPTIONS(Action.ADD_IF_NOT_DEFINED, name="headerless", type=bool,
                default=False, ignore_none=True)

        self._QUAD_TABLE.update(
            {
                ICInstruction.END: ICInfo(1, _end),
            }
        )

        engine.main()

    @staticmethod
    def emit_prologue() -> list[str]:
        """
        Prólogo del programa para ZX81 + SD81 Booster.

        Estructura del binario generado (ORG $0000):
          $0000-$00FF  vectors.asm  (vectores RST, incluido desde sysvars.asm)
          $0100        START_LABEL  (entrada del stage 2 bootstrap)
                       - mapeo de bloques 1-5 a sus páginas definitivas
                       - SP = $7FFF
                       - CALL <rutinas #init> (SD81_INIT_SYSVARS, etc.)
                       - JP __MAIN_LABEL__

        El stage 1 bootstrap (externo, en el cargador BASIC a $6000) ya ha:
          - Configurado HFILE=$C000 y activado modo Spectrum (POKE 2045, 172)
          - Desactivado el IO mapeado en memoria (POKE 2056)
          - Desactivado interrupciones (DI)
          - Mapeado bloque 0 → página 8  (JP $0100 ya ejecuta en RAM limpia)
        """
        # -- Definiciones del heap ------------------------------------------
        heap_init = [f"{common.DATA_LABEL}:"]

        if common.REQUIRES.intersection(common.MEMINITS) or f"{NAMESPACE}.__MEM_INIT" in common.INITS:
            heap_init.append(
                "; Defines HEAP SIZE\n"
                + OPTIONS.heap_size_label + " EQU " + str(OPTIONS.heap_size)
            )
            if OPTIONS.heap_address is None:
                heap_init.append(OPTIONS.heap_start_label + ":")
                heap_init.append(f"DEFS {OPTIONS.heap_size}")
            else:
                heap_init.append(
                    "; Defines HEAP ADDRESS\n"
                    + OPTIONS.heap_start_label + f" EQU {OPTIONS.heap_address}"
                )

        heap_init.append(
            "; Defines USER DATA Length in bytes\n"
            + f"{NAMESPACE}.ZXBASIC_USER_DATA_LEN"
            + f" EQU {common.DATA_END_LABEL} - {common.DATA_LABEL}"
        )
        heap_init.append(
            f"{NAMESPACE}.__LABEL__.ZXBASIC_USER_DATA_LEN"
            + f" EQU {NAMESPACE}.ZXBASIC_USER_DATA_LEN"
        )
        heap_init.append(
            f"{NAMESPACE}.__LABEL__.ZXBASIC_USER_DATA EQU {common.DATA_LABEL}"
        )

        # -- Tabla de vectores RST ($0000-$00FF) ----------------------------
        # Debe ser lo primero en el binario. Cada RST ocupa 8 bytes.
        # Usamos org absoluto para cada entrada: el ensamblador rellena los
        # huecos con ceros, lo que es correcto para una zona no ejecutable.
        output = ["org $0000"]
        output.append("jp $0100")      # $0000: reset / RST 0 → stage 2
        output.append("org $0008")
        output.append("di")            # $0008: RST $08 (error handler Spectrum)
        output.append("halt")
        output.append("org $0010")
        output.append("di")            # $0010-$0037: RSTs no usados
        output.append("halt")
        output.append("org $0018")
        output.append("di")
        output.append("halt")
        output.append("org $0020")
        output.append("di")
        output.append("halt")
        output.append("org $0028")
        output.append("di")            # $0028: RST $28 FP calc — nunca con __ZXB_NO_FLOAT
        output.append("halt")
        output.append("org $0030")
        output.append("di")
        output.append("halt")
        output.append("org $0038")
        output.append("di")            # $0038: RST $38 IM1 — DI permanente, nunca llega
        output.append("halt")
        output.append("org $0066")
        output.append("retn")          # $0066: NMI desactivada, pero el vector debe existir

        # -- Stage 2 bootstrap en $0100 ------------------------------------
        output.append(f"org {_STAGE2_ENTRY}")
        output.append(f"{common.START_LABEL}:")

        if OPTIONS.headerless:
            output.extend(heap_init)
            return output

        # Mapeo de bloques 1-5 a sus páginas definitivas.
        # El bloque 0 ya fue mapeado a la página 8 por el stage 1 externo.
        for block, page in _PAGE_MAP:
            output.extend(_map_block(block, page))

        # Pila al tope de la zona ejecutable
        output.append(f"ld   sp, {_STACK_TOP:#06x}")

        # Llamadas a rutinas de inicialización registradas con #init
        # (SD81_INIT_SYSVARS y cualquier otra del runtime incluido)
        output.extend(f"call {label}" for label in sorted(common.INITS))

        # Salto al programa del usuario
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
