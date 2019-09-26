#Uzebox

## technical specifications 
* CPU: ATmega644 at 28.61818 MHz (overclocked from default 20 MHz)
* Flash Memory (Program Memory): 64kb
* RAM Memory: 4kb
* Colours: 256 (same palette as from msx2-screen8, or zxspectrum-ulaplus)
* Video "Memory": 1 byte (!) - The video display is just a 8bit port, used defaultly from the interrupt video-mode kernels.
* Tile Display Memory Area: is (defaultly) inside the 4kb RAM memory, size depending on how is it used from the video-mode kernel choosed. Most of the ready video modes can have 256 different tiles available.
* Pattern Display Memory Area (tiles and sprites): is (defaultly) inside the 64kb Flash memory, size depending on how is it used from the video-mode kernel choosed
* Sprite Attribute Memory Area: is (defaultly) inside the 4kb RAM memory, size depending on how is it used from the video-mode kernel choosed
* Video Modes: 9 (up to now) - Since display modes are from interrupt, anyone is welcome on creating new video-modes when needed (and skilled for helping). Theoretically, from 1 cycle from ATmega644 processor, a display resolution like 1440x240 could be obtained. But since at least 4 cycles are needed to display a pixel, the width resolutions available from video modes are 360 (4 cycles), 288 (5), 240 (6), 180 (8), 144 (10) and 120 (12).

## more information 
* http://uzebox.org/wiki/index.php?title=Hello_World
* http://belogic.com/uzebox/index.asp
* http://lyons42.com/AVR/Opcodes/AVRSelectedOpcodeBlocks.html
* http://www.atmel.com/atmel/acrobat/doc0856.pdf
* http://uzebox.org/wiki/index.php?title=Video_Modes
* http://uzebox.org/wiki/index.php?title=BBCC
* https://docs.google.com/file/d/0B5DarBnaVpImS3FtTXJNQVYzRjg/edit
* http://www.basic-converter.org


