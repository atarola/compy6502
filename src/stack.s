; bare-bones stack lib
; the absolute basic set of commands needed to implement data stack-
; based processing.
;
; Notes:
; - top of the stack (TOS) is always 0, x (low byte) and 1, x (high byte)
;
; See:
; - https://users.ece.cmu.edu/~koopman/stack_computers/sec3_2.html
; - http://wilsonminesco.com/stacks/

.code

; push items to the stack, with optional values
.macro spush low, high
    pha
    dex
 .ifblank high
    lda $00
    sta 0, x
 .endif
 .ifnblank high
    lda high
    sta 0, x
 .endif
    dex
 .ifblank low
    lda $00
    sta 0, x
 .endif
 .ifnblank low
    lda low
    sta 0, x
 .endif
    pla
.endmacro

; remove the top item from the stack
.macro sdrop
    inx
    inx
.endmacro

; increment the value on the stack
.macro sinc
 .local @1
    pha
    inc 0, x
    bne @1
    inc 1, x
 @1:
    pla
.endmacro

; Fetch the value at location ADDR in program memory, returning N1
sfetch: ; ADDR -> N1
    lda (0, x)
    pha
    sinc
    lda (0, x)
    sta 1, x
    pla
    sta 0, x
    rts

; Store N1 at location ADDR in program memory.
sstore: ; N1, ADDR ->
    lda 2, x
    sta (0, x)
    sinc
    lda 3, x
    sta (0, x)
    sdrop
    sdrop
    rts

; Duplicate N1, returning a second copy of it on the stack
sdup: ; N1 -> N1, N1
    spush
    lda 2, x
    sta 0, x
    lda 3, x
    sta 1, x
    rts

; Push a copy of the second element on the stack, N1, onto
; the top of the stack
sover: ; N1, N2 -> N1, N2, N1
    spush
    lda 4, x
    sta 0, x
    lda 5, x
    sta 1, x
    rts

; Swap the order of N1 and N2 on the stack
sswap: ; N1, N2 -> N2, N1
    lda 0, x
    pha
    lda 2, x
    sta 0, x
    pla
    sta 2, x
    lda 1, x
    pha
    lda 3, x
    sta 1, x
    pha
    sta 3, x
    rts

; Perform a bitwise AND on N1 and N2, giving result N3
sand: ; N1, N2 -> N3
    lda 0, x
    and 2, x
    sta 2, x
    lda 1, x
    and 3, x
    sta 3, x
    sdrop
    rts

; Perform a bitwise OR on N1 and N2, giving result N3
sor: ; N1, N2 -> N3
    lda 0, x
    ora 2, x
    sta 2, x
    lda 1, x
    ora 3, x
    sta 3, x
    sdrop
    rts

; Perform a bitwise eXclusive OR on N1 and N2, giving result N3
sxor: ; N1, N2 -> N3
    lda 0, x
    eor 2, x
    sta 2, x
    lda 1, x
    eor 3, x
    sta 3, x
    sdrop
    rts

; Perform a bitwise not on N1
snot: ; N1 -> !N1
    lda 0, x
    eor #$ff
    sta 0, x
    lda 1, x
    eor #$ff
    sta 1, x
    rts

; Compare N1 and N2, storing the result in N3
seq: ; N1, N2 -> N3
    lda 0, x
    cmp 2, x
    bne @neq
    lda 1, x
    cmp 3, x
    bne @neq
    lda #$ff
    jmp @done
 @neq:
    lda #$00
 @done:
    sta 2, x
    sta 3, x
    sdrop
    rts

; Add N1 and N2, giving sum N3.
sadd: ; N1, N2 -> N3
    clc
    lda 0, x
    adc 2, x
    sta 2, x
    lda 1, x
    adc 3, x
    sta 3, x
    sdrop
    rts

; Subtract N2 from N1, giving difference N3.
ssub: ; N1, N2 -> N3
    sec
    lda 2, x
    sbc 0, x
    sta 2, x
    lda 3, x
    sbc 1, x
    sta 3, x
    sdrop
    rts
