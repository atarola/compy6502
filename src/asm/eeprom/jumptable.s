acia_putc_trampoline:
  jmp acia_putc

acia_getc_trampoline:
  jmp acia_getc

byte_to_hex_trampoline:
  jmp byte_to_hex

hex_to_nibble_trampoline:
  jmp hex_to_nibble

str_init_trampoline:
  jmp str_init

str_len_trampoline:
  jmp str_len

str_append_trampoline:
  jmp str_append

str_pop_trampoline:
  jmp str_pop
