; 6522 VIA handler
;
; Pins:
; - PA[0-7]: connected directly to the header
;
; SPI Port:
; - PB0: SPI clk (output)
; - PB1: MOSI (output)
; - PB[2-4]: Chip Select (output)
; - PB5: NC (output)
; - PB6: MISO (input)
; - PB7; NC (output)
;
; See Also:
; - https://wilsonminesco.com/6502primer/potpourri.html#BITBANG_SPI

.code

SPI_DATA = $e000
SPI_CONFIG = $e002

; set the clock low
.macro spi_clk_low
    lda #$01
    trb SPI_DATA
.endmacro

; set the clock high
.macro spi_clk_hi
    lda #$01
    tsb SPI_DATA
.endmacro

; do a low pulse
.macro spi_clk_low_pulse
    dec SPI_DATA
    inc SPI_DATA
.endmacro

.macro spi_clk_hi_pulse
    inc SPI_DATA
    dec SPI_DATA
.endmacro

; setup the via for SPI
spi_init:
    lda #%10111111
    sta SPI_CONFIG
    jmp spi_select_none

; select no devices
spi_select_none:
    lda #%00000000
    sta SPI_DATA
    rts

; select device one
spi_select_one:
    lda #$01
    jmp spi_select

; select device two
spi_select_two:
    lda #$02
    jmp spi_select

; select device three
spi_select_three:
    lda #$03
    jmp spi_select

; select device four
spi_select_four:
    lda #$04
    jmp spi_select

; select device five
spi_select_five:
    lda #$05
    jmp spi_select

; select device
spi_select:
    asl a
    asl a
    sta SPI_DATA
    rts

; spi send byte
spi_send: ; N1 ->
    spi_clk_low
    lda #$02

    ; high byte
    ldy #$04
 @high:
    asl 1, x
    trb SPI_DATA
    bcc @high_toggle
    tsb SPI_DATA
 @high_toggle:
    spi_clk_hi_pulse
    dey
    bne @high

    ; low byte
    ldy #$04
 @low:
    asl 1, x
    trb SPI_DATA
    bcc @low_toggle
    tsb SPI_DATA
 @low_toggle:
    spi_clk_hi_pulse
    dey
    bne @low

    sdrop
    rts
