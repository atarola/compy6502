from asm.unit.base import BaseTest


SOURCE = 0x0300
DEST = 0x0310


class TestKernelStringsSpanToStr(BaseTest):
    def test_strings_span_to_str(self):
        cpu = self.get_rom_cpu()

        cpu.set_k_ptr(DEST)
        cpu.set_k_ptr2(SOURCE)
        cpu.poke(SOURCE, bytes([ord("A"), ord("B"), ord("C")]))
        cpu.poke(DEST, bytes([0x02, ord("X"), ord("Y")]))

        self.run_sub(cpu, "SPAN_TO_STR", a=0x03)

        self.assertEqual(0x03, cpu.memory[DEST])
        self.assertEqual(ord("A"), cpu.memory[DEST + 1])
        self.assertEqual(ord("B"), cpu.memory[DEST + 2])
        self.assertEqual(ord("C"), cpu.memory[DEST + 3])

    def test_strings_span_to_str_empty(self):
        cpu = self.get_rom_cpu()

        cpu.set_k_ptr(DEST)
        cpu.set_k_ptr2(SOURCE)
        cpu.poke(SOURCE, bytes([ord("A"), ord("B"), ord("C")]))
        cpu.poke(DEST, bytes([0x02, ord("X"), ord("Y")]))

        self.run_sub(cpu, "SPAN_TO_STR", a=0x00)

        self.assertEqual(0x00, cpu.memory[DEST])
