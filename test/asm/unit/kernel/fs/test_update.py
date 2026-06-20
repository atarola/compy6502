from asm.unit.base import BaseTest

NAME_ADDR = 0x0500
DATA_ADDR = 0x0520
K_PTR2_LO = 0x04
K_PTR2_HI = 0x05


def pascal(s):
    return bytes([len(s)]) + s.encode("ascii")


class TestKernelFsUpdate(BaseTest):
    def test_tombstones_the_old_entry(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "greeting", b"hello world")
        self._find(cpu, "greeting")

        self._update(cpu, b"hellorld")

        self.assertFalse(cpu.carry())
        old_entry = fram.fram[0xFFD0 : 0xFFD0 + 0x18]
        self.assertEqual(0x1A, old_entry[0])  # FS_ENTRY_FILE_DEL

    def test_writes_new_content_under_the_same_name(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "greeting", b"hello world")
        self._find(cpu, "greeting")

        self._update(cpu, b"hellorld")

        # FS_UPDATE = FS_DELETE then FS_WRITE, so the new entry lands at
        # the slot that was the trailing stub before the update.
        new_entry = fram.fram[0xFFB8 : 0xFFB8 + 0x18]
        self.assertEqual(0x12, new_entry[0])  # FS_ENTRY_FILE
        self.assertEqual(bytes(pascal("greeting")), bytes(new_entry[7 : 7 + 9]))
        self.assertEqual(0, sum(new_entry) & 0xFF)

        new_start = int.from_bytes(new_entry[1:3], "little")
        new_len = int.from_bytes(new_entry[3:5], "little")
        self.assertEqual(b"hellorld", bytes(fram.fram[new_start : new_start + new_len]))

    def test_find_after_update_returns_the_new_entry(self):
        cpu = self.get_rom_cpu()
        cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "greeting", b"hello world")
        self._find(cpu, "greeting")

        self._update(cpu, b"hellorld")
        self._find(cpu, "greeting")

        self.assertFalse(cpu.carry())
        self.assertEqual(0xB8, cpu.memory[K_PTR2_LO])
        self.assertEqual(0xFF, cpu.memory[K_PTR2_HI])

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

    def _update(self, cpu, data):
        cpu.poke(DATA_ADDR, data)
        cpu.set_k_ptr(DATA_ADDR)
        cpu.set_k_len(len(data))
        self.run_sub(cpu, "FS_UPDATE", max_steps=10000)
