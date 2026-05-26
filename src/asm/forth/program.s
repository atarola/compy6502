.include "include/compy6502.inc"
.include "forth.inc"

;
; program space, to be overloaded during runtime or load
;

DICT_NEXT_TOKEN: .byte TOKEN_ENDDEF + 1

HEAP_FREE_LO: .byte <heap_seed_end ; empty space address low byte
HEAP_FREE_HI: .byte >heap_seed_end ; empty space address high byte

HEAP_TAIL_LO: .byte <false_record  ; name list tail low byte
HEAP_TAIL_HI: .byte >false_record  ; name list tail high byte

body_table:
.repeat 256
  .word invalid
.endrepeat

; dictionary heap: linked name and payload records
heap:
def_record:
  .word enddef_record
  .byte $03, "def", TOKEN_DEF

enddef_record:
  .word branch_record
  .byte $06, "enddef", TOKEN_ENDDEF

branch_record:
  .word bez_record
  .byte $06, "branch", TOKEN_BRANCH

bez_record:
  .word begin_record
  .byte $03, "bez", TOKEN_BEZ

begin_record:
  .word again_record
  .byte $05, "begin", TOKEN_BEGIN

again_record:
  .word until_record
  .byte $05, "again", TOKEN_AGAIN

until_record:
  .word if_record
  .byte $05, "until", TOKEN_UNTIL

if_record:
  .word endif_record
  .byte $02, "if", TOKEN_IF

endif_record:
  .word while_record
  .byte $05, "endif", TOKEN_ENDIF

while_record:
  .word else_record
  .byte $05, "while", TOKEN_WHILE

else_record:
  .word repeat_record
  .byte $04, "else", TOKEN_ELSE

repeat_record:
  .word clc_record
  .byte $06, "repeat", TOKEN_REPEAT

clc_record:
  .word sec_record
  .byte $03, "clc", TOKEN_CLC

sec_record:
  .word drop_record
  .byte $03, "sec", TOKEN_SEC

drop_record:
  .word dup_record
  .byte $04, "drop", TOKEN_DROP

dup_record:
  .word swap_record
  .byte $03, "dup", TOKEN_DUP

swap_record:
  .word over_record
  .byte $04, "swap", TOKEN_SWAP

over_record:
  .word rot_record
  .byte $04, "over", TOKEN_OVER

rot_record:
  .word rfrom_record
  .byte $03, "rot", TOKEN_ROT

rfrom_record:
  .word rto_record
  .byte $05, "rfrom", TOKEN_R_FROM

rto_record:
  .word eql_record
  .byte $03, "rto", TOKEN_R_TO

eql_record:
  .word eqz_record
  .byte $03, "eql", TOKEN_EQL

eqz_record:
  .word lt_record
  .byte $03, "eqz", TOKEN_EQZ

lt_record:
  .word lte_record
  .byte $02, "lt", TOKEN_LT

lte_record:
  .word gt_record
  .byte $03, "lte", TOKEN_LTE

gt_record:
  .word gte_record
  .byte $02, "gt", TOKEN_GT

gte_record:
  .word adc_record
  .byte $03, "gte", TOKEN_GTE

adc_record:
  .word sbc_record
  .byte $03, "adc", TOKEN_ADC

sbc_record:
  .word and_record
  .byte $03, "sbc", TOKEN_SBC

and_record:
  .word or_record
  .byte $03, "and", TOKEN_AND

or_record:
  .word eor_record
  .byte $02, "or", TOKEN_OR

eor_record:
  .word nand_record
  .byte $03, "eor", TOKEN_EOR

nand_record:
  .word sub_record
  .byte $04, "nand", TOKEN_NAND

sub_record:
  .word noop_record
  .byte $03, "sub", TOKEN_SUB

noop_record:
  .word fetch_record
  .byte $04, "noop", TOKEN_NOOP

fetch_record:
  .word store_record
  .byte $05, "fetch", TOKEN_LOAD_WORD

store_record:
  .word bye_record
  .byte $05, "store", TOKEN_STORE_WORD

bye_record:
  .word add_record
  .byte $03, "bye", TOKEN_END

add_record:
  .word print_record
  .byte $03, "add", TOKEN_ADD

print_record:
  .word return_word_record
  .byte $05, "print", TOKEN_PRINT_HEX

return_word_record:
  .word true_record
  .byte $06, "return", TOKEN_RETURN_WORD

true_record:
  .word false_record
  .byte $04, "true", TOKEN_TRUE

false_record:
  .word $FFFF
  .byte $05, "false", TOKEN_FALSE

; marker for the end of the seeded heap
heap_seed_end:
