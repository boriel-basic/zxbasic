; Configuración de arquitectura ZX81 + SD81 Booster
; Este fichero se incluye antes que cualquier otro del runtime.
;
; Activa la implementación de scroll por software (sin ROM Spectrum)
; y desactiva las funcionalidades que dependen de la ROM Spectrum.

; Usar scroll por buffer propio (en vez de CALL $0DFEh ROM Spectrum)
#define __ZXB_ENABLE_BUFFER_SCROLL

; Sin soporte de coma flotante en esta versión
; (el FP calculator de la ROM Spectrum no está disponible)
; Comentar esta línea cuando se integre fp_calc.asm
#define __ZXB_NO_FLOAT
