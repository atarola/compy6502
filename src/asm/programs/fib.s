.setcpu "65c02"

.include "include/compy6502.inc"

BASE = $0200

.org $3000
  ldx #$FF ; top of stack

  lda #' '
  jsr ACIA_PUTC

  lda #$01
  jsr push
  jsr peek
  jsr print_u8

  lda #$01
  jsr push
  jsr peek
  jsr print_u8

loop:
  jsr peek
  cmp #$80
  bcs end

  jsr dup
  jsr rot
  jsr add

  jsr peek
  jsr print_u8
 
  jmp loop

end:
  jmp $F500 ; back to wozmon

peek:
  lda BASE,x
  rts

push:
  dex
  sta BASE,x
  rts

pop:
  lda BASE,x
  inx
  rts

dup:
  jsr peek
  jsr push
  rts

rot:
  lda BASE,x
  inx 
  ldy BASE,x
  sta BASE,x
  tya
  inx 
  ldy BASE,x
  sta BASE,x
  tya
  dex
  dex
  sta BASE,x
  rts

add:
  jsr pop
  clc
  adc BASE,x
  sta BASE,x
  rts

print_u8:
  phx
  ldx #$00

@hundreds:
  cmp #100
  bcc @tens
  sec
  sbc #100
  inx
  jmp @hundreds

@tens:
  ldy #$00

@tens_sub:
  cmp #10
  bcc @emit
  sec
  sbc #10
  iny
  jmp @tens_sub

@emit:
  pha
  cpx #$00
  beq @maybe_tens
  txa
  clc
  adc #'0'
  jsr ACIA_PUTC

@maybe_tens:
  cpx #$00
  bne @print_tens
  cpy #$00
  beq @ones
  jmp @print_tens

@print_tens:
  tya
  clc
  adc #'0'
  jsr ACIA_PUTC

@ones:
  pla
  clc
  adc #'0'
  jsr ACIA_PUTC
  lda #' '
  jsr ACIA_PUTC
  plx
  rts
