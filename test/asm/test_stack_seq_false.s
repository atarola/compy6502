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
    lda #$aa
    sta 0, x
    lda #$ab
    sta 1, x

    jsr seq

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
