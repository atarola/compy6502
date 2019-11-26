.setcpu "65c02"

.include "stack.s"

.code

; app entrypoint
main:
    ldx #$ff

    ; bottom
    spush
    lda #$aa
    sta 0, x
    sta 1, x

    ; top
    spush
    lda #$55
    sta 0, x
    sta 1, x

    jsr sswap

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
