import subprocess


def pytest_sessionstart(session):
    subprocess.check_call(["./src/asm/eeprom/build.sh"])
