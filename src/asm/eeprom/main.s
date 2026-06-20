.setcpu "65c02"

.code

.segment "JUMPTABLE"
.include "jumptable.s"

.segment "KERNEL"
.include "kernel/acia.s"
.include "kernel/fram.s"
.include "kernel/fs.s"
.include "kernel/irq.s"
.include "kernel/iter.s"
.include "kernel/line.s"
.include "kernel/loader.s"
.include "kernel/mem.s"
.include "kernel/spi.s"
.include "kernel/strings.s"
.include "kernel/vectors.s"
.include "wozmon.s"

.segment "VECTORS"
.addr NMI_HANDLER
.addr RESET_HANDLER
.addr IRQ_HANDLER
