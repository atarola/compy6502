.include "include/compy6502.inc"

RESET_HANDLER:
    jmp WOZMON

NMI_HANDLER:
    rti

IRQ_HANDLER:
    rti
