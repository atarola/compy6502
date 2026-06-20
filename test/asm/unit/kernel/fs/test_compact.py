from asm.unit.base import BaseTest

NAME_ADDR = 0x0500
DATA_ADDR = 0x0520
K_PTR2_LO = 0x04
K_PTR2_HI = 0x05


def pascal(s):
    return bytes([len(s)]) + s.encode("ascii")


class TestKernelFsCompact(BaseTest):
    """Mirrors the format/write/update/compact sequence verified on real
    hardware: format, write "greeting"="hello world", update it to
    "hellorld" (tombstoning the original), then compact and confirm the
    deleted entry and its orphaned data are reclaimed while VOL_ID and
    the live entry survive -- this is the exact scenario that caught the
    ADD16-vs-SUB16 bug during manual testing.
    """

    def test_reclaims_the_tombstoned_entry_and_its_data(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "greeting", b"hello world")
        self._find(cpu, "greeting")
        self._update(cpu, b"hellorld")

        self.run_sub(cpu, "FS_COMPACT", max_steps=20000)

        self.assertFalse(cpu.carry())

        # superblock: DATA_PTR=13, INDEX_PTR=$FFB8, matching the hardware run
        self.assertEqual(bytes([0x0D, 0x00, 0xB8, 0xFF]), bytes(fram.fram[0:4]))
        self.assertEqual(0, sum(fram.fram[0:5]) & 0xFF)

    def test_vol_id_survives_intact(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "greeting", b"hello world")
        self._find(cpu, "greeting")
        self._update(cpu, b"hellorld")

        self.run_sub(cpu, "FS_COMPACT", max_steps=20000)

        entry = fram.fram[0xFFE8 : 0xFFE8 + 0x18]
        self.assertEqual(0x01, entry[0])  # FS_ENTRY_VOL_ID
        self.assertEqual(bytes(pascal("hello")), bytes(entry[1:7]))
        self.assertEqual(0, sum(entry) & 0xFF)

    def test_live_entry_relocated_to_the_compacted_slab_position(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "greeting", b"hello world")
        self._find(cpu, "greeting")
        self._update(cpu, b"hellorld")

        self.run_sub(cpu, "FS_COMPACT", max_steps=20000)

        entry = fram.fram[0xFFD0 : 0xFFD0 + 0x18]
        self.assertEqual(0x12, entry[0])  # FS_ENTRY_FILE
        self.assertEqual(5, int.from_bytes(entry[1:3], "little"))  # relocated to start=5
        self.assertEqual(8, int.from_bytes(entry[3:5], "little"))
        self.assertEqual(bytes(pascal("greeting")), bytes(entry[7 : 7 + 9]))
        self.assertEqual(0, sum(entry) & 0xFF)
        self.assertEqual(b"hellorld", bytes(fram.fram[5:13]))

    def test_fresh_stub_at_the_new_index_boundary(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "greeting", b"hello world")
        self._find(cpu, "greeting")
        self._update(cpu, b"hellorld")

        self.run_sub(cpu, "FS_COMPACT", max_steps=20000)

        entry = fram.fram[0xFFB8 : 0xFFB8 + 0x18]
        self.assertEqual(bytes([0x02] + [0x00] * 22 + [0xFE]), bytes(entry))

    def test_find_after_compact_returns_the_relocated_entry(self):
        cpu = self.get_rom_cpu()
        cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "greeting", b"hello world")
        self._find(cpu, "greeting")
        self._update(cpu, b"hellorld")

        self.run_sub(cpu, "FS_COMPACT", max_steps=20000)
        self._find(cpu, "greeting")

        self.assertFalse(cpu.carry())
        self.assertEqual(0xD0, cpu.memory[K_PTR2_LO])
        self.assertEqual(0xFF, cpu.memory[K_PTR2_HI])

    def test_compacting_with_no_deletions_is_a_no_op(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "foo", b"foo file data")

        before = bytes(fram.fram[0:0x10000])
        self.run_sub(cpu, "FS_COMPACT", max_steps=20000)
        after = bytes(fram.fram[0:0x10000])

        self.assertFalse(cpu.carry())
        self.assertEqual(before, after)

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
