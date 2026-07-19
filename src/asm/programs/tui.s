.setcpu "65c02"

.include "include/compy6502.inc"

MODE_SWITCH = $FF
MODE_TUI    = $01
KIND_PANEL   = $01
KIND_HPANEL  = $02
KIND_VPANEL  = $03
TUI_DESTROY  = $11
TUI_REVERT   = $1E
TUI_COMMIT   = $1F
TUI_CREATE   = $10

.org $1000
  lda #SPI_CLK_125K
  ora #SPI_CS_SEL3
  jsr SPI_CONFIGURE
  bcs @error

  jsr tui_mode
  bcs @error

  jsr tui_create_01
  bcs @error

  jsr tui_revert
  bcs @error

  jsr tui_create_02
  bcs @error

  jsr tui_commit
  bcs @error

  jsr tui_destroy_02
  bcs @error

  jsr tui_create_03
  bcs @error

  jsr tui_commit
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

; Send a TUI create transaction for handle 0x01.
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_create_01:
  jsr SPI_SELECT
  bcs @create_01_done
  lda #TUI_CREATE
  jsr SPI_WRITE
  lda #KIND_PANEL
  jsr SPI_WRITE
  lda #$01
  jsr SPI_WRITE
  lda #$00
  jsr SPI_WRITE

@create_01_deselect:
  pha
  jsr SPI_DESELECT
  pla
@create_01_done:
  rts

; Send a TUI create transaction for handle 0x02.
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_create_02:
  jsr SPI_SELECT
  bcs @create_02_done
  lda #TUI_CREATE
  jsr SPI_WRITE
  lda #KIND_HPANEL
  jsr SPI_WRITE
  lda #$02
  jsr SPI_WRITE
  lda #$00
  jsr SPI_WRITE

@create_02_deselect:
  pha
  jsr SPI_DESELECT
  pla
@create_02_done:
  rts

; Send a TUI create transaction for handle 0x03.
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_create_03:
  jsr SPI_SELECT
  bcs @create_03_done
  lda #TUI_CREATE
  jsr SPI_WRITE
  lda #KIND_VPANEL
  jsr SPI_WRITE
  lda #$03
  jsr SPI_WRITE
  lda #$00
  jsr SPI_WRITE

@create_03_deselect:
  pha
  jsr SPI_DESELECT
  pla
@create_03_done:
  rts

; Send a TUI revert transaction.
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_revert:
  jsr SPI_SELECT
  bcs @done
  lda #TUI_REVERT
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
@done:
  rts

; Send a TUI destroy transaction for handle 0x02.
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_destroy_02:
  jsr SPI_SELECT
  bcs @destroy_02_done
  lda #TUI_DESTROY
  jsr SPI_WRITE
  lda #$02
  jsr SPI_WRITE

@destroy_02_deselect:
  pha
  jsr SPI_DESELECT
  pla
@destroy_02_done:
  rts

; Send a TUI commit transaction.
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_commit:
  jsr SPI_SELECT
  bcs @done
  lda #TUI_COMMIT
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
@done:
  rts
