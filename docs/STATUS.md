# Phase 16 Status

## Binary invariant

`src/basic110_C1.10_recovered_phase16_exact.asm` rebuilds to exactly 32768 bytes with:

`SHA256 3033d1a54c99d7e2aa1fc7c8c2e51a56ae1b61bf4e70e8aa580f43c43e37a63e`

This is byte-for-byte identical to the reference IBM Cassette BASIC C1.10 ROM used during recovery.

## Phase 16 change

The final direct anonymous BASIC-DSEG operand at `DS:0001h` was promoted to:

```asm
.equ SCALE_MASK, 0x0001
```

`SCALXY` uses the byte as a mask against `BITS_PER_PIXEL` to select a horizontal clipping bound of either 320 or 640 pixels.

`SCALE_MASK` is deliberately a semantic name. The historical Microsoft/IBM source identifier has not been proved and may be changed later if stronger evidence appears.

## Structural state

- Direct raw `ds:0x...` references: **0**
- Anonymous `L_xxxx` labels: about **1603**
- `.byte` lines: about **2170**
- Source lines: about **14718**

Those counts are recovery metrics, not defect counts. Some raw bytes are intentionally retained because GNU GAS would otherwise select a different but semantically equivalent encoding or because the ROM uses overlapping-entry-point tricks.

## Known limitations

This is not a claim of original-source perfection. Remaining archaeology includes hidden memory operands in raw executable bytes, unnamed local control-flow structure, historical module boundaries, historical macro spelling, and period-assembler validation.
