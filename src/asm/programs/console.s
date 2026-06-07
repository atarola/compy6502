.setcpu "65c02"

.include "include/compy6502.inc"

PUT_CHAR = $21

.org $1000
  lda #SPI_CLK_1M
  ora #SPI_CS_SEL3
  jsr SPI_CONFIGURE

loop:
  jsr ACIA_GETC
  pha
  jsr ACIA_PUTC
  pla
  jsr console_put
  jmp loop

console_put:
  pha
  jsr SPI_SELECT
  lda #PUT_CHAR
  jsr SPI_WRITE
  jsr SPI_DESELECT
  jsr SPI_SELECT
  pla
  jsr SPI_WRITE
  jsr SPI_DESELECT
  rts