; shell prompt and line reader
shell:
  lda #$0A
  jsr ACIA_PUTC

  lda #$0D
  jsr ACIA_PUTC
  
  lda #'>'
  jsr ACIA_PUTC

  lda #' '
  jsr ACIA_PUTC

  ldx #$00

; echo input into INPUT_BASE until carriage return
@load_char:
  jsr ACIA_GETC
  cmp #$0D
  beq @load_end

  pha
  jsr ACIA_PUTC
  pla

  sta INPUT_BASE,x
  inx
  jmp @load_char

; terminate the input line and reset per-line state
@load_end:
  lda #$0D
  jsr ACIA_PUTC
  lda #$0A
  jsr ACIA_PUTC

  lda #$00
  sta INPUT_BASE,x
  sta SCRATCH_IDX
  ldx #$00

; skip spaces and find the start of the next word
@find_word_start:
  lda INPUT_BASE,x
  beq @execute_line
  cmp #' '
  bne @word_start
  inx
  jmp @find_word_start

; record the word start and scan to its end
@word_start:
  stx WORD_LO
  lda #>INPUT_BASE
  sta WORD_HI

  ldy #$01

; advance until space or end of line
@find_word_end:
  inx
  lda INPUT_BASE,x
  cmp #' '
  beq @word_end_space
  cmp #$00
  beq @word_end_line
  iny
  jmp @find_word_end

; emit a word terminated by space, then keep scanning
@word_end_space:
  sty WORD_LEN
  phx
  jsr find_token
  plx
  jmp @find_word_start

; emit the final word and finish the line
@word_end_line:
  sty WORD_LEN
  jsr find_token
  jmp @execute_line

; append shell return and run the scratch buffer
@execute_line:
  ldy SCRATCH_IDX
  lda #TOKEN_SHELL_RETURN
  sta SCRATCH_BASE,y
  inc SCRATCH_IDX
  jmp execute

; 

; resolve a word to either a known token or a hex literal
find_token:
  jsr find_name
  bcc @emit_token

  jsr parse_hex_byte
  bcc @emit_literal

  jmp shell_error

; append a token byte to scratch
@emit_token:
  ldy SCRATCH_IDX
  sta SCRATCH_BASE,y
  inc SCRATCH_IDX
  rts

; append TOKEN_LITERAL plus the parsed byte value
@emit_literal:
  sta TEMP_LO

  ldy SCRATCH_IDX
  lda #TOKEN_LITERAL
  sta SCRATCH_BASE,y
  inc SCRATCH_IDX

  ldy SCRATCH_IDX
  lda TEMP_LO
  sta SCRATCH_BASE,y
  inc SCRATCH_IDX

  rts

; scan through the name records in the heap
find_name:
  lda #<heap
  sta HEAP_CURR_LO

  lda #>heap
  sta HEAP_CURR_HI

; inspect the next table entry
@next_name:
  ldy #$00

  lda (HEAP_CURR_LO),y
  sta HEAP_NEXT_LO
  
  INC_HEAP_CURR
  lda (HEAP_CURR_LO),y
  sta HEAP_NEXT_HI

  INC_HEAP_CURR
  lda (HEAP_CURR_LO),y
  cmp WORD_LEN
  bne @next_word

  sta TEMP_LO
  ldx WORD_LO
  INC_HEAP_CURR

; compare the input word against this table entry
@compare_loop:
  ldy #$00

  lda INPUT_BASE,x
  cmp (HEAP_CURR_LO),y
  bne @next_word

  INC_HEAP_CURR
  inx

  dec TEMP_LO
  bne @compare_loop

  lda (HEAP_CURR_LO),y
  clc
  rts

; try the next word
@next_word:
  lda HEAP_NEXT_LO
  sta HEAP_CURR_LO

  cmp #$FF
  beq @not_found

  lda HEAP_NEXT_HI
  sta HEAP_CURR_HI

  jmp @next_name

; no table entry matched
@not_found:
  sec
  rts

; parse a 1-2 digit hex literal into a byte
parse_hex_byte:
  lda WORD_LEN
  beq @bad
  cmp #$03
  bcs @bad

  lda #$00
  sta TEMP_LO

  ldy #$00

; fold one hex digit into the accumulator
@parse_loop:
  lda (WORD_LO),y
  jsr HEX_TO_NIBBLE
  bcs @bad

  sta TEMP_HI
  lda TEMP_LO
  asl
  asl
  asl
  asl
  ora TEMP_HI
  sta TEMP_LO

  iny
  cpy WORD_LEN
  bne @parse_loop

  lda TEMP_LO
  clc
  rts

; invalid hex input
@bad:
  sec
  rts

; print an error marker and restart the shell
shell_error:
  lda #'!'
  jsr ACIA_PUTC

  lda #$0D
  jsr ACIA_PUTC

  lda #$0A
  jsr ACIA_PUTC

  jmp shell
