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

; Clear a Pascal string.
; in:  K_PTR = Pascal string buffer
; out: none
; clobbers: A, Y, flags
STR_INIT = JUMP_BASE + (3 * 2)

; Read the current Pascal string length.
; in:  K_PTR = Pascal string buffer
; out: A = length
; clobbers: A, Y, flags
STR_LEN = JUMP_BASE + (3 * 3)

; Append one byte to a Pascal string.
; in:  K_PTR = Pascal string buffer
;      A     = byte to append
; out: carry clear = appended
;      carry set   = no room / append failed
; clobbers: A, X, Y, flags
STR_APPEND = JUMP_BASE + (3 * 4)

; Remove the last byte from a Pascal string.
; in:  K_PTR = Pascal string buffer
; out: A = removed byte
;      carry clear = removed
;      carry set   = string was empty
; clobbers: A, Y, flags
STR_POP = JUMP_BASE + (3 * 5)

; Compare two Pascal strings for equality.
; in:  K_PTR  = left Pascal string
;      K_PTR2 = right Pascal string
; out: carry clear = equal
;      carry set   = not equal
; clobbers: A, X, Y, flags
STR_EQ = JUMP_BASE + (3 * 6)

; Convert byte to ASCII hex characters.
; in:  A = byte
; out: A = high ASCII hex character
;      X = low ASCII hex character
; clobbers: flags
BYTE_TO_HEX = JUMP_BASE + (3 * 7)

; Convert ASCII hex character to nibble.
; in:  A = ASCII hex character
; out: A = nibble
;      carry clear = valid
;      carry set = invalid
; clobbers: flags
HEX_TO_NIBBLE = JUMP_BASE + (3 * 8)

;
; Helper macros
; 

.macro INC_K_PTR
  inc K_PTR_LO
  bne :+
  inc K_PTR_HI
:
.endmacro

.macro DEC_K_PTR
  lda K_PTR_LO
  bne :+
  dec K_PTR_HI
:
  dec K_PTR_LO
.endmacro

.endif
