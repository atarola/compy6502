.include "include/compy6502.inc"

; Convert a byte to two ASCII hex characters.
; in:  A = byte
; out: A = high ASCII hex character
;      X = low ASCII hex character
; clobbers: flags
byte_to_hex:
  pha
  lsr
  lsr
  lsr
  lsr
  jsr nibble_to_hex
  tax

  pla
  and #$0F
  jsr nibble_to_hex

  pha
  txa
  plx
  rts

; Convert an ASCII hex character to a nibble.
; in:  A = ASCII hex character
; out: A = nibble
;      carry clear = valid
;      carry set = invalid
; clobbers: flags
hex_to_nibble:
  cmp #'0'
  bcc @bad
  cmp #'9' + 1
  bcc @digit

  cmp #'A'
  bcc @lower
  cmp #'F' + 1
  bcc @upper

@lower:
  cmp #'a'
  bcc @bad
  cmp #'f' + 1
  bcs @bad
  sec
  sbc #'a' - 10
  clc
  rts

@upper:
  sec
  sbc #'A' - 10
  clc
  rts

@digit:
  sec
  sbc #'0'
  clc
  rts

@bad:
  sec
  rts

; Convert a low nibble to an ASCII hex character.
; in:  A = nibble
; out: A = ASCII hex character
; clobbers: flags
nibble_to_hex:
  and #$0F
  cmp #$0A
  bcc @digit
  clc
  adc #'A' - 10
  rts

@digit:
  clc
  adc #'0'
  rts
