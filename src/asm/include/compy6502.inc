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
; FRAM Filesystem
;
; $0000           super block (5 bytes)
; $0005 to FREE   data slab (append-only, grows up)
; FREE to IDX     free area
; IDX to $FFFF    index (24-byte entries, grows down)
;
; FREE = FS_SB_DATA_PTR, IDX = FS_SB_INDEX_PTR (both tracked in the super block)
; file ID = FRAM address of index entry, returned by FS_FIND
;

; Super Block (at FRAM offset $0000, 5 bytes)
FS_SB_DATA_PTR      = $00   ; 2 bytes lo/hi, next free address in data slab
FS_SB_INDEX_PTR     = $02   ; 2 bytes lo/hi, address of the start of the index region (lowest entry in use)
FS_SB_CRC           = $04   ; 1 byte, zero-sum of all above bytes

FS_SB_SIZE          = $05   ; total super block size in bytes

; Index entry types
FS_ENTRY_VOL_ID     = $01
FS_ENTRY_START      = $02
FS_ENTRY_UNUSED     = $10
FS_ENTRY_FILE       = $12
FS_ENTRY_FILE_DEL   = $1A

FS_ENTRY_SIZE       = $18   ; 24 bytes, fixed stride for all entry types

; File Entry
FS_FILE_TYPE        = $00   ; 1 byte
FS_FILE_START       = $01   ; 2 bytes lo/hi, FRAM address of file data
FS_FILE_LEN         = $03   ; 2 bytes lo/hi, file size in bytes
FS_FILE_ADDR        = $05   ; 2 bytes lo/hi, expected RAM load address
FS_FILE_NAME        = $07   ; 16 bytes, pascal string (1 len + 15 chars)
FS_FILE_CRC         = $17   ; 1 byte, zero-sum of all 24 bytes

; Vol ID entry
FS_VOL_TYPE         = $00   ; 1 byte
FS_VOL_NAME         = $01   ; 16 bytes, pascal string (1 len + 15 chars)
                            ; $11: 6 bytes reserved
FS_VOL_CRC          = $17   ; 1 byte

; Start Marker / Unused entry
FS_SM_TYPE          = $00   ; 1 byte
                            ; $01: 22 bytes reserved
FS_SM_CRC           = $17   ; 1 byte

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

; iterator state: cursor, stop boundary, stride, callback ptr
; kept separate from the transient scratch below since it must
; survive calls made between _next invocations
K_ITER_CUR_LO = $08
K_ITER_CUR_HI = $09
K_ITER_CUR = K_ITER_CUR_LO

K_ITER_STOP_LO = $0A
K_ITER_STOP_HI = $0B
K_ITER_STOP = K_ITER_STOP_LO

K_ITER_STRIDE_LO = $0C
K_ITER_STRIDE_HI = $0D
K_ITER_STRIDE = K_ITER_STRIDE_LO

K_ITER_CB_LO = $0E
K_ITER_CB_HI = $0F
K_ITER_CB = K_ITER_CB_LO

; clobberable scratch
K_TMP0 = $1A
K_TMP1 = $1B
K_TMP2 = $1C
K_TMP3 = $1D
K_TMP4 = $1E
K_TMP5 = $1F

; Kernel entry jump table
; can `jsr ACIA_GETC` to execute these subroutines
;
; Each entry is the previous one + 3 (one jmp slot) rather than a fixed
; JUMP_BASE + (3 * N) literal, so inserting or removing an entry never
; requires renumbering the ones after it.
JUMP_BASE = $C100

; Re-enter the monitor. A fixed, memorable address ($C100) to type by
; hand from the terminal -- the monitor itself isn't at a fixed address,
; it's packed wherever the linker puts it within KERNEL.
; in:  none
; out: none (does not return)
WOZMON = JUMP_BASE

; Write byte to ACIA.
; in:  A = byte
; out: none
; clobbers: A, flags
ACIA_PUTC = WOZMON + 3

; Read byte from ACIA.
; in:  none
; out: A = byte
; clobbers: A, flags
ACIA_GETC = ACIA_PUTC + 3

; Clear a Pascal string.
; in:  K_PTR = Pascal string buffer
; out: none
; clobbers: A, Y, flags
STR_INIT = ACIA_GETC + 3

; Read the current Pascal string length.
; in:  K_PTR = Pascal string buffer
; out: A = length
; clobbers: A, Y, flags
STR_LEN = STR_INIT + 3

; Append one byte to a Pascal string.
; in:  K_PTR = Pascal string buffer
;      A     = byte to append
; out: carry clear = appended
;      carry set   = no room / append failed
; clobbers: A, X, Y, flags
STR_APPEND = STR_LEN + 3

