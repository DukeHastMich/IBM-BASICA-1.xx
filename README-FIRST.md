# IBM Cassette BASIC C1.10 Recovery — Emergency Context Snapshot

Snapshot date: 2026-09-10 (user local, America/New_York)
Current authoritative exact checkpoint: **Phase 15**

## Golden invariant

`basic110_C1.10_recovered_phase15_exact.rom` is byte-for-byte identical to the original `basic110(1).rom`.

- Original / rebuilt MD5: `eb28f0e8d3f641f2b58a3677b3b998cc`
- Original / rebuilt SHA256: `3033d1a54c99d7e2aa1fc7c8c2e51a56ae1b61bf4e70e8aa580f43c43e37a63e`

Never accept a semantic rewrite on the exact branch unless reassembly still compares byte-for-byte with the golden ROM.

## Current headline

The direct raw BASIC-DSEG magic-address count is now **ONE**:

`DS:0001h`

Phase 15 contains exactly one direct `ds:0x...` reference and it is:

```asm
SCALXY:
    mov  al,ds:BITS_PER_PIXEL
    ...
    mov  bx,640
    test BYTE PTR ds:0x1,al
    je   use_640
    mov  bx,320
```

Do **not** prematurely assign a historical symbol to `0001h`. Its consumer is understood as a compact graphics-width selector/mask, but the producer and historical name remain unresolved.

## Immediate open issue: “Magic One” and IBM BIOS state

The user correctly pulled the investigation back toward the machine-state handoff. The key question is **not** “is ROM byte 1 special?” and not simply “what is physical 0601h after POST?” The question is what machine/video state the IBM BIOS establishes immediately before INT 18h transfers to Cassette BASIC, and exactly how C1.10 imports, copies, derives, or aliases that state into the writable DSEG state that later appears as `DS:0001h`.

Important evidence already established:

- C1.10 `COLD_START` sets DS/ES/SS=0060h and copies 145 bytes from `CS:069Ah` into `DS:0000..0090`.
- Initial `RAM_INIT_IMAGE[1]` is 00h.
- Startup then jumps into the IBM-specific screen initialization at ROM `4BFEh`.
- At `4BFEh`, BASIC calls `INT 10h/AH=0Fh` (get current video state) and stores returned AL in `DS:0048` (`BIOS_VIDEO_MODE`).
- A genuine IBM PC BIOS keeps the live CGA mode-control state in the BIOS Data Area as `CRT_MODE_SET` (current value of the 3D8h register).
- IBM PC BIOS v3 uses the CGA mode-control table `2C,28,2D,29,2A,2E,1E,29` for modes 0..7.
- Those bits satisfy C1.10's `SCALXY` TEST truth table perfectly: modes 4/5 have bit 1 set while mode 6 has bit 0 clear.
- However, a direct C1.10 store from BDA `CRT_MODE_SET` to `DS:0001h` has **not yet been proved**. There may be an indirect/overlapping state copy or another compact machine-dependent setup path.
- The homemade VMB BIOS used for the PEEK experiment is **not admissible as a historical video witness**: it fakes mode set state and did not actually program CGA. Therefore its observed `PEEK(1)=0` cannot settle the real-machine question.

**Next exact task:** trace all startup/BASIC screen-init code from `COLD_START -> 4BFE` and all foreign-segment/BDA reads that can feed or overlap `DS:0001h`, with the IBM 5150 BIOS v3 BDA layout beside it. Do not assume a direct write search is sufficient.

## Latest proven promotions

- `DS:0070 = F_EDIT`: nonzero while the line editor / INLIN machinery is active. Phase 15 promoted this symbol while preserving exact bytes.
- `DS:0064 = CASSETTE_MOTOR_CMD`: stores the actual IBM BIOS cassette motor command code (`00h=ON`, `01h=OFF`), not merely an abstract Boolean state.
- IBM Cassette BIOS machine-control requests used by C1.10:
  - `INT 15h / AH=00h`: motor ON
  - `AH=01h`: motor OFF
  - `AH=02h`: read cassette block
  - `AH=03h`: write cassette block
- Cassette physical layer documented in Phase 14 comments: 8255 port 61h bit 3 motor relay, port 62h bit 4 cassette input, 8253 channel 2 output, IBM leader/sync/CRC framing.

## Critical context rules

- A numeric address has meaning only with the active segment. Never globally replace offsets without proving DS/ES context.
- Example: normal BASIC DSEG and `DS=0` IVT/BDA accesses can use identical numeric offsets for unrelated objects.
- `.byte` executable regions still contain hidden memory operands. Reaching zero direct `ds:0x...` references will **not** mean all RAM semantics are recovered. Audit raw byte regions afterward.
- GNU GAS exact source is currently the executable oracle. Final intended historical dialect is period MASM-family after semantic recovery.
- Do not claim period MASM assembled the source unless actually run under DOS.

## Source lineage / external witnesses used

- IBM PC BIOS v3 source (10/27/82 generation): `gawlas/IBM-PC-BIOS`, `IBM PC/PCBIOSV3.ASM`.
- IBM PC BIOS v2 was examined earlier but is not the preferred C1.10 partner generation.
- Microsoft GW-BASIC surviving 1982/83 source: `microsoft/GW-BASIC` and the reverse-engineered OEM module in `jeffpar/basicdos`.
- PCjs C1.00 ROM transcription/reference: `jeffpar/pcjs`, `machines/pcx86/ibm/5150/rom/basic/BASIC100.json5`.
- These later sources are lineage evidence, not automatic proof of literal C1.10 source identifiers.

## Files to open first after context loss

1. `core/basic110_C1.10_recovered_phase15_exact.asm`
2. `core/basic110(1).rom`
3. `README-FIRST.md`
4. `MAGIC_ONE_INVESTIGATION.md`
5. `firmware_witnesses/atbios(6).asm` only as the homemade BIOS regression witness, not historical authority.
6. `firmware_witnesses/Octek_FOX_II_286_AMI_HT12_effective_64K.bin` and its disassembly only as later firmware archaeology, not a 5150 truth source.
