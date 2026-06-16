;
; compy6502 public ABI constants
;

.ifndef COMPY6502_INC
COMPY6502_INC = 1

IO0_ADDR = $C000
IO1_ADDR = $C040
IO2_ADDR = $C080
IO3_ADDR = $C0C0

;
; wozmon monitor
;

WOZMON = $F500

;
; ACIA
;

ACIA_DATA = IO0_ADDR + 0
ACIA_STATUS = IO0_ADDR + 1
ACIA_COMMAND = IO0_ADDR + 2
ACIA_CONTROL = IO0_ADDR + 3

;
; SPI
;

SPI_DATA = IO1_ADDR + 0
SPI_CONFIG = IO1_ADDR + 1
SPI_STATUS = IO1_ADDR + 2

; chip select

SPI_CS_SEL0 = %00000000
SPI_CS_SEL1 = %00000001
SPI_CS_SEL2 = %00000010
SPI_CS_SEL3 = %00000011

SPI_CS_ENABLE = %00000100

; clock rate

SPI_CLK_125K = %00000000
SPI_CLK_250K = %00001000
SPI_CLK_500K = %00010000
SPI_CLK_1M   = %00011000

; SPI status register bits

SPI_BUSY      = %00000001

;
; ROM ABI
;

;
; RAM buffers
;

WOZMON_BUF = $0200  ; wozmon input buffer (256 bytes)
K_BUF      = $0300  ; kernel scratch buffer (256 bytes)

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

K_LEN_LO = $06
K_LEN_HI = $07
K_LEN = K_LEN_LO

; clobberable scratch
K_TMP0 = $08
K_TMP1 = $09
K_TMP2 = $0A
K_TMP3 = $0B

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

; Copy one Pascal string to another.
; in:  K_PTR  = destination Pascal string
;      K_PTR2 = source Pascal string
; out: none
; clobbers: A, X, Y, flags
STR_COPY = JUMP_BASE + (3 * 7)

; Copy a span into a Pascal string.
; in:  K_PTR  = destination Pascal string
;      K_PTR2 = source span start
;      A      = source span length
; out: none
; clobbers: A, X, Y, flags
SPAN_TO_STR = JUMP_BASE + (3 * 8)

; Convert byte to ASCII hex characters.
; in:  A = byte
; out: A = high ASCII hex character
;      X = low ASCII hex character
; clobbers: flags
BYTE_TO_HEX = JUMP_BASE + (3 * 9)

; Convert ASCII hex character to nibble.
; in:  A = ASCII hex character
; out: A = nibble
;      carry clear = valid
;      carry set = invalid
; clobbers: flags
HEX_TO_NIBBLE = JUMP_BASE + (3 * 10)

; Read and edit one line of input.
; in:  A     = prompt character
;      K_PTR = Pascal string buffer
; out: none
; clobbers: A, X, flags
LINE_EDIT = JUMP_BASE + (3 * 11)

; Update SPI configuration.
; in:  A = configuration byte
; out: carry clear = configuration applied
;      carry set   = configuration failed
; clobbers: A, flags
SPI_CONFIGURE = JUMP_BASE + (3 * 12)

; Assert the configured SPI chip select.
; in: none
; out: carry clear = released
;      carry set   = failed
; clobbers: A, flags
SPI_SELECT = JUMP_BASE + (3 * 13)

; Release the configured SPI chip select.
; in: none
; out: carry clear = released
;      carry set   = failed
; clobbers: A, flags
SPI_DESELECT = JUMP_BASE + (3 * 14)

; Transfer one SPI byte.
; in:  A = byte to transmit
; out: A = received byte
;      carry clear = success
;      carry set   = transfer failed
; clobbers: A, flags
SPI_TRANSFER = JUMP_BASE + (3 * 15)

; Transfer one SPI byte.
; in:  A = byte to transmit
; out: carry clear = success
;      carry set   = transfer failed
; clobbers: A, flags
SPI_WRITE = JUMP_BASE + (3 * 16)

; Initialize the FRAM for normal use.
; in:  none
; out: carry clear = initialized
;      carry set   = initialization failed
; clobbers: A, flags
FRAM_SETUP = JUMP_BASE + (3 * 17)

; Write a RAM chunk to FRAM.
; in:  K_PTR  = source RAM address
;      K_PTR2 = destination FRAM address
;      K_LEN  = byte count
; out: carry clear = written
;      carry set   = write failed
; clobbers: A, Y, flags, K_PTR, K_LEN
FRAM_WRITE_CHUNK = JUMP_BASE + (3 * 18)

; Read a FRAM chunk into RAM.
; in:  K_PTR  = destination RAM address
;      K_PTR2 = source FRAM address
;      K_LEN  = byte count
; out: carry clear = read
;      carry set   = read failed
; clobbers: A, Y, flags, K_PTR, K_LEN
FRAM_READ_CHUNK = JUMP_BASE + (3 * 19)

;
; Helper macros
; 

.macro INC16 ptr
  inc ptr
  bne :+
  inc ptr+1
:
.endmacro

.macro DEC16 ptr
  lda ptr
  bne :+
  dec ptr+1
:
  dec ptr
.endmacro

.endif
