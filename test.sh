#!/usr/bin/env bash -e

./build.sh && xxd -p -l 4096 ./bin/atarola64.bin > ./bin/temp.bin
