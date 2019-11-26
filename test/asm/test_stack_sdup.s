.setcpu "65c02"

.include "stack.s"

.code

; app entrypoint
main:
    ldx #$ff
    spush
    lda #$fc
    sta 0, x
    sta 1, x
    jsr sdup

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
