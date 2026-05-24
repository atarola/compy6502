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
; ANSI key codes
;

ANSI_KEY_UP = $80
ANSI_KEY_DOWN = $81
ANSI_KEY_ACCEPT = $82
ANSI_KEY_CANCEL = $83
ANSI_KEY_EDIT = $84

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

; Emit cursor-up one line.
; in:  none
; out: none
; clobbers: A, flags
ANSI_UP = JUMP_BASE + (3 * 2)

; Emit cursor-down one line.
; in:  none
; out: none
; clobbers: A, flags
ANSI_DOWN = JUMP_BASE + (3 * 3)

; Emit carriage return.
; in:  none
; out: none
; clobbers: A, flags
ANSI_CR = JUMP_BASE + (3 * 4)

; Emit carriage return + line feed.
; in:  none
; out: none
; clobbers: A, flags
ANSI_CRLF = JUMP_BASE + (3 * 5)

; Clear the current terminal line.
; in:  none
; out: none
; clobbers: A, flags
ANSI_CLEAR_LINE = JUMP_BASE + (3 * 6)

; Return to column 0 and clear the current terminal line.
; in:  none
; out: none
; clobbers: A, flags
ANSI_CR_CLEAR_LINE = JUMP_BASE + (3 * 7)

; Clear a Pascal string.
; in:  K_PTR = Pascal string buffer
; out: none
; clobbers: A, Y, flags
STR_INIT = JUMP_BASE + (3 * 8)

; Read the current Pascal string length.
; in:  K_PTR = Pascal string buffer
; out: A = length
; clobbers: A, Y, flags
STR_LEN = JUMP_BASE + (3 * 9)

; Append one byte to a Pascal string.
; in:  K_PTR = Pascal string buffer
;      A     = byte to append
; out: carry clear = appended
;      carry set   = no room / append failed
; clobbers: A, X, Y, flags
STR_APPEND = JUMP_BASE + (3 * 10)

; Remove the last byte from a Pascal string.
; in:  K_PTR = Pascal string buffer
; out: A = removed byte
;      carry clear = removed
;      carry set   = string was empty
; clobbers: A, Y, flags
STR_POP = JUMP_BASE + (3 * 11)

; Compare two Pascal strings for equality.
; in:  K_PTR  = left Pascal string
;      K_PTR2 = right Pascal string
; out: carry clear = equal
;      carry set   = not equal
; clobbers: A, X, Y, flags
STR_EQ = JUMP_BASE + (3 * 12)

; Reset line editor state.
; Clears the buffer and draws an empty prompt line.
; in:  K_PTR  = Pascal string buffer
;      K_TMP3 = prompt character
; out: none
; clobbers: A, flags
LINE_RESET = JUMP_BASE + (3 * 13)

; Run simple interactive line input.
; in:  K_PTR = Pascal string buffer
;      A     = prompt character
; out: A = $0D on accept
; clobbers: A, X, Y, flags
LINE_INPUT = JUMP_BASE + (3 * 14)

; Convert byte to ASCII hex characters.
; in:  A = byte
; out: A = high ASCII hex character
;      X = low ASCII hex character
; clobbers: flags
BYTE_TO_HEX = JUMP_BASE + (3 * 15)

; Convert ASCII hex character to nibble.
; in:  A = ASCII hex character
; out: A = nibble
;      carry clear = valid
;      carry set = invalid
; clobbers: flags
HEX_TO_NIBBLE = JUMP_BASE + (3 * 16)

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
