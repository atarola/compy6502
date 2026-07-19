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

; --- Test 1: No-revert commit chain ---
  jsr tui_create_01        ; create 0x01 panel
  bcs @error
  jsr tui_commit           ; live: 0x01
  bcs @error

  jsr tui_create_02        ; create 0x02 hpanel
  bcs @error
  jsr tui_commit           ; live: 0x01, 0x02
  bcs @error

; --- Test 2: Double revert (harmless) ---
  jsr tui_create_03        ; create 0x03 vpanel
  bcs @error
  jsr tui_revert           ; revert: staged back to live
  bcs @error
  jsr tui_revert           ; second revert: no-op
  bcs @error
  jsr tui_commit           ; live: 0x01, 0x02
  bcs @error

; --- Test 3: Destroy nonexistent (no-op) ---
  lda #$04
  jsr tui_destroy          ; destroy 0x04: doesn't exist
  bcs @error
  jsr tui_commit           ; live: 0x01, 0x02 (unchanged)
  bcs @error

; --- Test 4: Destroy after commit ---
  lda #$02
  jsr tui_destroy          ; destroy 0x02
  bcs @error
  jsr tui_commit           ; live: 0x01
  bcs @error

; --- Test 5: Create-replace existing handle ---
  jsr tui_create_01h       ; create 0x01 hpanel (replaces panel)
  bcs @error
  jsr tui_commit           ; live: 0x01 hpanel
  bcs @error

; --- Test 6: Empty commit (no-op) ---
  jsr tui_commit           ; live: 0x01 hpanel (unchanged)
  bcs @error

; --- Test 7: Multiple creates, single commit ---
  jsr tui_create_02v       ; create 0x02 vpanel
  bcs @error
  jsr tui_create_03p       ; create 0x03 panel
  bcs @error
  jsr tui_commit           ; live: 0x01 hpanel, 0x03 panel, 0x02 vpanel
  bcs @error

; --- Test 8: Revert undoes all staged changes ---
  lda #$01
  jsr tui_destroy          ; destroy 0x01
  bcs @error
  lda #$02
  jsr tui_destroy          ; destroy 0x02
  bcs @error
  jsr tui_revert           ; revert: staged back to live
  bcs @error
  jsr tui_commit           ; live: 0x01 hpanel, 0x03 panel, 0x02 vpanel
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

; Send a TUI create transaction for handle 0x01 (panel).
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_create_01:
  jsr SPI_SELECT
  bcs @done
  lda #TUI_CREATE
  jsr SPI_WRITE
  lda #KIND_PANEL
  jsr SPI_WRITE
  lda #$01
  jsr SPI_WRITE
  lda #$00
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
@done:
  rts

; Send a TUI create transaction for handle 0x01 (hpanel).
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_create_01h:
  jsr SPI_SELECT
  bcs @done
  lda #TUI_CREATE
  jsr SPI_WRITE
  lda #KIND_HPANEL
  jsr SPI_WRITE
  lda #$01
  jsr SPI_WRITE
  lda #$00
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
@done:
  rts

; Send a TUI create transaction for handle 0x02 (hpanel).
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_create_02:
  jsr SPI_SELECT
  bcs @done
  lda #TUI_CREATE
  jsr SPI_WRITE
  lda #KIND_HPANEL
  jsr SPI_WRITE
  lda #$02
  jsr SPI_WRITE
  lda #$00
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
@done:
  rts

; Send a TUI create transaction for handle 0x02 (vpanel).
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_create_02v:
  jsr SPI_SELECT
  bcs @done
  lda #TUI_CREATE
  jsr SPI_WRITE
  lda #KIND_VPANEL
  jsr SPI_WRITE
  lda #$02
  jsr SPI_WRITE
  lda #$00
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
@done:
  rts

; Send a TUI create transaction for handle 0x03 (vpanel).
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_create_03:
  jsr SPI_SELECT
  bcs @done
  lda #TUI_CREATE
  jsr SPI_WRITE
  lda #KIND_VPANEL
  jsr SPI_WRITE
  lda #$03
  jsr SPI_WRITE
  lda #$00
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
@done:
  rts

; Send a TUI create transaction for handle 0x03 (panel).
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_create_03p:
  jsr SPI_SELECT
  bcs @done
  lda #TUI_CREATE
  jsr SPI_WRITE
  lda #KIND_PANEL
  jsr SPI_WRITE
  lda #$03
  jsr SPI_WRITE
  lda #$00
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
