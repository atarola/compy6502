.include "include/compy6502.inc"

; Update SPI configuration.
; in:  A = configuration byte
; out: carry clear = configuration applied
;      carry set   = configuration failed
; clobbers: A, flags
spi_configure:
  sta SPI_CONFIG
  clc
  rts

; Assert the configured SPI chip select.
; in: none
; out: carry clear = released
;      carry set   = failed
; clobbers: A, flags
spi_select:
  lda #SPI_CS_ENABLE
  ora SPI_CONFIG
  sta SPI_CONFIG
  clc
  rts

; Release the configured SPI chip select.
; in: none
; out: carry clear = released
;      carry set   = failed
; clobbers: A, flags
spi_deselect:
  lda #SPI_CS_ENABLE
  eor #$FF
  and SPI_CONFIG
  sta SPI_CONFIG
  clc
  rts

; Transfer one SPI byte.
; in:  A = byte to transmit
; out: A = received byte
;      carry clear = success
;      carry set   = transfer failed
; clobbers: A, flags
spi_transfer:
  sta SPI_DATA

@wait:
  lda SPI_STATUS
  and #SPI_BUSY
  bne @wait

  lda SPI_DATA
  clc
  rts

; Transfer one SPI byte.
; in:  A = byte to transmit
; out: carry clear = success
;      carry set   = transfer failed
; clobbers: A, flags
spi_write:
  sta SPI_DATA

@wait:
  lda SPI_STATUS
  and #SPI_BUSY
  bne @wait
  clc
  rts
