;
; main file
;
.setcpu "65c02"

.include "stack.s"

.code

; app entrypoint
main:
    ; set the data stack pointer
    ldx #$ff

    ; load our data
    spush #$00, #$90
    spush #$55, #$aa
    spush #$00, #$90
    jsr sstore
    jsr sfetch
    jmp main

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
