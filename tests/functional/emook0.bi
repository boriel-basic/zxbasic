#define SetREG(reg,val) \
        LD A,reg \
        LD BC,val 

ASM 
        SetREG(A,254)
end Asm

