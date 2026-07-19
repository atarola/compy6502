.setcpu "65c02"

.include "include/compy6502.inc"

PUT_CHAR = $21
READ_STATUS = $01
HOST_READY = $02

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
  jsr console_wait_ready
  jsr SPI_SELECT
  lda #PUT_CHAR
  jsr SPI_WRITE
  pla
  jsr SPI_WRITE
  jsr SPI_DESELECT
  rts

console_wait_ready:
  jsr SPI_SELECT
  lda #READ_STATUS
  jsr SPI_WRITE
  lda #0
  jsr SPI_TRANSFER
  pha
  jsr SPI_DESELECT
  pla
  and #HOST_READY
  beq console_wait_ready
  rts
