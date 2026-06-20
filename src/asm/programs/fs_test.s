.setcpu "65c02"

.include "include/compy6502.inc"

; Exercises the FRAM filesystem kernel (FS_FORMAT/FS_WRITE/FS_FIND/FS_UPDATE/
; FS_COMPACT/FS_READ/FS_DUMP) -- format a volume, write a file, update its
; contents, dump before/after compacting, then read back and print the result.

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

  jsr FS_FORMAT
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

  jsr FS_WRITE
  bcc :+
  jmp @error
:

  ; find "greeting" -> K_PTR2 = file ID
  lda #<greeting_name
  sta K_PTR2_LO
  lda #>greeting_name
  sta K_PTR2_HI

  jsr FS_FIND
  bcc :+
  jmp @error
:

  ; update it to say "hellorld" (K_PTR2 already holds the file ID from FS_FIND)
  lda #<updated_data
  sta K_PTR_LO
  lda #>updated_data
  sta K_PTR_HI

  lda #<updated_data_len
  sta K_LEN_LO
  lda #>updated_data_len
  sta K_LEN_HI

  jsr FS_UPDATE
  bcc :+
  jmp @error
:

  ; dump before compacting, to show the orphaned entry/data FS_UPDATE left behind
  jsr FS_DUMP
  bcc :+
  jmp @error
:

  ; compact -- reclaims the deleted "hello world" entry and its data slab bytes
  jsr FS_COMPACT
  bcc :+
  jmp @error
:

  ; dump again to show the index/superblock shrank
  jsr FS_DUMP
  bcc :+
  jmp @error
:

  ; FS_COMPACT (like FS_UPDATE) relocates entries, so look up "greeting" again
  lda #<greeting_name
  sta K_PTR2_LO
  lda #>greeting_name
  sta K_PTR2_HI

  jsr FS_FIND
  bcc :+
  jmp @error
:

  ; peek at the index entry to stash the file length (FS_READ clobbers
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

  ; read the file into RAM (K_PTR2 still holds the file ID from FS_FIND)
  lda #<read_target
  sta K_PTR_LO
  lda #>read_target
  sta K_PTR_HI

  jsr FS_READ
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
  jsr PRINT_NEWLINE

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
