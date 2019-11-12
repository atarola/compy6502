#!/usr/bin/env bash -e

# create the build directories if they don't exist
mkdir -p ./build
mkdir -p ./bin

# clean up the build directories
rm -rf ./build/*
rm -rf ./bin/*

# # assemble all of the files
# for pathname in $(find . -type f -name "*.s"); do
#     # grab the filename
#     base=$(basename $pathname)
#     fname=${base%.*}
#
#     # assemble the file
#     ca65 -o "./build/$fname.o" $pathname
# done;

ca65 -I ./src -o ./build/atarola64.o ./src/atarola64.s
ld65 -C atarola64.x -o ./bin/atarola64.bin ./build/atarola64.o
