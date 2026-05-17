literal:
  FETCH_IP
  ldx #$00
  PUSH_AX

  jmp next

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

push:
  PUSH_AX
  jmp next

dup:
  PEEK_AX
  PUSH_AX
  jmp next