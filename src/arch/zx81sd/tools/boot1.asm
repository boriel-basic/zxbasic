; ===========================================================================
; bootstrap_stage1.asm — Stage 1 Bootstrap ZX81 + SD81 Booster
;
; Resides at $6000 (block 3). The BASIC loader sends it there before
; anything else because it's a neutral area: the ZX81's BASIC doesn't
; need it, and no block has been remapped yet.
;
; Startup sequence (see ZX81-SD81-Adaptation-Plan.md):
;   1. DI  — disable interrupts (ZX81 FAST mode already does this, but
;             it's repeated as a precaution before touching paging)
;   2. Activate Superfast HiRes Spectrum mode via the FPGA (POKE 2045 = $07FD)
;   3. Activate Chroma81 colour mode (port $7FEF) -- required separately
;      from step 2 on real hardware, see note below
;   4. Disable memory-mapped IO     (POKE 2056 = $0808)
;   5. Map block 0 -> page 8 (OUT ($E7), page=8, block=0)
;      Stage 2 ($0100-$0FFF on page 8) is now ready to run.
;   6. JP $0100  — jumps to stage 2 in the freshly mapped RAM
;
; Notes:
;   - HFILE=$C000 is the FPGA's default value when activating mode 172.
;     If your hardware requires setting it explicitly, uncomment the
;     HFILE block at the end.
;   - Chroma81 colour (step 3): activating Spectrum mode (step 2) does
;     NOT turn color on by itself on real hardware -- confirmed on a
;     real SD81 Booster (2026-07-05); the EightyOne emulator shows
;     color regardless of this step, which is a known emulator bug
;     (color should also require this OUT, to match real hardware).
;   - Stage 1 does NOT initialize SP; stage 2 does (ld sp, $7FFF).
;   - Blocks 1-5 are mapped in stage 2 (already running from page 8).
;
; Compile:
;   zxbasm bootstrap_stage1.asm -o bootstrap_stage1.bin
; or with pasmo:
;   pasmo --bin bootstrap_stage1.asm bootstrap_stage1.bin
;
; Load on the emulator / hardware at address $6000 (24576 decimal).
; Run from BASIC with:
;   RANDOMIZE USR 24576
; ===========================================================================

    org $6000

SD81_STAGE1:

    di                          ; Interrupts disabled

	; --------------------------------------------------------------------------
	; Set the framebuffer address (HFILE)
	; high=2044 low=(2043)
	;

	ld   hl, $C000
	ld   ($07FB), hl

	; --------------------------------------------------------------------------
    ; ------------------------------------------------------------------
    ; Activate Superfast HiRes Spectrum mode
    ; POKE 2045, 172  ->  ld a, 172 / ld ($07FD), a
    ; The SD81 Booster's FPGA interprets this as:
    ;   mode 172 ($AC) = Spectrum 256x192 from HFILE=$C000
    ; ------------------------------------------------------------------
    ld   a, 172
    ld   ($07FD), a

    ; ------------------------------------------------------------------
    ; Activate Chroma81 colour mode
    ; Activating Spectrum mode above does NOT turn color on by itself
    ; on real hardware (confirmed on real SD81 Booster; the EightyOne
    ; emulator shows color regardless, which is an emulator bug to
    ; report/fix there). Chroma81 is a separate port ($7FEF) that must
    ; be set explicitly.
    ; ------------------------------------------------------------------
    ld   bc, $7FEF               ; Chroma81 port: set known state
    ld   a, 39                   ; bit5=1 color on, bit4=0 char-code mode
    out  (c), a

    ; ------------------------------------------------------------------
    ; Disable memory-mapped IO
    ; POKE 2056, 0  ->  ld ($0808), a
    ; Avoids collisions between IN/OUT instructions and the RAM space
    ; ------------------------------------------------------------------
    xor  a
    ld   ($0808), a

    ; ------------------------------------------------------------------
    ; Map block 0 ($0000-$1FFF) -> SD81 page 8
    ; Port $E7: full 64-page mode, OUT (C), A with B=page, A=block
    ; Page 8 holds the compiled binary (vectors + stage 2 + runtime)
    ; ------------------------------------------------------------------
    ld   b, 8                   ; destination SD81 page (8 = first user page)
    ld   a, 0                   ; Z80 block to remap (block 0 = $0000-$1FFF)
    ld   c, $E7                 ; SD81 paging port
    out  (c), a                 ; map  (B=page, A=block)

    ; ------------------------------------------------------------------
    ; Jump to stage 2 in the freshly mapped RAM
    ; From here on, block 0 holds page 8:
    ;   $0000-$0067  RST vectors
    ;   $0100        __START_PROGRAM (stage 2's entry point)
    ; ------------------------------------------------------------------
    jp   $0100


    end SD81_STAGE1
