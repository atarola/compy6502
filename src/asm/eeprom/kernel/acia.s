
.include "include/compy6502.inc"

; Write byte to ACIA.
; in:  A = byte
; out: none
; clobbers: A, flags
acia_putc:
  sta ACIA_DATA
  lda #$FF
@delay:        
  dec
  bne @delay
  rts

; Read byte from ACIA.
; in:  none
; out: A = byte
; clobbers: A, flags
acia_getc:
@wait:
  lda ACIA_STATUS
  and #$08
  beq @wait
  lda ACIA_DATA
  rts
