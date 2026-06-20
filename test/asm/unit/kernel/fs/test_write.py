from asm.unit.base import BaseTest

NAME_ADDR = 0x0500
DATA_ADDR = 0x0520


def pascal(s):
    return bytes([len(s)]) + s.encode("ascii")


def format_volume(test, cpu, name="hello"):
    cpu.poke(NAME_ADDR, pascal(name))
    cpu.set_k_ptr(NAME_ADDR)
    test.run_sub(cpu, "FS_FORMAT", max_steps=10000)


def write_file(test, cpu, name, data):
    cpu.poke(NAME_ADDR, pascal(name))
    cpu.poke(DATA_ADDR, data)
    cpu.set_k_ptr(DATA_ADDR)
    cpu.set_k_ptr2(NAME_ADDR)
    cpu.set_k_len(len(data))
    test.run_sub(cpu, "FS_WRITE", max_steps=10000)


class TestKernelFsWrite(BaseTest):
    def test_writes_file_data_right_after_the_superblock(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        format_volume(self, cpu)

        write_file(self, cpu, "greeting", b"hello world")

        self.assertFalse(cpu.carry())
        self.assertEqual(b"hello world", bytes(fram.fram[5:16]))

    def test_writes_entry_into_the_start_stubs_old_slot(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        format_volume(self, cpu)

        write_file(self, cpu, "greeting", b"hello world")

        entry = fram.fram[0xFFD0 : 0xFFD0 + 0x18]
        self.assertEqual(0x12, entry[0])  # FS_ENTRY_FILE
        self.assertEqual(5, int.from_bytes(entry[1:3], "little"))  # FS_FILE_START
        self.assertEqual(11, int.from_bytes(entry[3:5], "little"))  # FS_FILE_LEN
        self.assertEqual(bytes(pascal("greeting")), bytes(entry[7 : 7 + 9]))
        self.assertEqual(0, sum(entry) & 0xFF)

    def test_plants_a_fresh_stub_one_slot_down(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        format_volume(self, cpu)

        write_file(self, cpu, "greeting", b"hello world")

        entry = fram.fram[0xFFB8 : 0xFFB8 + 0x18]
        self.assertEqual(bytes([0x02] + [0x00] * 22 + [0xFE]), bytes(entry))

    def test_updates_the_superblock(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        format_volume(self, cpu)

        write_file(self, cpu, "greeting", b"hello world")

        self.assertEqual(bytes([16, 0x00, 0xB8, 0xFF]), bytes(fram.fram[0:4]))
        self.assertEqual(0, sum(fram.fram[0:5]) & 0xFF)

    def test_second_write_appends_after_the_first(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        format_volume(self, cpu)
        write_file(self, cpu, "foo", b"foo file data")

        write_file(self, cpu, "bar", b"bar file data")

        self.assertFalse(cpu.carry())
        self.assertEqual(b"foo file data", bytes(fram.fram[5:18]))
        self.assertEqual(b"bar file data", bytes(fram.fram[18:31]))
