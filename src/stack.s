; stack operations
; See: http://wilsonminesco.com/stacks/StackOps.ASM

.zeropage

STACK_JUMP: .res 2

.code

; remove an item from the stack
.macro pop
    inx
    inx
.endmacro


; make space on the stack for a new value
.macro push value
    dex
    dex
.ifnblank value
    lda value
    sta 0, x
.endif
.endmacro


; stash a variable on the return stack
.macro stash ; (data -- )
    lda 1, x
    pha
    lda 0, x
    pha
    pop
.endmacro


; pull from the return stack back to the data stack
.macro unstash ; ( -- data)
    push
    pla
    sta 0, x
    pla
    sta 1, x
    rts
.endmacro


; increment the address counter
.macro increment ; ( addr -- addr + 1 )
.local @nope
    inc  0, x
    bne  @nope
    inc  1, x
 @nope:
.endmacro


; store the second stack item to the address indicated by the top
store: ; (data, addr -- )
    lda  2, x
    sta  (0, x)
    inc  0, x
    bne  @1
    inc  1, x
 @1:
    LDA  3, x
    STA  (0, x)
    pop
    pop
    RTS


; replace an address at the top of the stack with the contents
; at that address
fetch: ; (addr -- data)
    lda (0, x)
    pha
    inc 0, x
    bne @1
    inc 1, x
@1:
    lda (0, x)
    sta 1, x
    pla
    sta 0, x
    rts


; swap the top stack item and the one below it
swap: ; (b, a -- a, b)
    lda 0, x
    ldy 2, x
    sta 2, x
    sty 0, x

    lda 1, x
    ldy 3, x
    sta 3, x
    sty 1, x
    rts


; duplicate the item at the top of the stack
dup: ; (a -- a, a)
    push
    lda 2, x
    sta 0, x
    lda 3, x
    sta 1, x
    rts


; make an additional copy of the second stack item, and put the copy
; on the top
over: ; (b, a -- b, a, b)
    push
    lda 4, x
    sta 0, x
    lda 5, x
    sta 1, x
    rts


; rotate the third cell to the top
rot: ; (a, b, c -- b, c, a)
    ldy  0, x
    lda  4, x
    sta  0, x
    lda  2, x
    sta  4, x
    sty  2, x

    ldy  1, x
    lda  5, x
    sta  1, x
    lda  3, x
    sta  5, x
    sty  1, x
    rts


; add
plus: ; (a, b -- a + b)
    clc
    lda 0, x
    adc 2, x
    sta 2, x
    lda 1, x
    adc 3, x
    sta 3, x
    pop
    rts


; subtract
minus: ; (a, b -- a - b)
    sec
    lda 2, x
    sbc 0, x
    sta 2, x
    lda 3, x
    sbc 1, x
    sta 3, x
    pop
    rts


; bitwise and
bitwise_and: ; (a, b -- a & b)
    lda 0, x
    and 2, x
    sta 2, x
    lda 1, x
    and 3, x
    sta 3, x
    pop
    rts


; bitwise or
bitwise_or: ; (a, b -- a | b)
    lda 0, x
    ora 2, x
    sta 2, x
    lda 1, x
    ora 3, x
    sta 3, x
    pop
    rts


; bitwise xor
bitwise_xor: ; (a, b -- a xor b)
    lda 0, x
    eor 2, x
    sta 2, x
    lda 1, x
    eor 3, x
    sta 3, x
    pop
    rts


; bitwise not
bitwise_not: ; (a -- !a)
    lda  0, x
    eor  #$ff
    sta  0, x
    lda  1, x
    eor  #$ff
    sta  1, x
    rts
