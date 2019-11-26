
import unittest

from unit.base import BaseTest


class TestSpush(BaseTest):

    def test_spush(self):
        cpu = self.get_cpu("test_stack_spush")
        cpu.until_null()
        self.assertEqual(0xfd, cpu.x)


class TestSdrop(BaseTest):

    def test_sdrop(self):
        cpu = self.get_cpu("test_stack_sdrop")
        cpu.until_null()
        self.assertEqual(0xff, cpu.x)


class TestSinc(BaseTest):

    def test_sinc(self):
        cpu = self.get_cpu("test_stack_sinc")
        cpu.until_null()
        self.assertEqual('0x101', cpu.get_stack(0))


class TestSfetch(BaseTest):

    def test_sfetch(self):
        cpu = self.get_cpu("test_stack_sfetch")
        cpu.memory[0x6000:0x6002] = [0xaa, 0x55]
        cpu.until_null()
        self.assertEqual('0x55aa', cpu.get_stack(0))


class TestSstore(BaseTest):

    def test_sstore(self):
        cpu = self.get_cpu("test_stack_sstore")
        cpu.until_null()
        self.assertEqual('0xaaaa', cpu.get_word(0x6060))


class TestSdup(BaseTest):

    def test_sdup(self):
        cpu = self.get_cpu("test_stack_sdup")
        cpu.until_null()
        self.assertEqual('0xfcfc', cpu.get_stack(0))
        self.assertEqual('0xfcfc', cpu.get_stack(1))


class TestSover(BaseTest):

    def test_sover(self):
        cpu = self.get_cpu("test_stack_sover")
        cpu.until_null()
        self.assertEqual('0xaaaa', cpu.get_stack(0))
        self.assertEqual('0x5555', cpu.get_stack(1))
        self.assertEqual('0xaaaa', cpu.get_stack(2))


class TestSswap(BaseTest):

    def test_sswap(self):
        cpu = self.get_cpu("test_stack_sswap")
        cpu.until_null()
        self.assertEqual('0xaaaa', cpu.get_stack(0))
        self.assertEqual('0x5555', cpu.get_stack(1))


class TestSand(BaseTest):

    def test_sand(self):
        cpu = self.get_cpu("test_stack_sand")
        cpu.until_null()
        self.assertEqual('0x10', cpu.get_stack(0))


class TestSor(BaseTest):

    def test_sor(self):
        cpu = self.get_cpu("test_stack_sor")
        cpu.until_null()
        self.assertEqual('0xffff', cpu.get_stack(0))


class TestSxor(BaseTest):

    @unittest.skip("TODO")
    def test_sxor(self):
        pass


class TestSnot(BaseTest):

    @unittest.skip("TODO")
    def test_snot(self):
        pass


class TestSeq(BaseTest):

    def test_seq_true(self):
        cpu = self.get_cpu("test_stack_seq_true")
        cpu.until_null()
        self.assertEqual('0xffff', cpu.get_stack(0))

    def test_seq_false(self):
        cpu = self.get_cpu("test_stack_seq_false")
        cpu.until_null()
        self.assertEqual('0x0', cpu.get_stack(0))


class TestSadd(BaseTest):

    @unittest.skip("TODO")
    def test_sadd(self):
        pass


class TestSsub(BaseTest):

    @unittest.skip("TODO")
    def test_ssub(self):
        pass
