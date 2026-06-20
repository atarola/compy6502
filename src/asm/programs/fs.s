.setcpu "65c02"

.include "include/compy6502.inc"

; FRAM Filesystem
;
; $0000           super block (5 bytes)
; $0005 to FREE   data slab (append-only, grows up)
; FREE to IDX     free area
; IDX to $FFFF    index (24-byte entries, grows down)
;
; FREE = FS_SB_DATA_PTR, IDX = FS_SB_INDEX_PTR (both tracked in the super block)
; file ID = FRAM address of index entry, returned by fs_find

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

read_target = $6000   ; arbitrary RAM spot, well clear of this program and K_BUF

.org $1000
  jsr FRAM_SETUP
  bcc :+
  jmp @error
:

  lda #<vol_name
  sta K_PTR_LO
  lda #>vol_name
  sta K_PTR_HI

  jsr fs_format
  bcc :+
  jmp @error
:

  lda #<greeting_data
  sta K_PTR_LO
  lda #>greeting_data
  sta K_PTR_HI

  lda #<greeting_name
  sta K_PTR2_LO
  lda #>greeting_name
  sta K_PTR2_HI

  lda #<greeting_data_len
  sta K_LEN_LO
  lda #>greeting_data_len
  sta K_LEN_HI

  jsr fs_write
  bcc :+
  jmp @error
:

  ; find "greeting" -> K_PTR2 = file ID
  lda #<greeting_name
  sta K_PTR2_LO
  lda #>greeting_name
  sta K_PTR2_HI

  jsr fs_find
  bcc :+
  jmp @error
:

  ; update it to say "hellorld" (K_PTR2 already holds the file ID from fs_find)
  lda #<updated_data
  sta K_PTR_LO
  lda #>updated_data
  sta K_PTR_HI

  lda #<updated_data_len
  sta K_LEN_LO
  lda #>updated_data_len
  sta K_LEN_HI

  jsr fs_update
  bcc :+
  jmp @error
:

  ; dump before compacting, to show the orphaned entry/data fs_update left behind
  jsr fs_dump
  bcc :+
  jmp @error
:

  ; compact -- reclaims the deleted "hello world" entry and its data slab bytes
  jsr fs_compact
  bcc :+
  jmp @error
:

  ; dump again to show the index/superblock shrank
  jsr fs_dump
  bcc :+
  jmp @error
:

  ; fs_compact (like fs_update) relocates entries, so look up "greeting" again
  lda #<greeting_name
  sta K_PTR2_LO
  lda #>greeting_name
  sta K_PTR2_HI

  jsr fs_find
  bcc :+
  jmp @error
:

  ; peek at the index entry to stash the file length (fs_read clobbers
  ; K_LEN without returning it, and overwrites K_BUF itself)
  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jsr FRAM_READ_CHUNK
  bcc :+
  jmp @error
:

  lda K_BUF + FS_FILE_LEN
  sta K_TMP0
  lda K_BUF + FS_FILE_LEN + 1
  sta K_TMP1

  ; read the file into RAM (K_PTR2 still holds the file ID from fs_find)
  lda #<read_target
  sta K_PTR_LO
  lda #>read_target
  sta K_PTR_HI

  jsr fs_read
  bcc :+
  jmp @error
:

  ; print the file contents
  lda #<read_target
  sta K_PTR_LO
  lda #>read_target
  sta K_PTR_HI

  lda K_TMP0
  sta K_LEN_LO
  lda K_TMP1
  sta K_LEN_HI

@print_loop:
  lda K_LEN_LO
  ora K_LEN_HI
  beq @print_done

  lda (K_PTR)
  jsr ACIA_PUTC

  INC16 K_PTR
  DEC16 K_LEN
  jmp @print_loop

@print_done:
  jsr print_newline

  jmp WOZMON

@error:
  lda #'!'
  jsr ACIA_PUTC

  jmp WOZMON


vol_name:
  .byte $05, "hello"

greeting_name:
  .byte $08, "greeting"

greeting_data:
  .byte "hello world"
greeting_data_end:
greeting_data_len = greeting_data_end - greeting_data

updated_data:
  .byte "hellorld"
