; ( -- )
prim_branch:
  jmp next

; ( flag -- )
prim_branch_if_zero:
  jmp next

; ( flag -- )
prim_beq:
  jmp next

; ( -- )
prim_clc:
  jmp next

; ( -- )
prim_sec:
  jmp next

; ( x -- )
prim_drop:
  jmp next

; ( x -- x x )
prim_dup:
  jmp next

; ( a b -- b a )
prim_swap:
  jmp next

; ( a b -- a b a )
prim_over:
  jmp next

; ( -- x )
prim_r_from:
  jmp next

; ( x -- )
prim_r_to:
  jmp next

; ( a b -- flag )
prim_eql:
  jmp next

; ( a -- flag )
prim_eqz:
  jmp next

; ( a b -- a+b )
prim_adc:
  jmp next

; ( a b -- a-b )
prim_sbc:
  jmp next

; ( a b -- a&b )
prim_and:
  jmp next

; ( a b -- a|b )
prim_or:
  jmp next

; ( a b -- a^b )
prim_eor:
  jmp next

; ( a b -- ~(a & b) )
prim_nand:
  jmp next

; ( a b -- a+b )
prim_add:
  ldx SP
  lda STACK_BASE,x
  clc
  adc STACK_BASE + 2,x
  sta STACK_BASE + 2,x

  lda STACK_BASE + 1,x
  adc STACK_BASE + 3,x
  sta STACK_BASE + 3,x

  inc SP
  inc SP
  jmp next

; ( a b -- a-b )
prim_sub:
  jmp next

; ( -- )
prim_noop:
  jmp next

; ( addr -- x )
prim_load:
  jmp next

; ( x addr -- )
prim_store:
  jmp next

; ( -- n )
prim_literal:
  FETCH_IP
  ldx #$00
  PUSH_AX
  jmp next

; ( -- )
prim_end:
  lda #$0D
  jsr ACIA_PUTC

  lda #$0A
  jsr ACIA_PUTC

  jmp WOZMON

; ( -- )
prim_print_hex:
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