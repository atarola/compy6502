; main file

.setcpu "65c02"

.include "stack.s"
.include "acia.s"

.code


; main loop
main:
    jsr init

 @loop:
    jsr write_cursor
    push MAIN_BUFFER
    jsr dup
    jsr acia_read
    jsr acia_write
    jmp @loop


; setup the computer
init:
    jsr stack_init
    jsr acia_init
    rts


; write the cursor to the acia
write_cursor:
    push MAIN_PROMPT
    jsr acia_write
    rts


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
