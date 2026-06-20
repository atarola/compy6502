from asm.unit.base import BaseTest

NAME_ADDR = 0x0500
DATA_ADDR = 0x0520


def pascal(s):
    return bytes([len(s)]) + s.encode("ascii")


def hex_line(data):
    return "".join(f"{b:02X} " for b in data).encode("ascii") + b"\r\n"


class TestKernelFsDump(BaseTest):
    def test_dumps_superblock_then_each_entry_newest_seed_first(self):
        cpu = self.get_rom_cpu()
        acia = cpu.install_acia()
        cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "foo", b"foo file data")

        self.run_sub(cpu, "FS_DUMP", max_steps=200000)

        self.assertFalse(cpu.carry())
        superblock = hex_line(bytes([0x12, 0x00, 0xB8, 0xFF, 0x37]))
        vol_id = hex_line(bytes([0x01, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F] + [0x00] * 16 + [0xE6]))
        foo_entry = hex_line(
            bytes([0x12, 0x05, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x03, 0x66, 0x6F, 0x6F] + [0x00] * 12 + [0x95])
        )
        stub = hex_line(bytes([0x02] + [0x00] * 22 + [0xFE]))

        self.assertEqual(superblock + vol_id + foo_entry + stub, acia.output())

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
