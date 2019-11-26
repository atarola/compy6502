
from unit.base import BaseTest


ACIA_DATA = 0xe000
ACIA_STATUS = 0xe001
ACIA_COMMAND = 0xe002
ACIA_CONTROL = 0xe003


class TestAciaInit(BaseTest):

    def test_acia_init(self):
        cpu = self.get_cpu("test_acia_init")
        cpu.until_null()
        self.assertEqual('0xb', cpu.get_byte(ACIA_COMMAND))
        self.assertEqual('0x1f', cpu.get_byte(ACIA_CONTROL))


class TestAciaGet(BaseTest):

    def test_acia_get(self):
        cpu = self.get_cpu("test_acia_get")
        cpu.memory[ACIA_STATUS] = 0x08
        cpu.memory[ACIA_DATA] = 0x55
        cpu.until_null()
        self.assertEqual('0x5500', cpu.get_stack(0))

    def test_acia_get_wait(self):
        cpu = self.get_cpu("test_acia_get")
        cpu.memory[ACIA_DATA] = 0x55

        for _ in range(1000):
            cpu.step()

        self.assertNotEqual('0x5500', cpu.get_stack(0))

        cpu.memory[ACIA_STATUS] = 0x08
        cpu.until_null()
        self.assertEqual('0x5500', cpu.get_stack(0))


class TestAciaPut(BaseTest):

    def test_acia_put(self):
        cpu = self.get_cpu("test_acia_put")
        cpu.memory[ACIA_STATUS] = 0x10
        cpu.until_null()
        self.assertEqual('0x55', cpu.get_byte(ACIA_DATA))

    def test_acia_put_wait(self):
        cpu = self.get_cpu("test_acia_put")

        for _ in range(1000):
            cpu.step()

        self.assertNotEqual('0x55', cpu.get_byte(ACIA_DATA))

        cpu.memory[ACIA_STATUS] = 0x10
        cpu.until_null()
        self.assertEqual('0x55', cpu.get_byte(ACIA_DATA))


class TestAciaRead(BaseTest):

    def test_acia_read(self):
        test_string = b"the quick brown fox jumps over the lazy dog.\n"
        idx = 0

        cpu = self.get_cpu("test_acia_read")
        cpu.memory[ACIA_STATUS] = 0x08

        def next_char(foo):
            nonlocal idx
            c = test_string[idx]
            idx = idx + 1
            return c

        cpu.memory.subscribe_to_read([ACIA_DATA], next_char)
        cpu.until_null()

        actual = bytearray(cpu.memory[0x6060:0x6060 + len(test_string) - 1])
        self.assertEqual(test_string.rstrip(), actual)
