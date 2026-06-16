.setcpu "65c02"

.include "include/compy6502.inc"

; FRAM Filesystem
;
; $0000           super block (9 bytes)
; $0000-RSVD      reserved area
; RSVD to FREE    data slab (append-only, grows up)
; FREE to IDX     free area
; IDX to $FFFF    index (24-byte entries, grows down)
;
; file ID = FRAM address of index entry, returned by fs_find

; Super Block (at FRAM offset $0000, 9 bytes)
FS_SB_TOTAL_BYTES   = $00   ; 2 bytes lo/hi, total FRAM size
FS_SB_RSVD_BYTES    = $02   ; 2 bytes lo/hi, reserved area size
FS_SB_DATA_SIZE     = $04   ; 2 bytes lo/hi, bytes used in data slab
FS_SB_INDEX_SIZE    = $06   ; 2 bytes lo/hi, bytes used in index
FS_SB_CRC           = $08   ; 1 byte, zero-sum of all above bytes

FS_SB_SIZE          = $09   ; total super block size in bytes

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

.org $1000
  jsr FRAM_SETUP
  bcs @error

  lda #<vol_name
  sta K_PTR_LO
  lda #>vol_name
  sta K_PTR_HI

  jsr fs_format
  bcs @error

  jsr fs_dump
  bcs @error

  jmp WOZMON

@error:
  lda #'!'
  jsr ACIA_PUTC

  jmp WOZMON


vol_name:
  .byte $05, "hello"

; Initialize a fresh FRAM volume.
; in:  K_PTR = pascal string for volume name
; out: carry clear = success
;      carry set   = error
; clobbers: A, Y, flags, K_PTR, K_PTR2, K_LEN
fs_format:
  ; stash the pointer to the pascal string
  lda K_PTR_LO
  sta K_TMP2
  lda K_PTR_HI
  sta K_TMP3

  ; --- write super block ---
  lda #<super_block
  sta K_PTR_LO
  lda #>super_block
  sta K_PTR_HI

  stz K_PTR2_LO
  stz K_PTR2_HI

  lda #FS_SB_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jsr FRAM_WRITE_CHUNK
  bcs @error

  ; --- write start index record ---
  lda #<start_index_record
  sta K_PTR_LO
  lda #>start_index_record
  sta K_PTR_HI

  ; size
  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  ; target
  lda #$FF
  sta K_PTR2_HI
  lda #$FF - (FS_ENTRY_SIZE * 2 - 1)
  sta K_PTR2_LO

  ; make it so
  jsr FRAM_WRITE_CHUNK
  bcs @error

  lda #$01
  sta K_BUF

  lda K_TMP2
  sta K_PTR2_LO
  lda K_TMP3
  sta K_PTR2_HI

  lda #$01
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  jsr STR_COPY

  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda #FS_ENTRY_SIZE - 1
  tay
  sta K_LEN_LO
  stz K_LEN_HI

  jsr fs_crc
  sta K_BUF, y

  ; stash the buffer in the right place
  lda #$FF
  sta K_PTR2_HI
  lda #$FF - (FS_ENTRY_SIZE - 1)
  sta K_PTR2_LO

  ; size
  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  jsr FRAM_WRITE_CHUNK
  bcs @error

  clc
  rts

@error:
  sec
  rts

; Scan index for a file by name.
; in:  K_PTR  = pascal string filename
; out: carry clear = found, K_PTR2 = file ID (FRAM address of index entry)
;      carry set   = not found
; clobbers: A, flags
fs_find:
  sec
  rts

; Read file data into RAM.
; in:  K_PTR  = destination RAM address
;      K_PTR2 = file ID (FRAM address of index entry)
; out: carry clear = success
;      carry set   = error
; clobbers: A, Y, flags, K_PTR, K_LEN
fs_read:
  sec
  rts

; Append a new file to the volume.
; in:  K_PTR  = source RAM address (file data)
;      K_PTR2 = pascal string filename
;      K_LEN  = file length in bytes
; out: carry clear = success
;      carry set   = error
; clobbers: A, Y, flags, K_PTR, K_LEN
fs_write:
  sec
  rts

; Tombstone a file index entry.
; in:  K_PTR2 = file ID (FRAM address of index entry)
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags
fs_delete:
  sec
  rts

; Replace a file's contents (delete + write).
; in:  K_PTR  = source RAM address (new file data)
;      K_PTR2 = file ID (FRAM address of index entry)
;      K_LEN  = new file length in bytes
; out: carry clear = success
;      carry set   = error
; clobbers: A, Y, flags, K_PTR, K_LEN
fs_update:
  sec
  rts

; Defragment the data slab and rebuild the index.
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, Y, flags
fs_compact:
  sec
  rts

; Compute zero-sum CRC over N bytes in RAM.
; in:  K_PTR = address of buffer
;      K_LEN = byte count
; out: A = CRC byte (store in entry to make 24-byte sum zero)
; clobbers: A, flags
fs_crc:
  lda #$00
  sta K_TMP0

@loop:
  lda K_LEN_LO
  ora K_LEN_HI
  beq @end

  lda (K_PTR)
  clc
  adc K_TMP0
  sta K_TMP0

  INC16 K_PTR
  DEC16 K_LEN

  jmp @loop

@end:
  lda #$00
  sec
  sbc K_TMP0

  clc
  rts

print_newline:
  lda #$0D
  jsr ACIA_PUTC
  lda #$0A
  jsr ACIA_PUTC
  rts

; in:  K_PTR = buffer, K_LEN = byte count
; clobbers: A, X, flags, K_PTR, K_LEN
hex_dump:
@loop:
  lda K_LEN_LO
  ora K_LEN_HI
  beq @end

  lda (K_PTR)
  jsr BYTE_TO_HEX
  jsr ACIA_PUTC
  txa
  jsr ACIA_PUTC

  lda #' '
  jsr ACIA_PUTC

  INC16 K_PTR
  DEC16 K_LEN
  jmp @loop

@end:
  rts

; Dump the super block and all index entries to the ACIA.
; in:  none
; out: carry clear = success, carry set = error
; clobbers: A, X, Y, flags, K_PTR, K_PTR2, K_LEN, K_TMP0, K_TMP1
fs_dump:
  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI
  stz K_PTR2_LO
  stz K_PTR2_HI
  lda #FS_SB_SIZE
  sta K_LEN_LO
  stz K_LEN_HI
  jsr FRAM_READ_CHUNK
  bcs @error

  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI
  lda #FS_SB_SIZE
  sta K_LEN_LO
  stz K_LEN_HI
  jsr hex_dump
  jsr print_newline

  lda K_BUF + FS_SB_INDEX_SIZE
  sta K_TMP0
  lda K_BUF + FS_SB_INDEX_SIZE + 1
  sta K_TMP1

  lda #$FF
  sta K_PTR2_HI
  lda #$FF - (FS_ENTRY_SIZE - 1)
  sta K_PTR2_LO

@index_loop:
  lda K_TMP0
  ora K_TMP1
  beq @done

  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI
  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI
  jsr FRAM_READ_CHUNK
  bcs @error

  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI
  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI
  jsr hex_dump
  jsr print_newline

  lda K_PTR2_LO
  sec
  sbc #FS_ENTRY_SIZE
  sta K_PTR2_LO
  bcs @no_borrow_ptr
  dec K_PTR2_HI
@no_borrow_ptr:

  lda K_TMP0
  sec
  sbc #FS_ENTRY_SIZE
  sta K_TMP0
  bcs @no_borrow_cnt
  dec K_TMP1
@no_borrow_cnt:

  jmp @index_loop

@done:
  clc
  rts

@error:
  sec
  rts

start_index_record:
  .byte $02
  .res 22, $00
  .byte $FE

super_block:
  .byte $FF, $FF ; size of the storage
  .byte $09, $00 ; end of the reserved area and start of data slab
  .byte $00, $00 ; bytes used in data slab
  .byte $30, $00 ; bytes used in index
  .byte $C9
