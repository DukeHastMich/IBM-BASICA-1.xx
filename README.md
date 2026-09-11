# IBM Cassette BASIC C1.10 — Source Recovery

This repository is an ongoing source-level reconstruction and semantic archaeology of the 32 KiB IBM Personal Computer Cassette BASIC **C1.10** ROM.

The current source is not claimed to be IBM/Microsoft's original source text. It is a lossless executable reconstruction with progressively recovered routine names, RAM symbols, data structures, control flow, and comments based on ROM behavior, contemporary IBM firmware, surviving Microsoft BASIC-family sources, and differential analysis against nearby BASIC revisions.

## Current checkpoint: Phase 16

The Phase 16 source rebuilds to a ROM whose bytes are **identical** to the reference C1.10 image.

Reference identity:

- Size: `32768` bytes
- MD5: `eb28f0e8d3f641f2b58a3677b3b998cc`
- SHA-256: `3033d1a54c99d7e2aa1fc7c8c2e51a56ae1b61bf4e70e8aa580f43c43e37a63e`

Phase 16 also removes the last direct anonymous BASIC data-segment address. `DS:0001h` is now named `SCALE_MASK` as a **semantic recovery name** because `SCALXY` uses it as a mask when selecting the 320- versus 640-pixel horizontal clipping limit. The original historical IBM/Microsoft identifier remains unknown.

## Build

Requires GNU binutils with 16-bit instruction support via GAS `.code16`:

```sh
./build.sh
```

The script assembles, links, extracts the `.text` binary, and verifies the resulting SHA-256 against the known C1.10 reference hash.

To compare against a legally obtained reference ROM as well:

```sh
./verify_against_reference.sh /path/to/basic110.rom
```

## Accuracy model

There are two different meanings of "exact" in this project:

1. **Binary exactness:** current Phase 16 output is byte-for-byte identical to the reference ROM.
2. **Historical source exactness:** still in progress. Many original local labels, comments, module boundaries, macro names, and some instruction spellings are not recoverable with certainty.

The first is a hard invariant. The second is archaeology.

## What remains

Direct `ds:0x...` references are now zero, but this does **not** mean recovery is complete. Important remaining work includes:

- decode executable regions still represented with `.byte` where historical encoding or overlapping entry points complicate assembly;
- reduce anonymous `L_xxxx` labels as control-flow identities become provable;
- audit hidden RAM operands inside raw-byte regions;
- continue recovering historical identifiers from contemporary Microsoft/IBM source lineage;
- reconstruct more original module and macro organization;
- eventually validate a period MASM-family source form in an actual DOS environment.

At Phase 16 the source still contains roughly 1,600 anonymous local labels and roughly 2,100 `.byte` lines. Some `.byte` lines are intentional and may remain necessary for byte-exact historical instruction encoding.

## Repository layout

- `src/` — current exact semantic-recovery source.
- `docs/STATUS.md` — current checkpoint and known limitations.
- `docs/PROVENANCE.md` — evidence and source-lineage rules.
- `docs/RECOVERY_METHOD.md` — methodology and exactness invariant.
- `docs/evidence/` — selected differential/token/SYNCHR archaeology reports.
- `build.sh` — deterministic build plus expected-hash check.
- `verify_against_reference.sh` — optional byte comparison against a supplied ROM.

## Provenance and legal note

IBM Cassette BASIC and related historical software remain works of their respective rights holders. This repository is an independent historical reconstruction/research project. No claim is made that recovered names or comments reproduce unpublished original source unless explicitly supported by surviving evidence.

No project-wide reuse license has been selected for this public snapshot. See `COPYRIGHT_AND_LICENSE.md`.
