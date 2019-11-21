; ; main file
;
.setcpu "65c02"

.code


main:
    ldx $00

 @loop
    ldx $aa
    stx $6000
    nop

    ldx $55
    stx $6000
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
