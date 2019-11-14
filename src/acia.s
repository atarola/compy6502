; 6551 ACIA handler

.rodata

ACIA_DATA: .word $8800
ACIA_STATUS: .word $8801
ACIA_COMMAND: .word $8802
ACIA_CONTROL: .word $8803
ACIA_INIT_COMMAND: .byte %00001011 ; No parity, no echo, no interrupt
ACIA_INIT_CONTROL: .byte %00011111 ; 1 stop bit, 8 data bits, 19200 baud

.code


; init the acia
acia_init:
    lda ACIA_INIT_COMMAND
    sta ACIA_COMMAND
    lda ACIA_INIT_CONTROL
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
 @wait_rxd_full:
    and #$08
    beq @wait_rxd_full
    push ACIA_DATA
    rts


; write a character to the acia
acia_put: ; ( char -- )
 @wait_txd_empty:
    lda ACIA_STATUS
    and #$10
    beq @wait_txd_empty
    lda 1, x
    sta ACIA_DATA
    pop
    rts


; write a newline to the acia
acia_put_newline: ; ( -- )
    push #$0a
    jsr acia_put
    rts
