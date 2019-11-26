.setcpu "65c02"

.include "stack.s"
.include "acia.s"

.code

; app entrypoint
main:
    ldx #$ff
    jsr acia_init

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
