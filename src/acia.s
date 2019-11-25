; 6551 ACIA handler

.code

ACIA_DATA = $e000
ACIA_STATUS = $e001
ACIA_COMMAND = $e002
ACIA_CONTROL = $e003

; init the acia
acia_init:
    lda #%00001011 ; No parity, no echo, no interrupt
    sta ACIA_COMMAND
    lda #%00011111 ; 1 stop bit, 8 data bits, 19200 baud
    sta ACIA_CONTROL
    rts

; write a null-terminated string to the acia
; will output a newline-terminated string
acia_write: ; ( addr -- )
 @next_char:
    jsr sdup
    jsr sfetch
    lda 1, x
    beq @eos
    jsr acia_put
    sinc
    jmp @next_char
 @eos:
    jsr acia_put_newline
    sdrop
    rts

; read a newline-termiated string from the acia
; will output a null-terminated string
acia_read: ; ( addr -- )
 @next_char:
    spush
    jsr acia_get
    lda 1, x
    cmp $0a
    beq @eos
    jsr sswap
    jsr sstore
    sinc
    jmp @next_char
 @eos:
    sta 1, x
    jsr sswap
    jsr sstore
    sdrop
    rts

; read a character from the acia
acia_get: ; (  -- char )
 @wait_rxd_full:
    lda ACIA_STATUS
    and #$08
    beq @wait_rxd_full
    spush
    lda ACIA_DATA
    sta 1, x
    rts

; write a character to the acia
acia_put: ; ( char -- )
 @wait_txd_empty:
    lda ACIA_STATUS
    and #$10
    beq @wait_txd_empty
    lda 1, x
    sta ACIA_DATA
    sdrop
    rts

; write a newline to the acia
acia_put_newline: ; ( -- )
    spush #$00, #$0a
    spush #$00, #$0d
    jsr acia_put
    jsr acia_put
    rts
