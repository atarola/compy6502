; ; main file
;
.setcpu "65c02"

.code

FIRST = $0300
SECOND = $0301

; app entrypoint
main:
    ldx #$55
    stx FIRST
    ldx #$aa
    stx SECOND
 @loop:
    ldx FIRST
    stx $9001
    nop
    ldx SECOND
    stx $9001
    nop
    jmp @loop

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
