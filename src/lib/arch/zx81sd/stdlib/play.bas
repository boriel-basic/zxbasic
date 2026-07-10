' ----------------------------------------------------------------------
' play.bas (zx81sd) — COPIA de zx48k/stdlib/play.bas adaptada al hardware
' AY del SD81 Booster (interfaz ZonX-81). Mantener sincronizada con el
' original de zx48k; los UNICOS cambios respecto a el son:
'
'   1. _PLAY_WRITE_TO_REGISTER: puertos ZonX del chip A (latch $CF,
'      dato $0F) en vez de los del Spectrum 128 ($FFFD/$BFFD).
'   2. _Play_NoteDividers: tabla regenerada para reloj AY de 1.625 MHz
'      (la FPGA del SD81 clockea los AY a 3.25MHz/2) en vez de los
'      1.7734 MHz del Spectrum 128. divisor = round(1625000/16/f).
'   3. CpuCyclesPerSecond: 3250000 (ZX81) en vez de 3546900 (128K),
'      para que el tempo sea correcto.
'   4. Sin EI al terminar: el runtime zx81sd funciona con las
'      interrupciones deshabilitadas (la FPGA genera el video).
' ----------------------------------------------------------------------

' ----------------------------------------------------------------------
' This file is released under the MIT License
' 
' Copyright (C) 2026
' by Oleg S. Kostenko (a.k.a. Ollibony) <https://github.com/oskostenko>
' ----------------------------------------------------------------------

#pragma once

#pragma push(explicit)
#pragma push(strict)

#pragma explicit = true
#pragma strict = true

' ---------------------------------------------------------------------------------------------------------------------
' Plays the given MML strings on the AY music chip.
' The syntax is compatible with the Sinclair Basic Play routine.
' The documentation can be found here: https://fizyka.umk.pl/~jacek/zx/doc/man128/sp128p09.html
'
' This is work in progress. 

' The following commands are already implemented:
' - cdefgab, CDEFGAB - gives pitch of note within current octave range
' - $ - flattens note following it
' - # - sharpens note following it
' - & - denotes a rest
' - 1-12 - sets length of notes
' - _ - creates tied notes (sums multiple durations)
' - O - followed by a number 0 to 8 sets current octave range
' - V - followed by a number 0 to 15 sets volume of notes
' - T - followed by a number 60 to 240 sets tempo of music
' - N - separates two numbers (actually, any unexpected character does this, including space)
'
' The following commands are not implemented yet:
' - W, U, X - set volume effects
' - () - repetition
' - !! - comments
' - H - stop
' - M - channel mixer control
' - Y, Z - MIDI control (also you can't now pass more than 3 parameters to Play).
'
' Notes:
' - Unlike Sinclair Basic Play routine, this one doesn't insert tiny pauses between adjacent notes.
'   I consider this to be a feature, rather than a bug.
' - There are no checks for incorrect commands or parameters. Unknown commands are silently ignored,
'   and incorrect parameters cause undefined behavior.
' - This routine is more flexible in the way it parses commands than Sinclair Basic Play routine.
'   Some combinations that give errors in Sinclair Basic, will play fine in this implementation.
' - This sub tends to provide more accurate timings than the original Sinclair Basic Play routine.
'   However, perfect timing is not guaranteed, it may fluctuate depending on the complexity of the melody.
' - There can be subtle difference in behaviour between this sub and Sinclair Play,
'   especially in undocumented edge cases (such as using ties together with triplets).
' - This sub disables interrupts at the start, and enables them in the end,
'   regardless of whether they were enabled or not before.
' - The strings are passed by value and thus are copied on the routine invocation.
'   The memory-effective version of this routine is yet to be implemented.
' - The compiler gives warning `[W150] Parameter 'microticks' is never used`.
'   This is false positive and, unfortunately, cannot be suppressed on library level.
' ---------------------------------------------------------------------------------------------------------------------
declare sub Play(channel0 as string, channel1 as string = "", channel2 as string = "")


' Implementation ------------------------------------------------------------------------------------------------------

