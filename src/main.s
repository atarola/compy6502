.setcpu "65c02"

.code

.segment "KERNEL"
.include "kernel/vectors.s"

.segment "WOZMON"
.include "wozmon/wozmon.s"

.segment "VECTORS"
.addr NMI_HANDLER
.addr RESET_HANDLER
.addr IRQ_HANDLER