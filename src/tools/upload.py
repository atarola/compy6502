#!/usr/bin/env python3

import argparse
import time
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
    parser.add_argument("--start", default="S", help="wozmon command used to start the loader")
    parser.add_argument("--char-delay", type=float, default=0.01, help="seconds to wait between transmitted characters")
    parser.add_argument("--dry-run", action="store_true", help="print records without opening the serial port")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    path = Path(args.input)

    if args.dry_run:
        dry_run(path)
        return

    upload_records(path, args.port, args.baud, args.start, args.char_delay)


def dry_run(path: Path) -> None:
    with path.open("r") as lines:
        print("\n".join(line.strip() for line in lines if line.strip()))


def upload_records(path: Path, port: str, baud: int, start: str, char_delay: float) -> None:
    with serial.Serial(port, baudrate=baud, timeout=None) as connection:
        start_loader(connection, start, char_delay)
        with path.open("r") as lines:
            send_records(lines, connection, char_delay)
    print("\ndone")


def start_loader(connection: serial.Serial, start: str, char_delay: float) -> None:
    send_line(connection, start, char_delay)


def send_records(lines, connection: serial.Serial, char_delay: float) -> None:
    for line in lines:
        record = line.strip()
        if not record:
            continue
        if record.startswith("S0"):
            continue

        send_line(connection, record, char_delay)

        while True:
            response = connection.read(1)
            print(response.decode("ascii", errors="replace"), end="", flush=True)
            if response == b".":
                break
            if response == b"!":
                raise RuntimeError(f"target rejected record: {record}")


def send_line(connection: serial.Serial, line: str, char_delay: float) -> None:
    for char in line:
        connection.write(char.encode("ascii"))
        connection.flush()
        time.sleep(char_delay)

    connection.write(b"\r")
    connection.flush()
    time.sleep(char_delay)

if __name__ == "__main__":
    main()
