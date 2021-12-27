;
; main file
;
.setcpu "65c02"

.include "stack.s"
.include "spi.s"

.code

; app entrypoint
main:
    ; setup the hardware and data stacks
    ldx #$FF
    txs

    ; setup spi
    jsr spi_init
    jsr spi_select_one

    ; send a byte
    spush
    jsr spi_send

 @loop:
    nop
    jmp @loop

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.bss

.rodata

.segment "VECTORS"

.addr on_nmi, main, on_irq
