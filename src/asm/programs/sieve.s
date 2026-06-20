.setcpu "65c02"

.include "include/compy6502.inc"

; base of our memory space
BASE = $0300

; current number
CURRENT = $2C

; current offset
POINTER = $2D

.org $3000
  lda #$0A
  jsr ACIA_PUTC

  lda #$0D
  jsr ACIA_PUTC

  ldx #$FF

@init_loop:
  ; init our arena
  txa 
  beq @end_init_loop
  
  lda #$01
  sta BASE,x
  dex
  jmp @init_loop

@end_init_loop:
  ; 0 and 1 handling
  ldx #$00
  lda #$00
  sta BASE,x
  inx
  sta BASE,x
  inx

  ; setup current
  lda #$01
  sta CURRENT

@find_next_cur:
  ; loop over the arena till we find a prime
  ; going to printing if we overflow x
  inc CURRENT
  beq @print_primes

  ldx CURRENT
  lda BASE,x
  bne @process_current
  jmp @find_next_cur

@process_current:
  ; mark every multiple of current as composite
  stx POINTER

@process_current_loop:
  lda CURRENT
  clc
  adc POINTER
  bcs @find_next_cur
  sta POINTER

  ldx POINTER
  lda #$00
  sta BASE,x 

  jmp @process_current_loop

@print_primes:
  ; loop over the arena till we find a prime
  ldx #$01

@print_primes_loop:
  inx 
  beq @sieve_done

  lda BASE,x
  bne @print_found_prime
  jmp @print_primes_loop

@print_found_prime:
  txa 
  jsr print_u8
  jmp @print_primes_loop

@sieve_done:
  lda #$0D
  jsr ACIA_PUTC

  lda #$0A
  jsr ACIA_PUTC

  jmp WOZMON ; back to wozmon

print_u8:
  phx
  ldx #$00

@hundreds:
  cmp #100
  bcc @tens
  sec
  sbc #100
  inx
  jmp @hundreds

@tens:
  ldy #$00

@tens_sub:
  cmp #10
  bcc @emit
  sec
  sbc #10
  iny
  jmp @tens_sub

@emit:
  pha
  cpx #$00
  beq @maybe_tens
  txa
  clc
  adc #'0'
  jsr ACIA_PUTC

@maybe_tens:
  cpx #$00
  bne @print_tens
  cpy #$00
  beq @ones
  jmp @print_tens

@print_tens:
  tya
  clc
  adc #'0'
  jsr ACIA_PUTC

@ones:
  pla
  clc
  adc #'0'
  jsr ACIA_PUTC
  lda #' '
  jsr ACIA_PUTC
  plx
  rts
