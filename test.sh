#!/usr/bin/env bash -e

./build.sh && xxd -p -l 4096 ./bin/compy6502.bin > ./bin/temp.bin
