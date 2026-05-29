#!/usr/bin/env bash

set -euo pipefail

# create the build directories if they don't exist
mkdir -p ./build
mkdir -p ./bin

# clean up the build directories
rm -rf ./build/*
rm -rf ./bin/*

ca65 \
  -g \
  -I ./src/asm/eeprom \
  -I ./src/asm \
  -I ./src \
  -l ./build/compy6502.lst \
  -o ./build/compy6502.o \
  ./src/asm/eeprom/main.s

ld65 -C ./src/asm/eeprom/compy6502.x --dbgfile ./bin/compy6502.dbg -o ./bin/compy6502.bin ./build/compy6502.o
