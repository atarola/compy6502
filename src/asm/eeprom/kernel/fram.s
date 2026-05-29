.include "include/compy6502.inc"

;
; FRAM
;

FRAM_CMD_WREN = %00000110
FRAM_CMD_WRDI = %00000100
FRAM_CMD_RDSR = %00000101
FRAM_CMD_WRSR = %00000001
FRAM_CMD_READ = %00000011
FRAM_CMD_FSTRD = %00001011
FRAM_CMD_WRITE = %00000010
FRAM_CMD_SLEEP = %10111001
FRAM_CMD_RDID = %10011111

FRAM_CONFIG = SPI_CS_SEL0 | SPI_CLK_1M

; Initialize the FRAM for normal use.
; in:  none
; out: carry clear = initialized
;      carry set   = initialization failed
; clobbers: A, flags
fram_setup:
  lda #FRAM_CONFIG
  jsr SPI_CONFIGURE
  jsr SPI_SELECT

  lda #FRAM_CMD_WREN
  jsr SPI_WRITE

  jsr SPI_DESELECT
  clc
  rts

; Write a RAM chunk to FRAM.
; in:  K_PTR  = source RAM address
;      K_PTR2 = destination FRAM address
;      K_LEN  = byte count
; out: carry clear = written
;      carry set   = write failed
; clobbers: A, Y, flags, K_PTR, K_LEN
fram_write_chunk:
  jsr SPI_SELECT

  lda #FRAM_CMD_WRITE
  jsr SPI_WRITE

  lda K_PTR2_HI
  jsr SPI_WRITE

  lda K_PTR2_LO
  jsr SPI_WRITE

  ldy #$00

@loop:
  lda K_LEN_LO
  ora K_LEN_HI
  beq @end

  lda (K_PTR),y
  jsr SPI_WRITE

  INC16 K_PTR
  DEC16 K_LEN

  jmp @loop

@end:
  jsr SPI_DESELECT
  clc
  rts

; Read a FRAM chunk into RAM.
; in:  K_PTR  = destination RAM address
;      K_PTR2 = source FRAM address
;      K_LEN  = byte count
; out: carry clear = read
;      carry set   = read failed
; clobbers: A, Y, flags, K_PTR, K_LEN
fram_read_chunk:
  jsr SPI_SELECT

  lda #FRAM_CMD_READ
  jsr SPI_WRITE

  lda K_PTR2_HI
  jsr SPI_WRITE

  lda K_PTR2_LO
  jsr SPI_WRITE

  ldy #$00

@loop:
  lda K_LEN_LO
  ora K_LEN_HI
  beq @end

  lda #$00
  jsr SPI_TRANSFER
  sta (K_PTR),y

  INC16 K_PTR
  DEC16 K_LEN

  jmp @loop

@end:
  jsr SPI_DESELECT
  clc
  rts
