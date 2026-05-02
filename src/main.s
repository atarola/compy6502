.setcpu "65c02"

.code
main:
    ldx #$4C
    stx $5555

    ldx #$AA
    stx $5556
    stx $5557

    ldx #$4C
    stx $AAAA

    ldx #$55
    stx $AAAB

    ldx #$C5
    stx $AAAC

    jmp $5555

on_irq:
    rti

on_nmi:
    rti

.segment "TEST_C555"
.byte $4C, $AA, $DA

.segment "TEST_DAAA"
.byte $4C, $55, $55

.segment "VECTORS"
.addr on_nmi, main, on_irq