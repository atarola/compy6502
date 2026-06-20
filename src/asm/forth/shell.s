.include "include/compy6502.inc"
.include "forth.inc"

; shell prompt and line reader
shell:
next_line:
  ; scratch starts empty for each input line
  lda #$00
  sta SCRATCH_IDX

  lda #$0A
  jsr ACIA_PUTC

  lda #$0D
  jsr ACIA_PUTC

  lda #<INPUT_BASE
  sta K_PTR_LO

  lda #>INPUT_BASE
  sta K_PTR_HI

  ; change the line prefix per mode
  lda #'>'
  ldx SHELL_MODE
  cpx #STATE_PAYLOAD_CAPTURE
  bne :+
  lda #'-'
:
  jsr LINE_EDIT

  ; Pascal string text starts at byte 1, with length in byte 0
  ldx #$01

; skip spaces and find the start of the next word
@find_word_start:
  ; refresh the current line length because TEMP_HI is scratch elsewhere
  lda INPUT_BASE
  sta TEMP_HI

  cpx TEMP_HI
  beq @check_start
  bcc @check_start
  jmp @execute_line

@check_start:
  lda INPUT_BASE,x
  cmp #' '
  bne @word_start
  inx
  jmp @find_word_start

; record the start index of this word, then measure until space or EOL
@word_start:
  stx WORD_LO
  lda #>INPUT_BASE
  sta WORD_HI
  ldy #$00

@find_word_end:
  ; INPUT_BASE[0] is the last valid character index limit
  lda INPUT_BASE
  sta TEMP_HI

  cpx TEMP_HI
  beq @check_end
  bcc @check_end
  jmp @word_end_line

@check_end:
  lda INPUT_BASE,x
  cmp #' '
  beq @word_end_space

  inx
  iny
  jmp @find_word_end

; emit a word terminated by space, then keep scanning
@word_end_space:
  sty WORD_LEN
  phx
  jsr resolve_word
  plx
  jmp @find_word_start

; emit the final word and finish the line
@word_end_line:
  sty WORD_LEN
  jsr resolve_word

  lda SHELL_MODE
  cmp #STATE_PAYLOAD_CAPTURE
  beq next_line

  jmp @execute_line

; append shell return and run the scratch buffer
@execute_line:
  ldy SCRATCH_IDX
  lda #TOKEN_SHELL_RETURN
  sta SCRATCH_BASE,y
  inc SCRATCH_IDX
  jmp execute

; dispatch the current word according to the shell front-end state
resolve_word:
  lda SHELL_MODE
  cmp #STATE_INTERPRET
  beq resolve_interpret_word

  cmp #STATE_WORD_CAPTURE
  beq resolve_defname_word

  cmp #STATE_PAYLOAD_CAPTURE
  beq resolve_compile_word

  jmp shell_error

; resolve a word during the interpret state
resolve_interpret_word:
  jsr find_name
  bcc @handle_name

  jsr parse_hex_word
  bcc @handle_literal

  jmp shell_error

@handle_name:
  cmp #TOKEN_DEF
  beq @handle_def

  ldy SCRATCH_IDX
  sta SCRATCH_BASE,y
  inc SCRATCH_IDX
  rts

; append TOKEN_LITERAL plus the parsed word value
@handle_literal:
  sta TEMP_LO
  stx TEMP_HI

  ldy SCRATCH_IDX
  lda #TOKEN_LITERAL
  sta SCRATCH_BASE,y
  inc SCRATCH_IDX

  ldy SCRATCH_IDX
  lda TEMP_LO
  sta SCRATCH_BASE,y
  inc SCRATCH_IDX

  ldy SCRATCH_IDX
  lda TEMP_HI
  sta SCRATCH_BASE,y
  inc SCRATCH_IDX
  rts

@handle_def:
  lda DICT_NEXT_TOKEN
  beq @too_many_words

  ; reserve the next token now so the definition can refer to itself later
  sta COMP_RESERVED_TOKEN
  inc DICT_NEXT_TOKEN

  ; reset compiler stacks so an unclosed begin/if/while from a previously
  ; aborted definition can't leak into this one and clobber COMP_WORD_BUF
  INIT_COMP_BACK_STACK
  INIT_COMP_FIX_STACK

  lda #STATE_WORD_CAPTURE
  sta SHELL_MODE
  rts

@too_many_words:
  jmp shell_error

