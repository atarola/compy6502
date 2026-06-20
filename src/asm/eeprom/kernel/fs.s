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

COMPACT_CHUNK = 64   ; per-file data copy chunk size, staged at K_BUF + FS_ENTRY_SIZE

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

  jsr MEM_COPY

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

  jsr CRC
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

  jsr FS_READ_SB
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
  jsr ITER_INIT

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
  jsr ITER_NEXT
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
  jsr FS_READ_SB

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

  jsr MEM_COPY

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

  jsr MEM_COPY

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

  jsr CRC
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

  jsr CRC
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

  jsr CRC
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

  jsr FS_DELETE
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

  jmp FS_WRITE

@error:
  sec
  rts

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
  jsr FS_READ_SB
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
  jsr ITER_INIT

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

  jsr CRC
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
  jsr ITER_NEXT_DOWN
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

  jsr CRC
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
  jmp PRINT_NEWLINE

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
  jsr HEX_DUMP
  jsr PRINT_NEWLINE

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
  jsr HEX_DUMP
  jsr PRINT_NEWLINE

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

start_index_record:
  .byte $02
  .res 22, $00
  .byte $FE

super_block:
  .byte $05, $00 ; next free address in data slab
  .byte $D0, $FF ; start of the index region
  .byte $2C
