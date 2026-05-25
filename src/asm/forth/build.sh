#!/usr/bin/env bash

set -euo pipefail

mkdir -p ./build/asm/forth

rm -f ./build/asm/forth/forth.o
rm -f ./build/asm/forth/forth.lst
rm -f ./build/asm/forth/forth.srec

ca65 \
  --cpu 65c02 \
  --list-bytes 255 \
  -I ./src/asm \
  -I ./src \
  -l ./build/asm/forth/forth.lst \
  -o ./build/asm/forth/forth.o \
  ./src/asm/forth/main.s

python ./src/tools/srec.py ./build/asm/forth/forth.lst -o ./build/asm/forth/forth.srec
