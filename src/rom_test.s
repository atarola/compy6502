.setcpu "65c02"

.code

main:
loop:
    nop
    nop
    nop
    nop
    nop
    jmp loop

on_irq:
    rti

on_nmi:
    rti

.segment "VECTORS"
.addr on_nmi, main, on_irq