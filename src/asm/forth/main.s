.setcpu "65c02"

.include "include/compy6502.inc"
.include "forth.inc"

.org $1000
.include "vm.s"
.include "primitives.s"
.include "shell.s"

.org $2000
.include "program.s"
