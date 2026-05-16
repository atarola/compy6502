;  The WOZ Monitor for the Apple 1
;  Written by Steve Wozniak in 1976
;  - Modified by Ben Eater: https://gist.github.com/beneater/8136c8b7f2fd95ccdd4562a498758217
;  - Modified by @atarola

.include "include/compy6502.inc"

WOZMON_XAML  = $24                            ; Last "opened" location Low
WOZMON_XAMH  = $25                            ; Last "opened" location High
WOZMON_STL   = $26                            ; Store address Low
WOZMON_STH   = $27                            ; Store address High
WOZMON_L     = $28                            ; Hex value parsing Low
WOZMON_H     = $29                            ; Hex value parsing High
WOZMON_YSAV  = $2A                            ; Used to see if hex value is given
WOZMON_MODE  = $2B                            ; $00=XAM, $7F=STOR, $AE=BLOCK XAM

WOZMON_IN    = $0200                          ; Input buffer

WOZMON_START:
                lda     #%00011110            ; 8-N-1, 9600 baud
                STA     ACIA_CONTROL
                LDA     #$0B                  ; No parity, no echo, no interrupts.
                STA     ACIA_COMMAND
                LDA     #$1B                  ; Begin with escape.

WOZMON_NOTCR:
                CMP     #$08                  ; Backspace key?
                BEQ     WOZMON_BACKSPACE      ; Yes.
                CMP     #$1B                  ; ESC?
                BEQ     WOZMON_ESCAPE         ; Yes.
                INY                           ; Advance text index.
                BPL     WOZMON_NEXTCHAR       ; Auto ESC if line longer than 127.

WOZMON_ESCAPE:
                LDA     #$5C                  ; "\".
                JSR     WOZMON_ECHO           ; Output it.

WOZMON_GETLINE:
                LDA     #$0D                  ; Send CR
                JSR     WOZMON_ECHO
                LDA     #$0A                  ; Send LF for modern terminals.
                JSR     WOZMON_ECHO

                LDY     #$01                  ; Initialize text index.
WOZMON_BACKSPACE:
                DEY                           ; Back up text index.
                BMI     WOZMON_GETLINE        ; Beyond start of line, reinitialize.

WOZMON_NEXTCHAR:
                LDA     ACIA_STATUS           ; Check status.
                AND     #$08                  ; Key ready?
                BEQ     WOZMON_NEXTCHAR       ; Loop until ready.
                LDA     ACIA_DATA             ; Load character. B7 will be '0'.
                CMP     #$7F                  ; Delete key?
                BNE     WOZMON_STORECHAR      ; No.
                LDA     #$08                  ; Treat DEL as backspace.
WOZMON_STORECHAR:
                STA     WOZMON_IN,Y           ; Add to text buffer.
                JSR     WOZMON_ECHO           ; Display character.
                CMP     #$0D                  ; CR?
                BNE     WOZMON_NOTCR          ; No.

                LDY     #$FF                  ; Reset text index.
                LDA     #$00                  ; For XAM mode.
                TAX                           ; X=0.
WOZMON_SETBLOCK:
                ASL
WOZMON_SETSTOR:
                ASL                           ; Leaves $7B if setting STOR mode.
                STA     WOZMON_MODE           ; $00 = XAM, $74 = STOR, $B8 = BLOK XAM.
WOZMON_BLSKIP:
                INY                           ; Advance text index.
WOZMON_NEXTITEM:
                LDA     WOZMON_IN,Y           ; Get character.
                CMP     #$0D                  ; CR?
                BEQ     WOZMON_GETLINE        ; Yes, done this line.
                CMP     #$2E                  ; "."?
                BCC     WOZMON_BLSKIP         ; Skip delimiter.
                BEQ     WOZMON_SETBLOCK       ; Set BLOCK XAM mode.
                CMP     #$3A                  ; ":"?
                BEQ     WOZMON_SETSTOR        ; Yes, set STOR mode.
                CMP     #$52                  ; "R"?
                BEQ     WOZMON_RUN            ; Yes, run user program.
                CMP     #$53
                BNE     WOZMON_NOT_S
                JSR     SREC_LOAD
                JMP     WOZMON_GETLINE

WOZMON_NOT_S:
                STX     WOZMON_L              ; $00 -> L.
                STX     WOZMON_H              ;    and H.
                STY     WOZMON_YSAV           ; Save Y for comparison

WOZMON_NEXTHEX:
                LDA     WOZMON_IN,Y           ; Get character for hex test.
                EOR     #$30                  ; Map digits to $0-9.
                CMP     #$0A                  ; Digit?
                BCC     WOZMON_DIG            ; Yes.
                ADC     #$88                  ; Map letter "A"-"F" to $FA-FF.
                CMP     #$FA                  ; Hex letter?
                BCC     WOZMON_NOTHEX         ; No, character not hex.
WOZMON_DIG:
                ASL
                ASL                           ; Hex digit to MSD of A.
                ASL
                ASL

                LDX     #$04                  ; Shift count.
WOZMON_HEXSHIFT:
                ASL                           ; Hex digit left, MSB to carry.
                ROL     WOZMON_L              ; Rotate into LSD.
                ROL     WOZMON_H              ; Rotate into MSD's.
                DEX                           ; Done 4 shifts?
                BNE     WOZMON_HEXSHIFT       ; No, loop.
                INY                           ; Advance text index.
                BNE     WOZMON_NEXTHEX        ; Always taken. Check next character for hex.

WOZMON_NOTHEX:
                CPY     WOZMON_YSAV           ; Check if L, H empty (no hex digits).
                BNE     WOZMON_NOTESC         ; No, keep parsing.
                JMP     WOZMON_ESCAPE         ; Yes, generate ESC sequence.

WOZMON_NOTESC:

                BIT     WOZMON_MODE           ; Test MODE byte.
                BVC     WOZMON_NOTSTOR        ; B6=0 is STOR, 1 is XAM and BLOCK XAM.

                LDA     WOZMON_L              ; LSD's of hex data.
                STA     (WOZMON_STL,X)        ; Store current 'store index'.
                INC     WOZMON_STL            ; Increment store index.
                BNE     WOZMON_NEXTITEM       ; Get next item (no carry).
                INC     WOZMON_STH            ; Add carry to 'store index' high order.
WOZMON_TONEXTITEM:
                JMP     WOZMON_NEXTITEM       ; Get next command item.

WOZMON_RUN:
                JMP     (WOZMON_XAML)         ; Run at current XAM index.

WOZMON_NOTSTOR:
                BMI     WOZMON_XAMNEXT        ; B7 = 0 for XAM, 1 for BLOCK XAM.

                LDX     #$02                  ; Byte count.
WOZMON_SETADR:
                LDA     WOZMON_L-1,X          ; Copy hex data to
                STA     WOZMON_STL-1,X        ;  'store index'.
                STA     WOZMON_XAML-1,X       ; And to 'XAM index'.
                DEX                           ; Next of 2 bytes.
                BNE     WOZMON_SETADR         ; Loop unless X = 0.

WOZMON_NXTPRNT:
                BNE     WOZMON_PRDATA         ; NE means no address to print.
                LDA     #$0D                  ; CR.
                JSR     WOZMON_ECHO           ; Output it.
                LDA     #$0A                  ; LF for modern terminals.
                JSR     WOZMON_ECHO
                LDA     WOZMON_XAMH           ; 'Examine index' high-order byte.
                JSR     WOZMON_PRBYTE         ; Output it in hex format.
                LDA     WOZMON_XAML           ; Low-order 'examine index' byte.
                JSR     WOZMON_PRBYTE         ; Output it in hex format.
                LDA     #$3A                  ; ":".
                JSR     WOZMON_ECHO           ; Output it.

WOZMON_PRDATA:
                LDA     #$20                  ; Blank.
                JSR     WOZMON_ECHO           ; Output it.
                LDA     (WOZMON_XAML,X)       ; Get data byte at 'examine index'.
                JSR     WOZMON_PRBYTE         ; Output it in hex format.
WOZMON_XAMNEXT:
                STX     WOZMON_MODE           ; 0 -> MODE (XAM mode).
                LDA     WOZMON_XAML
                CMP     WOZMON_L              ; Compare 'examine index' to hex data.
                LDA     WOZMON_XAMH
                SBC     WOZMON_H
                BCS     WOZMON_TONEXTITEM     ; Not less, so no more data to output.

                INC     WOZMON_XAML
                BNE     WOZMON_MOD8CHK        ; Increment 'examine index'.
                INC     WOZMON_XAMH

WOZMON_MOD8CHK:
                LDA     WOZMON_XAML           ; Check low-order 'examine index' byte
                AND     #$07                  ; For MOD 8 = 0
                BPL     WOZMON_NXTPRNT        ; Always taken.

WOZMON_PRBYTE:
                PHA                           ; Save A for LSD.
                LSR
                LSR
                LSR                           ; MSD to LSD position.
                LSR
                JSR     WOZMON_PRHEX          ; Output hex digit.
                PLA                           ; Restore A.

WOZMON_PRHEX:
                AND     #$0F                  ; Mask LSD for hex print.
                ORA     #$30                  ; Add "0".
                CMP     #$3A                  ; Digit?
                BCC     WOZMON_ECHO           ; Yes, output it.
                ADC     #$06                  ; Add offset for letter.

WOZMON_ECHO:
                PHA                           ; Save A.
                STA     ACIA_DATA             ; Output character.
                LDA     #$FF                  ; Initialize delay loop.
WOZMON_TXDELAY:
                DEC                           ; Decrement A.
                BNE     WOZMON_TXDELAY        ; Until A gets to 0.
                PLA                           ; Restore A.
                RTS                           ; Return.
