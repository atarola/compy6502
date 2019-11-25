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

 @loop:
    ; write our cursor
    spush #<MAIN_PROMPT, #>MAIN_PROMPT
    jsr acia_write

    ; read
    spush #<MAIN_BUFFER, #>MAIN_BUFFER
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
