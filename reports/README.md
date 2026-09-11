# IBM Cassette BASIC C1.10 Reconstruction

This project contains a byte-exact, maintainable source reconstruction of the 32 KiB IBM Cassette BASIC C1.10 ROM. It is **not** a claim that the lost original Microsoft/IBM source file has been recovered verbatim; symbols and structures are reconstructed from the ROM and cross-identified against later-published Microsoft IBM-compatible BASIC source where correspondence is directly demonstrable.

## Build invariant

`basic110_C1.10_reconstructed.asm` assembles and links to exactly 32768 bytes and matches the original ROM byte-for-byte. Do not accept a refactor as baseline-safe until that invariant remains green.

## Recovered structure

* `STMDSP` at 0025h: statement/token dispatch table.
* `ALPTAB` at 0103h: A-Z reserved-word lookup table.
* `RESLST` at 0137h: encoded reserved words and token values.
* `ERRTAB_TEXT` at 03B5h: BASIC error strings.
* `RAM_INIT_IMAGE` at 069Ah: startup data copied from ROM into RAM.
* `CODE_BODY_START` at 0738h: first large executable region.
* `BASIC_TITLE_TEXT`, `BASIC_VERSION_TEXT`, and `BASIC_BUILD_DATE_TEXT`: banner/version data.
* `COLD_START` at 7E92h: cold-start initialization path.

The source intentionally leaves overlapping x86 entry-point tricks and encodings GNU `as` would normalize differently as `.byte` directives, with address comments. Those are recovery targets for later hand-conversion, not unknown junk.

## Evolution plan

Treat C1.10 as the immutable compatibility baseline. Add semantic labels and split modules while retaining byte identity. Once the baseline is fully mapped, make a separate 1.20-derived branch and compare against the historical PCjr C1.20 behavior before introducing new extensions.
