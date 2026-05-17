.setcpu "65c02"

.include "include/compy6502.inc"
.include "forth/forth.inc"

.org $0700
.include "forth/vm.inc"
.include "forth/primitives.inc"
.include "forth/shell.inc"

.org $1000
.include "forth/program.inc"
