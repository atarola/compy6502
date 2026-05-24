from asm.unit.base import BaseTest


LEFT = 0x0300
RIGHT = 0x0310


class TestKernelStringsStrEq(BaseTest):
    def test_strings_str_eq_equal(self):
        cpu = self.get_rom_cpu()

        cpu.set_k_ptr(LEFT)
        cpu.set_k_ptr2(RIGHT)
        cpu.poke(LEFT, bytes([0x03, ord("A"), ord("B"), ord("C")]))
        cpu.poke(RIGHT, bytes([0x03, ord("A"), ord("B"), ord("C")]))

        self.run_sub(cpu, "STR_EQ")

        self.assertFalse(cpu.carry())

    def test_strings_str_eq_different(self):
        cpu = self.get_rom_cpu()

        cpu.set_k_ptr(LEFT)
        cpu.set_k_ptr2(RIGHT)
        cpu.poke(LEFT, bytes([0x03, ord("A"), ord("B"), ord("C")]))
        cpu.poke(RIGHT, bytes([0x03, ord("A"), ord("B"), ord("D")]))

        self.run_sub(cpu, "STR_EQ")

        self.assertTrue(cpu.carry())
