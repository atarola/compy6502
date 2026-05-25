;
; Forth constants and macros
;

; shared Forth zero-page contract, stack bases, and token IDs
.ifndef FORTH_INC
FORTH_INC = 1

; zero-page workspace
TOKEN = $30         ; current token byte
TEMP_LO = $31       ; scratch byte / low temp
TEMP_HI = $32       ; scratch byte / high temp
IP_LO = $33         ; interpreter IP low byte
IP_HI = $34         ; interpreter IP high byte
TARGET_LO = $35     ; dispatch / indirect address low byte
TARGET_HI = $36     ; dispatch / indirect address high byte
SP = $37            ; data stack pointer
RP = $38            ; return stack pointer
WORD_LO = $39       ; current input word pointer low byte
WORD_HI = $3A       ; current input word pointer high byte
WORD_LEN = $3B      ; current input word length
HEAP_CURR_LO = $3C  ; current heap record low byte
HEAP_CURR_HI = $3D  ; current heap record high byte
HEAP_NEXT_LO = $3E  ; next heap record low byte
HEAP_NEXT_HI = $3F  ; next heap record high byte
SCRATCH_IDX = $40   ; scratch bytecode write index
SHELL_MODE = $41    ; front-end state: interpret / def name / compile
COMP_RESERVED_TOKEN = $42 ; token reserved for current definition
COMP_WRITE_PTR_LO = $43 ; staged heap write pointer low byte
COMP_WRITE_PTR_HI = $44 ; staged heap write pointer high byte
COMP_BACK_SP = $45  ; compiler backward-target stack pointer
COMP_FIX_SP = $46   ; compiler forward-fixup stack pointer

; fixed runtime buffers
STACK_BASE = $0300
RETURN_BASE = $0400
INPUT_BASE = $0500
SCRATCH_BASE = $0600

; compiler scratch page
COMP_WORD_BUF = $0700
COMP_BACK_STACK_TOP = $07DF
COMP_FIX_STACK_TOP = $07FF

; token IDs
; when adding make sure you update program.inc
TOKEN_INVALID = $00
TOKEN_END = $01
TOKEN_CALL = $02
TOKEN_RETURN = $03
TOKEN_SHELL_RETURN = $04
TOKEN_BRANCH = $05
TOKEN_BRANCH_IF_ZERO = $06
TOKEN_CLC = $07
TOKEN_SEC = $08
TOKEN_DROP = $09
TOKEN_DUP = $0A
TOKEN_SWAP = $0B
TOKEN_OVER = $0C
TOKEN_ROT = $0D
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
TOKEN_DEF = $1F
TOKEN_ENDDEF = $20

; shell state
STATE_INTERPRET = $00
STATE_WORD_CAPTURE = $01
STATE_PAYLOAD_CAPTURE = $02

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

; increment COMP_WRITE_PTR by one byte
.macro INC_COMP_WRITE_PTR
  inc COMP_WRITE_PTR_LO
  bne :+
  inc COMP_WRITE_PTR_HI
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

; reset the compiler backward-target stack pointer
.macro INIT_COMP_BACK_STACK
  lda #<(COMP_BACK_STACK_TOP + 1)
  sta COMP_BACK_SP
.endmacro

; push A(low)/X(high) onto the compiler backward-target stack
.macro PUSH_COMP_BACK_AX
  sta TEMP_LO

  dec COMP_BACK_SP
  ldy COMP_BACK_SP
  txa
  sta COMP_WORD_BUF,y

  dec COMP_BACK_SP
  ldy COMP_BACK_SP
  lda TEMP_LO
  sta COMP_WORD_BUF,y
.endmacro

; pop the top compiler backward-target cell into A(low)/X(high)
.macro POP_COMP_BACK_AX
  ldy COMP_BACK_SP
  lda COMP_WORD_BUF,y
  inc COMP_BACK_SP

  ldy COMP_BACK_SP
  ldx COMP_WORD_BUF,y
  inc COMP_BACK_SP
.endmacro

; reset the compiler forward-fixup stack pointer
.macro INIT_COMP_FIX_STACK
  lda #<(COMP_FIX_STACK_TOP + 1)
  sta COMP_FIX_SP
.endmacro

; push A(low)/X(high) onto the compiler forward-fixup stack
.macro PUSH_COMP_FIX_AX
  sta TEMP_LO

  dec COMP_FIX_SP
  ldy COMP_FIX_SP
  txa
  sta COMP_WORD_BUF,y

  dec COMP_FIX_SP
  ldy COMP_FIX_SP
  lda TEMP_LO
  sta COMP_WORD_BUF,y
.endmacro

; pop the top compiler forward-fixup cell into A(low)/X(high)
.macro POP_COMP_FIX_AX
  ldy COMP_FIX_SP
  lda COMP_WORD_BUF,y
  inc COMP_FIX_SP

  ldy COMP_FIX_SP
  ldx COMP_WORD_BUF,y
  inc COMP_FIX_SP
.endmacro

.endif