updated_data_end:
updated_data_len = updated_data_end - updated_data

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

  ; copy the zeroed start record template into the buffer so reserved
  ; bytes are clean instead of stale RAM
  lda #<start_index_record
  sta K_PTR_LO
  lda #>start_index_record
  sta K_PTR_HI

  lda #<K_BUF
  sta K_PTR2_LO
  lda #>K_BUF
  sta K_PTR2_HI

  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jsr mem_copy

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

  jsr crc
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

; Find a file by name in the index.
; in:  K_PTR2 = pascal string filename
; out: carry clear = success, K_PTR2 = file ID (FRAM address of index entry)
;      carry set   = not found
; clobbers: A, X, Y, flags, K_PTR2
fs_find:
  lda K_PTR2_LO
  pha
  lda K_PTR2_HI
  pha

  jsr fs_read_sb
  bcc :+
  pla
  pla
  jmp @error
:

  lda K_BUF + FS_SB_INDEX_PTR
  sta K_PTR2_LO
  lda K_BUF + FS_SB_INDEX_PTR + 1
  sta K_PTR2_HI

  lda #$FF
  sta K_TMP2
  sta K_TMP3

  lda #FS_ENTRY_SIZE
  jsr iter_init

  pla 
  sta K_TMP3
  pla
  sta K_TMP2

@loop:
  lda K_PTR2_LO
  sta K_TMP4
  lda K_PTR2_HI
  sta K_TMP5

  ; grab the next index
  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jsr FRAM_READ_CHUNK
  bcs @error

  ; compare the input string to the buffer
  lda K_TMP2
  sta K_PTR_LO
  lda K_TMP3
  sta K_PTR_HI

  lda #>K_BUF
  sta K_PTR2_HI
  lda #FS_FILE_NAME
  sta K_PTR2_LO

  jsr STR_EQ
  bcc @done 

  ; not eql so continue iteration
  jsr iter_next
  bcs @error

  jmp @loop

@done:
  lda K_TMP4
  sta K_PTR2_LO
  lda K_TMP5
  sta K_PTR2_HI

  clc
  rts

@error:
  sec
  rts

; Read file data into RAM.
; in:  K_PTR  = destination RAM address
;      K_PTR2 = file ID (FRAM address of index entry)
; out: carry clear = success
;      carry set   = error
; clobbers: A, Y, flags, K_PTR, K_LEN
fs_read:
  lda K_PTR_LO
  sta K_TMP4
  lda K_PTR_HI
  sta K_TMP5

  ; grab the record from the fram
  lda #>K_BUF
  sta K_PTR_HI
  stz K_PTR_LO

  stz K_LEN_HI
  lda #FS_ENTRY_SIZE
  sta K_LEN_LO

  jsr FRAM_READ_CHUNK
  bcc :+
  jmp @error
:

  ; ram address
  lda K_TMP4
  sta K_PTR_LO
  lda K_TMP5
  sta K_PTR_HI

  ; fram address
  lda K_BUF + FS_FILE_START
  sta K_PTR2_LO
  lda K_BUF + FS_FILE_START + 1
  sta K_PTR2_HI

  ; grab the file size 
  lda K_BUF + FS_FILE_LEN
  sta K_LEN_LO
  lda K_BUF + FS_FILE_LEN + 1
  sta K_LEN_HI

  jsr FRAM_READ_CHUNK
  bcs @error

  clc
  rts

@error:
  sec
  rts

; Read the super block into K_BUF.
; in:  none
; out: carry clear = success, carry set = error
; clobbers: A, Y, flags, K_PTR, K_PTR2, K_LEN
fs_read_sb:
  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  stz K_PTR2_LO
  stz K_PTR2_HI

  lda #FS_SB_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jmp FRAM_READ_CHUNK

