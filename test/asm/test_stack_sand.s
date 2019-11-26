.setcpu "65c02"

.include "stack.s"

.code

; app entrypoint
main:
    ldx #$ff

    ; bottom
    spush
    lda #$ff
    sta 0, x
    sta 1, x

    ; top
    spush
    lda #$10
    sta 0, x
    lda #$00
    sta 1, x

    jsr sand

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
