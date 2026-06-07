.setcpu "65c02"

.include "include/compy6502.inc"

PUT_CHAR = $21

.org $1000
  lda #SPI_CLK_1M
  ora #SPI_CS_SEL3
  jsr SPI_CONFIGURE

  lda #'!'
loop:
  pha
  jsr console_put
  pla
  clc
  adc #1
  cmp #'~' + 1
  bcc loop
  lda #'!'
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
