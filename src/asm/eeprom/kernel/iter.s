.include "include/compy6502.inc"

; Fixed-stride iterator over a region of memory (e.g. the FRAM filesystem
; index). State lives in K_ITER_CUR/K_ITER_STOP/K_ITER_STRIDE/K_ITER_CB
; instead of the transient K_PTR/K_LEN/K_TMP scratch, since it must
; survive whatever the caller does between calls.

; Set up the iterator cursor, stop boundary, and stride.
; in:  K_PTR2 = start cursor address
;      K_TMP2/K_TMP3 = stop boundary address (lo/hi)
;      A = stride (bytes per step)
; out: none
; clobbers: A, flags
iter_init:
  sta K_ITER_STRIDE
  stz K_ITER_STRIDE_HI

  lda K_PTR2_LO
  sta K_ITER_CUR_LO
  lda K_PTR2_HI
  sta K_ITER_CUR_HI

  lda K_TMP2
  sta K_ITER_STOP_LO
  lda K_TMP3
  sta K_ITER_STOP_HI

  clc
  rts

; Advance the iterator and return the next item address.
; in:  none (uses K_ITER_CUR/K_ITER_STOP/K_ITER_STRIDE)
; out: carry clear = item available, K_PTR2 = item address
;      carry set   = iteration complete
; clobbers: A, flags
iter_next:
  ADD16 K_ITER_CUR, K_ITER_STRIDE
  bcs :+

  CMP16 K_ITER_CUR, K_ITER_STOP
  bcs :+

  lda K_ITER_CUR_LO
  sta K_PTR2_LO
  lda K_ITER_CUR_HI
  sta K_PTR2_HI

  rts
:
  rts

; Advance the iterator downward and return the next item address.
; Counterpart to iter_next for walking toward lower addresses (e.g.
; compacting the index oldest-to-newest). iter_init covers both
; directions unchanged -- only the advance/stop direction differs, so
; there's no iter_init_down.
; in:  none (uses K_ITER_CUR/K_ITER_STOP/K_ITER_STRIDE)
; out: carry clear = item available, K_PTR2 = item address
;      carry set   = iteration complete
; clobbers: A, flags
iter_next_down:
  SUB16 K_ITER_CUR, K_ITER_STRIDE
  bcc @done             ; borrow -- wrapped past $0000

  CMP16 K_ITER_CUR, K_ITER_STOP
  bcc @done             ; CUR < STOP
  beq @done             ; CUR == STOP -- boundary itself is excluded

  lda K_ITER_CUR_LO
  sta K_PTR2_LO
  lda K_ITER_CUR_HI
  sta K_PTR2_HI

  clc
  rts

@done:
  sec
  rts

; Walk the iterator to completion, invoking a callback for each item.
; in:  K_ITER_CB = callback address (called once per item via trampoline,
;      with K_PTR2 = item address)
; out: carry clear = success
;      carry set   = error (propagated from a callback, if any)
; clobbers: A, X, Y, flags, K_PTR2
iter_for_each:
@loop:
  ADD16 K_ITER_CUR, K_ITER_STRIDE
  bcs @done

  CMP16 K_ITER_CUR, K_ITER_STOP
  bcs @done

  lda K_ITER_CUR_LO
  sta K_PTR2_LO
  lda K_ITER_CUR_HI
  sta K_PTR2_HI

  jsr iter_trampoline
  bcs @error

  jmp @loop

@error:
  rts

@done:
  clc
  rts

iter_trampoline:
  jmp (K_ITER_CB)
