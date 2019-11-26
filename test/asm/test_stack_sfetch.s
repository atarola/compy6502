.setcpu "65c02"

.include "stack.s"

.code

; app entrypoint
main:
    ldx #$ff
    spush
    lda #$00
    sta 0, x
    lda #$60
    sta 1, x
    jsr sfetch

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
