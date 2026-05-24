from asm.unit.base import BaseTest


BUFFER = 0x0300


class TestKernelStringsStrLen(BaseTest):
    def test_strings_str_len(self):
        cpu = self.get_rom_cpu()

        cpu.set_k_ptr(BUFFER)
        cpu.memory[BUFFER] = 0x03

        self.run_sub(cpu, "STR_LEN")

        self.assertEqual(0x03, cpu.a)
