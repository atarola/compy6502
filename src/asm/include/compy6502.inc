;
; compy6502 public ABI constants
;

.ifndef COMPY6502_INC
COMPY6502_INC = 1

;
; ACIA
;

ACIA_BASE           = $C000
ACIA_DATA           = ACIA_BASE + 0
ACIA_STATUS         = ACIA_BASE + 1
ACIA_COMMAND        = ACIA_BASE + 2
ACIA_CONTROL        = ACIA_BASE + 3

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

.endif