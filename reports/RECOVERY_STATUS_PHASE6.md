# IBM Cassette BASIC Recovery Status — Phase 6

C1.10 recovered source remains byte-for-byte exact.

- C1.10 MD5: `eb28f0e8d3f641f2b58a3677b3b998cc`
- rebuilt Phase-6 MD5: `eb28f0e8d3f641f2b58a3677b3b998cc`
- C1.20 reference MD5: `14d67552a24cbdc04dada9d8312143ea`
- C1.10 -> C1.20: 313 changed bytes in 31 runs

Major Phase-6 gains:
- proven 8 KiB checksum-fixup mechanism and three fixup bytes;
- `CRTWID` and additional screen/graphics state recovered;
- USR/DEF USR and user-defined-FN parameter state recovered;
- USR C1.20 malformed sentinel patch identified as a genuine checksummed ROM defect;
- PCjr/cartridge compatibility routine recovered;
- C1.20 floating-point zero-handling changes understood at control-flow level.

Recovery metrics:
- raw anonymous DSEG references: 494
- unique anonymous DSEG addresses: 120
- anonymous local labels: 1748
- `.byte` directive lines: 2149

Next:
- identify C1.10 mathematical data overwritten at 5FC9-6024;
- prove historical names for C1.20-only math helpers / remaining OEM screen state;
- continue high-fanout routine and DSEG recovery;
- migrate the semantically closed C1.10 source toward the supplied period MASM
  toolchain while using the current GNU build only as a byte-exact oracle.