; Append a new file to the volume.
; in:  K_PTR  = source RAM address (file data)
;      K_PTR2 = pascal string filename
;      K_LEN  = file length in bytes
; out: carry clear = success
;      carry set   = error
; clobbers: A, Y, flags, K_PTR, K_LEN
fs_write:
  ; stash the filename
  lda K_PTR2_LO
  pha
  lda K_PTR2_HI
  pha

  ; stash the source
  lda K_PTR_LO
  pha
  lda K_PTR_HI
  pha

  ; stash the file length
  lda K_LEN_LO
  sta K_TMP0
  lda K_LEN_HI
  sta K_TMP1

  ; grab the superblock and stash it locally
  jsr fs_read_sb

  ; restore the filesize
  lda K_TMP0
  sta K_LEN_LO
  lda K_TMP1
  sta K_LEN_HI

  ; restore the source pointer
  pla 
  sta K_PTR_HI
  pla 
  sta K_PTR_LO

  ; set the target
  lda K_BUF + FS_SB_DATA_PTR
  sta K_PTR2_LO
  sta K_TMP2

  lda K_BUF + FS_SB_DATA_PTR + 1
  sta K_PTR2_HI
  sta K_TMP3

  ; write out the file
  jsr FRAM_WRITE_CHUNK
  bcc :+
  jmp @fram_write_error
:

  ; calculate where the new free pointer goes
  ; (compute into K_PTR2, not K_TMP2/K_TMP3 -- those still hold the file's
  ; start address, needed below for FS_FILE_START)
  lda K_TMP2
  sta K_PTR2_LO
  lda K_TMP3
  sta K_PTR2_HI

  ADD16 K_PTR2, K_TMP0
  lda K_PTR2_LO
  sta K_BUF + FS_SB_DATA_PTR
  lda K_PTR2_HI
  sta K_BUF + FS_SB_DATA_PTR + 1

  ; calculate the new index ptr
  stz K_LEN_HI
  lda #FS_ENTRY_SIZE
  sta K_LEN_LO

  SUB16 K_BUF + FS_SB_INDEX_PTR, K_LEN

  ; copy the start index record to our buffer
  lda #FS_ENTRY_SIZE 
  sta K_PTR2_LO
  lda #>K_BUF
  sta K_PTR2_HI

  lda #<start_index_record
  sta K_PTR_LO
  lda #>start_index_record
  sta K_PTR_HI

  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jsr mem_copy

  ; copy another start entry afterword as a stub
  lda #(FS_ENTRY_SIZE * 2)
  sta K_PTR2_LO
  lda #>K_BUF
  sta K_PTR2_HI

  lda #<start_index_record
  sta K_PTR_LO
  lda #>start_index_record
  sta K_PTR_HI

  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jsr mem_copy

  ; lets build the entry
  lda #FS_ENTRY_FILE
  sta K_BUF + (FS_ENTRY_SIZE * 2) + FS_FILE_TYPE

  lda K_TMP2
  sta K_BUF + (FS_ENTRY_SIZE * 2) + FS_FILE_START
  lda K_TMP3
  sta K_BUF + (FS_ENTRY_SIZE * 2) + FS_FILE_START + 1

  lda K_TMP0 
  sta K_BUF + (FS_ENTRY_SIZE * 2) + FS_FILE_LEN
  lda K_TMP1
  sta K_BUF + (FS_ENTRY_SIZE * 2) + FS_FILE_LEN + 1

  ; TODO: write proper entry point
  stz K_BUF + (FS_ENTRY_SIZE * 2) + FS_FILE_ADDR
  stz K_BUF + (FS_ENTRY_SIZE * 2) + FS_FILE_ADDR + 1

  ; write the filename in 
  lda #((FS_ENTRY_SIZE * 2) + FS_FILE_NAME) 
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI
  pla 
  sta K_PTR2_HI
  pla 
  sta K_PTR2_LO
  jsr STR_COPY

  ; time to crc the whole thing
  lda #(FS_ENTRY_SIZE * 2)
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda #(FS_ENTRY_SIZE - 1)
  sta K_LEN_LO
  stz K_LEN_HI

  jsr crc
  sta K_BUF + (FS_ENTRY_SIZE * 2) + FS_FILE_CRC

  ; lets write the index records first
  lda #FS_ENTRY_SIZE
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda K_BUF + FS_SB_INDEX_PTR
  sta K_PTR2_LO
  lda K_BUF + FS_SB_INDEX_PTR + 1
  sta K_PTR2_HI

  lda #(FS_ENTRY_SIZE * 2)
  sta K_LEN_LO
  stz K_LEN_HI

  jsr FRAM_WRITE_CHUNK
  bcc :+
  jmp @error
