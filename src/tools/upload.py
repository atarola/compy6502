#!/usr/bin/env python3

import argparse
from pathlib import Path

import serial

#
# upload a motorola srect file over a serial link.
#

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="S-record file to upload")
    parser.add_argument("-p", "--port", required=True, help="serial port")
    parser.add_argument("-b", "--baud", type=int, default=9600, help="serial baud rate")
    parser.add_argument("--dry-run", action="store_true", help="print records without opening the serial port")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    path = Path(args.input)

    if args.dry_run:
        dry_run(path)
        return

    upload_records(path, args.port, args.baud)


def dry_run(path: Path) -> None:
    with path.open("r") as lines:
        print("\n".join(line.strip() for line in lines if line.strip()))


def upload_records(path: Path, port: str, baud: int) -> None:
    with serial.Serial(port, baudrate=baud, timeout=None) as connection:
        with path.open("r") as lines:
            send_records(lines, connection)
    print("\ndone")


def send_records(lines, connection: serial.Serial) -> None:
    for line in lines:
        record = line.strip()
        if not record:
            continue

        connection.write(record.encode("ascii") + b"\r")
        connection.flush()

        response = connection.read(1)
        print(response.decode("ascii", errors="replace"), end="", flush=True)
        if response == b".":
            continue
        if response == b"!":
            raise RuntimeError(f"target rejected record: {record}")
        raise RuntimeError(f"unexpected target response {response!r} after record: {record}")


if __name__ == "__main__":
    main()
