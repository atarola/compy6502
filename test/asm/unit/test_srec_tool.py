import importlib.util
import io
import unittest
from pathlib import Path

SREC_PATH = Path(__file__).resolve().parents[3] / "src" / "tools" / "srec.py"
_spec = importlib.util.spec_from_file_location("srec", SREC_PATH)
srec = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(srec)


def decode_s1_lines(output):
    records = []
    for line in output.splitlines():
        if not line.startswith("S1"):
            continue
        count = int(line[2:4], 16)
        addr = int(line[4:8], 16)
        payload = line[8:8 + (count - 3) * 2]
        data = [int(payload[i:i + 2], 16) for i in range(0, len(payload), 2)]
        records.append((addr, data))
    return records


class TestParseLine(unittest.TestCase):
    def test_parses_address_and_bytes(self):
        line = "000900  1  0D 0A 68 69    \n"
        self.assertEqual((0x0900, [0x0D, 0x0A, 0x68, 0x69]), srec.parse_line(line))

    def test_treats_xx_placeholder_as_zero(self):
        line = "001000  1  AA xx BB    \n"
        self.assertEqual((0x1000, [0xAA, 0x00, 0xBB]), srec.parse_line(line))

    def test_ignores_lines_without_bytes(self):
        line = "000900  1               fram_string:\n"
        self.assertIsNone(srec.parse_line(line))

    def test_ignores_relocatable_lines(self):
        line = "000000r 2               IO0_ADDR = $C000\n"
        self.assertIsNone(srec.parse_line(line))


class TestSrecord(unittest.TestCase):
    def test_data_record_checksum(self):
        self.assertEqual("S1040400AA4D", srec.srecord("1", 0x0400, [0xAA]))

    def test_header_record(self):
        self.assertEqual("S004000000FB", srec.srecord("0", 0, [0x00]))

    def test_end_record(self):
        self.assertEqual("S9030000FC", srec.srecord("9", 0, []))


class TestConvertFile(unittest.TestCase):
    def test_coalesces_contiguous_bytes_and_caps_chunk_size(self):
        run_bytes = list(range(70))
        line1 = "001000  1  " + " ".join(f"{b:02X}" for b in run_bytes) + "\n"
        line2 = "002000  1  AA BB CC\n"
        out = io.StringIO()

        srec.convert_file(io.StringIO(line1 + line2), out, "sram")

        records = decode_s1_lines(out.getvalue())
        self.assertEqual(
            [
                (0x1000, run_bytes[:64]),
                (0x1040, run_bytes[64:]),
                (0x2000, [0xAA, 0xBB, 0xCC]),
            ],
            records,
        )

    def test_header_encodes_target(self):
        out = io.StringIO()
        srec.convert_file(io.StringIO(""), out, "fram")
        self.assertTrue(out.getvalue().startswith("S004000001"))

    def test_skips_lines_with_no_bytes(self):
        line = "000900  1               fram_string:\n"
        out = io.StringIO()

        srec.convert_file(io.StringIO(line), out, "sram")

        self.assertEqual([], decode_s1_lines(out.getvalue()))


if __name__ == "__main__":
    unittest.main()
