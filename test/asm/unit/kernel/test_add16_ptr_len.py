from asm.unit.base import BaseTest, K_PTR_LO, K_PTR_HI


class TestKernelAdd16PtrLen(BaseTest):
    def test_add16_ptr_len(self):
        cpu = self.get_rom_cpu()
        cpu.set_k_ptr(0x1234)
        cpu.set_k_len(0x0010)

        self.run_sub(cpu, "ADD16_PTR_LEN")

        lo = cpu.memory[K_PTR_LO]
        hi = cpu.memory[K_PTR_HI]
        self.assertEqual(0x1244, (hi << 8) | lo)

    def test_add16_ptr_len_carry(self):
        cpu = self.get_rom_cpu()
        cpu.set_k_ptr(0x12FF)
        cpu.set_k_len(0x0001)

        self.run_sub(cpu, "ADD16_PTR_LEN")

        lo = cpu.memory[K_PTR_LO]
        hi = cpu.memory[K_PTR_HI]
        self.assertEqual(0x1300, (hi << 8) | lo)
