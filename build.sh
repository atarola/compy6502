#!/usr/bin/env bash -e

# create the build directories if they don't exist
mkdir -p ./build
mkdir -p ./bin

# clean up the build directories
rm -rf ./build/*
rm -rf ./bin/*

ca65 -I ./src -o ./build/compy6502.o ./src/main.s
ld65 -C compy6502.x -o ./bin/compy6502.bin ./build/compy6502.o