:

  ; lets update the crc for the superblock
  stz K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda #FS_SB_SIZE - 1 
  sta K_LEN_LO
  stz K_LEN_HI

  jsr crc
  sta K_BUF + FS_SB_CRC

  ; lets write the superblock to the fram
  stz K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  stz K_PTR2_LO
  stz K_PTR2_HI

  lda #FS_SB_SIZE
  sta K_LEN_LO
  stz K_LEN_HI
  
  jsr FRAM_WRITE_CHUNK
  bcc :+
  jmp @error
:

  clc
  rts

@error:
  sec
  rts

@fram_write_error:
  pla
  pla
  sec 
  rts

; Tombstone a file index entry.
; in:  K_PTR2 = file ID (FRAM address of index entry)
; out: carry clear = success
;      carry set   = error
; clobbers: A, flags, K_PTR, K_LEN, K_TMP0
fs_delete:
  ; grab the record from the fram
  lda #>K_BUF
  sta K_PTR_HI
  stz K_PTR_LO

  stz K_LEN_HI
  lda #FS_ENTRY_SIZE
  sta K_LEN_LO

  jsr FRAM_READ_CHUNK
  bcc :+
  jmp @error
:

  ; set the marker to deleted
  lda #FS_ENTRY_FILE_DEL
  sta K_BUF + FS_FILE_TYPE

  ; time to crc the whole thing
  lda #>K_BUF
  sta K_PTR_HI
  stz K_PTR_LO

  lda #(FS_ENTRY_SIZE - 1)
  sta K_LEN_LO
  stz K_LEN_HI

  jsr crc
  sta K_BUF + FS_FILE_CRC

  ; write the whole thing back to fram
  lda #>K_BUF
  sta K_PTR_HI
  stz K_PTR_LO

  stz K_LEN_HI
  lda #FS_ENTRY_SIZE
  sta K_LEN_LO

  jsr FRAM_WRITE_CHUNK
  bcc :+
  jmp @error
:

  clc
  rts

@error:
  sec
  rts

; Replace a file's contents (delete + write).
; in:  K_PTR  = source RAM address (new file data)
;      K_PTR2 = file ID (FRAM address of index entry)
;      K_LEN  = new file length in bytes
; out: carry clear = success
;      carry set   = error
; clobbers: A, X, Y, flags, K_PTR, K_PTR2, K_LEN, K_TMP0, K_TMP1, K_TMP2, K_TMP3, K_TMP4, K_TMP5
fs_update:
  ; stash the new file's source and length while we look up the old name
  lda K_PTR_LO
  pha
  lda K_PTR_HI
  pha
  lda K_LEN_LO
  pha
  lda K_LEN_HI
  pha

  ; stash the file ID, then read the old entry so we can recover its name
  lda K_PTR2_LO
  sta K_TMP4
  lda K_PTR2_HI
  sta K_TMP5

  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jsr FRAM_READ_CHUNK
  bcc :+
  pla
  pla
  pla
  pla
  jmp @error
:

  ; stash the filename past where fs_delete/fs_write touch K_BUF
  ; (they only use offsets 0-71; FS_ENTRY_SIZE*3 = 72 lands just past that)
  lda #<(K_BUF + (FS_ENTRY_SIZE * 3))
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda #<K_BUF + FS_FILE_NAME
  sta K_PTR2_LO
  lda #>K_BUF
  sta K_PTR2_HI

  jsr STR_COPY

  ; delete the old entry (file ID stashed in K_TMP4/K_TMP5)
  lda K_TMP4
  sta K_PTR2_LO
  lda K_TMP5
  sta K_PTR2_HI

  jsr fs_delete
  bcc :+
  pla
  pla
  pla
  pla
  jmp @error
:

  ; restore the new file's source and length
  pla
  sta K_LEN_HI
  pla
  sta K_LEN_LO
  pla
  sta K_PTR_HI
  pla
  sta K_PTR_LO

  ; write the new content back under the old name
  lda #<(K_BUF + (FS_ENTRY_SIZE * 3))
  sta K_PTR2_LO
  lda #>K_BUF
  sta K_PTR2_HI

  jmp fs_write

@error:
  sec
  rts

COMPACT_CHUNK = 64   ; per-file data copy chunk size, staged at K_BUF + FS_ENTRY_SIZE

