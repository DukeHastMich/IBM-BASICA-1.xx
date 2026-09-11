#!/bin/sh
set -eu
as --32 -o basic110.o basic110_C1.10_reconstructed.asm
ld -m elf_i386 -Ttext=0 -e ROM_ENTRY -o basic110.elf basic110.o
objcopy -O binary -j .text basic110.elf basic110_rebuilt.rom
cmp -s basic110_rebuilt.rom "basic110(1).rom" && echo "BYTE-FOR-BYTE MATCH"
