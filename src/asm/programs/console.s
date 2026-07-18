.setcpu "65c02"

.include "include/compy6502.inc"

PUT_CHAR = $21
GET_CHAR = $20

.org $1000
  lda #SPI_CLK_125K
  ora #SPI_CS_SEL3
  jsr SPI_CONFIGURE

loop:
  jsr console_get
  beq loop
  pha
  jsr ACIA_PUTC
  pla
  jsr console_put
  jmp loop

console_get:
  jsr SPI_SELECT
  lda #GET_CHAR
  jsr SPI_WRITE
  lda #0
  jsr SPI_TRANSFER
  pha
  jsr SPI_DESELECT
  jsr console_delay
  pla
  rts

console_put:
  pha
  jsr SPI_SELECT
  lda #PUT_CHAR
  jsr SPI_WRITE
  pla
  jsr SPI_WRITE
  jsr SPI_DESELECT
  jsr console_delay
  rts

console_delay:
  pha
  lda #$FF
@loop:
  dec
  bne @loop
  pla
  rts