' How many ticks there are in a bar (a whole note).
' A tick is a single iteration of the main processing loop.
const _Play_TicksPerBar as ubyte = 96

const _Play_NotesPerOctave as ubyte = 12
const _Play_TotalOctaves as ubyte = 9

' Maps note length to the corresponding number of ticks.
dim _Play_NoteLengthsInTicks(1 to 12) as ubyte => { _
    _Play_TicksPerBar / 16,       _ '1 - semi-quaver
    _Play_TicksPerBar / 16 * 1.5, _ '2 - dotted semi-quaver	
    _Play_TicksPerBar / 8,        _ '3 - quaver
    _Play_TicksPerBar / 8 * 1.5,  _ '4 - dotted quaver
    _Play_TicksPerBar / 4,        _ '5 - crotchet
    _Play_TicksPerBar / 4 * 1.5,  _ '6 - dotted crotchet
    _Play_TicksPerBar / 2,        _ '7 - minim
    _Play_TicksPerBar / 2 * 1.5,  _ '8 - dotted minim
    _Play_TicksPerBar,            _ '9 - semi-breve
    _Play_TicksPerBar / 24,       _ '10 - triplet semi-quaver
    _Play_TicksPerBar / 12,       _ '11 - triplet quaver
    _Play_TicksPerBar / 6         _ '12 - triplet crotchet
}

' Divider values that need to be sent to the audio chip registers to play the notes.
' Note that the lowest notes in octave 0 are unplayable because of 12-bit overflow and probably wrong notes will be
' played instead of them.
' TODO: replace them with maximum possible values or zeros? See how it's done in Sinclair Play.
' TODO: in Sinclair Play it is possible to play notes in higher octaves (using several sharps in a row).
'       Need to add more values to the table.
dim _Play_NoteDividers(0 to _Play_NotesPerOctave * _Play_TotalOctaves - 1) as uinteger = { _
_ ' C     C#    D     D#    E     F     F#    G     G#    A     A#    B
    6211, 5863, 5534, 5223, 4930, 4653, 4392, 4145, 3913, 3693, 3486, 3290, _ 'octave 0
    3106, 2931, 2767, 2611, 2465, 2327, 2196, 2073, 1956, 1847, 1743, 1645, _ 'octave 1
    1553, 1466, 1383, 1306, 1232, 1163, 1098, 1036,  978,  923,  871,  823, _ 'octave 2
     776,  733,  692,  653,  616,  582,  549,  518,  489,  462,  436,  411, _ 'octave 3
     388,  366,  346,  326,  308,  291,  274,  259,  245,  231,  218,  206, _ 'octave 4
     194,  183,  173,  163,  154,  145,  137,  130,  122,  115,  109,  103, _ 'octave 5
      97,   92,   86,   82,   77,   73,   69,   65,   61,   58,   54,   51, _ 'octave 6
      49,   46,   43,   41,   39,   36,   34,   32,   31,   29,   27,   26, _ 'octave 7
      24,   23,   22,   20,   19,   18,   17,   16,   15,   14,   14,   13  _ 'octave 8
}

' Maps ascii code of a letter to the corresponding index of `_Play_NoteDividers` (octave 0).
dim _Play_NoteIndexes(code("A") to code("G")) as ubyte = { _
    /'A'/ 9,  _
    /'B'/ 11, _
    /'C'/ 0,  _
    /'D'/ 2,  _
    /'E'/ 4,  _
    /'F'/ 5,  _
    /'G'/ 7   _
}

' Pointer to the current channel context.
' Made global for better performance, and also because it would be problematic to access it from nested subs if it were
' local (see 'Implementation note' on `Play`).
dim _Play_ContextPtr as uinteger

' Switches to the first channel context.
#define _PLAY_CTX_FIRST_CHANNEL() let _Play_ContextPtr = ChannelContextBufferPtr

' Swithes to the next channel context.
#define _PLAY_CTX_NEXT_CHANNEL() let _Play_ContextPtr = _Play_ContextPtr + ChannelContextSize

