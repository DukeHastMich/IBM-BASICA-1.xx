# C1.20 Differential Open Items — Phase 6

## Resolved during this pass

- `000B`, `4BE4`, `7FE8`: resolved as 8 KiB ROM checksum compensation bytes.
- `0029`: resolved as `CRTWID`.
- `0537/0539/053B/053D`: resolved as `GXPOS/GYPOS/GRPACY/GRPACX`.
- `1D39`: understood as `FINVLS` parameter-frame word-count correction.
- `1B95/1B98`: control-flow anomaly understood as a shipped malformed attempt to
  widen the USR undefined-entry sentinel comparison. Preserve in historical C1.20.

## Still open

1. **Exact historical labels for C1.20-only helpers at 600B and 6015.**
   Their behavior is understood, but no surviving source label has yet been proven.

2. **Historical identifier for DS:0048.**
   Its role is proven: it stores the current BIOS video mode and is consumed by
   SCREEN/video routines. Phase 6 uses the explicit reconstructed name
   `BIOS_VIDEO_MODE` rather than pretending to know Microsoft's original symbol.

3. **Historical identifier for DS:0055.**
   Its behavior is a graphics pixel-packing/bit-depth parameter: 2 for modes 4/5,
   1 for mode 6, and 0 where the old CGA graphics path is unavailable. Do not
   assign a historical source name until one is supported.

4. Continue classifying the data/constant area overwritten by the C1.20 code at
   5FC9-6024 so that the C1.10 side is also represented as named mathematical data,
   not an opaque byte reservoir.
