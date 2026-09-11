# DS:0001h — Current Investigation State

This is the last direct anonymous BASIC-DSEG address in Phase 15.

## Proven consumer

At ROM 4B07h (`SCALXY`):

```asm
mov  al,ds:BITS_PER_PIXEL        ; 2 in CGA modes 4/5, 1 in mode 6
or   al,al
je   graphics_error
...
mov  bx,0280h                    ; 640
test BYTE PTR ds:0001h,al
je   width_selected
mov  bx,0140h                    ; 320
```

Therefore `DS:0001h` is used as a mask/selector to choose 320-vs-640 horizontal clipping. It is **not** itself multiplied and is not proved to be a shift multiplier.

## Initial state

`RAM_INIT_IMAGE` begins:

```text
DS:0000 <- 00
DS:0001 <- 00
DS:0002 <- 00
DS:0003 <- C3
...
```

COLD_START copies 0x91 bytes from ROM 069Ah to DSEG 0000h.

## Startup video path

After RAM init and top-memory computation, startup jumps to ROM 4BFEh:

```asm
mov ah,0Fh
int 10h                       ; get current video mode
mov ds:BIOS_VIDEO_MODE,al     ; DS:0048
...
```

This is the right neighborhood for the producer hunt.

## Real IBM BIOS clue

IBM PC BIOS v3 BDA contains:

```text
40:49 CRT_MODE
40:4A CRT_COLS (word)
40:4C CRT_LEN  (word)
40:4E CRT_START(word)
40:50..5F cursor positions
40:60 CURSOR_MODE (word)
40:62 ACTIVE_PAGE
40:63 ADDR_6845 (word)
40:65 CRT_MODE_SET   <- current setting of 3x8/CGA mode-control register
40:66 CRT_PALETTE
```

The IBM mode-control table for modes 0..7 is:

`2C 28 2D 29 2A 2E 1E 29`

For the graphics modes:

```text
mode 4: CRT_MODE_SET=2Ah; BITS_PER_PIXEL=2; 2Ah & 02h != 0 -> 320
mode 5: CRT_MODE_SET=2Eh; BITS_PER_PIXEL=2; 2Eh & 02h != 0 -> 320
mode 6: CRT_MODE_SET=1Eh; BITS_PER_PIXEL=1; 1Eh & 01h == 0 -> 640
```

This is an exceptionally strong behavioral match, but **we have not yet proved that DS:0001 is a copy/shadow of CRT_MODE_SET**.

## User's latest correction / hypothesis — preserve this

The user pointed out that the investigation may have drifted into treating `0001h` as if it meant the beginning of BIOS code or simply post-zeroed RAM. Their intended model is that a **machine-state image / BIOS-established video state is copied or imported into BASIC's working state**, likely including state written by INT 10h immediately before the BIOS transfers to the ROM.

Do not dismiss this by saying “POST zeroes 0601h.” That only describes one physical RAM byte before BASIC establishes its own DSEG. The real question is the state-transfer mapping.

## PEEK experiment caveat

A test under the current homemade `atbios(6).asm` showed:

```text
             DS:0001 DS:0055
START           0       0
SCREEN 1        0       2
SCREEN 2        0       1
SCREEN 0        0       0
```

This proves the BASIC-owned `BITS_PER_PIXEL` field follows the SCREEN paths, but it does not prove real IBM behavior for `0001h`, because that BIOS does not implement authentic CGA mode switching and lacks major video services.

## Next proof plan

1. Disassemble/decode every instruction from COLD_START through IBM-specific video initialization, including currently raw `.byte` regions.
2. Track DS/ES explicitly at every BDA/IVT access.
3. Search for reads of BDA `40:65` (physical 0465h) and nearby video state, including indirect pointer/word/block-copy mechanisms.
4. Search for any block copy whose destination includes DSEG 0000..0002.
5. Check C1.00 for the same exact mechanism and compare with C1.10.
6. If a producer is found, only then promote `DS:0001` to a historical/semantic symbol and rebuild/cmp.
7. After direct magic reaches zero, audit memory operands embedded in executable `.byte` blocks.
