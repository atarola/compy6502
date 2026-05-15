.setcpu "65c02"

.include "include/compy6502.inc"

.org $3000
.byte $0D, $0A, "Hello World!", $0D, $0A, $00

.org $4000
  ldx #$00

loop:  
  lda $3000,x
  beq end
  sta ACIA_DATA

  lda #$FF
delay:        
  dec
  bne delay
  inx
  jmp loop

end:
  jmp $F500 ; back to wozmon
