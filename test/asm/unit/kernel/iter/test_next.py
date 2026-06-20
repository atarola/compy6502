from asm.unit.base import BaseTest

K_PTR2_LO = 0x04
K_PTR2_HI = 0x05
K_ITER_CUR_LO = 0x08
K_ITER_CUR_HI = 0x09
K_ITER_STOP_LO = 0x0A
K_ITER_STOP_HI = 0x0B
K_ITER_STRIDE_LO = 0x0C
K_ITER_STRIDE_HI = 0x0D


def set_iter(cpu, cur, stop, stride):
    cpu.memory[K_ITER_CUR_LO] = cur & 0xFF
    cpu.memory[K_ITER_CUR_HI] = cur >> 8
    cpu.memory[K_ITER_STOP_LO] = stop & 0xFF
    cpu.memory[K_ITER_STOP_HI] = stop >> 8
    cpu.memory[K_ITER_STRIDE_LO] = stride & 0xFF
    cpu.memory[K_ITER_STRIDE_HI] = stride >> 8


class TestKernelIterNext(BaseTest):
    def test_advances_by_stride_and_returns_address(self):
        cpu = self.get_rom_cpu()
        set_iter(cpu, cur=0x1000, stop=0x1006, stride=3)

        self.run_sub(cpu, "ITER_NEXT")

        self.assertFalse(cpu.carry())
        self.assertEqual(0x03, cpu.memory[K_PTR2_LO])
        self.assertEqual(0x10, cpu.memory[K_PTR2_HI])

    def test_stops_once_cursor_reaches_boundary(self):
        cpu = self.get_rom_cpu()
        set_iter(cpu, cur=0x1003, stop=0x1006, stride=3)

        self.run_sub(cpu, "ITER_NEXT")

        self.assertTrue(cpu.carry())

    def test_stops_on_overflow_past_ffff(self):
        cpu = self.get_rom_cpu()
        set_iter(cpu, cur=0xFFFE, stop=0xFFFF, stride=3)

        self.run_sub(cpu, "ITER_NEXT")

        self.assertTrue(cpu.carry())
