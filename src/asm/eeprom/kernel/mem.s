.include "include/compy6502.inc"

; Compute zero-sum CRC over N bytes in RAM.
; in:  K_PTR = address of buffer
;      K_LEN = byte count
; out: A = CRC byte (store in entry to make 24-byte sum zero)
; clobbers: A, flags
crc:
  lda #$00
  sta K_TMP0

@loop:
  lda K_LEN_LO
  ora K_LEN_HI
  beq @end

  lda (K_PTR)
  clc
  adc K_TMP0
  sta K_TMP0

  INC16 K_PTR
  DEC16 K_LEN

  jmp @loop

@end:
  lda #$00
  sec
  sbc K_TMP0

  clc
  rts

; Copy K_LEN bytes from K_PTR to K_PTR2.
; in:  K_PTR  = source address
;      K_PTR2 = destination address
;      K_LEN  = byte count
; clobbers: A, flags, K_PTR, K_PTR2, K_LEN
mem_copy:
@loop:
  lda K_LEN_LO
  ora K_LEN_HI
  beq @end

  lda (K_PTR)
  sta (K_PTR2)

  INC16 K_PTR
  INC16 K_PTR2
  DEC16 K_LEN

  jmp @loop

@end:
  rts
