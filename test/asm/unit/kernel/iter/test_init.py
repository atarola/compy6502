from asm.unit.base import BaseTest

K_TMP2 = 0x1C
K_TMP3 = 0x1D
K_ITER_CUR_LO = 0x08
K_ITER_CUR_HI = 0x09
K_ITER_STOP_LO = 0x0A
K_ITER_STOP_HI = 0x0B
K_ITER_STRIDE_LO = 0x0C
K_ITER_STRIDE_HI = 0x0D


class TestKernelIterInit(BaseTest):
    def test_sets_cursor_stop_and_stride(self):
        cpu = self.get_rom_cpu()
        cpu.set_k_ptr2(0x1000)
        cpu.memory[K_TMP2] = 0x00
        cpu.memory[K_TMP3] = 0x20

        self.run_sub(cpu, "ITER_INIT", a=0x18)

        self.assertEqual(0x00, cpu.memory[K_ITER_CUR_LO])
        self.assertEqual(0x10, cpu.memory[K_ITER_CUR_HI])
        self.assertEqual(0x00, cpu.memory[K_ITER_STOP_LO])
        self.assertEqual(0x20, cpu.memory[K_ITER_STOP_HI])
        self.assertEqual(0x18, cpu.memory[K_ITER_STRIDE_LO])
        self.assertEqual(0x00, cpu.memory[K_ITER_STRIDE_HI])

    def test_carry_clear(self):
        cpu = self.get_rom_cpu()
        cpu.set_k_ptr2(0x1000)
        cpu.memory[K_TMP2] = 0x00
        cpu.memory[K_TMP3] = 0x20

        self.run_sub(cpu, "ITER_INIT", a=0x18)

        self.assertFalse(cpu.carry())
