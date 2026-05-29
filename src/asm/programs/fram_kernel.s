.setcpu "65c02"

.include "include/compy6502.inc"

FRAM_ADDR = $AAAA
DEST_ADDR = $6666

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
  .byte $0D, $0A, "your mom!", $0D, $0A, $00
fram_string_end:

FRAM_STR_LEN = (fram_string_end - fram_string)

.org $1000
  jsr FRAM_SETUP

  ; src address
  lda #<fram_string
  sta K_PTR_LO
  lda #>fram_string
  sta K_PTR_HI

  jsr setup_pointers
  jsr FRAM_WRITE_CHUNK
  jsr print_newline
  jmp WOZMON

.org $1100
  jsr FRAM_SETUP

  ; dest addr
  lda #<DEST_ADDR
  sta K_PTR_LO
  lda #>DEST_ADDR
  sta K_PTR_HI

  jsr setup_pointers
  jsr FRAM_READ_CHUNK
  jsr print_dest_string
  jsr print_newline
  jmp WOZMON

setup_pointers:
  ; dest addr
  lda #<FRAM_ADDR
  sta K_PTR2_LO
  lda #>FRAM_ADDR
  sta K_PTR2_HI
  
  ; length
  lda #<FRAM_STR_LEN
  sta K_LEN_LO
  lda #>FRAM_STR_LEN
  sta K_LEN_HI
  rts

print_newline:
  lda #$0D
  jsr ACIA_PUTC
  lda #$0A
  jsr ACIA_PUTC
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
  