.segment "KERNEL"

RESET_HANDLER:
    sei
    cld
    jmp WOZMON_START

NMI_HANDLER:
    rti

IRQ_HANDLER:
    rti