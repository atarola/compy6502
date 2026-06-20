wozmon_trampoline:
  jmp WOZMON_START

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

crc_trampoline:
  jmp crc

mem_copy_trampoline:
  jmp mem_copy

iter_init_trampoline:
  jmp iter_init

iter_next_trampoline:
  jmp iter_next

iter_next_down_trampoline:
  jmp iter_next_down

iter_for_each_trampoline:
  jmp iter_for_each

hex_dump_trampoline:
  jmp hex_dump

print_newline_trampoline:
  jmp print_newline

print_file_name_trampoline:
  jmp print_file_name

fs_format_trampoline:
  jmp fs_format

fs_find_trampoline:
  jmp fs_find

fs_read_trampoline:
  jmp fs_read

fs_read_sb_trampoline:
  jmp fs_read_sb

fs_write_trampoline:
  jmp fs_write

fs_delete_trampoline:
  jmp fs_delete

fs_update_trampoline:
  jmp fs_update

fs_compact_trampoline:
  jmp fs_compact

fs_dump_trampoline:
  jmp fs_dump