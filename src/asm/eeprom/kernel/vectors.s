.include "include/compy6502.inc"

RESET_HANDLER:
    lda #<irq_noop
    sta IRQ_HOOK_LO
    lda #>irq_noop
    sta IRQ_HOOK_HI

    jmp WOZMON

NMI_HANDLER:
    rti

IRQ_HANDLER:
    jmp IRQ_DISPATCHER
