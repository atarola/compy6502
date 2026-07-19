.setcpu "65c02"

.include "include/compy6502.inc"

MODE_SWITCH = $FF
MODE_TUI    = $01

.org $1000
  lda #SPI_CLK_125K
  ora #SPI_CS_SEL3
  jsr SPI_CONFIGURE
  bcs @error

  jsr tui_mode
  bcs @error

@done:
  jmp WOZMON

@error:
  jmp WOZMON

; Switch display processor to TUI mode.
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_mode:
  jsr SPI_SELECT
  bcs @done
  lda #MODE_SWITCH
  jsr SPI_WRITE
  bcs @deselect
  lda #MODE_TUI
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
@done:
  rts
