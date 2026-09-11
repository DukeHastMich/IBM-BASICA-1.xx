#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SRC="$ROOT/src/basic110_C1.10_recovered_phase16_exact.asm"
OUT="$ROOT/build"
EXPECTED="3033d1a54c99d7e2aa1fc7c8c2e51a56ae1b61bf4e70e8aa580f43c43e37a63e"

mkdir -p "$OUT"
as --32 -o "$OUT/basic110.o" "$SRC"
ld -m elf_i386 -Ttext=0 -e ROM_ENTRY -o "$OUT/basic110.elf" "$OUT/basic110.o"
objcopy -O binary -j .text "$OUT/basic110.elf" "$OUT/basic110_C1.10.rom"

ACTUAL="$(sha256sum "$OUT/basic110_C1.10.rom" | awk '{print $1}')"
[ "$ACTUAL" = "$EXPECTED" ] || {
    echo "HASH MISMATCH" >&2
    echo "expected: $EXPECTED" >&2
    echo "actual:   $ACTUAL" >&2
    exit 1
}

SIZE="$(wc -c < "$OUT/basic110_C1.10.rom" | tr -d ' ')"
[ "$SIZE" = "32768" ] || {
    echo "SIZE MISMATCH: $SIZE" >&2
    exit 1
}

echo "BYTE IMAGE HASH MATCH: $ACTUAL"
echo "output: $OUT/basic110_C1.10.rom"
