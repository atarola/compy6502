
from asm.unit.base import BaseTest


class TestFramework(BaseTest):

    def test_compile(self):
        cpu = self.get_cpu("fixtures/minimal_program")
        cpu.until_null()
        self.assertEqual(0xff, cpu.x)
