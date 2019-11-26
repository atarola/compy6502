
from unit.base import BaseTest


class TestFramework(BaseTest):

    def test_compile(self):
        cpu = self.get_cpu("test_framework_compile")
        cpu.until_null()
        self.assertEqual(0xff, cpu.x)

    def test_include(self):
        cpu = self.get_cpu("test_framework_include")
        cpu.until_null()
        self.assertEqual(0xff, cpu.x)
