#!/bin/sh
set -eu
BASE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$BASE"

as --32 -o basic110_phase5.o basic110_C1.10_recovered_phase5_exact.asm
ld -m elf_i386 -Ttext=0 -e ROM_ENTRY -o basic110_phase5.elf basic110_phase5.o
objcopy -O binary -j .text basic110_phase5.elf basic110_C1.10_recovered_phase5_exact.rom

if [ -f "basic110(1).rom" ]; then
    cmp basic110_C1.10_recovered_phase5_exact.rom "basic110(1).rom"
    echo "BYTE-FOR-BYTE MATCH"
fi
