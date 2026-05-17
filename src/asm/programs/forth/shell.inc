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

;

find_name:
  ldx #$00

@next_name:
  stx WORD_IDX 
  lda name_table,x
  beq @not_found
  
  cmp WORD_LEN
  bne @skip_entry
  
  sta TEMP_LO
  inx 
  ldy #$00

@compare_loop:
  lda name_table,x
  cmp (WORD_LO),y
  bne @skip_from_saved 
  inx
  iny

  dec TEMP_LO
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
  lda WORD_LEN
  beq @bad
  cmp #$03
  bcs @bad

  lda #$00
  sta TEMP_LO

  ldy #$00

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

@bad:
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

;

name_table:
  .byte $06, "branch", TOKEN_BRANCH
  .byte $03, "bez", TOKEN_BRANCH_IF_ZERO
  .byte $03, "beq", TOKEN_BEQ
  .byte $03, "clc", TOKEN_CLC
  .byte $03, "sec", TOKEN_SEC
  .byte $04, "drop", TOKEN_DROP
  .byte $03, "dup", TOKEN_DUP
  .byte $04, "swap", TOKEN_SWAP
  .byte $04, "over", TOKEN_OVER
  .byte $05, "rfrom", TOKEN_R_FROM
  .byte $03, "rto", TOKEN_R_TO
  .byte $03, "eql", TOKEN_EQL
  .byte $03, "eqz", TOKEN_EQZ
  .byte $03, "adc", TOKEN_ADC
  .byte $03, "sbc", TOKEN_SBC
  .byte $03, "and", TOKEN_AND
  .byte $02, "or", TOKEN_OR
  .byte $03, "eor", TOKEN_EOR
  .byte $04, "nand", TOKEN_NAND
  .byte $03, "sub", TOKEN_SUB
  .byte $04, "noop", TOKEN_NOOP
  .byte $05, "fetch", TOKEN_LOAD_WORD
  .byte $05, "store", TOKEN_STORE_WORD
  .byte $03, "bye", TOKEN_END
  .byte $03, "add", TOKEN_ADD
  .byte $05, "print", TOKEN_PRINT_HEX
  .byte $00