; Defragment the data slab and rebuild the index.
;
; K_TMP2/K_TMP3 = index write-cursor, K_TMP4/K_TMP5 = slab write-cursor
; (high-water mark); both persist for the whole routine. K_TMP0/K_TMP1
; track the current file's old data pointer while copying. K_BUF holds
; the entry being processed at offset 0, a COMPACT_CHUNK-sized data
; staging buffer at offset FS_ENTRY_SIZE, and the new slab position for
; the current file (stashed before the copy loop advances K_TMP4/K_TMP5)
; at offset FS_ENTRY_SIZE + COMPACT_CHUNK.
;
; in:  none
; out: carry clear = success
;      carry set   = error
; clobbers: A, X, Y, flags, K_PTR, K_PTR2, K_LEN, K_TMP0, K_TMP1, K_TMP2, K_TMP3, K_TMP4, K_TMP5
fs_compact:
  jsr fs_read_sb
  bcc :+
  jmp @error
:

  ; stop boundary for the downward walk = the current (pre-compaction) index_ptr
  lda K_BUF + FS_SB_INDEX_PTR
  sta K_TMP2
  lda K_BUF + FS_SB_INDEX_PTR + 1
  sta K_TMP3

  ; seed = $FFD0, the first real entry just below the fixed VOL_ID slot at $FFE8
  lda #$FF
  sta K_PTR2_HI
  lda #$FF - (FS_ENTRY_SIZE * 2 - 1)
  sta K_PTR2_LO

  lda #FS_ENTRY_SIZE
  jsr iter_init

  ; index write-cursor starts at the same seed
  lda #$FF
  sta K_TMP3
  lda #$FF - (FS_ENTRY_SIZE * 2 - 1)
  sta K_TMP2

  ; slab write-cursor (high-water mark) starts right after the superblock
  lda #FS_SB_SIZE
  sta K_TMP4
  stz K_TMP5

@loop:
  ; read the entry at the read-cursor (K_PTR2) into K_BUF
  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jsr FRAM_READ_CHUNK
  bcc :+
  jmp @error
:

  ; anything but a live file (deleted, or the trailing start-stub) is
  ; reclaimed by simply not carrying it forward
  lda K_BUF + FS_FILE_TYPE
  cmp #FS_ENTRY_FILE
  beq :+
  jmp @advance
:

  ; stash this file's new slab position before the copy loop moves
  ; K_TMP4/K_TMP5 forward
  lda K_TMP4
  sta K_BUF + FS_ENTRY_SIZE + COMPACT_CHUNK
  lda K_TMP5
  sta K_BUF + FS_ENTRY_SIZE + COMPACT_CHUNK + 1

  ; moving read-pointer over the file's old data, starts at its old start
  lda K_BUF + FS_FILE_START
  sta K_TMP0
  lda K_BUF + FS_FILE_START + 1
  sta K_TMP1

@copy_loop:
  ; remaining = FS_FILE_LEN - (K_TMP0/K_TMP1 - FS_FILE_START)
  lda K_TMP0
  sta K_PTR2_LO
  lda K_TMP1
  sta K_PTR2_HI
  SUB16 K_PTR2, K_BUF + FS_FILE_START

  lda K_BUF + FS_FILE_LEN
  sta K_LEN_LO
  lda K_BUF + FS_FILE_LEN + 1
  sta K_LEN_HI
  SUB16 K_LEN, K_PTR2

  lda K_LEN_LO
  ora K_LEN_HI
  beq @copy_done

  ; this chunk = min(remaining, COMPACT_CHUNK)
  lda K_LEN_HI
  bne @full_chunk
  lda K_LEN_LO
  cmp #COMPACT_CHUNK + 1
  bcc @chunk_size_set
@full_chunk:
  lda #COMPACT_CHUNK
@chunk_size_set:
  tax
  sta K_LEN_LO
  stz K_LEN_HI

  ; read the chunk from the old location into K_BUF's staging area
  lda K_TMP0
  sta K_PTR2_LO
  lda K_TMP1
  sta K_PTR2_HI

  lda #<(K_BUF + FS_ENTRY_SIZE)
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  jsr FRAM_READ_CHUNK
  bcc :+
  jmp @error
