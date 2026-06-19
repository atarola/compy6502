acia_putc_trampoline:
  jmp acia_putc

acia_getc_trampoline:
  jmp acia_getc

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

str_copy_trampoline:
  jmp str_copy

span_to_str_trampoline:
  jmp span_to_str

byte_to_hex_trampoline:
  jmp byte_to_hex

hex_to_nibble_trampoline:
  jmp hex_to_nibble

line_edit_trampoline:
  jmp line_edit

spi_configure_trampoline:
  jmp spi_configure

spi_select_trampoline:
  jmp spi_select

spi_deselect_trampoline:
  jmp spi_deselect

spi_transfer_trampoline:
  jmp spi_transfer

spi_write_trampoline:
  jmp spi_write

fram_setup_trampoline:
  jmp fram_setup

fram_write_chunk_trampoline:
  jmp fram_write_chunk

fram_read_chunk_trampoline:
  jmp fram_read_chunk