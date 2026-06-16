; K_PTR += K_LEN
; clobbers: A, flags
add16_ptr_len:
  lda K_PTR_LO
  clc
  adc K_LEN_LO
  sta K_PTR_LO
  lda K_PTR_HI
  adc K_LEN_HI
  sta K_PTR_HI
  rts

; K_PTR -= K_LEN
; clobbers: A, flags
sub16_ptr_len:
  lda K_PTR_LO
  sec
  sbc K_LEN_LO
  sta K_PTR_LO
  lda K_PTR_HI
  sbc K_LEN_HI
  sta K_PTR_HI
  rts

; K_PTR2 += K_LEN
; clobbers: A, flags
add16_ptr2_len:
  lda K_PTR2_LO
  clc
  adc K_LEN_LO
  sta K_PTR2_LO
  lda K_PTR2_HI
  adc K_LEN_HI
  sta K_PTR2_HI
  rts
