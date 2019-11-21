; 6551 ACIA handler

.rodata

ACIA_DATA = $E000
ACIA_STATUS = $E001
ACIA_COMMAND = $E002
ACIA_CONTROL = $E003
ACIA_INIT_COMMAND = %00001011 ; No parity, no echo, no interrupt
ACIA_INIT_CONTROL = %00011111 ; 1 stop bit, 8 data bits, 19200 baud

.code


; init the acia
acia_init:
    lda #ACIA_INIT_COMMAND
    sta ACIA_COMMAND
    lda #ACIA_INIT_CONTROL
    sta ACIA_CONTROL
    rts


; write a null-terminated string to the acia
; will output a newline-terminated string
acia_write: ; ( addr -- )
 @next_char:
    jsr dup
    jsr fetch
    lda 1, x
    beq @eos
    jsr acia_put
    increment
    jmp @next_char
 @eos:
    jsr acia_put_newline
    pop
    rts


; read a newline-termiated string from the acia
; will output a null-terminated string
acia_read: ; ( addr -- )
 @next_char:
    jsr dup
    jsr acia_get
    lda 1, x
    cmp $0a
    beq @eos
    jsr swap
    jsr store
    increment
    jmp @next_char
 @eos:
    lda #$00
    sta 1, x
    jsr swap
    jsr store
    pop
    rts


; read a character from the acia
acia_get: ; (  -- char )
 @not_full:
    lda ACIA_STATUS
    and #$08
    beq @not_full
    push ACIA_DATA
    jsr fetch
    rts


; write a character to the acia
acia_put: ; ( char -- )
 @not_empty:
    lda ACIA_STATUS
    and #$10
    beq @not_empty
    lda 1, x
    sta ACIA_DATA
    pop
    rts


; write a newline to the acia
acia_put_newline: ; ( -- )
    push #$0a
    jsr acia_put
    rts
