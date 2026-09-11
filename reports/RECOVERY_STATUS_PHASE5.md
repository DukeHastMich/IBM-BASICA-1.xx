# IBM Cassette BASIC C1.10 semantic recovery — Phase 5

## Exact-build invariant

Original ROM: `basic110(1).rom`  
Recovered source: `basic110_C1.10_recovered_phase5_exact.asm`

- Size: 32768 bytes
- MD5 original: `eb28f0e8d3f641f2b58a3677b3b998cc`
- MD5 rebuilt: `eb28f0e8d3f641f2b58a3677b3b998cc`
- SHA-256 original: `3033d1a54c99d7e2aa1fc7c8c2e51a56ae1b61bf4e70e8aa580f43c43e37a63e`
- SHA-256 rebuilt: `3033d1a54c99d7e2aa1fc7c8c2e51a56ae1b61bf4e70e8aa580f43c43e37a63e`
- `cmp`: byte-for-byte identical

## What Phase 5 establishes

This is an intermediate semantic-recovery checkpoint, not a claim that all source is recovered.

Recovered and named in this pass include the formula evaluator entry/loop (`FRMEVL`,
`FRMCHK`, `LPOPER`, `EVAL`), integer/byte expression helpers (`GETINT`, `GETIN2`,
`INTFR2`, `GETBYT`, `CONINT`), tokenizer byte-save helpers (`KRNSVC`, `KRNSAV`),
variable resolver/DIM entries (`DIMCON`, `DIM`, `PTRGET`, `PTRGT1`, `PTRGT2`),
case conversion (`MAKUPL`, `MAKUPS`), integer conversion (`FRCINT`), and numeric
sign handling (`SIGN`/`SIGNS`).

The direct `SYNCHR` inline-operand control-flow damage identified in Phase 2 has
been repaired. There are now **0** regions tagged
`pending CFG recovery` from that repair pass.

## Remaining recovery debt

- Raw anonymous DSEG references: 582
- Unique still-anonymous DSEG addresses: 134
- Unique `L_xxxx` labels still present: 1759
- `.byte` directive lines: 2148

These counts deliberately include legitimate serialized tables/data and known
historical instruction encodings. Therefore `.byte` count is not itself an
"unknown count." Every remaining executable byte region still needs classification
as either:
1. real source instruction(s),
2. understood inline/self-consuming operand data,
3. understood table/string/constant data,
4. an exact historical encoding that the period assembler can express naturally,
5. or a genuine recovery defect to eliminate.

## Important recovered mechanism: SYNCHR

`SYNCHR` consumes one byte placed directly after the CALL instruction:

    CALL SYNCHR
    DB expected_character_or_token

It pops the return address, compares the inline byte to BASIC program text,
advances both pointers through the compare, pushes the advanced return address,
and returns past the byte. Blind linear disassembly therefore misidentified many
post-call bytes as instruction opcodes. Those call sites have now been repaired
as source-level inline operands.

## Build

Run:

    ./build_recovered_phase5.sh

The GNU build exists only as the current exact-output oracle. The end target is
period-appropriate MASM-family source, using the supplied Microsoft/IBM 1981
assembler material to eliminate modern-assembler encoding accommodations.

## Next recovery priority

1. Continue DSEG map recovery, especially the initialized 145-byte image copied
   from ROM offset 069Ah to DS:0000h at cold start.
2. Recover remaining high-fanout interpreter and math helpers by direct
   correspondence with the surviving Microsoft BASIC source family.
3. Classify every executable `.byte` block.
4. Port the semantically recovered source into period MASM syntax and test
   historical encoding choices against Microsoft MASM 1.00 / IBM Macro
   Assembler 1.00.
5. Only after C1.10 source is semantically closed and exact-build green, branch
   for the new 1.20 functionality.
