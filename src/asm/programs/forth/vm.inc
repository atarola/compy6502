boot:
  lda #$FF
  sta SP
  sta RP
  jmp shell

execute:
  lda #<SCRATCH_BASE
  sta IP_LO

  lda #>SCRATCH_BASE
  sta IP_HI

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

return:
  POP_RETURN_AX
  sta IP_LO
  stx IP_HI
  jmp next

shell_return:
  jmp shell

invalid:
  lda #'!'
  jsr ACIA_PUTC

  lda #$0D
  jsr ACIA_PUTC

  lda #$0A
  jsr ACIA_PUTC

  jmp WOZMON

end:
  lda #$0D
  jsr ACIA_PUTC

  lda #$0A
  jsr ACIA_PUTC

  jmp WOZMON

print_hex:
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

primative_table:
  .word invalid
  .word end
  .word call
  .word return
  .word shell_return
  .word branch
  .word branch_if_zero
  .word beq_word
  .word clc_word
  .word sec_word
  .word drop
  .word dup
  .word swap
  .word over
  .word r_from
  .word r_to
  .word eql
  .word eqz
  .word adc_word
  .word sbc_word
  .word and_word
  .word or_word
  .word eor_word
  .word nand
  .word sub_word
  .word noop
  .word load_word
  .word store_word
  .word literal
  .word add
  .word print_hex

primative_table_used = (* - primative_table) / 2

.repeat 128 - primative_table_used
  .word call
.endrepeat

body_table:
.repeat 128
  .word invalid
.endrepeat