; Remove the last byte from a Pascal string.
; in:  K_PTR = Pascal string buffer
; out: A = removed byte
;      carry clear = removed
;      carry set   = string was empty
; clobbers: A, Y, flags
STR_POP = STR_APPEND + 3

; Compare two Pascal strings for equality.
; in:  K_PTR  = left Pascal string
;      K_PTR2 = right Pascal string
; out: carry clear = equal
;      carry set   = not equal
; clobbers: A, X, Y, flags
STR_EQ = STR_POP + 3

; Copy one Pascal string to another.
; in:  K_PTR  = destination Pascal string
;      K_PTR2 = source Pascal string
; out: none
; clobbers: A, X, Y, flags
STR_COPY = STR_EQ + 3

; Copy a span into a Pascal string.
; in:  K_PTR  = destination Pascal string
;      K_PTR2 = source span start
;      A      = source span length
; out: none
; clobbers: A, X, Y, flags
SPAN_TO_STR = STR_COPY + 3

; Convert byte to ASCII hex characters.
; in:  A = byte
; out: A = high ASCII hex character
;      X = low ASCII hex character
; clobbers: flags
BYTE_TO_HEX = SPAN_TO_STR + 3

; Convert ASCII hex character to nibble.
; in:  A = ASCII hex character
; out: A = nibble
;      carry clear = valid
;      carry set = invalid
; clobbers: flags
HEX_TO_NIBBLE = BYTE_TO_HEX + 3

; Read and edit one line of input.
; in:  A     = prompt character
;      K_PTR = Pascal string buffer
; out: none
; clobbers: A, X, flags
LINE_EDIT = HEX_TO_NIBBLE + 3

; Update SPI configuration.
; in:  A = configuration byte
; out: carry clear = configuration applied
;      carry set   = configuration failed
; clobbers: A, flags
SPI_CONFIGURE = LINE_EDIT + 3

; Assert the configured SPI chip select.
; in: none
; out: carry clear = released
;      carry set   = failed
; clobbers: A, flags
SPI_SELECT = SPI_CONFIGURE + 3

; Release the configured SPI chip select.
; in: none
; out: carry clear = released
;      carry set   = failed
; clobbers: A, flags
SPI_DESELECT = SPI_SELECT + 3

; Transfer one SPI byte.
; in:  A = byte to transmit
; out: A = received byte
;      carry clear = success
;      carry set   = transfer failed
; clobbers: A, flags
SPI_TRANSFER = SPI_DESELECT + 3

; Transfer one SPI byte.
; in:  A = byte to transmit
; out: carry clear = success
;      carry set   = transfer failed
; clobbers: A, flags
SPI_WRITE = SPI_TRANSFER + 3

; Initialize the FRAM for normal use.
; in:  none
; out: carry clear = initialized
;      carry set   = initialization failed
; clobbers: A, flags
FRAM_SETUP = SPI_WRITE + 3

; Write a RAM chunk to FRAM.
; in:  K_PTR  = source RAM address
;      K_PTR2 = destination FRAM address
;      K_LEN  = byte count
; out: carry clear = written
;      carry set   = write failed
; clobbers: A, Y, flags, K_PTR, K_LEN
FRAM_WRITE_CHUNK = FRAM_SETUP + 3

; Read a FRAM chunk into RAM.
; in:  K_PTR  = destination RAM address
;      K_PTR2 = source FRAM address
;      K_LEN  = byte count
; out: carry clear = read
;      carry set   = read failed
; clobbers: A, Y, flags, K_PTR, K_LEN
FRAM_READ_CHUNK = FRAM_WRITE_CHUNK + 3

; Compute zero-sum CRC over N bytes in RAM.
; in:  K_PTR = address of buffer
;      K_LEN = byte count
; out: A = CRC byte (store in entry to make 24-byte sum zero)
; clobbers: A, flags
CRC = FRAM_READ_CHUNK + 3

; Copy K_LEN bytes from K_PTR to K_PTR2.
; in:  K_PTR  = source address
;      K_PTR2 = destination address
;      K_LEN  = byte count
; clobbers: A, flags, K_PTR, K_PTR2, K_LEN
MEM_COPY = CRC + 3

; Set up a fixed-stride iterator's cursor, stop boundary, and stride.
; in:  K_PTR2 = start cursor address
;      K_TMP2/K_TMP3 = stop boundary address (lo/hi)
;      A = stride (bytes per step)
; out: none
; clobbers: A, flags
ITER_INIT = MEM_COPY + 3

; Advance the iterator and return the next item address.
; in:  none (uses K_ITER_CUR/K_ITER_STOP/K_ITER_STRIDE)
; out: carry clear = item available, K_PTR2 = item address
;      carry set   = iteration complete
; clobbers: A, flags
ITER_NEXT = ITER_INIT + 3

