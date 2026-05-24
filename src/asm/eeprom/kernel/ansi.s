.include "include/compy6502.inc"

; Emit cursor-up one line.
; in:  none
; out: none
; clobbers: A, flags
ansi_up:
  lda #$1B
  jsr ACIA_PUTC
  lda #'['
  jsr ACIA_PUTC
  lda #'A'
  jsr ACIA_PUTC
  rts

; Emit cursor-down one line.
; in:  none
; out: none
; clobbers: A, flags
ansi_down:
  lda #$1B
  jsr ACIA_PUTC
  lda #'['
  jsr ACIA_PUTC
  lda #'B'
  jsr ACIA_PUTC
  rts

; Emit carriage return.
; in:  none
; out: none
; clobbers: A, flags
ansi_cr:
  lda #$0D
  jsr ACIA_PUTC
  rts

; Emit carriage return + line feed.
; in:  none
; out: none
; clobbers: A, flags
ansi_crlf:
  jsr ansi_cr
  lda #$0A
  jsr ACIA_PUTC
  rts

; Clear the current terminal line.
; in:  none
; out: none
; clobbers: A, flags
ansi_clear_line:
  lda #$1B
  jsr ACIA_PUTC
  lda #'['
  jsr ACIA_PUTC
  lda #'2'
  jsr ACIA_PUTC
  lda #'K'
  jsr ACIA_PUTC
  rts

; Return to column 0 and clear the current terminal line.
; in:  none
; out: none
; clobbers: A, flags
ansi_cr_clear_line:
  jsr ansi_cr
  jsr ansi_clear_line
  jsr ansi_cr
  rts
