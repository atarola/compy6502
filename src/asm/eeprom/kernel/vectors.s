.include "include/compy6502.inc"

RESET_HANDLER:
    cld

    lda #<irq_noop
    sta IRQ_HOOK_LO
    lda #>irq_noop
    sta IRQ_HOOK_HI

    jmp WOZMON

NMI_HANDLER:
    rti

IRQ_HANDLER:
    jmp irq_dispatch