; Advance the iterator downward and return the next item address.
; in:  none (uses K_ITER_CUR/K_ITER_STOP/K_ITER_STRIDE)
; out: carry clear = item available, K_PTR2 = item address
;      carry set   = iteration complete
; clobbers: A, flags
ITER_NEXT_DOWN = ITER_NEXT + 3

; Walk the iterator to completion, invoking a callback for each item.
; in:  K_ITER_CB = callback address (called once per item, K_PTR2 = item address)
; out: carry clear = success
;      carry set   = error (propagated from a callback, if any)
; clobbers: A, X, Y, flags, K_PTR2
ITER_FOR_EACH = ITER_NEXT_DOWN + 3

; Print a buffer as space-separated ASCII hex bytes.
; in:  K_PTR = buffer, K_LEN = byte count
; clobbers: A, X, flags, K_PTR, K_LEN
HEX_DUMP = ITER_FOR_EACH + 3

; Print a CRLF to the ACIA.
; in:  none
; out: none
; clobbers: A, flags
PRINT_NEWLINE = HEX_DUMP + 3

; Print the name of the file at K_PTR2, then a newline.
; in:  K_PTR2 = file ID (FRAM address of index entry)
; clobbers: A, X, Y, flags, K_PTR, K_LEN
PRINT_FILE_NAME = PRINT_NEWLINE + 3

; Initialize a fresh FRAM volume.
; in:  K_PTR = pascal string for volume name
; out: carry clear = success
;      carry set   = error
; clobbers: A, Y, flags, K_PTR, K_PTR2, K_LEN
FS_FORMAT = PRINT_FILE_NAME + 3

; Find a file by name in the index.
; in:  K_PTR2 = pascal string filename
; out: carry clear = success, K_PTR2 = file ID (FRAM address of index entry)
;      carry set   = not found
; clobbers: A, X, Y, flags, K_PTR2
FS_FIND = FS_FORMAT + 3

; Read file data into RAM.
; in:  K_PTR  = destination RAM address
;      K_PTR2 = file ID (FRAM address of index entry)
; out: carry clear = success
;      carry set   = error
; clobbers: A, Y, flags, K_PTR, K_LEN
FS_READ = FS_FIND + 3

; Read the super block into K_BUF.
; in:  none
; out: carry clear = success, carry set = error
; clobbers: A, Y, flags, K_PTR, K_PTR2, K_LEN
FS_READ_SB = FS_READ + 3

; Append a new file to the volume.
; in:  K_PTR  = source RAM address (file data)
;      K_PTR2 = pascal string filename
;      K_LEN  = file length in bytes
; out: carry clear = success
;      carry set   = error
; clobbers: A, Y, flags, K_PTR, K_LEN
FS_WRITE = FS_READ_SB + 3

; Tombstone a file index entry.
; in:  K_PTR2 = file ID (FRAM address of index entry)
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags, K_PTR, K_LEN, K_TMP0
FS_DELETE = FS_WRITE + 3

; Replace a file's contents (delete + write).
; in:  K_PTR  = source RAM address (new file data)
;      K_PTR2 = file ID (FRAM address of index entry)
;      K_LEN  = new file length in bytes
; out: carry clear = success
;      carry set   = error
; clobbers: A, X, Y, flags, K_PTR, K_PTR2, K_LEN, K_TMP0, K_TMP1, K_TMP2, K_TMP3, K_TMP4, K_TMP5
FS_UPDATE = FS_DELETE + 3

; Defragment the data slab and rebuild the index.
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, X, Y, flags, K_PTR, K_PTR2, K_LEN, K_TMP0, K_TMP1, K_TMP2, K_TMP3, K_TMP4, K_TMP5
FS_COMPACT = FS_UPDATE + 3

; Dump the super block and all index entries to the ACIA.
; in:  none
; out: carry clear = success, carry set = error
; clobbers: A, X, Y, flags, K_PTR, K_PTR2, K_LEN, K_TMP0, K_TMP1
FS_DUMP = FS_COMPACT + 3

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

; compare two 16-bit lo/hi pairs; sets flags as if by CMP lhs - rhs (BCC/BEQ/BCS usable as a 16-bit comparison)
.macro CMP16 lhs, rhs
  lda lhs+1
  cmp rhs+1
  bne :+
  lda lhs
  cmp rhs
:
.endmacro

; dst += src (both 16-bit lo/hi pairs)
.macro ADD16 dst, src
  lda dst
  clc
  adc src
  sta dst
  lda dst+1
  adc src+1
  sta dst+1
.endmacro

; dst -= src (both 16-bit lo/hi pairs)
.macro SUB16 dst, src
  lda dst
  sec
  sbc src
  sta dst
  lda dst+1
  sbc src+1
  sta dst+1
.endmacro

.endif
