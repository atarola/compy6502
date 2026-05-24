from asm.unit.base import BaseTest

INPUT_SCRIPT = b"S1040400AA4D\r"
END_SCRIPT = b"S9\r"
BAD_CHECKSUM_SCRIPT = b"S1040400AA4E\r"
BAD_HEX_SCRIPT = b"S1040400AG4D\r"
BAD_TYPE_SCRIPT = b"S2040400AA4C\r"


def srec_loader_caller(address):
    return bytes([0x20, address & 0xFF, address >> 8, 0xEA])


class TestKernelSrecLoader(BaseTest):
    def test_srec_loader_writes_record_and_acks(self):
        cpu = self.get_rom_cpu()
        address = self.get_rom_address("SREC_LOAD")

        cpu.install_acia(INPUT_SCRIPT)
        cpu.poke(0x0600, srec_loader_caller(address))
        cpu.pc = 0x0600

        for _ in range(5000):
            if cpu.memory[0x0400] == 0xAA and cpu.acia_output() == b".":
                break

            cpu.step()
        else:
            self.fail(f"loader did not write and ack the record: {cpu.register_line()}")

        self.assertEqual(0xAA, cpu.memory[0x0400])
        self.assertEqual(b".", cpu.acia_output())

    def test_srec_loader_returns_on_s9(self):
        cpu = self.get_rom_cpu()
        address = self.get_rom_address("SREC_LOAD")

        cpu.install_acia(END_SCRIPT)
        cpu.poke(0x0600, srec_loader_caller(address))
        cpu.pc = 0x0600

        cpu.until_pc(0x0603)

        self.assertEqual(b".", cpu.acia_output())
        self.assertEqual(0x00, cpu.memory[0x0400])

    def test_srec_loader_rejects_bad_checksum(self):
        cpu = self.get_rom_cpu()
        address = self.get_rom_address("SREC_LOAD")

        cpu.install_acia(BAD_CHECKSUM_SCRIPT)
        cpu.poke(0x0600, srec_loader_caller(address))
        cpu.pc = 0x0600

        cpu.until_pc(0x0603)

        self.assertEqual(b"!", cpu.acia_output())
        self.assertEqual(0xAA, cpu.memory[0x0400])

    def test_srec_loader_rejects_bad_hex(self):
        cpu = self.get_rom_cpu()
        address = self.get_rom_address("SREC_LOAD")

        cpu.install_acia(BAD_HEX_SCRIPT)
        cpu.poke(0x0600, srec_loader_caller(address))
        cpu.pc = 0x0600

        cpu.until_pc(0x0603)

        self.assertEqual(b"!", cpu.acia_output())
        self.assertEqual(0x00, cpu.memory[0x0400])

    def test_srec_loader_rejects_bad_type(self):
        cpu = self.get_rom_cpu()
        address = self.get_rom_address("SREC_LOAD")

        cpu.install_acia(BAD_TYPE_SCRIPT)
        cpu.poke(0x0600, srec_loader_caller(address))
        cpu.pc = 0x0600

        cpu.until_pc(0x0603)

        self.assertEqual(b"!", cpu.acia_output())
        self.assertEqual(0x00, cpu.memory[0x0400])