; the word after `def` becomes the name and locks in the heap write start
resolve_defname_word:
  ; set the high-water mark of the heap for the next writing block
  lda HEAP_FREE_LO
  sta COMP_WRITE_PTR_LO

  lda HEAP_FREE_HI
  sta COMP_WRITE_PTR_HI

  ; setup SPAN_TO_STR
  lda #<COMP_WORD_BUF
  sta K_PTR_LO

  lda #>COMP_WORD_BUF
  sta K_PTR_HI

  lda WORD_LO
  sta K_PTR2_LO

  lda WORD_HI
  sta K_PTR2_HI

  lda WORD_LEN
  jsr SPAN_TO_STR

  ; next state
  lda #STATE_PAYLOAD_CAPTURE
  sta SHELL_MODE
  rts

; compile mode emits directly into heap space instead of scratch space
resolve_compile_word:
  jsr find_name
  bcc @handle_name

  jsr parse_hex_word
  bcc @handle_literal

  jmp shell_error

@handle_name:
  cmp #TOKEN_ENDDEF
  bne :+
  jmp @handle_enddef
:

  cmp #TOKEN_BEGIN
  bne :+
  jmp @handle_begin
:

  cmp #TOKEN_AGAIN
  bne :+
  jmp @handle_again
:

  cmp #TOKEN_UNTIL
  bne :+
  jmp @handle_until
:

  cmp #TOKEN_IF
  bne :+
  jmp @handle_if
:

  cmp #TOKEN_ELSE
  bne :+
  jmp @handle_else
:

  cmp #TOKEN_ENDIF
  bne :+
  jmp @handle_endif
:

  cmp #TOKEN_WHILE
  bne :+
  jmp @handle_while
:

  cmp #TOKEN_REPEAT
  bne :+
  jmp @handle_repeat
:

  ldy #$00
  sta (COMP_WRITE_PTR_LO),y
  INC_COMP_WRITE_PTR
  rts

; append TOKEN_LITERAL plus the parsed word value
@handle_literal:
  sta TEMP_LO
  stx TEMP_HI
  ldy #$00

  lda #TOKEN_LITERAL
  sta (COMP_WRITE_PTR_LO),y
  INC_COMP_WRITE_PTR

  lda TEMP_LO
  sta (COMP_WRITE_PTR_LO),y
  INC_COMP_WRITE_PTR

  lda TEMP_HI
  sta (COMP_WRITE_PTR_LO),y
  INC_COMP_WRITE_PTR

  rts

@handle_begin:
  lda COMP_WRITE_PTR_LO
  ldx COMP_WRITE_PTR_HI
  PUSH_COMP_BACK_AX
  rts

@handle_again:
  lda #TOKEN_BRANCH
  jmp @handle_back_ptr

@handle_until:
  lda #TOKEN_BEZ
  jmp @handle_back_ptr

@handle_back_ptr:
  ldy #$00
  sta (COMP_WRITE_PTR_LO),y
  INC_COMP_WRITE_PTR

  POP_COMP_BACK_AX
  dea
  sec
  sbc COMP_WRITE_PTR_LO
  
  ldy #$00
  sta (COMP_WRITE_PTR_LO),y
  INC_COMP_WRITE_PTR

  rts

@handle_if:
@handle_while:
  ldy #$00
  lda #TOKEN_BEZ
  sta (COMP_WRITE_PTR_LO),y
  INC_COMP_WRITE_PTR

  lda #$00
  sta (COMP_WRITE_PTR_LO),y

  lda COMP_WRITE_PTR_LO
  ldx COMP_WRITE_PTR_HI
  PUSH_COMP_FIX_AX
  INC_COMP_WRITE_PTR

  rts 

@handle_else:
  ldy #$00
  lda #TOKEN_BRANCH
  sta (COMP_WRITE_PTR_LO),y
  INC_COMP_WRITE_PTR

  ldy #$00
  lda #$00
  sta (COMP_WRITE_PTR_LO),y

  lda COMP_WRITE_PTR_LO
  ldx COMP_WRITE_PTR_HI
  PUSH_RETURN_AX
    
  INC_COMP_WRITE_PTR

  jsr @rewrite_backref

  POP_RETURN_AX
  PUSH_COMP_FIX_AX
  
  rts 

@handle_endif:
@rewrite_backref:
  POP_COMP_FIX_AX
  sta TEMP_LO
  stx TEMP_HI
  
  ldy #$00
  lda COMP_WRITE_PTR_LO
  dea 
  sec 
  sbc TEMP_LO
  sta (TEMP_LO),y

  rts

