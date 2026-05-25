.include "include/compy6502.inc"

; Read and edit one line of input.
; in:  A     = prompt character
;      K_PTR = Pascal string buffer
; out: none
; clobbers: A, X, flags
line_edit:
  jsr ACIA_PUTC

  lda #' '
  jsr ACIA_PUTC

  jsr STR_INIT

@load_char:
  jsr ACIA_GETC
  cmp #$0D
  beq @load_end

  cmp #$08
  beq @backspace

  cmp #$7F
  beq @backspace

  pha
  jsr ACIA_PUTC
  pla

  jsr STR_APPEND
  jmp @load_char

@backspace:
  jsr STR_LEN
  beq @load_char

  jsr STR_POP

  lda #$08
  jsr ACIA_PUTC
  lda #' '
  jsr ACIA_PUTC
  lda #$08
  jsr ACIA_PUTC
  jmp @load_char

@load_end:
  rts
