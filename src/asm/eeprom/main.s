.setcpu "65c02"

.code

.segment "JUMPTABLE"
.include "jumptable.s"

.segment "KERNEL"
.include "kernel/acia.s"
.include "kernel/ansi.s"
.include "kernel/irq.s"
.include "kernel/line.s"
.include "kernel/loader.s"
.include "kernel/strings.s"
.include "kernel/vectors.s"

.segment "WOZMON"
.include "wozmon.s"

.segment "VECTORS"
.addr NMI_HANDLER
.addr RESET_HANDLER
.addr IRQ_HANDLER
