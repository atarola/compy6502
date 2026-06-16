from asm.unit.base import BaseTest, K_PTR_LO, K_PTR_HI


class TestKernelSub16PtrLen(BaseTest):
    def test_sub16_ptr_len(self):
        cpu = self.get_rom_cpu()
        cpu.set_k_ptr(0x1234)
        cpu.set_k_len(0x0010)

        self.run_sub(cpu, "SUB16_PTR_LEN")

        lo = cpu.memory[K_PTR_LO]
        hi = cpu.memory[K_PTR_HI]
        self.assertEqual(0x1224, (hi << 8) | lo)

    def test_sub16_ptr_len_borrow(self):
        cpu = self.get_rom_cpu()
        cpu.set_k_ptr(0x1300)
        cpu.set_k_len(0x0001)

        self.run_sub(cpu, "SUB16_PTR_LEN")

        lo = cpu.memory[K_PTR_LO]
        hi = cpu.memory[K_PTR_HI]
        self.assertEqual(0x12FF, (hi << 8) | lo)
