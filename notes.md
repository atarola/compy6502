## SPI thinking

6502 bus <-> TinyFPGA BX <-> SPI bus
                        -> onboard FRAM
                        -> SPI socket 0
                        -> SPI socket 1
                        -> SPI socket 2

Each socket gets:

GND
3.3v
SCK
MOSI
MISO
CS
IRQ/GPIO
RESET/GPIO

FRAM: Infineon/CYPRESS FM25640B-GTR
