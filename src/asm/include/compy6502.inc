;
; compy6502 public ABI constants
;

.ifndef COMPY6502_INC
COMPY6502_INC = 1

;
; wozmon monitor
;

WOZMON = $F500

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
