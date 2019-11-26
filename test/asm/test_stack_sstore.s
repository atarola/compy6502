.setcpu "65c02"

.include "stack.s"

.code

; app entrypoint
main:
    ldx #$ff

    ; value to store
    spush
    lda #$aa
    sta 0, x
    sta 1, x

    ; location to store
    spush
    lda #$60
    sta 0, x
    sta 1, x

    ; do the thing
    jsr sstore

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
