; arch_config.asm — Constantes de arquitectura ZX81 + SD81 Booster
;
; Sobreescribe zx48k/runtime/arch_config.asm para redirigir las
; llamadas ROM del runtime hacia implementaciones propias en RAM.

; ---------------------------------------------------------------------------
; Usar scroll por buffer propio (sin ROM Spectrum)
; ---------------------------------------------------------------------------
#define __ZXB_ENABLE_BUFFER_SCROLL

; ---------------------------------------------------------------------------
; Sin soporte de coma flotante en esta versión
; (el FP calculator de la ROM Spectrum no está disponible)
; ---------------------------------------------------------------------------
#define __ZXB_NO_FLOAT

; ---------------------------------------------------------------------------
; Gráficos — implementaciones propias
; ---------------------------------------------------------------------------
; Incluir aquí los ficheros con las rutinas que sustituyen a las ROM calls.
; El resto del runtime (plot.asm, draw.asm...) incluye arch_config.asm,
; por lo que estas definiciones quedan disponibles automáticamente.

#include once <pixel_addr.asm>
#include once <po_gr_1.asm>

; Nota: SCROLL_SCR, KEY_SCAN, KEY_TEST, KEY_CODE, LD_BYTES, ROM_SAVE, etc.
; deberán implementarse cuando se necesiten. Los dejamos sin definir
; para que el enlazador falle con un error claro si se usan accidentalmente.
