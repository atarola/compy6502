; ( -- )
branch:
  jmp next

; ( flag -- )
branch_if_zero:
  jmp next

; ( flag -- )
beq_word:
  jmp next

; ( -- )
clc_word:
  jmp next

; ( -- )
sec_word:
  jmp next

; ( x -- )
drop:
  jmp next

; ( x -- x x )
dup:
  jmp next

; ( a b -- b a )
swap:
  jmp next

; ( a b -- a b a )
over:
  jmp next

; ( -- x )
r_from:
  jmp next

; ( x -- )
r_to:
  jmp next

; ( a b -- flag )
eql:
  jmp next

; ( a -- flag )
eqz:
  jmp next

; ( a b -- a+b )
adc_word:
  jmp next

; ( a b -- a-b )
sbc_word:
  jmp next

; ( a b -- a&b )
and_word:
  jmp next

; ( a b -- a|b )
or_word:
  jmp next

; ( a b -- a^b )
eor_word:
  jmp next

; ( a b -- ~(a & b) )
nand:
  jmp next

; ( a b -- a-b )
sub_word:
  jmp next

; ( -- )
noop:
  jmp next

; ( addr -- x )
load_word:
  jmp next

; ( x addr -- )
store_word:
  jmp next

; ( -- n )
literal:
  FETCH_IP
  ldx #$00
  PUSH_AX
  jmp next

; ( a b -- a+b )
add:
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
