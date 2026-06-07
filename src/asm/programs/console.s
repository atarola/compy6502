.setcpu "65c02"

.include "include/compy6502.inc"

READ_STATUS = $01
GET_CHAR = $20
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
  
  jsr console_set_character
  jmp loop

console_set_character:
  pha
  jsr SPI_SELECT
  lda #PUT_CHAR
  jsr SPI_WRITE
  jsr SPI_DESELECT

  jsr delay

  jsr SPI_SELECT
  pla
  jsr SPI_WRITE
  jsr SPI_DESELECT
  rts

delay:
  ldy #255
@inner:
  dey
  bne @inner
  sec
  rts
