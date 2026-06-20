from asm.unit.base import BaseTest

NAME_ADDR = 0x0500

FS_FILE_TYPE = 0x00
FS_FILE_NAME = 0x07
FS_FILE_CRC = 0x17
VOL_ID_ADDR = 0xFFE8
START_STUB_ADDR = 0xFFD0


def pascal(s):
    return bytes([len(s)]) + s.encode("ascii")


class TestKernelFsFormat(BaseTest):
    def test_writes_superblock_pointing_past_the_start_stub(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        cpu.poke(NAME_ADDR, pascal("hello"))
        cpu.set_k_ptr(NAME_ADDR)

        self.run_sub(cpu, "FS_FORMAT", max_steps=10000)

        self.assertFalse(cpu.carry())
        self.assertEqual(bytes([0x05, 0x00, 0xD0, 0xFF]), bytes(fram.fram[0:4]))
        self.assertEqual(0, sum(fram.fram[0:5]) & 0xFF)

    def test_writes_vol_id_entry_at_the_fixed_top_slot(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        cpu.poke(NAME_ADDR, pascal("hello"))
        cpu.set_k_ptr(NAME_ADDR)

        self.run_sub(cpu, "FS_FORMAT", max_steps=10000)

        entry = fram.fram[VOL_ID_ADDR : VOL_ID_ADDR + 0x18]
        self.assertEqual(0x01, entry[FS_FILE_TYPE])
        self.assertEqual(bytes(pascal("hello")), bytes(entry[1 : 1 + 6]))
        self.assertEqual(0, sum(entry) & 0xFF)

    def test_writes_clean_start_stub_below_vol_id(self):
        cpu = self.get_rom_cpu()
        fram = cpu.install_fram()
        cpu.poke(NAME_ADDR, pascal("hello"))
        cpu.set_k_ptr(NAME_ADDR)

        self.run_sub(cpu, "FS_FORMAT", max_steps=10000)

        entry = fram.fram[START_STUB_ADDR : START_STUB_ADDR + 0x18]
        self.assertEqual(bytes([0x02] + [0x00] * 22 + [0xFE]), bytes(entry))
