from asm.unit.base import BaseTest

NAME_ADDR = 0x0500
DATA_ADDR = 0x0520


def pascal(s):
    return bytes([len(s)]) + s.encode("ascii")


class TestKernelFsDelete(BaseTest):
    def test_marks_the_entry_deleted_and_keeps_it_zero_summed(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "greeting", b"hello world")
        self._find(cpu, "greeting")  # K_PTR2 = file ID

        self.run_sub(cpu, "FS_DELETE", max_steps=10000)

        self.assertFalse(cpu.carry())
        entry = fram.fram[0xFFD0 : 0xFFD0 + 0x18]
        self.assertEqual(0x1A, entry[0])  # FS_ENTRY_FILE_DEL
        self.assertEqual(0, sum(entry) & 0xFF)

    def test_does_not_touch_the_files_data(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "greeting", b"hello world")
        self._find(cpu, "greeting")

        self.run_sub(cpu, "FS_DELETE", max_steps=10000)

        self.assertEqual(b"hello world", bytes(fram.fram[5:16]))

    def _format(self, cpu):
        cpu.poke(NAME_ADDR, pascal("hello"))
        cpu.set_k_ptr(NAME_ADDR)
        self.run_sub(cpu, "FS_FORMAT", max_steps=10000)

    def _write(self, cpu, name, data):
        cpu.poke(NAME_ADDR, pascal(name))
        cpu.poke(DATA_ADDR, data)
        cpu.set_k_ptr(DATA_ADDR)
        cpu.set_k_ptr2(NAME_ADDR)
        cpu.set_k_len(len(data))
        self.run_sub(cpu, "FS_WRITE", max_steps=10000)

    def _find(self, cpu, name):
        cpu.poke(NAME_ADDR, pascal(name))
        cpu.set_k_ptr2(NAME_ADDR)
        self.run_sub(cpu, "FS_FIND", max_steps=10000)
