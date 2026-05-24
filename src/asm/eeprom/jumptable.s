acia_putc_trampoline:
  jmp acia_putc

acia_getc_trampoline:
  jmp acia_getc

ansi_up_trampoline:
  jmp ansi_up

ansi_down_trampoline:
  jmp ansi_down

ansi_cr_trampoline:
  jmp ansi_cr

ansi_crlf_trampoline:
  jmp ansi_crlf

ansi_clear_line_trampoline:
  jmp ansi_clear_line

ansi_cr_clear_line_trampoline:
  jmp ansi_cr_clear_line

str_init_trampoline:
  jmp str_init

str_len_trampoline:
  jmp str_len

str_append_trampoline:
  jmp str_append

str_pop_trampoline:
  jmp str_pop

str_eq_trampoline:
  jmp str_eq

line_reset_trampoline:
  jmp line_reset

line_input_trampoline:
  jmp line_input

byte_to_hex_trampoline:
  jmp byte_to_hex

hex_to_nibble_trampoline:
  jmp hex_to_nibble