:

  ; write it out to the slab write-cursor
  txa
  sta K_LEN_LO
  stz K_LEN_HI

  lda K_TMP4
  sta K_PTR2_LO
  lda K_TMP5
  sta K_PTR2_HI

  lda #<(K_BUF + FS_ENTRY_SIZE)
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  jsr FRAM_WRITE_CHUNK
  bcc :+
  jmp @error
:

  ; advance the old-data read-pointer and the slab write-cursor by the chunk
  txa
  sta K_LEN_LO
  stz K_LEN_HI
  ADD16 K_TMP0, K_LEN
  ADD16 K_TMP4, K_LEN

  jmp @copy_loop

@copy_done:
  ; patch FS_FILE_START to the stashed new slab position
  lda K_BUF + FS_ENTRY_SIZE + COMPACT_CHUNK
  sta K_BUF + FS_FILE_START
  lda K_BUF + FS_ENTRY_SIZE + COMPACT_CHUNK + 1
  sta K_BUF + FS_FILE_START + 1

  ; recompute the entry CRC
  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda #(FS_ENTRY_SIZE - 1)
  sta K_LEN_LO
  stz K_LEN_HI

  jsr crc
  sta K_BUF + FS_FILE_CRC

  ; write the entry to the index write-cursor
  lda K_TMP2
  sta K_PTR2_LO
  lda K_TMP3
  sta K_PTR2_HI

  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jsr FRAM_WRITE_CHUNK
  bcs @error

  ; advance the index write-cursor
  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI
  SUB16 K_TMP2, K_LEN

@advance:
  jsr iter_next_down
  bcs :+
  jmp @loop
:

  ; iteration complete -- write a fresh start-stub at the final index
  ; write-cursor
  lda #<start_index_record
  sta K_PTR_LO
  lda #>start_index_record
  sta K_PTR_HI

  lda K_TMP2
  sta K_PTR2_LO
  lda K_TMP3
  sta K_PTR2_HI

  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jsr FRAM_WRITE_CHUNK
  bcs @error

  ; build and write the new superblock
  lda K_TMP4
  sta K_BUF + FS_SB_DATA_PTR
  lda K_TMP5
  sta K_BUF + FS_SB_DATA_PTR + 1
  lda K_TMP2
  sta K_BUF + FS_SB_INDEX_PTR
  lda K_TMP3
  sta K_BUF + FS_SB_INDEX_PTR + 1

  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda #FS_SB_SIZE - 1
  sta K_LEN_LO
  stz K_LEN_HI

  jsr crc
  sta K_BUF + FS_SB_CRC

  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  stz K_PTR2_LO
  stz K_PTR2_HI

  lda #FS_SB_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jsr FRAM_WRITE_CHUNK
  bcs @error

  clc
  rts

@error:
  sec
  rts

; Compute zero-sum CRC over N bytes in RAM.
; in:  K_PTR = address of buffer
;      K_LEN = byte count
; out: A = CRC byte (store in entry to make 24-byte sum zero)
; clobbers: A, flags
crc:
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

; Copy K_LEN bytes from K_PTR to K_PTR2.
; in:  K_PTR  = source address
;      K_PTR2 = destination address
;      K_LEN  = byte count
; clobbers: A, flags, K_PTR, K_PTR2, K_LEN
mem_copy:
@loop:
  lda K_LEN_LO
  ora K_LEN_HI
  beq @end

  lda (K_PTR)
  sta (K_PTR2)

  INC16 K_PTR
  INC16 K_PTR2
  DEC16 K_LEN

  jmp @loop

@end:
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

; Read the entry named by K_PTR2 (file ID) and print its name, then a newline.
; in:  K_PTR2 = file ID (FRAM address of index entry)
; clobbers: A, X, Y, flags, K_PTR, K_LEN
print_file_name:
  lda #<K_BUF
  sta K_PTR_LO
  lda #>K_BUF
  sta K_PTR_HI

  lda #FS_ENTRY_SIZE
  sta K_LEN_LO
  stz K_LEN_HI

  jsr FRAM_READ_CHUNK
  bcs @done

  ldx K_BUF + FS_FILE_NAME
  beq @done

  ldy #$01
@loop:
  lda K_BUF + FS_FILE_NAME, y
  jsr ACIA_PUTC
  iny
  dex
  bne @loop

