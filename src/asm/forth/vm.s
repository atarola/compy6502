.include "include/compy6502.inc"
.include "forth.inc"

; initialize VM state and enter the shell
boot:
  lda #$FF
  sta SP
  sta RP

  lda #STATE_INTERPRET
  sta SHELL_MODE

  jmp shell

; point IP at the scratch buffer and start executing it
execute:
  lda #<SCRATCH_BASE
  sta IP_LO

  lda #>SCRATCH_BASE
  sta IP_HI

; fetch the next token and dispatch through primative_table
next:
  FETCH_IP
  sta TOKEN
  asl ; * 2
  tax

  lda primative_table,x
  sta TARGET_LO

  lda primative_table + 1,x
  sta TARGET_HI
  
  jmp (TARGET_LO)

; primitive call: save IP and jump through body_table
call:
  lda IP_LO
  ldx IP_HI
  PUSH_RETURN_AX

  lda TOKEN
  asl ; * 2
  tax

  lda body_table,x
  sta IP_LO

  lda body_table + 1,x
  sta IP_HI

  jmp next

; primitive return: restore IP from the return stack
return:
  POP_RETURN_AX
  sta IP_LO
  stx IP_HI
  jmp next

; token target that goes back to the shell prompt
shell_return:
  jmp shell

; fatal VM error: print ! and return to Wozmon
invalid:
  lda #'!'
  jsr ACIA_PUTC

  lda #$0D
  jsr ACIA_PUTC

  lda #$0A
  jsr ACIA_PUTC

  jmp WOZMON

; token dispatch table for VM primitives
primative_table:
  .word invalid
  .word prim_end
  .word call
  .word return
  .word shell_return
  .word prim_branch
  .word prim_bez
  .word prim_clc
  .word prim_sec
  .word prim_drop
  .word prim_dup
  .word prim_swap
  .word prim_over
  .word prim_rot
  .word prim_r_from
  .word prim_r_to
  .word prim_eql
  .word prim_eqz
  .word prim_adc
  .word prim_sbc
  .word prim_and
  .word prim_or
  .word prim_eor
  .word prim_nand
  .word prim_sub
  .word prim_noop
  .word prim_load
  .word prim_store
  .word prim_literal
  .word prim_add
  .word prim_print_hex
  .word return
  .word prim_true
  .word prim_false
  .word prim_begin
  .word prim_again
  .word prim_until
  .word prim_if
  .word prim_endif
  .word prim_while
  .word prim_else
  .word prim_repeat
  .word prim_def
  .word prim_enddef

primative_table_used = (* - primative_table) / 2

.repeat 128 - primative_table_used
  .word call
.endrepeat
