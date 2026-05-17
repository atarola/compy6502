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

@load_end:
  lda #$0D
  jsr ACIA_PUTC
  lda #$0A
  jsr ACIA_PUTC

  lda #$00
  sta INPUT_BASE,x
  sta SCRATCH_IDX
  ldx #$00

@find_word_start:
  lda INPUT_BASE,x
  beq @execute_line
  cmp #' '
  bne @word_start
  inx
  jmp @find_word_start

@word_start:
  stx WORD_LO
  lda #>INPUT_BASE
  sta WORD_HI

  ldy #$01

@find_word_end:
  inx
  lda INPUT_BASE,x
  cmp #' '
  beq @word_end_space
  cmp #$00
  beq @word_end_line
  iny
  jmp @find_word_end

@word_end_space:
  sty WORD_LEN
  phx
  jsr find_token
  plx
  jmp @find_word_start

@word_end_line:
  sty WORD_LEN
  jsr find_token
  jmp @execute_line

@execute_line:
  ldy SCRATCH_IDX
  lda #TOKEN_SHELL_RETURN
  sta SCRATCH_BASE,y
  inc SCRATCH_IDX
  jmp execute

; 

find_token:
  jsr find_name
  bcc @emit_token

  jsr parse_hex_byte
  bcc @emit_literal

  jmp shell_error

@emit_token:
  ldy SCRATCH_IDX
  sta SCRATCH_BASE,y
  inc SCRATCH_IDX
  rts

@emit_literal:
  rts

;

find_name:
  ldx #$00

@next_name:
  stx WORD_IDX 
  lda name_table,x
  beq @not_found
  
  cmp WORD_LEN
  bne @skip_entry
  
  sta TEMP
  inx 
  ldy #$00

@compare_loop:
  lda name_table,x
  cmp (WORD_LO),y
  bne @skip_from_saved 
  inx
  iny

  dec TEMP
  bne @compare_loop

  lda name_table,x
  clc
  rts

@skip_from_saved:
  ldx WORD_IDX

@skip_entry:
  lda name_table,x
  clc
  adc #$02

@skip_inc:
  inx
  dec
  bne @skip_inc
  jmp @next_name

@not_found:
  sec
  rts

;

parse_hex_byte:
  sec
  rts

;

shell_error:
  lda #'!'
  jsr ACIA_PUTC

  lda #$0D
  jsr ACIA_PUTC

  lda #$0A
  jsr ACIA_PUTC

  lda #$FF
  sta SP
  jmp shell
