.setcpu "65c02"

.code

; app entrypoint
main:
    ldx #$ff

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
