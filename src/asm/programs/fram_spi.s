.setcpu "65c02"

.include "include/compy6502.inc"

FRAM_ADDR = $1234
DEST_ADDR = $5555

FRAM_CMD_WREN  = $06
FRAM_CMD_WRDI  = $04
FRAM_CMD_RDSR  = $05
FRAM_CMD_WRSR  = $01
FRAM_CMD_READ  = $03
FRAM_CMD_FSTRD = $0B
FRAM_CMD_WRITE = $02
FRAM_CMD_SLEEP = $B9
FRAM_CMD_RDID  = $9F

.org $0900
fram_string:
  .byte $0D, $0A, "Hello World!", $0D, $0A, $00

.org $1000
  lda #SPI_CLK_1M
  jsr SPI_CONFIGURE
  
  jsr fram_write_string
  jmp WOZMON

.org $1100
  lda #SPI_CLK_1M
  jsr SPI_CONFIGURE

  jsr fram_read_string
  jsr print_dest_string
  jmp WOZMON

fram_write_string:
  jsr SPI_SELECT
  lda #FRAM_CMD_WREN
  jsr SPI_WRITE
  jsr SPI_DESELECT

  jsr SPI_SELECT
  lda #FRAM_CMD_WRITE
  jsr SPI_WRITE
  lda #>FRAM_ADDR
  jsr SPI_WRITE
  lda #<FRAM_ADDR
  jsr SPI_WRITE

  ldy #$00
@loop:
  lda fram_string,y
  jsr SPI_WRITE
  lda fram_string,y
  beq @done

  iny
  bne @loop

@done:
  jsr SPI_DESELECT
  rts

fram_read_string:
  jsr SPI_SELECT
  lda #FRAM_CMD_WREN
  jsr SPI_WRITE
  jsr SPI_DESELECT

  jsr SPI_SELECT
  lda #FRAM_CMD_READ
  jsr SPI_WRITE
  lda #>FRAM_ADDR
  jsr SPI_WRITE
  lda #<FRAM_ADDR
  jsr SPI_WRITE

  ldy #$00
@loop:
  lda #$00
  jsr SPI_TRANSFER
  sta DEST_ADDR,y

  beq @done

  iny
  bne @loop

@done:
  jsr SPI_DESELECT
  rts

print_dest_string:
  ldx #$00
@loop:
  lda DEST_ADDR,x
  beq @done

  jsr ACIA_PUTC

  inx
  bne @loop

@done:
  rts
  