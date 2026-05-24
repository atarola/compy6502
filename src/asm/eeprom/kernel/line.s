.include "include/compy6502.inc"

; Reset line editor state.
; Clears the buffer and draws an empty prompt line.
; in:  K_PTR  = Pascal string buffer
;      K_TMP3 = prompt character
; out: none
; clobbers: A, flags
line_reset:
  jsr str_init
  jsr ansi_cr_clear_line

  lda K_TMP3
  jsr ACIA_PUTC
  lda #' '
  jsr ACIA_PUTC
  
  rts

; Run simple interactive line input.
; in:  K_PTR = Pascal string buffer
;      A     = prompt character
; out: A = $0D on accept
; clobbers: A, X, Y, flags
line_input:
  sta K_TMP3
  jsr line_reset

@loop:
  jsr ACIA_GETC
  cmp #$0D
  beq @loop_end

  cmp #$08
  beq @backspace

  cmp #$7F
  beq @backspace

  pha
  jsr STR_APPEND
  bcs @append_failed
  pla
  
  jsr ACIA_PUTC
  jmp @loop

@append_failed:
  pla
  jsr line_reset
  jmp @loop

@backspace:
  jsr STR_POP
  bcs @loop

  lda #$08
  jsr ACIA_PUTC
  lda #' '
  jsr ACIA_PUTC
  lda #$08
  jsr ACIA_PUTC
  jmp @loop

@loop_end:
  rts
