;
; Forth constants and macros
;

.ifndef FORTH_INC
FORTH_INC = 1

TOKEN = $20
TEMP = $21
IP_LO = $22
IP_HI = $23
TARGET_LO = $24
TARGET_HI = $25
SP = $26
RP = $27
WORD_LO = $28 
WORD_HI = $29
WORD_LEN = $2A
WORD_IDX = $2B
SCRATCH_IDX = $2C

STACK_BASE = $0300
RETURN_BASE = $0400
INPUT_BASE = $0500
SCRATCH_BASE = $0600

TOKEN_INVALID = $00
TOKEN_END = $01
TOKEN_LITERAL = $02
TOKEN_ADD = $03
TOKEN_PRINT_HEX = $04
TOKEN_CALL = $05
TOKEN_RETURN = $06
TOKEN_DUP = $07
TOKEN_SHELL_RETURN = $08

.macro INC_IP
  inc IP_LO
  bne :+
  inc IP_HI
:
.endmacro

.macro FETCH_IP
  ldy #0
  lda (IP_LO),y
  INC_IP
.endmacro

.macro PEEK_AX
  ldy SP
  lda STACK_BASE,y
  ldx STACK_BASE+1,y
.endmacro

.macro PUSH_AX
  sta TEMP

  dec SP
  ldy SP
  txa
  sta STACK_BASE,y

  dec SP
  ldy SP
  lda TEMP
  sta STACK_BASE,y
.endmacro

.macro POP_AX
  ldy SP
  lda STACK_BASE,y
  inc SP

  ldy SP
  ldx STACK_BASE,y
  inc SP
.endmacro

.macro PUSH_RETURN_AX
  sta TEMP

  dec RP
  ldy RP
  txa
  sta RETURN_BASE,y

  dec RP
  ldy RP
  lda TEMP
  sta RETURN_BASE,y
.endmacro

.macro POP_RETURN_AX
  ldy RP
  lda RETURN_BASE,y
  inc RP

  ldy RP
  ldx RETURN_BASE,y
  inc RP
.endmacro

.endif