@done:
  jmp print_newline

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

  lda K_BUF + FS_SB_INDEX_PTR
  sta K_TMP0
  lda K_BUF + FS_SB_INDEX_PTR + 1
  sta K_TMP1

  lda #$FF
  sta K_PTR2_HI
  lda #$FF - (FS_ENTRY_SIZE - 1)
  sta K_PTR2_LO

@index_loop:
  ; stop once K_PTR2 < boundary (K_TMP0/K_TMP1)
  lda K_PTR2_HI
  cmp K_TMP1
  bcc @done
  bne @process
  lda K_PTR2_LO
  cmp K_TMP0
  bcc @done

@process:
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

  jmp @index_loop

@done:
  clc
  rts

@error:
  sec
  rts

; Fixed-stride iterator over the index region. State lives in
; K_ITER_CUR/K_ITER_STOP/K_ITER_STRIDE/K_ITER_CB instead of the transient
; K_PTR/K_LEN/K_TMP scratch, since it must survive whatever the caller does
; between calls.

; Set up the iterator cursor, stop boundary, and stride.
; in:  K_PTR2 = start cursor address
;      K_TMP2/K_TMP3 = stop boundary address (lo/hi)
;      A = stride (bytes per step)
; out: none
; clobbers: A, flags
iter_init:
  sta K_ITER_STRIDE
  stz K_ITER_STRIDE_HI

  lda K_PTR2_LO
  sta K_ITER_CUR_LO
  lda K_PTR2_HI
  sta K_ITER_CUR_HI

  lda K_TMP2
  sta K_ITER_STOP_LO
  lda K_TMP3
  sta K_ITER_STOP_HI

  clc
  rts

; Advance the iterator and return the next item address.
; in:  none (uses K_ITER_CUR/K_ITER_STOP/K_ITER_STRIDE)
; out: carry clear = item available, K_PTR2 = item address
;      carry set   = iteration complete
; clobbers: A, flags
iter_next:
  ADD16 K_ITER_CUR, K_ITER_STRIDE
  bcs :+

  CMP16 K_ITER_CUR, K_ITER_STOP
  bcs :+

  lda K_ITER_CUR_LO
  sta K_PTR2_LO
  lda K_ITER_CUR_HI
  sta K_PTR2_HI

  rts
:
  rts

; Advance the iterator downward and return the next item address.
; Counterpart to iter_next for walking toward lower addresses (e.g.
; compacting the index oldest-to-newest). iter_init covers both
; directions unchanged -- only the advance/stop direction differs, so
; there's no iter_init_down.
; in:  none (uses K_ITER_CUR/K_ITER_STOP/K_ITER_STRIDE)
; out: carry clear = item available, K_PTR2 = item address
;      carry set   = iteration complete
; clobbers: A, flags
iter_next_down:
  SUB16 K_ITER_CUR, K_ITER_STRIDE
  bcc @done             ; borrow -- wrapped past $0000

  CMP16 K_ITER_CUR, K_ITER_STOP
  bcc @done             ; CUR < STOP
  beq @done             ; CUR == STOP -- boundary itself is excluded

  lda K_ITER_CUR_LO
  sta K_PTR2_LO
  lda K_ITER_CUR_HI
  sta K_PTR2_HI

  clc
  rts

@done:
  sec
  rts

; Walk the iterator to completion, invoking a callback for each item.
; in:  K_ITER_CB = callback address (called once per item via trampoline,
;      with K_PTR2 = item address)
; out: carry clear = success
;      carry set   = error (propagated from a callback, if any)
; clobbers: A, X, Y, flags, K_PTR2
iter_for_each:
@loop:
  ADD16 K_ITER_CUR, K_ITER_STRIDE
  bcs @done

  CMP16 K_ITER_CUR, K_ITER_STOP
  bcs @done

  lda K_ITER_CUR_LO
  sta K_PTR2_LO
  lda K_ITER_CUR_HI
  sta K_PTR2_HI

  jsr iter_trampoline
  bcs @error
  
  jmp @loop

@error:
  rts

@done:
  clc
  rts

iter_trampoline:
  jmp (K_ITER_CB)

start_index_record:
  .byte $02
  .res 22, $00
  .byte $FE

super_block:
  .byte $05, $00 ; next free address in data slab
  .byte $D0, $FF ; start of the index region
  .byte $2C
