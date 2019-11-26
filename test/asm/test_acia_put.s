.setcpu "65c02"

.include "stack.s"
.include "acia.s"

.code

; app entrypoint
main:
    ldx #$ff

    spush
    lda #$55
    sta 1, x

    jsr acia_put

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
