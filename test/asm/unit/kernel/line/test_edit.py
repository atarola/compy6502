from asm.unit.base import BaseTest


BUFFER = 0x0300


class TestKernelLineLineEdit(BaseTest):
    def test_line_line_edit_clears_existing_string_before_input(self):
        cpu = self.get_rom_cpu()
        acia = cpu.install_acia("A\r")
        cpu.set_k_ptr(BUFFER)
        cpu.memory[BUFFER] = 0x02
        cpu.memory[BUFFER + 1] = ord("X")
        cpu.memory[BUFFER + 2] = ord("Y")

        self.run_sub(cpu, "LINE_EDIT", a=ord(">"), max_steps=10000)

        self.assertEqual(0x01, cpu.memory[BUFFER])
        self.assertEqual(ord("A"), cpu.memory[BUFFER + 1])

    def test_line_line_edit_echoes_prompt_and_stores_input(self):
        cpu = self.get_rom_cpu()
        acia = cpu.install_acia("ABC\r")
        cpu.set_k_ptr(BUFFER)

        self.run_sub(cpu, "LINE_EDIT", a=ord(">"), max_steps=10000)

        self.assertEqual(b"> ABC", acia.output())
        self.assertEqual(ord("A"), cpu.memory[BUFFER + 1])
        self.assertEqual(ord("B"), cpu.memory[BUFFER + 2])
        self.assertEqual(ord("C"), cpu.memory[BUFFER + 3])

    def test_line_line_edit_backspace_rewinds_one_character(self):
        cpu = self.get_rom_cpu()
        acia = cpu.install_acia(b"AB\x08C\r")
        cpu.set_k_ptr(BUFFER)

        self.run_sub(cpu, "LINE_EDIT", a=ord(">"), max_steps=10000)

        self.assertEqual(b"> AB\x08 \x08C", acia.output())
        self.assertEqual(ord("A"), cpu.memory[BUFFER + 1])
        self.assertEqual(ord("C"), cpu.memory[BUFFER + 2])
