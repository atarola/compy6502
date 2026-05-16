.include "include/compy6502.inc"

SREC_LINE_IN = $0200
SREC_CTR = $2C
SREC_LOC_LO = $2D
SREC_LOC_HI = $2E
SREC_SCRATCH = $02FC
SREC_SUM = $02FD

; WRITE srec records from the ACIA to the specified address locations
; in: none
; out: none
; clobbers: A, X, Y, flags
SREC_LOAD:
  ldx #$00

@load_char:
  jsr ACIA_GETC
  cmp #$0D
  beq @load_end
  sta SREC_LINE_IN,x
  inx
  jmp @load_char

@load_end:
  lda #$00
  sta SREC_LINE_IN,x

  ldx #$00
  lda SREC_LINE_IN,x
  cmp #'S'
  beq @line_ok
  jmp @error

@line_ok:
  inx
  lda SREC_LINE_IN,x
  cmp #'1'
  beq @parse_s1
  cmp #'9'
  beq @end
  jmp @error

@end:
  lda #'.'
  jsr ACIA_PUTC
  rts

@error:
  lda #'!'
  jsr ACIA_PUTC
  rts

@parse_s1:
  inx
  jsr @parse_byte
  bcs @error
  sta SREC_CTR
  sta SREC_SUM
  
  inx
  jsr @parse_byte
  bcs @error
  sta SREC_LOC_HI
  jsr @add_sum

  inx
  jsr @parse_byte
  bcs @error
  sta SREC_LOC_LO
  jsr @add_sum

  ldy #$00
  dec SREC_CTR
  dec SREC_CTR
  dec SREC_CTR

@parse_data:
  beq @checksum

  inx
  jsr @parse_byte
  bcs @error
  sta (SREC_LOC_LO),y
  jsr @add_sum

  iny
  dec SREC_CTR
  jmp @parse_data

@checksum:
  inx 
  jsr @parse_byte
  bcs @error
  jsr @add_sum
  
  lda SREC_SUM
  cmp #$FF
  bne @error

  lda #'.'
  jsr ACIA_PUTC
  jmp SREC_LOAD

@parse_byte:
  lda SREC_LINE_IN,x
  jsr @parse_hex_char
  bcs @bad_byte
  asl
  asl
  asl
  asl
  sta SREC_SCRATCH

  inx
  lda SREC_LINE_IN,x
  jsr @parse_hex_char
  bcs @bad_byte

  ora SREC_SCRATCH
  clc
  rts

@bad_byte:
  sec
  rts

@parse_hex_char:
  cmp #'A'
  bcc @parse_digit
  cmp #'G'
  bcs @bad_hex
  sec
  sbc #('A' - 10)
  clc
  rts
@parse_digit:
  sec
  sbc #'0'
  clc
  rts

@bad_hex:
  sec
  rts

@add_sum:
  clc
  adc SREC_SUM
  sta SREC_SUM
  rts
