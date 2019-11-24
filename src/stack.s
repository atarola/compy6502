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
    sta  1, x
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

; Push N1 onto the hardware stack
shpush: ; N1 ->
    lda 1, x
    pha
    lda 0, x
    pha
    sdrop
    rts

; Pop N1 from the hardware stack
shpop: ; -> N1
    spush
    pla
    sta 0, x
    pla
    sta 1, x
    rts

; Add N1 and N2, giving sum N3.
sadd: ; N1, N2 -> N3
    rts

; Subtract N2 from N1, giving difference N3.
ssub: ; N1, N2 -> N3
    rts

; Duplicate N1, returning a second copy of it on the stack
sdup: ; N1 -> N1, N1
    rts

; Push a copy of the second element on the stack, N1, onto
; the top of the stack
sover: ; N1, N2 -> N1, N2, N1
    rts

; Swap the order of N1 and N2 on the stack
sswap: ; N1, N2 -> N2, N1
    rts

; Perform a bitwise AND on N1 and N2, giving result N3
sand: ; N1, N2 -> N3
    rts

; Perform a bitwise OR on N1 and N2, giving result N3
sor: ; N1, N2 -> N3
    rts

; Perform a bitwise eXclusive OR on N1 and N2, giving result N3
sxor: ; N1, N2 -> N3
    rts
