from asm.unit.base import BaseTest

SRC_ADDR = 0x0300
DST_ADDR = 0x0400


class TestKernelMemCopy(BaseTest):
    def test_copies_bytes_from_source_to_destination(self):
        cpu = self.get_rom_cpu()
        data = bytes([0xAA, 0xBB, 0xCC, 0xDD])
        cpu.poke(SRC_ADDR, data)
        cpu.set_k_ptr(SRC_ADDR)
        cpu.set_k_ptr2(DST_ADDR)
        cpu.set_k_len(len(data))

        self.run_sub(cpu, "MEM_COPY")

        self.assertEqual(list(data), list(cpu.memory[DST_ADDR : DST_ADDR + len(data)]))

    def test_zero_length_copies_nothing(self):
        cpu = self.get_rom_cpu()
        cpu.poke(DST_ADDR, bytes([0x00]))
        cpu.set_k_ptr(SRC_ADDR)
        cpu.set_k_ptr2(DST_ADDR)
        cpu.set_k_len(0)

        self.run_sub(cpu, "MEM_COPY")

        self.assertEqual(0x00, cpu.memory[DST_ADDR])

    def test_does_not_modify_the_source(self):
        cpu = self.get_rom_cpu()
        data = bytes([0x01, 0x02, 0x03])
        cpu.poke(SRC_ADDR, data)
        cpu.set_k_ptr(SRC_ADDR)
        cpu.set_k_ptr2(DST_ADDR)
        cpu.set_k_len(len(data))

        self.run_sub(cpu, "MEM_COPY")

        self.assertEqual(list(data), list(cpu.memory[SRC_ADDR : SRC_ADDR + len(data)]))
