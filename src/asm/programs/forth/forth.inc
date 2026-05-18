;
; Forth constants and macros
;

; shared Forth zero-page contract, stack bases, and token IDs
.ifndef FORTH_INC
FORTH_INC = 1

; zero-page workspace
TOKEN = $20         ; current token byte
TEMP_LO = $21       ; scratch byte / low temp
TEMP_HI = $22       ; scratch byte / high temp
IP_LO = $23         ; interpreter IP low byte
IP_HI = $24         ; interpreter IP high byte
TARGET_LO = $25     ; dispatch / indirect address low byte
TARGET_HI = $26     ; dispatch / indirect address high byte
SP = $27            ; data stack pointer
RP = $28            ; return stack pointer
WORD_LO = $29       ; current input word pointer low byte
WORD_HI = $2A       ; current input word pointer high byte
WORD_LEN = $2B      ; current input word length
HEAP_CURR_LO = $2C  ; current heap record low byte
HEAP_CURR_HI = $2D  ; current heap record high byte
HEAP_NEXT_LO = $2E  ; next heap record low byte
HEAP_NEXT_HI = $2F  ; next heap record high byte
SCRATCH_IDX = $30   ; scratch bytecode write index

; fixed runtime buffers
STACK_BASE = $0300
RETURN_BASE = $0400
INPUT_BASE = $0500
SCRATCH_BASE = $0600

; token IDs
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

; increment IP by one byte
.macro INC_IP
  inc IP_LO
  bne :+
  inc IP_HI
:
.endmacro

; increment HEAP_CURR by one byte
.macro INC_HEAP_CURR
  inc HEAP_CURR_LO
  bne :+
  inc HEAP_CURR_HI
:
.endmacro

; fetch byte at IP into A and advance IP
.macro FETCH_IP
  ldy #0
  lda (IP_LO),y
  INC_IP
.endmacro

; read stack cell offset from SP: 0 = SP cell, 1 = one cell below, ...
.macro PEEK_AX cell
  ldy SP
  .ifblank cell
    lda STACK_BASE,y
    ldx STACK_BASE+1,y
  .else
    lda STACK_BASE + ((cell) * 2),y
    ldx STACK_BASE + ((cell) * 2) + 1,y
  .endif
.endmacro

; write A(low)/X(high) to stack cell offset from SP: 0 = SP cell, 1 = one cell below, ...
.macro POKE_AX cell
  ldy SP
  .ifblank cell
    sta STACK_BASE,y
    txa
    sta STACK_BASE+1,y
  .else
    sta STACK_BASE + ((cell) * 2),y
    txa
    sta STACK_BASE + ((cell) * 2) + 1,y
  .endif
.endmacro

; push A(low)/X(high) onto the data stack
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

; push true flag onto the data stack
.macro PUSH_TRUE
  lda #$FF
  ldx #$FF
  PUSH_AX
.endmacro

; push false flag onto the data stack
.macro PUSH_FALSE
  lda #$00
  ldx #$00
  PUSH_AX
.endmacro

; pop the top stack cell into A(low)/X(high)
.macro POP_AX
  ldy SP
  lda STACK_BASE,y
  inc SP

  ldy SP
  ldx STACK_BASE,y
  inc SP
.endmacro

; push A(low)/X(high) onto the return stack
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

; pop the top return-stack cell into A(low)/X(high)
.macro POP_RETURN_AX
  ldy RP
  lda RETURN_BASE,y
  inc RP

  ldy RP
  ldx RETURN_BASE,y
  inc RP
.endmacro

.endif
