.segment "KERNEL"

RESET_HANDLER:
    jmp WOZMON_START

NMI_HANDLER:
    rti

IRQ_HANDLER:
    rti
