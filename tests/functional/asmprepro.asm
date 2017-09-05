; Test recursive inclusion in ASM files

#ifndef __I1__
#   ifndef __I2__
#       define __I2__
nop ; I2
#       include "asmprepro.asm"
#   endif
#   define __I1__
nop ; I1
#   include "asmprepro.asm"
#   undef __I1__
nop
#endif



