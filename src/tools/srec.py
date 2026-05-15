#!/usr/bin/env python3

import argparse
import re
from typing import TextIO
from pathlib import Path

#
# parse a ca65 .lst file and output a set of motorola srects.
#

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="input file")
    parser.add_argument("-o", "--output", required=True, help="output file")
    parser.add_argument("--target", choices=["sram", "fram"], default="sram", help="memory target")
    return parser.parse_args()


# Details: https://en.wikipedia.org/wiki/Motorola_S-record
def srecord(record_type: str, addr: int, data: list[int]) -> str:
    count = 3 + len(data)
    addr_bytes = [(addr >> 8) & 0xFF, addr & 0xFF]
    checksum = (~sum([count, *addr_bytes, *data])) & 0xFF
    payload = "".join(f"{item:02X}" for item in data)
    return f"S{record_type}{count:02X}{addr:04X}{payload}{checksum:02X}"


def convert_file(in_file: TextIO, out_file: TextIO, target: str) -> None:
    target_id = {"sram": 0x00, "fram": 0x01}[target]
    print(srecord("0", 0, [target_id]), file=out_file)

    for line in in_file:
        parsed = parse_line(line)
        if parsed is None:
            continue

        addr, data = parsed
        print(srecord("1", addr, data), file=out_file)

    print(srecord("9", 0, []), file=out_file)


def parse_line(line: str) -> tuple[int, list[int]] | None:
    parts = re.split(r" {2,}", line.rstrip())

    if len(parts) < 3:
        return None

    if not re.fullmatch(r"[0-9A-Fa-f]{6}", parts[0]):
        return None

    tokens = parts[2].split()
    if not tokens:
        return None

    if not all(re.fullmatch(r"[0-9A-Fa-f]{2}|xx", token, re.I) for token in tokens):
        return None

    data = [0 if token.lower() == "xx" else int(token, 16) for token in tokens]
    return int(parts[0], 16), data


def main():
    args = parse_args()

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    with Path(args.input).open("r") as in_file:
        with output.open("w") as out_file:
            convert_file(in_file, out_file, args.target)


if __name__ == "__main__":
    main()
