from asm.unit.base import BaseTest

K_ITER_CUR_LO = 0x08
K_ITER_CUR_HI = 0x09
K_ITER_STOP_LO = 0x0A
K_ITER_STOP_HI = 0x0B
K_ITER_STRIDE_LO = 0x0C
K_ITER_STRIDE_HI = 0x0D
K_ITER_CB_LO = 0x0E
K_ITER_CB_HI = 0x0F

CALLBACK_ADDR = 0x0210
COUNTER_ADDR = 0x0250
LAST_ITEM_ADDR = 0x0260

# Records each visited K_PTR2 (lo/hi) and bumps a call counter, then
# always succeeds (carry clear).
CALLBACK_OK = bytes(
    [
        0xEE, 0x50, 0x02,  # INC $0250
        0xA5, 0x04,        # LDA K_PTR2_LO
        0x8D, 0x60, 0x02,  # STA $0260
        0xA5, 0x05,        # LDA K_PTR2_HI
        0x8D, 0x61, 0x02,  # STA $0261
        0x18,              # CLC
        0x60,              # RTS
    ]
)

# Same, but fails (carry set) on the second call.
CALLBACK_FAILS_ON_SECOND_CALL = bytes(
    [
        0xEE, 0x50, 0x02,  # INC $0250
        0xAD, 0x50, 0x02,  # LDA $0250
        0xC9, 0x02,        # CMP #$02
        0xF0, 0x02,        # BEQ +2
        0x18,              # CLC
        0x60,              # RTS
        0x38,              # SEC
        0x60,              # RTS
    ]
)


def set_iter(cpu, cur, stop, stride, callback):
    cpu.memory[K_ITER_CUR_LO] = cur & 0xFF
    cpu.memory[K_ITER_CUR_HI] = cur >> 8
    cpu.memory[K_ITER_STOP_LO] = stop & 0xFF
    cpu.memory[K_ITER_STOP_HI] = stop >> 8
    cpu.memory[K_ITER_STRIDE_LO] = stride & 0xFF
    cpu.memory[K_ITER_STRIDE_HI] = stride >> 8
    cpu.memory[K_ITER_CB_LO] = CALLBACK_ADDR & 0xFF
    cpu.memory[K_ITER_CB_HI] = CALLBACK_ADDR >> 8
    cpu.memory[COUNTER_ADDR] = 0
    cpu.poke(CALLBACK_ADDR, callback)


class TestKernelIterForEach(BaseTest):
    def test_calls_back_for_each_item_until_done(self):
        cpu = self.get_rom_cpu()
        set_iter(cpu, cur=0x1000, stop=0x1009, stride=3, callback=CALLBACK_OK)

        self.run_sub(cpu, "ITER_FOR_EACH", max_steps=5000)

        self.assertFalse(cpu.carry())
        self.assertEqual(2, cpu.memory[COUNTER_ADDR])
        self.assertEqual(0x06, cpu.memory[LAST_ITEM_ADDR])
        self.assertEqual(0x10, cpu.memory[LAST_ITEM_ADDR + 1])

    def test_propagates_callback_error_and_stops(self):
        cpu = self.get_rom_cpu()
        set_iter(cpu, cur=0x1000, stop=0x1100, stride=3, callback=CALLBACK_FAILS_ON_SECOND_CALL)

        self.run_sub(cpu, "ITER_FOR_EACH", max_steps=5000)

        self.assertTrue(cpu.carry())
        self.assertEqual(2, cpu.memory[COUNTER_ADDR])
