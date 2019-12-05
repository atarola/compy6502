;
; main file
;
.setcpu "65c02"

.include "stack.s"
.include "acia.s"

.code

; app entrypoint
main:
    ldx #$ff
    jsr acia_init

 @loop:
    ; write our cursor
    spush
    lda #<MAIN_PROMPT
    sta 0, x
    lda #>MAIN_PROMPT
    sta 1, x

    jsr acia_write

    ; read
    spush
    lda #<MAIN_BUFFER
    sta 0, x
    lda #>MAIN_BUFFER
    sta 1, x
    jsr sdup
    jsr acia_read

    ; print
    jsr acia_write
    jmp @loop

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.bss

MAIN_BUFFER: .res 255

.rodata

MAIN_PROMPT: .byte " --> ", $00

.segment "VECTORS"

.addr on_nmi, main, on_irq