@handle_repeat:
  lda #TOKEN_BRANCH
  jsr @handle_back_ptr
  jsr @rewrite_backref
  rts

; finish the payload, append the dictionary node, and publish the new word
@handle_enddef:
  ldy #$00

  ; add the return to the payload
  lda #TOKEN_RETURN
  sta (COMP_WRITE_PTR_LO),y 
  INC_COMP_WRITE_PTR

  ; set the value the tail points to to the current write pointer
  lda HEAP_TAIL_LO
  sta TEMP_LO
  lda HEAP_TAIL_HI
  sta TEMP_HI

  ldy #$00
  lda COMP_WRITE_PTR_LO
  sta (TEMP_LO),y
  iny
  lda COMP_WRITE_PTR_HI
  sta (TEMP_LO),y

  ; set the new tail to be the current ptr
  lda COMP_WRITE_PTR_LO
  sta HEAP_TAIL_LO
  lda COMP_WRITE_PTR_HI
  sta HEAP_TAIL_HI

  ; write the sentinel for the end of the heap
  ldy #$00
  lda #$FF
  sta (COMP_WRITE_PTR_LO),y 
  INC_COMP_WRITE_PTR
  sta (COMP_WRITE_PTR_LO),y 
  INC_COMP_WRITE_PTR

  ; copy the name into the heap
  lda COMP_WRITE_PTR_LO
  sta K_PTR_LO
  lda COMP_WRITE_PTR_HI
  sta K_PTR_HI

  lda #<COMP_WORD_BUF
  sta K_PTR2_LO
  lda #>COMP_WORD_BUF
  sta K_PTR2_HI 
  
  jsr STR_COPY

  ; increment the write pointer by the size of the string + 1
  ldy #$00
  lda (COMP_WRITE_PTR_LO),y
  sta TEMP_LO
  inc TEMP_LO

  lda COMP_WRITE_PTR_LO
  clc
  adc TEMP_LO
  sta COMP_WRITE_PTR_LO
  bcc :+
  inc COMP_WRITE_PTR_HI
:

  ; add the token at the end of the node
  ldy #$00
  lda COMP_RESERVED_TOKEN
  sta (COMP_WRITE_PTR_LO),y
  INC_COMP_WRITE_PTR

  ; add the top of heap to the body table at the right place
  asl
  tax
  lda HEAP_FREE_LO
  sta body_table,x
  
  inx
  lda HEAP_FREE_HI
  sta body_table,x

  ; set the top of heap to the write pointer
  lda COMP_WRITE_PTR_LO
  sta HEAP_FREE_LO

  lda COMP_WRITE_PTR_HI
  sta HEAP_FREE_HI

  ; set the state back to interpret
  lda #STATE_INTERPRET
  sta SHELL_MODE
  rts

; scan through the name records in the heap
find_name:
  lda #<heap
  sta HEAP_CURR_LO

  lda #>heap
  sta HEAP_CURR_HI

; linked records are: next ptr, name length, name bytes, token byte
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
  bne :+

  lda HEAP_NEXT_HI
  cmp #$FF
  beq @not_found
  sta HEAP_CURR_HI
  jmp @next_name

:
  lda HEAP_NEXT_HI
  sta HEAP_CURR_HI

  jmp @next_name

; no table entry matched
@not_found:
  sec
  rts

; parse a 1-4 digit hex literal into a word for immediate execution
; or compilation as TOKEN_LITERAL payload
; out: A = low byte, X = high byte
parse_hex_word:
  lda WORD_LEN
  beq @bad
  cmp #$05
  bcs @bad

  lda #$00
  sta TEMP_LO
  sta TEMP_HI

  ldy #$00

; fold one hex digit from HEX_TO_NIBBLE into the 16-bit accumulator
@parse_loop:
  lda (WORD_LO),y
  jsr HEX_TO_NIBBLE
  bcs @bad

  tax

  asl TEMP_LO
  rol TEMP_HI
  asl TEMP_LO
  rol TEMP_HI
  asl TEMP_LO
  rol TEMP_HI
  asl TEMP_LO
  rol TEMP_HI

  lda TEMP_LO
  txa
  ora TEMP_LO
  sta TEMP_LO

  iny
  cpy WORD_LEN
  bne @parse_loop

  lda TEMP_LO
  ldx TEMP_HI
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

  lda #STATE_INTERPRET
  sta SHELL_MODE

  lda #$0D
  jsr ACIA_PUTC

  lda #$0A
  jsr ACIA_PUTC

  jmp shell
