.setcpu "65c02"

.include "include/compy6502.inc"

MODE_SWITCH = $FF
MODE_TUI    = $01

TUI_CREATE   = $10
TUI_REMOVE   = $11
TUI_SET_PROP = $12
TUI_SET_TEXT = $13
TUI_ABORT    = $1E
TUI_COMMIT   = $1F

TUI_TYPE_VBOX    = $01
TUI_TYPE_HBOX    = $02
TUI_TYPE_LABEL   = $03
TUI_TYPE_LISTBOX = $04
TUI_TYPE_ITEM    = $05

TUI_ROOT_HANDLE = $00

NODE_MAIN   = $01
NODE_TITLE  = $02
NODE_LIST   = $03
NODE_STATUS = $04

.org $1000
  lda #SPI_CLK_125K
  ora #SPI_CS_SEL3
  jsr SPI_CONFIGURE
  bcs @error

  jsr tui_mode
  bcs @error

  jsr tui_abort
  bcs @error

  lda #NODE_MAIN
  ldx #TUI_ROOT_HANDLE
  ldy #TUI_TYPE_VBOX
  jsr tui_create
  bcs @error

  lda #NODE_TITLE
  ldx #NODE_MAIN
  ldy #TUI_TYPE_LABEL
  jsr tui_create
  bcs @error

  lda #NODE_TITLE
  ldx #<title_text
  ldy #>title_text
  jsr tui_set_text_zp
  bcs @error

  lda #NODE_LIST
  ldx #NODE_MAIN
  ldy #TUI_TYPE_LISTBOX
  jsr tui_create
  bcs @error

  lda #NODE_STATUS
  ldx #NODE_MAIN
  ldy #TUI_TYPE_LABEL
  jsr tui_create
  bcs @error

  lda #NODE_STATUS
  ldx #<status_text
  ldy #>status_text
  jsr tui_set_text_zp
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
  lda #MODE_SWITCH
  jsr debug_hex_byte
  lda #' '
  jsr ACIA_PUTC
  lda #MODE_TUI
  jsr debug_hex_byte
  jsr PRINT_NEWLINE

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
  clc
@done:
  rts

; Print one byte as two ASCII hex characters.
; in:  A = byte
; out: none
; clobbers: A, X, flags, K_TMP5
debug_hex_byte:
  jsr BYTE_TO_HEX
  stx K_TMP5
  jsr ACIA_PUTC
  lda K_TMP5
  jsr ACIA_PUTC
  rts

; Create a retained UI node.
; in:  A = handle
;      X = parent handle
;      Y = node type
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags, K_TMP0-K_TMP2
tui_create:
  sta K_TMP0
  stx K_TMP1
  sty K_TMP2
  jsr SPI_SELECT
  bcs @done
  lda #TUI_CREATE
  jsr SPI_WRITE
  bcs @deselect
  lda K_TMP0
  jsr SPI_WRITE
  bcs @deselect
  lda K_TMP1
  jsr SPI_WRITE
  bcs @deselect
  lda K_TMP2
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
  clc
@done:
  rts

; Remove a retained UI node subtree.
; in:  A = handle
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags, K_TMP0
tui_remove:
  sta K_TMP0
  jsr SPI_SELECT
  bcs @done
  lda #TUI_REMOVE
  jsr SPI_WRITE
  bcs @deselect
  lda K_TMP0
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
  clc
@done:
  rts

; Set a byte property on a retained UI node.
; in:  A = handle
;      X = property key
;      Y = property value
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags, K_TMP0-K_TMP2
tui_set_prop:
  sta K_TMP0
  stx K_TMP1
  sty K_TMP2
  jsr SPI_SELECT
  bcs @done
  lda #TUI_SET_PROP
  jsr SPI_WRITE
  bcs @deselect
  lda K_TMP0
  jsr SPI_WRITE
  bcs @deselect
  lda K_TMP1
  jsr SPI_WRITE
  bcs @deselect
  lda K_TMP2
  jsr SPI_WRITE

@deselect:
  pha
  jsr SPI_DESELECT
  pla
  clc
@done:
  rts

; Set text from a Pascal string.
; in:  A = handle
;      X/Y = source Pascal string address lo/hi
; out: carry clear = success
;      carry set   = error
; clobbers: A, X, Y, flags, K_PTR, K_LEN, K_TMP0
tui_set_text_zp:
  sta K_TMP0
  stx K_PTR_LO
  sty K_PTR_HI
  ldy #0
  lda (K_PTR),y
  sta K_LEN_LO
  stz K_LEN_HI
  INC16 K_PTR
  lda K_TMP0
  jsr tui_set_text
  rts

; Set text on a retained UI node.
; in:  A     = handle
;      K_PTR = source text address
;      K_LEN = byte count
; out: carry clear = success
;      carry set   = error
; clobbers: A, Y, flags, K_PTR, K_LEN, K_TMP0
tui_set_text:
  sta K_TMP0
  jsr SPI_SELECT
  bcs @done
  lda #TUI_SET_TEXT
  jsr SPI_WRITE
  bcs @deselect
  lda K_TMP0
  jsr SPI_WRITE
  bcs @deselect
  lda K_LEN_LO
  jsr SPI_WRITE
  bcs @deselect
  lda K_LEN_HI
  jsr SPI_WRITE
  bcs @deselect

@loop:
  lda K_LEN_LO
  ora K_LEN_HI
  beq @deselect
  lda (K_PTR)
  jsr SPI_WRITE
  bcs @deselect
  INC16 K_PTR
  DEC16 K_LEN
  jmp @loop

@deselect:
  pha
  jsr SPI_DESELECT
  pla
  clc
@done:
  rts

; Apply staged retained-tree mutations.
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_commit:
  lda #TUI_COMMIT
  jsr tui_write_opcode
  rts

; Discard staged retained-tree mutations.
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
tui_abort:
  lda #TUI_ABORT
  jsr tui_write_opcode
  rts

; Write one TUI opcode as a complete command.
; in:  A = opcode
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags, K_TMP0
tui_write_opcode:
  sta K_TMP0
  jsr SPI_SELECT
  bcs @done
  lda K_TMP0
  jsr SPI_WRITE
  pha
  jsr SPI_DESELECT
  pla
  clc
@done:
  rts

title_text:
  .byte title_text_end - title_text_data
title_text_data:
  .byte "COMPY6502"
title_text_end:

status_text:
  .byte status_text_end - status_text_data
status_text_data:
  .byte "Ready"
status_text_end:
