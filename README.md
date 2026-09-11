# IBM Cassette BASIC C1.10 — Source Recovery

This repository contains a source-level reconstruction of the 32 KiB IBM Personal Computer Cassette BASIC **C1.10** ROM.

The reconstruction is built from the C1.10 ROM image and supporting historical evidence. It is intended to provide a readable, modifiable assembly source while preserving the exact executable image. It is a reconstructed source tree, not a transcription of unpublished IBM/Microsoft source text.

## Phase 16

Phase 16 builds a 32,768-byte ROM that is **byte-for-byte identical** to the C1.10 reference image used for recovery.

Reference identity:

- Size: `32768` bytes
- MD5: `eb28f0e8d3f641f2b58a3677b3b998cc`
- SHA-256: `3033d1a54c99d7e2aa1fc7c8c2e51a56ae1b61bf4e70e8aa580f43c43e37a63e`

Binary identity is the invariant for the exact branch: a source change is accepted only when the resulting ROM remains identical to the reference image unless the change is intentionally creating a new ROM revision.

Phase 16 also names the final direct anonymous BASIC data-segment operand at `DS:0001h` as `SCALE_MASK`. `SCALXY` uses this byte as a mask against `BITS_PER_PIXEL` when selecting the 320- or 640-pixel horizontal clipping limit. `SCALE_MASK` is a semantic recovery name; no surviving evidence currently establishes the historical IBM/Microsoft identifier.

## Source representation

The source distinguishes between executable instructions, structured data, exact byte encodings, and material that still requires semantic classification.

- **Executable code** is represented as 8086 assembly mnemonics where the instruction stream is established and GNU GAS can reproduce the required encoding.
- **Known data** is represented as strings, words, tables, constants, or byte arrays as appropriate. A `.byte` directive used for known data is a normal data representation, not an unresolved region.
- **Exact instruction encodings** may remain as `.byte` when GNU GAS would otherwise choose a different encoding or where the ROM uses overlapping entry points. Those bytes are understood and are retained literally to preserve the OEM image.
- **Not-yet-classified material** remains literal until its role is established strongly enough to promote it to code or structured data.

The number of `.byte` directives is not a measure of reconstruction completeness. Recovery status is based on whether the role and behavior of a region are understood, not on which assembler directive emits its bytes.

## OEM ROM checksums

The C1.10 image consists of four contiguous 8 KiB ROM blocks. Each 8 KiB block in the reference image has an 8-bit additive sum of `00h`.

Three explicitly identified OEM checksum bytes are preserved in the source:

```asm
OEM_ROM_CHECKSUM_BYTE_BLOCK0:
    .byte 0x5D    # 000B: OEM 8 KiB ROM checksum byte (bank sum = 00h)

OEM_ROM_CHECKSUM_BYTE_BLOCK2:
    .byte 0xF6    # 4BE4: OEM 8 KiB ROM checksum byte (bank sum = 00h)

OEM_ROM_CHECKSUM_BYTE_BLOCK3:
    .byte 0x14    # 7FE8: OEM 8 KiB ROM checksum byte (bank sum = 00h)
```

These values are present at the same offsets in the original C1.10 ROM; they are not build padding or reconstruction fixups. Differential comparison with C1.20 shows corresponding checksum-byte changes in modified blocks while preserving the `00h` additive checksum for each block.

## Build

GNU binutils is required. The source uses GAS Intel syntax with `.code16`.

```sh
./build.sh
```

The build script assembles the source, links it at ROM offset zero, extracts the `.text` image, verifies the 32,768-byte size, and checks the expected C1.10 SHA-256.

To perform a direct byte comparison against a legally obtained C1.10 reference ROM:

```sh
./verify_against_reference.sh /path/to/basic110.rom
```

A successful reference verification establishes that every output byte matches the reference image at the same ROM offset.

## Recovery status

The executable image is fully preserved and reproducible. Remaining source-recovery work is limited to source-level archaeology and maintainability:

- classify any raw regions whose code/data role has not yet been established;
- promote memory operands and other semantics embedded in intentionally literal executable encodings when doing so improves source readability without changing the byte stream;
- replace anonymous local labels with semantic names when control-flow identity is supported by evidence;
- identify historical routine, variable, module, and macro names where contemporary IBM/Microsoft lineage provides specific support;
- reconstruct historical module and macro organization where evidence permits;
- validate an equivalent period MASM-family source form if a historically styled build becomes a project requirement.

These items do not affect the byte-exact status of the Phase 16 ROM.

## Naming and provenance

The ROM itself is the primary executable reference. Semantic names and comments are promoted from direct behavior, control flow, data usage, differential comparison with nearby BASIC revisions, contemporary IBM firmware, and surviving Microsoft BASIC-family source lineage.

When a function or data item is understood but its original historical identifier is not established, the source uses a descriptive semantic recovery name rather than an anonymous numeric address. Historical names are used only when supported by evidence.

See:

- `docs/STATUS.md` — Phase 16 checkpoint and structural state
- `docs/PROVENANCE.md` — evidence and source-lineage rules
- `docs/RECOVERY_METHOD.md` — reconstruction methodology and binary invariant
- `docs/evidence/` — selected differential, token, and control-flow evidence

## Repository layout

- `src/` — current byte-exact C1.10 reconstruction source
- `docs/` — status, provenance, methodology, and recovery evidence
- `build.sh` — deterministic build and expected-hash verification
- `verify_against_reference.sh` — direct comparison against a supplied reference ROM
- `CHECKSUMS.sha256` — hashes for the public recovery package

## Copyright and licensing

This is a mixed-license repository. Original material created for the recovery project—such as the build and verification scripts, recovery documentation, analysis, and project-authored annotations—is licensed under the MIT License.

The reconstructed IBM/Microsoft program content is not relicensed by this project. `src/basic110_C1.10_recovered_phase16_exact.asm` is excluded from the MIT grant as a complete work because it reconstructs historical program content; the same exclusion applies to any byte-exact ROM image produced from it. Project-authored comments, semantic labels, and annotations within the reconstructed source are MIT-licensed only to the extent they are separately copyrightable and separable from the historical program content.

Reference ROM images are not tracked in Git, and generated `.rom` and `.bin` files are ignored.

See `LICENSE` for the license map, `LICENSE-MIT` for the MIT terms, and `COPYRIGHT_AND_LICENSE.md` for the full copyright and provenance statement.
