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
  jsr @print_hex_byte

  lda STACK_BASE,x     ; low byte
  jsr @print_hex_byte

  jmp next

@print_hex_byte:
  pha
  lsr
  lsr
  lsr
  lsr
  jsr @print_hex_nibble

  pla
  and #$0F
  jsr @print_hex_nibble
  rts

@print_hex_nibble:
  and #$0F
  cmp #$0A
  bcc @digit

  clc
  adc #'A' - 10
  jmp ACIA_PUTC

@digit:
  clc
  adc #'0'
  jmp ACIA_PUTC

name_table:
  .byte 3, "add", TOKEN_ADD
  .byte 3, "bye", TOKEN_END
  .byte 0

primative_table:
  .word invalid
  .word end
  .word literal
  .word add
  .word print_hex
  .word call
  .word return
  .word dup
  .word shell_return

primative_table_used = (* - primative_table) / 2

.repeat 128 - primative_table_used
  .word call
.endrepeat

body_table:
.repeat 128
  .word invalid
.endrepeat
