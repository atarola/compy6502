#!/usr/bin/env python3
import argparse
import re
import subprocess
from pathlib import Path


LISTING_BYTES = re.compile(r"^([0-9A-Fa-f]{6})\s+\d+\s+((?:[0-9A-Fa-f]{2}\s*)+)(?:\s{2,}.*)?$")


def parse_int(value):
    value = value.strip()
    if value.startswith("$"):
        return int(value[1:], 16)
    if value.lower().startswith("0x"):
        return int(value, 16)
    return int(value, 16)


def read_listing(path):
    memory = {}

    for line in path.read_text().splitlines():
        match = LISTING_BYTES.match(line)
        if not match:
            continue

        address = int(match.group(1), 16)
        byte_text = match.group(2)
        bytes_ = [int(part, 16) for part in byte_text.split()]

        for offset, byte in enumerate(bytes_):
            memory[address + offset] = byte

    return memory


def contiguous_ranges(memory):
    if not memory:
        return

    start = previous = min(memory)
    bytes_ = [memory[start]]

    for address in sorted(memory)[1:]:
        if address == previous + 1:
            bytes_.append(memory[address])
        else:
            yield start, bytes_
            start = address
            bytes_ = [memory[address]]
        previous = address

    yield start, bytes_


def print_wozmon(memory, columns, run_address):
    for start, bytes_ in contiguous_ranges(memory):
        for offset in range(0, len(bytes_), columns):
            address = start + offset
            chunk = bytes_[offset:offset + columns]
            print(f"{address:04X}: " + " ".join(f"{byte:02X}" for byte in chunk))

    if run_address is not None:
        print(f"{run_address:04X}R")


def main():
    parser = argparse.ArgumentParser(description="Assemble ca65 source and print Wozmon-ready hex lines.")
    parser.add_argument("source", type=Path)
    parser.add_argument("-r", "--run", type=parse_int, help="Append a Wozmon run command for this address.")
    parser.add_argument("-c", "--columns", type=int, default=5, help="Bytes per Wozmon line.")
    parser.add_argument("--cpu", default="65c02", help="ca65 CPU target.")
    args = parser.parse_args()

    build_dir = Path("build/wozmon")
    build_dir.mkdir(parents=True, exist_ok=True)

    stem = args.source.stem
    object_path = build_dir / f"{stem}.o"
    listing_path = build_dir / f"{stem}.lst"

    subprocess.check_call([
        "ca65",
        "--cpu", args.cpu,
        "--list-bytes", "32",
        "-l", str(listing_path),
        "-o", str(object_path),
        str(args.source),
    ])

    memory = read_listing(listing_path)
    print_wozmon(memory, args.columns, args.run)


if __name__ == "__main__":
    main()
