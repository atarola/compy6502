.setcpu "65c02"

.include "include/compy6502.inc"

.org $1000
  lda #SPI_CLK_125K
  ora #SPI_CS_SEL3
  jsr SPI_CONFIGURE
  bcs @done

  lda #'1'
  jsr ACIA_PUTC
  jsr PRINT_NEWLINE
  lda #<txn_1
  ldx #>txn_1
  ldy #txn_1_end - txn_1
  jsr send_txn

  lda #'2'
  jsr ACIA_PUTC
  jsr PRINT_NEWLINE
  lda #<txn_2
  ldx #>txn_2
  ldy #txn_2_end - txn_2
  jsr send_txn

  lda #'3'
  jsr ACIA_PUTC
  jsr PRINT_NEWLINE
  lda #<txn_3
  ldx #>txn_3
  ldy #txn_3_end - txn_3
  jsr send_txn

  lda #'4'
  jsr ACIA_PUTC
  jsr PRINT_NEWLINE
  lda #<txn_4
  ldx #>txn_4
  ldy #txn_4_end - txn_4
  jsr send_txn

  lda #'8'
  jsr ACIA_PUTC
  jsr PRINT_NEWLINE
  lda #<txn_8
  ldx #>txn_8
  ldy #txn_8_end - txn_8
  jsr send_txn

  lda #'1'
  jsr ACIA_PUTC
  lda #'6'
  jsr ACIA_PUTC
  jsr PRINT_NEWLINE
  lda #<txn_16
  ldx #>txn_16
  ldy #txn_16_end - txn_16
  jsr send_txn

@done:
  jmp WOZMON

; Send one SPI transaction.
; in:  A = payload address lo
;      X = payload address hi
;      Y = byte count
; out: carry clear = success
;      carry set   = error
; clobbers: A, X, Y, flags, K_PTR, K_LEN
send_txn:
  sta K_PTR_LO
  stx K_PTR_HI
  sty K_LEN_LO
  stz K_LEN_HI

  jsr SPI_SELECT
  bcs @done

@loop:
  lda K_LEN_LO
  beq @deselect
  lda (K_PTR)
  jsr SPI_WRITE
  bcs @deselect
  INC16 K_PTR
  dec K_LEN_LO
  jmp @loop

@deselect:
  pha
  jsr SPI_DESELECT
  jsr delay
  pla
  clc
@done:
  rts

; Leave CS high long enough for RP2040-side diagnostics to observe it.
; in:  none
; out: none
; clobbers: A, flags
delay:
  lda #$FF
@loop:
  dec
  bne @loop
  rts

txn_1:
  .byte $A1
txn_1_end:

txn_2:
  .byte $B1, $B2
txn_2_end:

txn_3:
  .byte $C1, $C2, $C3
txn_3_end:

txn_4:
  .byte $D1, $D2, $D3, $D4
txn_4_end:

txn_8:
  .byte $E1, $E2, $E3, $E4, $E5, $E6, $E7, $E8
txn_8_end:

txn_16:
  .byte $F1, $F2, $F3, $F4, $F5, $F6, $F7, $F8
  .byte $F9, $FA, $FB, $FC, $FD, $FE, $FF, $00
txn_16_end:
