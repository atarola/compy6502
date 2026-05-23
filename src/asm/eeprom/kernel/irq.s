.include "include/compy6502.inc"

irq_noop:
  rts

; System IRQ dispatcher.
;
; in:  hardware IRQ state
; out: none
; clobbers: flags
irq_dispatch:
  pha
  txa
  pha
  tya
  pha

  jsr @call_hook

  pla
  tay
  pla
  tax
  pla
  rti

@call_hook:
  jmp (IRQ_HOOK)
