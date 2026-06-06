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
  jsr console_status
  bne :+
  jsr delay
  jmp loop
:

  lda #'.'
  jsr ACIA_PUTC

  jsr console_get_character
  pha
  jsr BYTE_TO_HEX
  pha
  jsr ACIA_PUTC
  pla
  txa
  jsr ACIA_PUTC
  pla
  jsr console_set_character

  jsr delay
  jmp loop

console_status:
  jsr SPI_SELECT
  lda #READ_STATUS
  jsr SPI_WRITE
  jsr SPI_DESELECT
  
  jsr delay
  
  jsr SPI_SELECT
  lda #$00
  jsr SPI_TRANSFER
  pha
  jsr SPI_DESELECT
  pla
  rts

console_get_character:
  jsr SPI_SELECT
  lda #GET_CHAR
  jsr SPI_WRITE
  jsr SPI_DESELECT

  jsr delay
  jsr delay
  jsr delay

  jsr SPI_SELECT
  lda #$00
  jsr SPI_TRANSFER
  pha
  jsr SPI_DESELECT
  pla
  rts

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
