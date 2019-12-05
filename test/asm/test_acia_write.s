.setcpu "65c02"

.include "stack.s"
.include "acia.s"

.code

; app entrypoint
main:
    ldx #$ff

    spush
    lda #<MAIN_PROMPT
    sta 0, x
    lda #>MAIN_PROMPT
    sta 1, x

    jsr acia_write

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.rodata

MAIN_PROMPT: .byte "The quick brown fox jumps over the lazy dog.", $00

.segment "VECTORS"

.addr on_nmi, main, on_irq
