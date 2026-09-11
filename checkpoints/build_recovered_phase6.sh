#!/bin/sh
set -eu
BASE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$BASE"

as --32 -o basic110_phase6.o basic110_C1.10_recovered_phase6_exact.asm
ld -m elf_i386 -Ttext=0 -e ROM_ENTRY -o basic110_phase6.elf basic110_phase6.o
objcopy -O binary -j .text basic110_phase6.elf basic110_C1.10_recovered_phase6_exact.rom

cmp basic110_C1.10_recovered_phase6_exact.rom "basic110(1).rom"
echo "BYTE-FOR-BYTE C1.10 MATCH"

python3 - <<'PY'
from pathlib import Path
for name in ["basic110(1).rom", "basic110_C1.10_recovered_phase6_exact.rom"]:
    b=Path(name).read_bytes()
    print(name, "8K checksum sums:", [sum(b[i:i+8192]) & 0xff for i in range(0,len(b),8192)])
PY
