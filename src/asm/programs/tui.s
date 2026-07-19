.setcpu "65c02"

.include "include/compy6502.inc"

MODE_SWITCH = $FF
MODE_TUI    = $01
KIND_PANEL   = $01
KIND_HPANEL  = $02
KIND_VPANEL  = $03
KIND_LABEL   = $04
KIND_ITEM    = $05
KIND_LISTBOX = $06
TUI_DESTROY  = $11
TUI_CREATE   = $10
TUI_SET      = $12
TUI_REVERT   = $1E
TUI_COMMIT   = $1F

PROP_X         = $00
PROP_Y         = $01
PROP_WIDTH     = $02
PROP_HEIGHT    = $03
PROP_VISIBLE   = $04
PROP_FOCUS     = $05
PROP_TEXT_HDL  = $06
PROP_FLEX      = $07

.org $1000
  lda #SPI_CLK_125K
  ora #SPI_CS_SEL3
  jsr SPI_CONFIGURE
  bcc :+
  jmp @error
:

  jsr tui_mode
  bcc :+
  jmp @error
:

; --- Layout: two panels, left 66%, right 33% ---
  lda #KIND_PANEL
  ldx #$01
  ldy #$00
  jsr tui_create             ; create 0x01 panel under root
  bcc :+
  jmp @error
:
  lda #KIND_PANEL
  ldx #$02
  ldy #$00
  jsr tui_create             ; create 0x02 panel under root
  bcc :+
  jmp @error
:

; set left panel (0x02, first in child list) flex=2
  lda #$02
  ldx #PROP_FLEX
  ldy #2
  jsr tui_set
  bcc :+
  jmp @error
:

; set right panel (0x01, second in child list) flex=1
  lda #$01
  ldx #PROP_FLEX
  ldy #1
  jsr tui_set
  bcc :+
  jmp @error
:

; set both visible
  lda #$01
  ldx #PROP_VISIBLE
  ldy #1
  jsr tui_set
  bcc :+
  jmp @error
:
  lda #$02
  ldx #PROP_VISIBLE
  ldy #1
  jsr tui_set
  bcc :+
  jmp @error
:

  jsr tui_commit
  bcc :+
  jmp @error
:

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

; Send a TUI create transaction.
; in:  A = kind, X = handle, Y = parent
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_create:
  pha
  jsr SPI_SELECT
  bcs @done
  lda #TUI_CREATE
  jsr SPI_WRITE
  pla
  jsr SPI_WRITE
  txa
  jsr SPI_WRITE
  tya
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
@done:
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

; Send a TUI destroy transaction.
; in:  A = handle
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_destroy:
  tax
  jsr SPI_SELECT
  bcs @done
  lda #TUI_DESTROY
  jsr SPI_WRITE
  txa
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
@done:
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

; Send a TUI set transaction.
; in:  A = handle, X = key, Y = value
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_set:
  pha
  jsr SPI_SELECT
  bcs @done
  lda #TUI_SET
  jsr SPI_WRITE
  pla
  jsr SPI_WRITE
  txa
  jsr SPI_WRITE
  tya
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
@done:
  rts
