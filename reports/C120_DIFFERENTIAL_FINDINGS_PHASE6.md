# IBM Cassette BASIC C1.10 -> C1.20 Differential Archaeology — Phase 6

## Reference images

C1.10:
- size: 32768 bytes
- MD5: `eb28f0e8d3f641f2b58a3677b3b998cc`
- SHA-256: `3033d1a54c99d7e2aa1fc7c8c2e51a56ae1b61bf4e70e8aa580f43c43e37a63e`

Uploaded C1.20:
- size: 32768 bytes
- MD5: `14d67552a24cbdc04dada9d8312143ea`
- SHA-256: `01125823844d9877564d3365fbe212effaa3204004832293335c222672798f02`

The images differ at **313 bytes** grouped into **31 contiguous runs**.

## 8 KiB ROM checksum structure

Each 8 KiB quarter of both images independently has an unsigned-byte sum of 00h:

- C1.10: [0, 0, 0, 0]
- C1.20: [0, 0, 0, 0]

Three otherwise nonsensical changed bytes are therefore proven checksum compensation slots:

- `000B`: C1.10 `5D` -> C1.20 `B2`, balances 0000-1FFF.
- `4BE4`: C1.10 `F6` -> C1.20 `46`, balances 4000-5FFF.
- `7FE8`: C1.10 `14` -> C1.20 `D8`, balances 6000-7FFF.

For each changed 8 KiB block, removing that one byte from the delta leaves exactly the
opposite modulo-256 sum. These bytes must be represented as ROM checksum fixups, not
as recovered executable instructions.

## C1.20 PCjr/cartridge compatibility routine

C1.20 inserts code at `5FC9`:

1. Save DS.
2. Set DS=FFFFh and inspect byte `FFFF:000E`.
3. If the byte is not `FDh`, restore DS/ES and return.
4. For `FDh`, set ES=E800h and compare nine bytes at `E800:001A` with the local
   nine-byte signature at ROM `4CE4`.
5. If equal, restore DS/ES and return.
6. If unequal, disable the function-key display flag (`KEYSW`), clear the screen,
   print the NUL-terminated message `Cartridge Required`, and loop forever.

This establishes the new block as a PCjr/cartridge compatibility gate rather than a
generic BASIC change.

## CRTWID proven by the CLS delta

C1.10 `CLS` chooses a rightmost column of 39 when `[0029]=40`, otherwise 79.

C1.20 replaces that entire choice with:

    MOV DL,[0029]
    DEC DL

The surviving Microsoft screen-driver source names the physical character width
`CRTWID`. Therefore `DS:0029 = CRTWID` is now promoted to a recovered symbol.

## Graphics accumulator variables recovered

The ROM coordinate scanner matches the surviving generalized graphics `SCAND`
algorithm:

- `DS:0537 = GXPOS`
- `DS:0539 = GYPOS`
- `DS:053B = GRPACY`
- `DS:053D = GRPACX`

The machine-dependent routine at `4AB4` initializes `GRPACX/GRPACY` to the graphics
screen center and sets a still-not-historically-named pixel packing/bit-depth byte at
`DS:0055`. C1.20 rewrites this routine for its expanded video handling.

## USR sentinel: real C1.20 shipped-ROM defect

C1.10 at `1B95`:

    80 FA FF       CMP DL,FFh
    75 03          JNZ continue

The source-family intent is to test the complete 16-bit USR dispatch pointer against
FFFFh. C1.20 changes those bytes to:

    81 FA FF FF    CMP DX,FFFFh
    03 E9 ...      ; former JNZ displacement now decodes into following code

Thus the C1.20 patch widens the compare but consumes the old JNZ opcode.

Later Microsoft GWEVAL source expresses the intended fixed-size sequence as the
compact sign-extended immediate form:

    83 FA FF       CMP DX,-1
    75 03          JNZ continue

This is almost certainly not download corruption: the first 8 KiB of the supplied
C1.20 ROM has a valid zero checksum *including* the malformed bytes, and its checksum
compensation byte at `000B` is `B2`. Substituting the compact intended bytes would
break that checksum and require `000B=3A`. The malformed sequence was therefore
present when this ROM image's checksum was established.

The C1.20 reference image must remain unmodified. A future corrected-development
branch may fix it deliberately, with documentation.

## DEF FN parameter-frame correction

At `FINVLS`, C1.10 uses:

    ROR AL,1

C1.20 changes it to:

    SHR AL,1

The surviving source explains AL as the parameter-block byte length plus four bytes,
then describes the result as the number of two-byte entries. `SHR` is the direct
byte-count-to-word-count operation. This is classified as a C1.20 interpreter
bug-fix/hardening delta.

## Floating-point zero handling

C1.20 inserts two small helpers into space beginning at `600B` and `6015`, and changes
the conversion/normalization paths at `724D` and `72B6`.

`600B` factors the operation that sets the implied mantissa bit and installs working
exponent `B8h`.

`6015` preserves carry while testing the FAC exponent. When the exponent is zero it
removes its own continuation return address and returns directly to its caller's
caller with BX:DX zero. This is an intentional zero-FAC early-return helper.

The path at `724D` additionally tests `FACEXP` and immediately returns on zero. The
semantic purpose is established; exact historical labels for these C1.20-only helpers
are not yet proven.

## Phase-6 C1.10 recovery invariant

`basic110_C1.10_recovered_phase6_exact.asm` still rebuilds to C1.10 byte-for-byte:

- rebuilt MD5: `eb28f0e8d3f641f2b58a3677b3b998cc`
- `cmp`: exact
- 8 KiB checksum sums: [0, 0, 0, 0]

Current recovery debt after Phase 6:
- anonymous DSEG references: 494
- unique anonymous DSEG addresses: 120
- unique `L_xxxx` labels: 1748
- `.byte` directive lines: 2149

The `.byte` count includes legitimate tables, inline operands, checksum fixups, and
historical exact encodings and is not an unknown-count metric.
