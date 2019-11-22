; ; main file
;
.setcpu "65c02"

.code

ACIA_DATA = $E000
ACIA_STATUS = $E001
ACIA_COMMAND = $E002
ACIA_CONTROL = $E003

; app entrypoint
main:
    lda #%00001011
    sta ACIA_COMMAND
    lda #%00011111
    sta ACIA_CONTROL

write:
    ldx #0

next_char:
wait_txd_empty:
    lda ACIA_STATUS
    and #$10
    beq wait_txd_empty
    lda text, x
    beq read
    sta ACIA_DATA
    inx
    jmp next_char

read:
wait_rxd_full:
    lda ACIA_STATUS
    and #$08
    beq wait_rxd_full
    lda ACIA_DATA
    jmp write

text:
    .byte "Hello World!", $0d, $0a, $00

; IRQ handler
on_irq:
    rti

; NMI handler
on_nmi:
    rti

.segment "VECTORS"

.addr on_nmi, main, on_irq
