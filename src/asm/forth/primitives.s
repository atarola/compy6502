; branch ( -- )
prim_branch:
  jmp next

; 0branch ( flag -- )
prim_branch_if_zero:
  jmp next

; beq ( -- )
prim_beq:
  jmp next

; def ( -- )
prim_def:
  jmp next

; enddef ( -- )
prim_enddef:
  jmp next

; clc ( -- )
prim_clc:
  clc
  jmp next

; sec ( -- )
prim_sec:
  sec
  jmp next

; drop ( x -- )
prim_drop:
  inc SP
  inc SP
  jmp next

; dup ( x -- x x )
prim_dup:
  PEEK_AX
  PUSH_AX
  jmp next

; swap ( a b -- b a )
prim_swap:
  POP_AX
  PUSH_RETURN_AX

  PEEK_AX
  PUSH_AX

  POP_RETURN_AX
  POKE_AX 1

  jmp next

; over ( a b -- a b a )
prim_over:
  PEEK_AX 1
  PUSH_AX
  jmp next

; rot ( a b c -- b c a )
prim_rot:
  PEEK_AX 2
  PUSH_RETURN_AX
  POP_AX
  PUSH_RETURN_AX
  POP_AX
  PUSH_RETURN_AX
  POP_AX
  POP_RETURN_AX
  PUSH_AX
  POP_RETURN_AX
  PUSH_AX
  POP_RETURN_AX
  PUSH_AX

  jmp next

; r> ( -- x )
prim_r_from:
  POP_RETURN_AX
  PUSH_AX
  jmp next

; >r ( x -- )
prim_r_to:
  POP_AX
  PUSH_RETURN_AX
  jmp next

; = ( n1 n2 -- flag )
prim_eql:
  POP_AX
  stx TEMP_HI
  sta TEMP_LO

  POP_AX
  cmp TEMP_LO
  bne @false

  txa
  cmp TEMP_HI
  bne @false

  PUSH_TRUE
  jmp next

@false:
  PUSH_FALSE
  jmp next

; 0= ( x -- flag )
prim_eqz:
  POP_AX

  cmp #$00
  bne @false

  txa
  cmp #$00
  bne @false

  PUSH_TRUE
  jmp next

@false:
  PUSH_FALSE
  jmp next

; + ( a b -- a+b )
prim_add:
  clc
  ; fall through to prim_adc

; adc ( a b -- a+b )
prim_adc:
  POP_AX
  stx TEMP_HI
  sta TEMP_LO

  POP_AX
  adc TEMP_LO
  sta TEMP_LO

  txa 
  adc TEMP_HI
  tax

  lda TEMP_LO

  PUSH_AX
  jmp next

; - ( a b -- a-b )
prim_sub: 
  sec
  ; fall through to prim_sbc

; sbc ( a b -- a-b )
prim_sbc:
  POP_AX
  stx TEMP_HI
  sta TEMP_LO

  POP_AX
  sbc TEMP_LO
  sta TEMP_LO

  txa 
  sbc TEMP_HI
  tax

  lda TEMP_LO

  PUSH_AX
  jmp next

; and ( a b -- a&b )
prim_and:
  POP_AX
  stx TEMP_HI
  sta TEMP_LO

  POP_AX
  and TEMP_LO
  sta TEMP_LO

  txa
  and TEMP_HI
  tax

  lda TEMP_LO
  PUSH_AX
  jmp next

; or ( a b -- a|b )
prim_or:
  POP_AX
  stx TEMP_HI
  sta TEMP_LO

  POP_AX
  ora TEMP_LO
  sta TEMP_LO

  txa
  ora TEMP_HI
  tax

  lda TEMP_LO
  PUSH_AX
  jmp next

; eor ( a b -- a^b )
prim_eor:
  POP_AX
  stx TEMP_HI
  sta TEMP_LO

  POP_AX
  eor TEMP_LO
  sta TEMP_LO

  txa
  eor TEMP_HI
  tax

  lda TEMP_LO
  PUSH_AX
  jmp next

; nand ( a b -- ~(a & b) )
prim_nand:
  POP_AX
  stx TEMP_HI
  sta TEMP_LO

  POP_AX
  and TEMP_LO
  eor #$FF
  sta TEMP_LO

  txa
  and TEMP_HI
  eor #$FF
  tax

  lda TEMP_LO
  PUSH_AX
  jmp next

; noop ( -- )
prim_noop:
  jmp next

; @ ( addr -- x )
prim_load:
  POP_AX
  stx TEMP_HI
  sta TEMP_LO

  ldy #$01
  lda (TEMP_LO),y
  tax
  dey
  lda (TEMP_LO),y
  PUSH_AX
  
  jmp next

; ! ( x addr -- )
prim_store:
  POP_AX
  stx TEMP_HI
  sta TEMP_LO

  ldy #$00
  POP_AX
  sta (TEMP_LO),y
  iny
  txa
  sta (TEMP_LO),y

  jmp next

; literal ( -- n )
prim_literal:
  FETCH_IP
  ldx #$00
  PUSH_AX
  jmp next

; end ( -- )
prim_end:
  lda #$0D
  jsr ACIA_PUTC

  lda #$0A
  jsr ACIA_PUTC

  jmp WOZMON

; . ( -- )
prim_print_hex:
  lda #$0D
  jsr ACIA_PUTC

  lda #$0A
  jsr ACIA_PUTC

  ldx SP

  lda STACK_BASE + 1,x ; high byte
  jsr BYTE_TO_HEX
  jsr ACIA_PUTC
  txa
  jsr ACIA_PUTC

  ldx SP
  lda STACK_BASE,x     ; low byte
  jsr BYTE_TO_HEX
  jsr ACIA_PUTC
  txa
  jsr ACIA_PUTC

  jmp next
