#!/bin/sh
set -eu
[ "$#" -eq 1 ] || { echo "usage: $0 /path/to/reference.rom" >&2; exit 2; }
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REF="$1"
"$ROOT/build.sh"
cmp "$ROOT/build/basic110_C1.10.rom" "$REF"
echo "BYTE-FOR-BYTE MATCH AGAINST: $REF"
