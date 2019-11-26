.setcpu "65c02"

.include "stack.s"
.include "acia.s"

.code

; app entrypoint
main:
    ldx #$ff

    spush
    lda #$60
    sta 0, x
    sta 1, x

    jsr acia_read

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
