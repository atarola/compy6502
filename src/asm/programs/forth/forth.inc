;
; Forth constants and macros
;

.ifndef FORTH_INC
FORTH_INC = 1

TOKEN = $20
TEMP_LO = $21
TEMP_HI = $22
IP_LO = $23
IP_HI = $24
TARGET_LO = $25
TARGET_HI = $26
SP = $27
RP = $28
WORD_LO = $29 
WORD_HI = $2A
WORD_LEN = $2B
WORD_IDX = $2C
SCRATCH_IDX = $2D

STACK_BASE = $0300
RETURN_BASE = $0400
INPUT_BASE = $0500
SCRATCH_BASE = $0600

TOKEN_INVALID = $00
TOKEN_END = $01
TOKEN_CALL = $02
TOKEN_RETURN = $03
TOKEN_SHELL_RETURN = $04
TOKEN_BRANCH = $05
TOKEN_BRANCH_IF_ZERO = $06
TOKEN_BEQ = $07
TOKEN_CLC = $08
TOKEN_SEC = $09
TOKEN_DROP = $0A
TOKEN_DUP = $0B
TOKEN_SWAP = $0C
TOKEN_OVER = $0D
TOKEN_R_FROM = $0E
TOKEN_R_TO = $0F
TOKEN_EQL = $10
TOKEN_EQZ = $11
TOKEN_ADC = $12
TOKEN_SBC = $13
TOKEN_AND = $14
TOKEN_OR = $15
TOKEN_EOR = $16
TOKEN_NAND = $17
TOKEN_SUB = $18
TOKEN_NOOP = $19
TOKEN_LOAD_WORD = $1A
TOKEN_STORE_WORD = $1B
TOKEN_LITERAL = $1C
TOKEN_ADD = $1D
TOKEN_PRINT_HEX = $1E

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
  sta TEMP_LO

  dec SP
  ldy SP
  txa
  sta STACK_BASE,y

  dec SP
  ldy SP
  lda TEMP_LO
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
  sta TEMP_LO

  dec RP
  ldy RP
  txa
  sta RETURN_BASE,y

  dec RP
  ldy RP
  lda TEMP_LO
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
