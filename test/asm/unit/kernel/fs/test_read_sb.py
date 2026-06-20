from asm.unit.base import BaseTest

NAME_ADDR = 0x0500
K_BUF = 0x0300


def pascal(s):
    return bytes([len(s)]) + s.encode("ascii")


class TestKernelFsReadSb(BaseTest):
    def test_reads_the_superblock_into_k_buf(self):
        cpu = self.get_rom_cpu()
        cpu.install_fram()
        cpu.poke(NAME_ADDR, pascal("hello"))
        cpu.set_k_ptr(NAME_ADDR)
        self.run_sub(cpu, "FS_FORMAT", max_steps=10000)

        self.run_sub(cpu, "FS_READ_SB", max_steps=10000)

        self.assertFalse(cpu.carry())
        self.assertEqual(
            bytes([0x05, 0x00, 0xD0, 0xFF]),
            bytes(cpu.memory[K_BUF : K_BUF + 4]),
        )
        self.assertEqual(0, sum(cpu.memory[K_BUF : K_BUF + 5]) & 0xFF)
