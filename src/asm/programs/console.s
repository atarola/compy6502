.setcpu "65c02"

.include "include/compy6502.inc"

CHAR_IDX = $A0

.org $1000
  lda #SPI_CLK_125K
  ora #SPI_CS_SEL3
  jsr SPI_CONFIGURE

  stz CHAR_IDX

  jsr console_write
  jmp WOZMON

console_write:
  jsr SPI_SELECT
  lda #$21
  jsr SPI_WRITE
  jsr SPI_DESELECT

  jsr SPI_SELECT
  ldy CHAR_IDX
  lda chars,y
  jsr SPI_WRITE
  jsr SPI_DESELECT

  ldy CHAR_IDX
  iny
  cpy #7
  bne :+
  ldy #0
:
  sty CHAR_IDX

  jsr delay
  jmp console_write

chars:
  .byte "abcdefg"

delay:
  ldx #16
@middle:
  ldy #0
@inner:
  dey
  bne @inner
  dex
  bne @middle
  sec
  rts