' Gets the value of the given `type` at the given `offset` of the current channel context.
#define _PLAY_CTX_GET(type, offset) (peek(type, _Play_ContextPtr + (offset)))

' Sets the given `value` of the given `type` to the given `offset` of the current channel context.
#define _PLAY_CTX_SET(type, offset, value) poke type _Play_ContextPtr + (offset), (value)

' Arithmetically adds the given `value` to the value of the given `type` stored at the given `offset`
' of the current channel context.
#define _PLAY_CTX_ADD(type, offset, value) _PLAY_CTX_SET(type, offset, _PLAY_CTX_GET(type, offset) + (value))

' Write the value to the given register of the sound chip.
#define _PLAY_WRITE_TO_REGISTER(register, value) out $cf, (register) : out $0f, (value)


' Main sub.
'
' Implementation note:
' If you want to extend the inner subs or functions, or add new ones,
' please beware that the current compiler version (v1.19.0-beta7 at the time of writing)
' doesn't support accessing outer local vars from the inner sub/function,
' if the inner sub/function has its own vars or params.
' 
' TODO: add sub variants that accept strings byref, and that accept an array.
' TODO: check valid ranges of command parameters, handle integer overflow/underflow
'
sub Play(channel0 as string, channel1 as string = "", channel2 as string = "")

    const CpuCyclesPerSecond as ulong = 3250000
    const CpuCyclesPerMicrotick as ubyte = 27  ' see the `Wait` sub
    const BeatsPerBar as ubyte = 4
    const SecondsPerMinute as ubyte = 60
    const ChannelCount as ubyte = 3

    const DefaultTempo as ubyte = 120
    const DefaultOctave as ubyte = 5
    const DefaultNoteLength as ubyte = 5
    const DefaultVolume as ubyte = 15
    const DefaultMixer as ubyte = %11111000

    ' General processing overhead compensation. Applied to every `Wait` invocation.
    ' Determined experimentally.
    ' TODO: adjust if needed after everything is implemented.
    const TickGeneralOverheadInMicroticks as uinteger = 90

    ' Overhead compensation for commands processing of a single channel.
    ' Applied only on those ticks when there are commands processed for the channel.
    ' Determined experimentally.
    ' TODO: adjust if needed after everything is implemented.
    const TickChannelCommandsOverheadInMicroticks as uinteger = 140
  
    ' Channel numbers are zero-based, because it's better in terms of performance (less arithmetics in runtime needed).
    const MaxChannel as ubyte = ChannelCount - 1  

    ' Size of a single channel context in bytes. Don't forget to increase this if you add more context fields.  
    ' Note: this is used in macro `_PLAY_CTX_NEXT_CHANNEL`.
    const ChannelContextSize as ubyte = 15

    ' Channel context data is stored here.
    dim ChannelContextBuffer(0 to ChannelContextSize * ChannelCount - 1) as ubyte

    ' Pointer to context data.
    ' Note: this is used in macro `_PLAY_CTX_FIRST_CHANNEL`.
    dim ChannelContextBufferPtr as uinteger
    ChannelContextBufferPtr = @ChannelContextBuffer(0)

    ' Offsets of fields in a channel context.
    ' If you add more fields, don't forget to increase `ChannelContextSize`.
    const _CharPtr         as ubyte = 0 ' (uinteger) Pointer to the current character in the channel string.
    const _StringEndPtr    as ubyte = 2 ' (uinteger) Pointer to the first byte after the last char of the channel
                                        '            string.
    const _TickBackCounter as ubyte = 4 ' (uinteger) How many ticks to wait before proceeding to the next command
                                        '            in the channel string. Zero means we need to proceed now.
    const _PrimaryNoteLengthInTicks as ubyte = 6 ' (uinteger) Current note length in ticks.
    const _ActualNoteLengthInTicks  as ubyte = 8 ' (uinteger) Actual note length in ticks.
                                                 '            Mostly the same as `_PrimaryNoteLengthInTicks`,
                                                 '            but may differ for triplets and ties.
    const _ResetNoteLengthBackCount as ubyte = 10 ' (ubyte) How many notes left to play before actual note length must
                                                  '         be reset to primary note length.
    const _BaseDividerIndex   as ubyte = 11 ' (ubyte) Divider index (see `_Play_NoteDividers`) that corresponds to
                                            '         note C of the current octave.
    const _SemitoneAdjustment as ubyte = 12 ' (byte)  How many semitones to add or subtract from the next note.
    const _FinishedFlag       as ubyte = 13 ' (ubyte) If nonzero, then the channel has finished playing.
    const _Volume             as ubyte = 14 ' (ubyte) Current volume.

    ' Current tempo as beats per minute. A 'beat' is a 1/4-length note.
    dim Tempo as ubyte

    ' Current tempo as microticks per tick.
    ' For 'microtick' definition, see the `CpuCyclesPerMicrotick` const.
    ' For 'tick' definition, see the `_Play_TicksPerBar` const.
    dim MicroticksPerTick as uinteger

    dim LastChar as ubyte      ' Last char read by `ReadChar` sub.    
    dim LastNumber as uinteger ' Last number read by `ReadNumber` sub.

    ' Reads a char from the current channel string and puts it to `LastChar` variable.
    ' Puts 0 if there's nothing left to read.
    ' This is a sub, not a function, for performance reasons.
    sub ReadChar
        if _PLAY_CTX_GET(uinteger, _CharPtr) = _PLAY_CTX_GET(uinteger, _StringEndPtr) then
            LastChar = 0
            return
        end if
        
        LastChar = peek(_PLAY_CTX_GET(uinteger, _CharPtr))
        _PLAY_CTX_ADD(uinteger, _CharPtr, 1)
    end sub

    ' Reads the number from the current channel string and puts it in `LastNumber` variable.
    ' Puts 0 if the number is unreadable.
    sub ReadNumber
        LastNumber = 0

        do
            ReadChar

            if LastChar >= code("0") and LastChar <= code("9") then
                LastNumber = LastNumber * 10 + LastChar - code("0")
            else
                ' The number has ended.
                if LastChar <> 0 then
                    ' Step back if the string has not ended.
                    _PLAY_CTX_ADD(uinteger, _CharPtr, -1)
                end if
                exit do
            end if
        loop
    end sub

    ' Sets octave for the current channel.
    sub SetOctave(octave as ubyte)
        _PLAY_CTX_SET(ubyte, _BaseDividerIndex, octave * _Play_NotesPerOctave)
    end sub

    ' Sets `MicroticksPerTick` according to the current `Tempo` value.
    sub UpdateMicroticksPerTick
        MicroticksPerTick = _
            CpuCyclesPerSecond * SecondsPerMinute * BeatsPerBar _
            / CpuCyclesPerMicrotick / _Play_TicksPerBar / Tempo
    end sub

    ' Waits for the given amount of microticks.
    ' One microtick is 27 CPU cycles (if you change it, also change `CpuCyclesPerMicrotick` const).
    ' TODO: is it possible to suppress the 'unused parameter' warning?
    sub fastcall Wait(microticks as uinteger)
        asm
            proc
            local loop

            ld bc, 1        ; bc = 1
            or a            ; reset carry flag
        loop:
            sbc hl, bc      ; microticks = microticks - bc       ; 15 cycles
            jr nz, loop     ; if microticks <> 0 then goto loop  ; 12 cycles

            endp
        end asm
    end sub

    ' Set pitch on the sound chip for a channel.
    sub SetChipPitchDivider(channel as ubyte, divider as uinteger)
        _PLAY_WRITE_TO_REGISTER(channel * 2, divider band $ff)
        _PLAY_WRITE_TO_REGISTER(channel * 2 + 1, divider >> 8)
    end sub

    ' Set volume on the sound chip for a channel.
    sub SetChipVolume(channel as ubyte, volume as ubyte)
        _PLAY_WRITE_TO_REGISTER(channel + 8, volume)
    end sub

    ' Set mixer mode on the sound chip.
    sub SetChipMixer(value as ubyte)
        _PLAY_WRITE_TO_REGISTER(7, value)
    end sub

    ' If macro `_PLAY_BENCHMARK_MODE` is defined, then interrupts are not disabled, and the system timer is used to
    ' measure the duration of play. The duration in ticks is printed on the screen after playing.
    ' Note that interrupts add overhead and inaccuracies to timings, so this mode is not intended for fine-tuning
    ' timings. This should only be used for differential analysis of code optimization efficiency.
    #ifndef _PLAY_BENCHMARK_MODE
        asm
            di
        end asm
    #endif

    _PLAY_CTX_FIRST_CHANNEL()
    _PLAY_CTX_SET(uinteger, _CharPtr, @channel0)

    _PLAY_CTX_NEXT_CHANNEL()
    _PLAY_CTX_SET(uinteger, _CharPtr, @channel1)

    _PLAY_CTX_NEXT_CHANNEL()
    _PLAY_CTX_SET(uinteger, _CharPtr, @channel2)

    dim channel as ubyte
    dim strLen as uinteger

    _PLAY_CTX_FIRST_CHANNEL()

    for channel = 0 to MaxChannel
        ' We need low-level access to the strings to achieve good performance.
        
        ' dereference the pointer to the heap
        _PLAY_CTX_SET(uinteger, _CharPtr, peek(uinteger, _PLAY_CTX_GET(uinteger, _CharPtr)))

        ' read the string length
        strLen = peek(uinteger, _PLAY_CTX_GET(uinteger, _CharPtr))

        ' adjust the pointer so it points to the first char
        _PLAY_CTX_ADD(uinteger, _CharPtr, 2)

        ' calculate and store the pointer to the string end
        _PLAY_CTX_SET(uinteger, _StringEndPtr, _PLAY_CTX_GET(uinteger, _CharPtr) + strLen)

        SetOctave DefaultOctave
        _PLAY_CTX_SET(ubyte, _Volume, DefaultVolume)
        _PLAY_CTX_SET(uinteger, _PrimaryNoteLengthInTicks, _Play_NoteLengthsInTicks(DefaultNoteLength))
        _PLAY_CTX_SET(uinteger, _ActualNoteLengthInTicks, _Play_NoteLengthsInTicks(DefaultNoteLength))
        _PLAY_CTX_SET(uinteger, _TickBackCounter, 0)
        _PLAY_CTX_SET(byte, _SemitoneAdjustment, 0)
        _PLAY_CTX_SET(ubyte, _ResetNoteLengthBackCount, 0)
        _PLAY_CTX_SET(ubyte, _FinishedFlag, 0)
        
        _PLAY_CTX_NEXT_CHANNEL()
    next channel

    Tempo = DefaultTempo
    UpdateMicroticksPerTick
    SetChipMixer DefaultMixer

    dim processedChannels as ubyte
    dim finishedChannels as ubyte
    dim lengthInTicks as uinteger
    dim dividerIndex as ubyte

    #ifdef _PLAY_BENCHMARK_MODE
        dim SysFrames as uinteger at $5c78
        dim startTime as uinteger = SysFrames
    #endif

    do
        finishedChannels = 0
        processedChannels = 0

        _PLAY_CTX_FIRST_CHANNEL()

        for channel = 0 to MaxChannel
            if _PLAY_CTX_GET(uinteger, _TickBackCounter) = 0 then
                do
                    ReadChar

                    if LastChar = 0 then
                        ' This channel has finished playing.
                        _PLAY_CTX_SET(ubyte, _FinishedFlag, 1)
                        ' While other channels are still playing, this one will do rests.
                        SetChipVolume channel, 0
                        exit do

                    else if LastChar = code("&") then
                        SetChipVolume channel, 0
                        exit do

                    else if (LastChar >= code("a") and LastChar <= code("g")) _
                        or (LastChar >= code("A") and LastChar <= code("G")) then

                        dividerIndex = _PLAY_CTX_GET(ubyte, _BaseDividerIndex)

                        if LastChar >= code("a") then
                            ' if lowercase, then transpose down 1 octave and make uppercase
                            dividerIndex = dividerIndex - _Play_NotesPerOctave
                            LastChar = LastChar - 32
                        end if

                        dividerIndex = dividerIndex + _
                            _Play_NoteIndexes(LastChar) + _PLAY_CTX_GET(byte, _SemitoneAdjustment)

                        _PLAY_CTX_SET(byte, _SemitoneAdjustment, 0)

                        SetChipPitchDivider channel, _Play_NoteDividers(dividerIndex)
                        SetChipVolume channel, _PLAY_CTX_GET(ubyte, _Volume)

                        exit do

                    else if LastChar = code("$") then
                        _PLAY_CTX_ADD(byte, _SemitoneAdjustment, -1)

                    else if LastChar = code("#") then
                        _PLAY_CTX_ADD(byte, _SemitoneAdjustment, 1)

                    else if LastChar >= code("0") and LastChar <= code("9")
                        _PLAY_CTX_ADD(uinteger, _CharPtr, -1)  ' step back
                        ReadNumber
                        lengthInTicks = _Play_NoteLengthsInTicks(LastNumber)

                        _PLAY_CTX_SET(uinteger, _ActualNoteLengthInTicks, lengthInTicks)
                        
                        if LastNumber >= 10 then
                            ' triplet mode (temporary length)
                            _PLAY_CTX_SET(ubyte, _ResetNoteLengthBackCount, 3)
                        else
                            _PLAY_CTX_SET(uinteger, _PrimaryNoteLengthInTicks, lengthInTicks)
                        end if

                    else if LastChar = code("_") then
                        ' TODO: ties with triplets work differently in Sinclair ROM.
                        ReadNumber
                        lengthInTicks = _Play_NoteLengthsInTicks(LastNumber)

                        _PLAY_CTX_SET(ubyte, _ResetNoteLengthBackCount, 1)
                        _PLAY_CTX_ADD(uinteger, _ActualNoteLengthInTicks, lengthInTicks)
                        _PLAY_CTX_SET(uinteger, _PrimaryNoteLengthInTicks, lengthInTicks)

                    else if LastChar = code("O") then
                        ReadNumber
                        SetOctave LastNumber

                    else if LastChar = code("V") then
                        ReadNumber
                        _PLAY_CTX_SET(ubyte, _Volume, LastNumber)

                    else if LastChar = code("T") then
                        ReadNumber
                        
                        if channel = 0 then
                            Tempo = LastNumber
                            UpdateMicroticksPerTick
                        end if
                                        
                    ' TODO: process other commands here
                    end if
                loop

                if _PLAY_CTX_GET(ubyte, _ResetNoteLengthBackCount) > 0 then
                    _PLAY_CTX_ADD(ubyte, _ResetNoteLengthBackCount, -1)
                else
                    _PLAY_CTX_SET(uinteger, _ActualNoteLengthInTicks, _PLAY_CTX_GET(uinteger, _PrimaryNoteLengthInTicks))
                end if

                _PLAY_CTX_SET(uinteger, _TickBackCounter, _PLAY_CTX_GET(uinteger, _ActualNoteLengthInTicks))

                processedChannels = processedChannels + 1
            end if

            _PLAY_CTX_ADD(uinteger, _TickBackCounter, -1)

            finishedChannels = finishedChannels + _PLAY_CTX_GET(ubyte, _FinishedFlag)

            _PLAY_CTX_NEXT_CHANNEL()
        next channel

        Wait MicroticksPerTick _
            - TickGeneralOverheadInMicroticks _
            - TickChannelCommandsOverheadInMicroticks * processedChannels
    loop until finishedChannels = ChannelCount

    #ifdef _PLAY_BENCHMARK_MODE
        print "Play duration: "; SysFrames - startTime; " ticks."
    #endif

    ' (zx81sd) Sin EI final: el runtime funciona con las interrupciones
    ' deshabilitadas y rehabilitarlas podria disparar una INT sin handler.
end sub

#pragma pop(explicit)
#pragma pop(strict)
