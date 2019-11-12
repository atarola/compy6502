.setcpu "6502"
.segment "CODE"

main:
        lda #$ff
        sta $6002

        lda #$55
        sta $6000

        lda #$aa
        sta $6000

        jmp main

on_irq:
        rti

on_nmi:
        rti

.segment "RODATA"

.segment "VECTORS"
  .addr on_nmi, main, on_irq
