;
; compy6502 public ABI constants
;

.ifndef COMPY6502_INC
COMPY6502_INC = 1

;
; wozmon monitor
;

WOZMON = $F500
IRQ_DISPATCHER = irq_dispatch

;
; ACIA
;

ACIA_BASE = $C000
ACIA_DATA = ACIA_BASE + 0
ACIA_STATUS = ACIA_BASE + 1
ACIA_COMMAND = ACIA_BASE + 2
ACIA_CONTROL = ACIA_BASE + 3

;
; ROM ABI
;

; Kernel constants
; $00 thru $1F are reserved for kernel work

; userland IRQ hook, initalized to a noop
IRQ_HOOK_LO  = $00
IRQ_HOOK_HI  = $01
IRQ_HOOK = IRQ_HOOK_LO

K_PTR_LO = $02
K_PTR_HI = $03
K_PTR = K_PTR_LO

K_PTR2_LO = $04
K_PTR2_HI = $05
K_PTR2 = K_PTR2_LO

K_TMP0 = $06
K_TMP1 = $07
K_TMP2 = $08
K_TMP3 = $09

; Kernel entry jump table
; can `jsr ACIA_GETC` to execute these subroutines
JUMP_BASE = $C100

; Write byte to ACIA.
; in:  A = byte
; out: none
; clobbers: A, flags
ACIA_PUTC = JUMP_BASE + (3 * 0)

; Read byte from ACIA.
; in:  none
; out: A = byte
; clobbers: A, flags
ACIA_GETC = JUMP_BASE + (3 * 1)

; Convert byte to ASCII hex characters.
; in:  A = byte
; out: A = high ASCII hex character
;      X = low ASCII hex character
; clobbers: flags
BYTE_TO_HEX = JUMP_BASE + (3 * 2)

; Convert ASCII hex character to nibble.
; in:  A = ASCII hex character
; out: A = nibble
;      carry clear = valid
;      carry set = invalid
; clobbers: flags
HEX_TO_NIBBLE = JUMP_BASE + (3 * 3)

.endif
