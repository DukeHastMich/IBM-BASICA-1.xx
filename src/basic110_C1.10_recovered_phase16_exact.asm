# -----------------------------------------------------------------------------
# IBM Personal Computer Cassette BASIC C1.10
# SEMANTIC RECOVERY SOURCE - PHASE 16 (exact C1.10 rebuild)
# -----------------------------------------------------------------------------
# This file is the working semantic recovery of the C1.10 ROM. It remains incomplete: Original Microsoft/IBM
# comments, macro organization, and local symbol names that are not independently
# recoverable are not claimed. Names matched against Microsoft's later-published
# IBM-compatible BASIC sources are retained where the ROM/table relationship is clear.
#
# Unknown numeric addresses / byte regions that remain are tracked as recovery defects.
# Original ROM: 32768 bytes, F600:0000, MD5 eb28f0e8d3f641f2b58a3677b3b998cc
# Rebuild is verified byte-for-byte with GNU binutils.
#
# Build:
#   as --32 -o basic110_reconstructed.o basic110_reconstructed.asm
#   ld -m elf_i386 -Ttext=0 -e ROM_ENTRY -o basic110_reconstructed.elf basic110_reconstructed.o
#   objcopy -O binary -j .text basic110_reconstructed.elf basic110_reconstructed.rom
#
# Strategy:
#   * Real 8086 instructions for statically recovered executable code.
#   * Symbolic dispatch/token/error tables.
#   * .byte only for unclassified data, overlapping-entrypoint tricks, and
#     instructions for which GNU as selects a non-identical historical encoding.
# -----------------------------------------------------------------------------

.intel_syntax noprefix
.code16
.section .text
.global ROM_ENTRY

# -----------------------------------------------------------------------------
# Recovered interpreter constants / DSEG map (through phase 16; confidence varies by annotation)
# These names are supported by direct ROM behavior and matching Microsoft BASIC
# source-family sequences; unresolved addresses remain numeric for now.
# -----------------------------------------------------------------------------
.equ ERRFLG,  0x0028
.equ CURLIN,  0x002E
.equ TXTTAB,  0x0030
.equ CNTOFL,  0x006F
.equ KBUF,    0x00B8
.equ KBFLEN,  0x013E
.equ VALTYP,  0x02FB
.equ DORES,   0x02FC
.equ DONUM,   0x02FD
.equ MEMSIZ,  0x030A
.equ FRETOP,  0x032F
.equ TEMP,    0x033B
.equ AUTFLG,  0x033E
.equ AUTLIN,  0x033F
.equ AUTINC,  0x0341
.equ SAVTXT,  0x0343
.equ SAVSTK,  0x0345   # saved known-good stack pointer for error/reset recovery
.equ ERRLIN,  0x0347   # BASIC line number at last error
.equ DOT,     0x0349
.equ ERRTXT,  0x034B   # saved program-text pointer used by RESUME
.equ ONELIN,  0x034D   # ON ERROR GOTO target line/pointer state
.equ ONEFLG,  0x034F   # nonzero while executing ON ERROR trap
.equ VARTAB,  0x0358
.equ DATPTR,  0x035E
.equ CHNFLG,  0x046B
.equ PTRFIL,  0x04E9
.equ NAMCNT,  0x008E
.equ NAMBUF,  0x008F
.equ DIMFLG,  0x02FA
.equ DEFTBL,  0x031F
.equ TEMP3,   0x0331
.equ TEMP2,   0x0352
.equ OLDLIN,  0x0354   # saved continuation line number
.equ OLDTXT,  0x0356   # saved continuation text pointer
.equ SUBFLG,  0x0339
.equ FLGOVC,  0x04A8
.equ FACLO,   0x04A3
.equ FACSGN,  0x04A5
.equ FACEXP,  0x04A6

# Phase 6: symbols resolved by C1.10<->C1.20 differential archaeology and
# direct correspondence with the surviving Microsoft BASIC source family.
.equ USRTAB,          0x0012
.equ CRTWID,          0x0029
.equ CSRY,            0x0056   # current cursor row/line; low byte of packed CSRY:CSRX word
.equ CSRX,            0x0057   # current cursor column; immediately follows CSRY
.equ FSTLIN,          0x0058   # older editor: first/start physical line of marked logical input
.equ FSTCOL,          0x0059   # older editor: first/start column of marked logical input
.equ LSTCOL,          0x005A   # older editor: last-column bound; C1.10 has no adjacent later-style LSTLIN here
.equ WDOTOP,          0x005B   # top row of active text window
.equ WDOBOT,          0x005C   # bottom row of active text window
.equ LINCNT,          0x005D   # last/physical screen row count used when widening window

.equ PEN_ENABLED,          0x0034   # semantic: PEN statement enables/disables light-pen function access
.equ STRIG_ENABLED,        0x0045   # semantic: STRIG statement enables/disables joystick-trigger function access
.equ CASSETTE_MOTOR_CMD,   0x0064   # BIOS INT 15h cassette motor command: 00=on, 01=off
.equ LOAD_PROTECT_FLAG,    0x0463   # semantic: protected-program bit extracted from load header then copied to PROFLG
.equ BIOS_VIDEO_MODE, 0x0048   # semantic recovery name; historical identifier not yet proven
.equ KEYSW,           0x0071
.equ CONLO,           0x0302
.equ CONTXT,          0x02FE   # saved text pointer following an embedded constant
.equ CONSAV,          0x0300   # saved embedded-constant token
.equ CONTYP,          0x0301   # saved embedded-constant value type
.equ NUMCON,          0x0004   # two-byte fake text used by CHRGTR to re-scan embedded constants
.equ DSEGZ,           0x0006   # data-segment zero byte immediately following NUMCON
.equ SCALE_MASK,       0x0001   # semantic recovery name: SCALXY mask selecting 320-vs-640 horizontal graphics limit; historical identifier unresolved
.equ TEMPPT,          0x030C   # pointer to next temporary string-descriptor slot
.equ TEMPST,          0x030E   # base of temporary string-descriptor area
.equ SAVSEG,          0x0350
.equ PRMSTK,          0x037A
.equ PRMLEN,          0x037C
.equ PARM1,           0x037E
.equ PRMLN2,          0x03E4
.equ PARM2,           0x03E6
.equ NOFUNS,          0x044D
.equ FUNACT,          0x0450
.equ GXPOS,           0x0537
.equ GYPOS,           0x0539
.equ GRPACY,          0x053B
.equ GRPACX,          0x053D

# Phase 7: math workspace and variable-table symbols recovered by exact
# control-flow correspondence with Microsoft MATH1/MATH2/BIPTRG.
.equ ARYTAB,          0x035A
.equ STREND,          0x035C
.equ ARYTA2,          0x044B
.equ DBUFF,           0x0478
.equ DFACL,           0x049F
.equ FACM1,           0x04A5   # historical $FACM1 word alias; FACSGN is its low/sign byte
.equ FAC_AUX,         0x04A7   # semantic alias for historical $FAC+1 workspace byte
.equ ARGLO,           0x04AB
.equ ARG_M1,          0x04B1   # historical $ARG-1 word
.equ ARGEXP,          0x04B2   # historical $ARG exponent byte
.equ FMTCX,           0x0481   # historical $FMTCX word
.equ FMTAX,           0x0483   # historical $FMTAX word
.equ FMTAL,           0x0483   # historical $FMTAL low-byte alias

# Phase 8: interpreter/input/video state proven from exact source-family matches.
.equ FLGINP,          0x033A   # READ/INPUT selector; exact GWMAIN READ/INPCON correspondence
.equ USFLG,           FLGINP   # exact BIPRTU alias: PRINT USING printed-a-value flag shares this early-BASIC temp byte
.equ PTRFLG,          0x033D   # nonzero when encoded line pointers exist; DEPTR gate
.equ OPTVAL,          0x045C   # OPTION BASE value (0 or 1)
.equ OPTFLG,          0x045D   # OPTION BASE has-been-seen flag/value+1
.equ TEMPA,           0x045E   # general temp word; CALL86 stores user subroutine offset here
.equ ACTIVE_PAGE,     0x0049   # semantic recovery name: BIOS page used for drawing/cursor I/O
.equ VISUAL_PAGE,     0x004A   # semantic recovery name: BIOS page selected for display
.equ TEXT_FOREGROUND_COLOR, 0x004B  # semantic: COLOR foreground, 0..31; bit 4 feeds blink state
.equ TEXT_BACKGROUND_COLOR, 0x004C  # semantic: COLOR background, 0..15
.equ BORDER_PALETTE_VALUE, 0x004D  # semantic: BIOS AH=0Bh border/background palette value
.equ TEXT_WRITE_ATTRIBUTE, 0x004E  # semantic: BIOS AH=09h attribute for character writes
.equ SCREEN_FILL_ATTRIBUTE,0x004F  # semantic: attribute for blanks, scrolling and CLS
.equ CTRL_BREAK_PENDING, 0x005E  # semantic: INT 1Bh deferred Break flag; next read returns Ctrl-C and clears it
.equ KEY_EXPANSION_STATE,0x006A # semantic: 00=none, FF=stream macro, 01=emit trailing space
.equ KEY_EXPANSION_PTR,  0x006B # semantic: offset of current function-key/keyword expansion string
.equ KEY_EXPANSION_SEG,  0x006D # semantic: segment of current expansion string (DS RAM or CS ROM)
.equ KEY_EXPANSION_SEG_HI,0x006E # high-byte alias used to distinguish ROM-vs-RAM expansion termination
.equ SOUND_RETRIGGER_FLAG,0x0065 # semantic: preserve speaker gate while waiting to retune an active SOUND
.equ SOUND_TICK_COUNTDOWN,0x0066 # semantic: timer-tick duration remaining for active SOUND
.equ BITS_PER_PIXEL,  0x0055   # semantic: CGA pixel bit width/shift count; 2 in modes 4/5, 1 in mode 6, 0=no old graphics path
.equ SAVE_END_ADDR,    0x0704   # semantic: exclusive end of current SAVE/BSAVE/cassette transfer span
.equ PIXEL_BYTE_ADDR,   0x06F3   # semantic: mapped B800 framebuffer byte offset for current graphics point
.equ PIXEL_MASK,        0x06F5   # semantic: bit mask selecting current pixel within mapped byte
.equ ATRBYT,            0x06F6   # source-family name; older CGA SETATR stores the expanded/repeated pixel attribute pattern
.equ ENDFOR,          0x0335   # saved end-of-FOR/loop statement text pointer; exact GWMAIN FOR match
.equ PROFLG,          0x0464   # protected-program flag; SCRTCH clears it
.equ TOPMEM,          0x002C   # top of BASIC RAM/stack; STKINI and OMERR stack anchor
.equ DSCTMP,          0x032C   # three-byte temporary string descriptor
.equ NXTTXT,          0x0453   # exact NEXT86 name: starting NEXT text pointer saved across PTRGET/FNDFOR
.equ NXTFLG,          0x0455   # NEXT86 control flag
.equ FVALSV,          0x0456   # saved initial FOR value used by NEXT86
.equ TRCFLG,          0x0476   # TRACE state; TON/TOFF set/clear
.equ TEMP9,           0x044E   # string-GC parameter-block iteration pointer (BASIC DSEG context only)
.equ PRMFLG,          0x044A   # exact BIPTRG name: nonzero while PARM1 must be searched before normal variables
.equ INPPAS,          0x0452   # exact GWMAIN name: SCNVAL input-pass/early-return state
.equ NXTLIN,          0x045A   # line number of matching NEXT/WEND while scanning loop structure
.equ MAX_FILE_NUMBER, 0x04DF   # semantic recovery name: highest legal BASIC file number
.equ FILE_PTR_TABLE,  0x04E0   # semantic recovery name: pointer to static table of file-block pointers
.equ FILE0_BLOCK_END, 0x04E4   # semantic: final byte address of static file block 0, initialized as first-block base + 0x33
.equ FILENAME_83_BUFFER,0x04F0   # semantic: 11-byte padded 8.3 filename buffer (name+extension, no device prefix)
.equ FILENAME_DOT_SEEN,0x06FF   # semantic: nonzero after filename parser consumes extension separator dot
.equ MRGFLG,          0x0465   # MERGE/CHAIN merge state; exact CLEARC correspondence
.equ NLONLY,          0x0536   # LOAD/file-state flags; exact CLEARC/GIO correspondence
.equ RUNFLG,          0x04EF   # LOAD ,R state: run program after successful load
.equ BINARY_ADDR_PARAM_SWITCH, 0x0060  # BLOAD/BSAVE explicit start-address override: 00=use file address, FF=caller supplied
.equ SAVE_PROTECT_FLAG, 0x0462  # semantic: nonzero only for SAVE ...,P; gates protected-program transform/restore

# Phase 10: additional exact/semantic recoveries.
.equ RNDCOP,          0x0007   # exact GWDATA name: four-byte initial random-number seed copy
.equ RNDX,            0x000B   # exact GWDATA name: four-byte last/generated random-number state

# Phase 11: parser/editor/math/file/cassette structures recovered in the continuing pass.
.equ BUFMIN,          0x01F6   # exact source-family name: sentinel comma immediately before BUF
.equ BUF,             0x01F7   # exact source-family name: BASIC line input buffer
.equ TTYPOS,          0x02F9   # exact GWDATA name: terminal/output position state immediately before DIMFLG
.equ NAMTMP,          0x00B5   # exact BIPTRG name: saved text pointer during long variable/subscript recovery
.equ TEMP8,           0x0333   # exact BISTRS name: end-of-array temp used during string garbage collection
.equ DATLIN,          0x0337   # exact GWMAIN name: current DATA statement line for READ error reporting
.equ PRMPRV,          0x03E2   # exact GWDATA name: previous parameter-block pointer; initialized to PRMSTK
.equ F_EDIT,          0x0070   # screen-editor family name: nonzero while INLIN/editor machinery is active
.equ F_INST,          0x0072   # exact screen-editor family name: FFh indicates insert mode
.equ CURSOR_SHAPE,    0x0068   # semantic: BIOS INT 10h/AH=01 cursor start/end scan-line word
.equ STICK_VALUES,    0x0041   # semantic: four cached joystick timing values for STICK(0..3)
.equ LPT_WIDTH,       0x0062   # semantic/source-family field role: printer columns per line
.equ LPT_POSITION,    0x0063   # semantic/source-family field role: current zero-relative printer column
.equ LSTCHR,          0x0027   # exact source-family name: last screen-output character; used for CR/LF filtering
.equ BASIC_PROGRAM_FILE_FLAG, 0x005F # semantic: SAVE program-file selector; yields cassette/file header bit 40h, cleared for BSAVE
.equ PRINT_ZONE_LIMIT,0x002A   # semantic: PRINT-comma wrap threshold derived from 14-column zones
.equ EDITOR_BLANK_CHAR,0x0050  # semantic: old screen editor blank/fill character; initialized to ASCII space
.equ CASSETTE_XFER_COUNT, 0x0549 # semantic: saved BIOS cassette transfer byte count
.equ CASSETTE_XFER_SEG,   0x054B # semantic: saved BIOS cassette transfer segment
.equ CASSETTE_XFER_OFF,   0x054D # semantic: saved BIOS cassette transfer offset

# IBM 5150 BIOS cassette machine-control interface (INT 15h).
# These are the actual request codes used by C1.10; BASIC delegates physical
# modulation, leader/sync/CRC handling and relay control to the system BIOS.
.equ BIOS_CASS_MOTOR_ON,    0x00
.equ BIOS_CASS_MOTOR_OFF,   0x01
.equ BIOS_CASS_READ_BLOCK,  0x02
.equ BIOS_CASS_WRITE_BLOCK, 0x03
.equ BIOS_CASS_ST_OK,             0x00
.equ BIOS_CASS_ST_CRC_ERROR,      0x01
.equ BIOS_CASS_ST_NO_TRANSITIONS, 0x02
.equ BIOS_CASS_ST_NO_LEADER,      0x04
.equ BIOS_CASS_ST_BAD_COMMAND,    0x80
# Physical IBM 5150 cassette hardware used underneath the BIOS:
#   8255 PPI port 61h bit 3: 0=motor on, 1=motor off
#   8255 PPI port 62h bit 4: cassette data input
#   8253 timer channel 2: cassette data output; 1=1ms, 0=0.5ms
#   BIOS record framing: 256 FFh leader bytes, 0 sync bit, 16h sync byte,
#   256-byte data blocks followed by 2-byte CRC values.
.equ IBM_PPI_PORT_B,              0x61
.equ IBM_PPI_CASS_MOTOR_OFF_BIT, 0x08
.equ IBM_PPI_PORT_C,              0x62
.equ IBM_PPI_CASS_DATA_IN_BIT,    0x10
.equ IBM_CASS_SYNC_BYTE,          0x16
# Foreign-segment absolute offsets used only while DS=0.
.equ IVT_INT1B_OFF,   0x006C
.equ IVT_INT1B_SEG,   0x006E
.equ IVT_INT1C_OFF,   0x0070
.equ IVT_INT1C_SEG,   0x0072
.equ BASIC_DSEG_SAVE_ABS, 0x0510 # physical 0000:0510, loaded by installed INT 1Bh/1Ch handlers
.equ BDA_VIDEO_PAGE_START_ABS, 0x044E # physical 0000:044E = BDA CRT page-start offset
.equ CONHI,           CONLO+2  # upper two bytes of saved 4-byte embedded constant

# Token/operator values recovered from the ROM reserved-word/operator tables.
.equ TK_GREAT, 0xE6
.equ TK_EQUAL, 0xE7
.equ TK_LESS,  0xE8
.equ TK_PLUS,  0xE9
.equ TK_MINUS, 0xEA
.equ TK_MULT,  0xEB
.equ TK_DIV,   0xEC
.equ TK_EXP,   0xED
.equ TK_AND,   0xEE
.equ TK_OR,    0xEF
.equ TK_XOR,   0xF0
.equ TK_EQV,   0xF1
.equ TK_IMP,   0xF2
.equ TK_MOD,   0xF3
.equ TK_IDIV,  0xF4

# Statement/syntax tokens used by inline SYNCHR operands.
.equ TOK_INPUT, 0x85
.equ TOK_GOTO,  0x89
.equ TOK_TO,    0xCC
.equ TOK_THEN,  0xCD
.equ TOK_FN,    0xD1
.equ TOK_OFF,   0xDD

ROM_ENTRY:
    jmp    COLD_START                            # 0000: E9 8F 7E
BASICA_ENTRY_1:
    call   FRCINT                                # 0003: E8 A7 6B
    retf                                         # 0006: CB
BASICA_ENTRY_2:
    call   MAKINT                                # 0007: E8 02 65
    retf                                         # 000A: CB
OEM_ROM_CHECKSUM_BYTE_BLOCK0:
    .byte 0x5D                                  # 000B: OEM 8 KiB ROM checksum byte (bank sum = 00h)
ROM_CODE_000C:
    # C1.20 changes only the preceding compensation byte (5D->B2); code resumes here.
L_000C:
    call   ISFLIO                                # 000C: E8 C7 2F
    je     L_001E                                # 000F: 74 0D
    mov    si,WORD PTR ds:PTRFIL                  # 0011: 8B 36 E9 04
    mov    al,BYTE PTR [si+0x2e]                 # 0015: 8A 44 2E
    cmp    al,0xfe                               # 0018: 3C FE
    je     L_001E                                # 001A: 74 02
    cmp    al,0xfd                               # 001C: 3C FD
L_001E:
    ret                                          # 001E: C3
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 # 001F
STMDSP:
    .word ENDST                # token 81 END
    .word FOR                  # token 82 FOR
    .word NEXT                 # token 83 NEXT
    .word DATAS                # token 84 DATA
    .word INPUT                # token 85 INPUT
    .word DIM                  # token 86 DIM
    .word READ                 # token 87 READ
    .word LET                  # token 88 LET
    .word GOTO                 # token 89 GOTO/GO TO
    .word RUN                  # token 8A RUN
    .word IFS                  # token 8B IF
    .word RESTORE              # token 8C RESTORE
    .word GOSUB                # token 8D GOSUB
    .word RETURN               # token 8E RETURN
    .word REM                  # token 8F REM
    .word STOP                 # token 90 STOP
    .word PRINT                # token 91 PRINT
    .word CLEAR                # token 92 CLEAR
    .word LIST                 # token 93 LIST
    .word SCRATH               # token 94 NEW
    .word ONGOTO               # token 95 ON
    .word FNWAIT               # token 96 WAIT
    .word DEF                  # token 97 DEF
    .word POKE                 # token 98 POKE
    .word CONT                 # token 99 CONT
    .word SNERR                # token 9A reserved
    .word SNERR                # token 9B reserved
    .word FNOUT                # token 9C OUT
    .word LPRINT               # token 9D LPRINT
    .word LLIST                # token 9E LLIST
    .word 0x0000               # token 9F reserved
    .word WIDTHS               # token A0 WIDTH
    .word ELSES                # token A1 ELSE
    .word TON                  # token A2 TRON
    .word TOFF                 # token A3 TROFF
    .word SWAP                 # token A4 SWAP
    .word ERASE                # token A5 ERASE
    .word EDIT                 # token A6 EDIT
    .word ERRORS               # token A7 ERROR
    .word RESUME               # token A8 RESUME
    .word DELETE               # token A9 DELETE
    .word AUTO                 # token AA AUTO
    .word RESEQ                # token AB RENUM
    .word DEFSTR               # token AC DEFSTR
    .word DEFINT               # token AD DEFINT
    .word DEFREA               # token AE DEFSNG
    .word DEFDBL               # token AF DEFDBL
    .word LINE                 # token B0 LINE
    .word WHILE                # token B1 WHILE
    .word WEND                 # token B2 WEND
    .word CALLS                # token B3 CALL
    .word 0x0000               # token B4 reserved
    .word 0x0000               # token B5 reserved
    .word 0x0000               # token B6 reserved
    .word WRITE                # token B7 WRITE
    .word OPTION               # token B8 OPTION
    .word RANDOM               # token B9 RANDOMIZE
    .word OPEN                 # token BA OPEN
    .word CLOSE                # token BB CLOSE
    .word LOAD                 # token BC LOAD
    .word MERGE                # token BD MERGE
    .word SAVE                 # token BE SAVE
    .word COLOR                # token BF COLOR
    .word CLS                  # token C0 CLS
    .word MOTOR                # token C1 MOTOR
    .word BSAVE                # token C2 BSAVE
    .word BLOAD                # token C3 BLOAD
    .word SOUNDS               # token C4 SOUND
    .word BEEPS                # token C5 BEEP
    .word PSET                 # token C6 PSET
    .word PRESET               # token C7 PRESET
    .word SCREEN               # token C8 SCREEN
    .word KEYS                 # token C9 KEY
    .word LOCATE               # token CA LOCATE
FUNDSP:
    .word LEFT_DOLLAR            # FF 01 LEFT$
    .word RIGHT_DOLLAR           # FF 02 RIGHT$
    .word MID_DOLLAR             # FF 03 MID$
    .word SGN                    # FF 04 SGN
    .word VINT                   # FF 05 INT
    .word ABSFN                  # FF 06 ABS
    .word SQR                    # FF 07 SQR
    .word RND                    # FF 08 RND
    .word SIN                    # FF 09 SIN
    .word LOG                    # FF 0A LOG
    .word EXP                    # FF 0B EXP
    .word COS                    # FF 0C COS
    .word TAN                    # FF 0D TAN
    .word ATN                    # FF 0E ATN
    .word FRE                    # FF 0F FRE
    .word FNINP                  # FF 10 INP
    .word POS                    # FF 11 POS
    .word LEN                    # FF 12 LEN
    .word STR_DOLLAR             # FF 13 STR$
    .word VAL                    # FF 14 VAL
    .word ASC                    # FF 15 ASC
    .word CHR_DOLLAR             # FF 16 CHR$
    .word PEEK                   # FF 17 PEEK
    .word SPACE_DOLLAR           # FF 18 SPACE$
    .word STRO_DOLLAR            # FF 19 OCT$
    .word STRH_DOLLAR            # FF 1A HEX$
    .word LPOS                   # FF 1B LPOS
    .word FRCINT                 # FF 1C CINT
    .word FRCSNG                 # FF 1D CSNG
    .word FRCDBL                 # FF 1E CDBL
    .word FIXER                  # FF 1F FIX
    .word PENF                   # FF 20 PEN
    .word STICKF                 # FF 21 STICK
    .word STRIGF                 # FF 22 STRIG
    .word EOF                    # FF 23 EOF
    .word LOC                    # FF 24 LOC
    .word LOF                    # FF 25 LOF
ALPTAB:
    .word ATAB                 # A reserved-word group
    .word BTAB                 # B reserved-word group
    .word CTAB                 # C reserved-word group
    .word DTAB                 # D reserved-word group
    .word ETAB                 # E reserved-word group
    .word FTAB                 # F reserved-word group
    .word GTAB                 # G reserved-word group
    .word HTAB                 # H reserved-word group
    .word ITAB                 # I reserved-word group
    .word JTAB                 # J reserved-word group
    .word KTAB                 # K reserved-word group
    .word LTAB                 # L reserved-word group
    .word MTAB                 # M reserved-word group
    .word NTAB                 # N reserved-word group
    .word OTAB                 # O reserved-word group
    .word PTAB                 # P reserved-word group
    .word QTAB                 # Q reserved-word group
    .word RTAB                 # R reserved-word group
    .word STAB                 # S reserved-word group
    .word TTAB                 # T reserved-word group
    .word UTAB                 # U reserved-word group
    .word VTAB                 # V reserved-word group
    .word WTAB                 # W reserved-word group
    .word XTAB                 # X reserved-word group
    .word YTAB                 # Y reserved-word group
    .word ZTAB                 # Z reserved-word group
RESLST:
ATAB:
    .byte 'U', 'T', ('O' | 0x80), 0xAA # AUTO token AA
    .byte 'N', ('D' | 0x80), 0xEE # AND token EE
    .byte 'B', ('S' | 0x80), 0x06 # ABS token 06
    .byte 'T', ('N' | 0x80), 0x0E # ATN token 0E
    .byte 'S', ('C' | 0x80), 0x15 # ASC token 15
    .byte 0x00 # end reserved-word group
BTAB:
    .byte 'S', 'A', 'V', ('E' | 0x80), 0xC2 # BSAVE token C2
    .byte 'L', 'O', 'A', ('D' | 0x80), 0xC3 # BLOAD token C3
    .byte 'E', 'E', ('P' | 0x80), 0xC5 # BEEP token C5
    .byte 0x00 # end reserved-word group
CTAB:
    .byte 'O', 'L', 'O', ('R' | 0x80), 0xBF # COLOR token BF
    .byte 'L', 'O', 'S', ('E' | 0x80), 0xBB # CLOSE token BB
    .byte 'O', 'N', ('T' | 0x80), 0x99 # CONT token 99
    .byte 'L', 'E', 'A', ('R' | 0x80), 0x92 # CLEAR token 92
    .byte 'S', 'R', 'L', 'I', ('N' | 0x80), 0xDB # CSRLIN token DB
    .byte 'I', 'N', ('T' | 0x80), 0x1C # CINT token 1C
    .byte 'S', 'N', ('G' | 0x80), 0x1D # CSNG token 1D
    .byte 'D', 'B', ('L' | 0x80), 0x1E # CDBL token 1E
    .byte 'O', ('S' | 0x80), 0x0C # COS token 0C
    .byte 'H', 'R', ('$' | 0x80), 0x16 # CHR$ token 16
    .byte 'A', 'L', ('L' | 0x80), 0xB3 # CALL token B3
    .byte 'L', ('S' | 0x80), 0xC0 # CLS token C0
    .byte 0x00 # end reserved-word group
DTAB:
    .byte 'E', 'L', 'E', 'T', ('E' | 0x80), 0xA9 # DELETE token A9
    .byte 'A', 'T', ('A' | 0x80), 0x84 # DATA token 84
    .byte 'I', ('M' | 0x80), 0x86 # DIM token 86
    .byte 'E', 'F', 'S', 'T', ('R' | 0x80), 0xAC # DEFSTR token AC
    .byte 'E', 'F', 'I', 'N', ('T' | 0x80), 0xAD # DEFINT token AD
    .byte 'E', 'F', 'S', 'N', ('G' | 0x80), 0xAE # DEFSNG token AE
    .byte 'E', 'F', 'D', 'B', ('L' | 0x80), 0xAF # DEFDBL token AF
    .byte 'E', ('F' | 0x80), 0x97 # DEF token 97
    .byte 0x00 # end reserved-word group
ETAB:
    .byte 'L', 'S', ('E' | 0x80), 0xA1 # ELSE token A1
    .byte 'N', ('D' | 0x80), 0x81 # END token 81
    .byte 'R', 'A', 'S', ('E' | 0x80), 0xA5 # ERASE token A5
    .byte 'D', 'I', ('T' | 0x80), 0xA6 # EDIT token A6
    .byte 'R', 'R', 'O', ('R' | 0x80), 0xA7 # ERROR token A7
    .byte 'R', ('L' | 0x80), 0xD4 # ERL token D4
    .byte 'R', ('R' | 0x80), 0xD5 # ERR token D5
    .byte 'X', ('P' | 0x80), 0x0B # EXP token 0B
    .byte 'O', ('F' | 0x80), 0x23 # EOF token 23
    .byte 'Q', ('V' | 0x80), 0xF1 # EQV token F1
    .byte 0x00 # end reserved-word group
FTAB:
    .byte 'O', ('R' | 0x80), 0x82 # FOR token 82
    .byte ('N' | 0x80), 0xD1 # FN token D1
    .byte 'R', ('E' | 0x80), 0x0F # FRE token 0F
    .byte 'I', ('X' | 0x80), 0x1F # FIX token 1F
    .byte 0x00 # end reserved-word group
GTAB:
    .byte 'O', 'T', ('O' | 0x80), 0x89 # GOTO token 89
    .byte 'O', ' ', 'T', ('O' | 0x80), 0x89 # GO TO token 89
    .byte 'O', 'S', 'U', ('B' | 0x80), 0x8D # GOSUB token 8D
    .byte 0x00 # end reserved-word group
HTAB:
    .byte 'E', 'X', ('$' | 0x80), 0x1A # HEX$ token 1A
    .byte 0x00 # end reserved-word group
ITAB:
    .byte 'N', 'P', 'U', ('T' | 0x80), 0x85 # INPUT token 85
    .byte ('F' | 0x80), 0x8B # IF token 8B
    .byte 'N', 'S', 'T', ('R' | 0x80), 0xD8 # INSTR token D8
    .byte 'N', ('T' | 0x80), 0x05 # INT token 05
    .byte 'N', ('P' | 0x80), 0x10 # INP token 10
    .byte 'M', ('P' | 0x80), 0xF2 # IMP token F2
    .byte 'N', 'K', 'E', 'Y', ('$' | 0x80), 0xDE # INKEY$ token DE
    .byte 0x00 # end reserved-word group
JTAB:
    .byte 0x00 # end reserved-word group
KTAB:
    .byte 'E', ('Y' | 0x80), 0xC9 # KEY token C9
    .byte 0x00 # end reserved-word group
LTAB:
    .byte 'O', 'C', 'A', 'T', ('E' | 0x80), 0xCA # LOCATE token CA
    .byte 'P', 'R', 'I', 'N', ('T' | 0x80), 0x9D # LPRINT token 9D
    .byte 'L', 'I', 'S', ('T' | 0x80), 0x9E # LLIST token 9E
    .byte 'P', 'O', ('S' | 0x80), 0x1B # LPOS token 1B
    .byte 'E', ('T' | 0x80), 0x88 # LET token 88
    .byte 'I', 'N', ('E' | 0x80), 0xB0 # LINE token B0
    .byte 'O', 'A', ('D' | 0x80), 0xBC # LOAD token BC
    .byte 'I', 'S', ('T' | 0x80), 0x93 # LIST token 93
    .byte 'O', ('G' | 0x80), 0x0A # LOG token 0A
    .byte 'O', ('C' | 0x80), 0x24 # LOC token 24
    .byte 'E', ('N' | 0x80), 0x12 # LEN token 12
    .byte 'E', 'F', 'T', ('$' | 0x80), 0x01 # LEFT$ token 01
    .byte 'O', ('F' | 0x80), 0x25 # LOF token 25
    .byte 0x00 # end reserved-word group
MTAB:
    .byte 'O', 'T', 'O', ('R' | 0x80), 0xC1 # MOTOR token C1
    .byte 'E', 'R', 'G', ('E' | 0x80), 0xBD # MERGE token BD
    .byte 'O', ('D' | 0x80), 0xF3 # MOD token F3
    .byte 'I', 'D', ('$' | 0x80), 0x03 # MID$ token 03
    .byte 0x00 # end reserved-word group
NTAB:
    .byte 'E', 'X', ('T' | 0x80), 0x83 # NEXT token 83
    .byte 'E', ('W' | 0x80), 0x94 # NEW token 94
    .byte 'O', ('T' | 0x80), 0xD3 # NOT token D3
    .byte 0x00 # end reserved-word group
OTAB:
    .byte 'P', 'E', ('N' | 0x80), 0xBA # OPEN token BA
    .byte 'U', ('T' | 0x80), 0x9C # OUT token 9C
    .byte ('N' | 0x80), 0x95 # ON token 95
    .byte ('R' | 0x80), 0xEF # OR token EF
    .byte 'C', 'T', ('$' | 0x80), 0x19 # OCT$ token 19
    .byte 'P', 'T', 'I', 'O', ('N' | 0x80), 0xB8 # OPTION token B8
    .byte 'F', ('F' | 0x80), 0xDD # OFF token DD
    .byte 0x00 # end reserved-word group
PTAB:
    .byte 'R', 'I', 'N', ('T' | 0x80), 0x91 # PRINT token 91
    .byte 'O', 'K', ('E' | 0x80), 0x98 # POKE token 98
    .byte 'O', ('S' | 0x80), 0x11 # POS token 11
    .byte 'E', 'E', ('K' | 0x80), 0x17 # PEEK token 17
    .byte 'S', 'E', ('T' | 0x80), 0xC6 # PSET token C6
    .byte 'R', 'E', 'S', 'E', ('T' | 0x80), 0xC7 # PRESET token C7
    .byte 'O', 'I', 'N', ('T' | 0x80), 0xDC # POINT token DC
    .byte 'E', ('N' | 0x80), 0x20 # PEN token 20
    .byte 0x00 # end reserved-word group
QTAB:
    .byte 0x00 # end reserved-word group
RTAB:
    .byte 'U', ('N' | 0x80), 0x8A # RUN token 8A
    .byte 'E', 'T', 'U', 'R', ('N' | 0x80), 0x8E # RETURN token 8E
    .byte 'E', 'A', ('D' | 0x80), 0x87 # READ token 87
    .byte 'E', 'S', 'T', 'O', 'R', ('E' | 0x80), 0x8C # RESTORE token 8C
    .byte 'E', ('M' | 0x80), 0x8F # REM token 8F
    .byte 'E', 'S', 'U', 'M', ('E' | 0x80), 0xA8 # RESUME token A8
    .byte 'I', 'G', 'H', 'T', ('$' | 0x80), 0x02 # RIGHT$ token 02
    .byte 'N', ('D' | 0x80), 0x08 # RND token 08
    .byte 'E', 'N', 'U', ('M' | 0x80), 0xAB # RENUM token AB
    .byte 'A', 'N', 'D', 'O', 'M', 'I', 'Z', ('E' | 0x80), 0xB9 # RANDOMIZE token B9
    .byte 0x00 # end reserved-word group
STAB:
    .byte 'C', 'R', 'E', 'E', ('N' | 0x80), 0xC8 # SCREEN token C8
    .byte 'T', 'O', ('P' | 0x80), 0x90 # STOP token 90
    .byte 'W', 'A', ('P' | 0x80), 0xA4 # SWAP token A4
    .byte 'A', 'V', ('E' | 0x80), 0xBE # SAVE token BE
    .byte 'P', 'C', ('(' | 0x80), 0xD2 # SPC( token D2
    .byte 'T', 'E', ('P' | 0x80), 0xCF # STEP token CF
    .byte 'G', ('N' | 0x80), 0x04 # SGN token 04
    .byte 'Q', ('R' | 0x80), 0x07 # SQR token 07
    .byte 'I', ('N' | 0x80), 0x09 # SIN token 09
    .byte 'T', 'R', ('$' | 0x80), 0x13 # STR$ token 13
    .byte 'T', 'R', 'I', 'N', 'G', ('$' | 0x80), 0xD6 # STRING$ token D6
    .byte 'P', 'A', 'C', 'E', ('$' | 0x80), 0x18 # SPACE$ token 18
    .byte 'O', 'U', 'N', ('D' | 0x80), 0xC4 # SOUND token C4
    .byte 'T', 'I', 'C', ('K' | 0x80), 0x21 # STICK token 21
    .byte 'T', 'R', 'I', ('G' | 0x80), 0x22 # STRIG token 22
    .byte 0x00 # end reserved-word group
TTAB:
    .byte 'H', 'E', ('N' | 0x80), 0xCD # THEN token CD
    .byte 'R', 'O', ('N' | 0x80), 0xA2 # TRON token A2
    .byte 'R', 'O', 'F', ('F' | 0x80), 0xA3 # TROFF token A3
    .byte 'A', 'B', ('(' | 0x80), 0xCE # TAB( token CE
    .byte ('O' | 0x80), 0xCC # TO token CC
    .byte 'A', ('N' | 0x80), 0x0D # TAN token 0D
    .byte 0x00 # end reserved-word group
UTAB:
    .byte 'S', 'I', 'N', ('G' | 0x80), 0xD7 # USING token D7
    .byte 'S', ('R' | 0x80), 0xD0 # USR token D0
    .byte 0x00 # end reserved-word group
VTAB:
    .byte 'A', ('L' | 0x80), 0x14 # VAL token 14
    .byte 'A', 'R', 'P', 'T', ('R' | 0x80), 0xDA # VARPTR token DA
    .byte 0x00 # end reserved-word group
WTAB:
    .byte 'I', 'D', 'T', ('H' | 0x80), 0xA0 # WIDTH token A0
    .byte 'A', 'I', ('T' | 0x80), 0x96 # WAIT token 96
    .byte 'H', 'I', 'L', ('E' | 0x80), 0xB1 # WHILE token B1
    .byte 'E', 'N', ('D' | 0x80), 0xB2 # WEND token B2
    .byte 'R', 'I', 'T', ('E' | 0x80), 0xB7 # WRITE token B7
    .byte 0x00 # end reserved-word group
XTAB:
    .byte 'O', ('R' | 0x80), 0xF0 # XOR token F0
    .byte 0x00 # end reserved-word group
YTAB:
    .byte 0x00 # end reserved-word group
ZTAB:
    .byte 0x00 # end reserved-word group
OPERATOR_TOKEN_BYTES:
    .byte 0xAB, 0xE9, 0xAD, 0xEA, 0xAA, 0xEB, 0xAF, 0xEC, 0xDE, 0xED, 0xDC, 0xF4 # 036B
    .byte 0xA7, 0xD9, 0xBE, 0xE6, 0xBD, 0xE7, 0xBC, 0xE8, 0x00 # 0377
CHAR_CLASS_TABLE:
    .byte 0x79, 0x79, 0x7C, 0x7C, 0x7F, 0x50, 0x46, 0x3C, 0x32, 0x28, 0x7A, 0x7B # 0380
    .byte 0x82, 0x6B, 0x00, 0x00, 0xAD, 0x6B, 0x3B, 0x64, 0x51, 0x6B, 0xA8, 0x66 # 038C
    .byte 0x03, 0x63, 0x53, 0x6C, 0x20, 0x63, 0x74, 0x65, 0x12, 0x63, 0x19, 0x63 # 0398
    .byte 0x41, 0x63, 0x28, 0x63, 0x31, 0x64, 0x6A, 0x63, 0x4F, 0x63, 0x89, 0x63 # 03A4
    .byte 0xD7, 0x18, 0xB4, 0x65, 0x00 # 03B0
ERRTAB_TEXT:
MSG_ERR_NEXT_WITHOUT_FOR:
    .asciz "NEXT without FOR"
MSG_ERR_SYNTAX_ERROR:
    .asciz "Syntax error"
MSG_ERR_RETURN_WITHOUT_GOSUB:
    .asciz "RETURN without GOSUB"
MSG_ERR_OUT_OF_DATA:
    .asciz "Out of DATA"
MSG_ERR_ILLEGAL_FUNCTION_CALL:
    .asciz "Illegal function call"
MSG_ERR_OVERFLOW:
    .asciz "Overflow"
MSG_ERR_OUT_OF_MEMORY:
    .asciz "Out of memory"
MSG_ERR_UNDEFINED_LINE_NUMBER:
    .asciz "Undefined line number"
MSG_ERR_SUBSCRIPT_OUT_OF_RANGE:
    .asciz "Subscript out of range"
MSG_ERR_DUPLICATE_DEFINITION:
    .asciz "Duplicate Definition"
MSG_ERR_DIVISION_BY_ZERO:
    .asciz "Division by zero"
MSG_ERR_ILLEGAL_DIRECT:
    .asciz "Illegal direct"
MSG_ERR_TYPE_MISMATCH:
    .asciz "Type mismatch"
MSG_ERR_OUT_OF_STRING_SPACE:
    .asciz "Out of string space"
MSG_ERR_STRING_TOO_LONG:
    .asciz "String too long"
MSG_ERR_STRING_FORMULA_TOO_COMPLEX:
    .asciz "String formula too complex"
MSG_ERR_CAN_T_CONTINUE:
    .asciz "Can't continue"
MSG_ERR_UNDEFINED_USER_FUNCTION:
    .asciz "Undefined user function"
MSG_ERR_NO_RESUME:
    .asciz "No RESUME"
MSG_ERR_RESUME_WITHOUT_ERROR:
    .asciz "RESUME without error"
MSG_ERR_UNPRINTABLE_ERROR:
    .asciz "Unprintable error"
MSG_ERR_MISSING_OPERAND:
    .asciz "Missing operand"
MSG_ERR_LINE_BUFFER_OVERFLOW:
    .asciz "Line buffer overflow"
MSG_ERR_DEVICE_TIMEOUT:
    .asciz "Device Timeout"
MSG_ERR_DEVICE_FAULT:
    .asciz "Device Fault"
MSG_ERR_FOR_WITHOUT_NEXT:
    .asciz "FOR Without NEXT"
MSG_ERR_OUT_OF_PAPER:
    .asciz "Out of Paper"
MSG_ERR_:
    .asciz "?"
MSG_ERR_WHILE_WITHOUT_WEND:
    .asciz "WHILE without WEND"
MSG_ERR_WEND_WITHOUT_WHILE:
    .asciz "WEND without WHILE"
MSG_ERR_FIELD_OVERFLOW:
    .asciz "FIELD overflow"
MSG_ERR_INTERNAL_ERROR:
    .asciz "Internal error"
MSG_ERR_BAD_FILE_NUMBER:
    .asciz "Bad file number"
MSG_ERR_FILE_NOT_FOUND:
    .asciz "File not found"
MSG_ERR_BAD_FILE_MODE:
    .asciz "Bad file mode"
MSG_ERR_FILE_ALREADY_OPEN:
    .asciz "File already open"
MSG_ERR__2:
    .asciz "?"
MSG_ERR_DEVICE_I_O_ERROR:
    .asciz "Device I/O Error"
MSG_ERR_FILE_ALREADY_EXISTS:
    .asciz "File already exists"
MSG_ERR__3:
    .asciz "?"
MSG_ERR__4:
    .asciz "?"
MSG_ERR_DISK_FULL:
    .asciz "Disk full"
MSG_ERR_INPUT_PAST_END:
    .asciz "Input past end"
MSG_ERR_BAD_RECORD_NUMBER:
    .asciz "Bad record number"
MSG_ERR_BAD_FILE_NAME:
    .asciz "Bad file name"
MSG_ERR__5:
    .asciz "?"
MSG_ERR_DIRECT_STATEMENT_IN_FILE:
    .asciz "Direct statement in file"
MSG_ERR_TOO_MANY_FILES:
    .asciz "Too many files"
RAM_INIT_IMAGE:
    .byte 0x00, 0x00, 0x00, 0xC3, 0x1E, 0x10, 0x00, 0x52, 0xC7, 0x4F, 0x80, 0x52 # 069A
    .byte 0xC7, 0x4F, 0x80, 0xE4, 0x00, 0xCB, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF # 06A6
    .byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF # 06B2
    .byte 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x50, 0x38, 0x00, 0x72, 0x07, 0xFE, 0xFF # 06BE
    .byte 0x0F, 0x07, 0x0A, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 # 06CA
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 # 06D6
    .byte 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x07, 0x07, 0x20, 0x00, 0x00, 0x00 # 06E2
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x18, 0x18, 0x00, 0x00 # 06EE
    .byte 0x00, 0x00, 0x50, 0x00, 0x01, 0x00, 0x00, 0x00, 0x07, 0x07, 0x00, 0x00 # 06FA
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01 # 0706
    .byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 # 0712
    .byte 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01 # 071E
MSG_IN:
    .asciz " in "
REDDY_MSG:
    .ascii "Ok"
    .byte 0xFF, 0x0D, 0x00
BREAK_MSG:
    .asciz "Break"
CODE_BODY_START:
    mov    bx,0x4                                # 0738: BB 04 00
    .byte 0x03, 0xDC # 073B
L_073D:
    inc    bx                                    # 073D: 43
    mov    al,BYTE PTR [bx]                      # 073E: 8A 07
    inc    bx                                    # 0740: 43
    cmp    al,0xb1                               # 0741: 3C B1
    jne    L_074C                                # 0743: 75 07
    mov    cx,0x6                                # 0745: B9 06 00
    .byte 0x03, 0xD9 # 0748
    jmp    L_073D                                # 074A: EB F1
L_074C:
    cmp    al,0x82                               # 074C: 3C 82
    je     L_0751                                # 074E: 74 01
L_0750:
    ret                                          # 0750: C3
L_0751:
    mov    cl,BYTE PTR [bx]                      # 0751: 8A 0F
    inc    bx                                    # 0753: 43
    mov    ch,BYTE PTR [bx]                      # 0754: 8A 2F
    inc    bx                                    # 0756: 43
    push   bx                                    # 0757: 53
    .byte 0x8B, 0xD9, 0x0B, 0xD2 # 0758
    xchg   dx,bx                                 # 075C: 87 DA
    je     L_0764                                # 075E: 74 04
    xchg   dx,bx                                 # 0760: 87 DA
    .byte 0x3B, 0xDA # 0762
L_0764:
    mov    cx,0x10                               # 0764: B9 10 00
    pop    bx                                    # 0767: 5B
    je     L_0750                                # 0768: 74 E6
    .byte 0x03, 0xD9 # 076A
    jmp    L_073D                                # 076C: EB CF
L_076E:
    mov    cx,0x8b5                              # 076E: B9 B5 08
    jmp    L_0805                                # 0771: E9 91 00
L_0774:
    int    0x86                                  # 0774: CD 86
    mov    bx,WORD PTR ds:CURLIN                   # 0776: 8B 1E 2E 00
    .byte 0x8A, 0xC7, 0x22, 0xC3 # 077A
    inc    al                                    # 077E: FE C0
    je     L_078B                                # 0780: 74 09
    mov    al,ds:ONEFLG                           # 0782: A0 4F 03
    .byte 0x0A, 0xC0 # 0785
    mov    dl,0x13                               # 0787: B2 13
    jne    L_07D8                                # 0789: 75 4D
L_078B:
    jmp    L_2E4B                                # 078B: E9 BD 26
    .byte 0xB2, 0x3D, 0xB9 # 078E
L_0791:
    mov    dl,0x39                               # 0791: B2 39
    .byte 0xB9 # 0793
L_0794:
    .byte 0xB2, 0x36 # 0794
    mov    cx,0x35b2                             # 0796: B9 B2 35
    .byte 0xB9 # 0799
L_079A:
    .byte 0xB2, 0x34, 0xB9 # 079A
L_079D:
    .byte 0xB2, 0x33, 0xB9 # 079D
L_07A0:
    .byte 0xB2, 0x3E, 0xB9 # 07A0
L_07A3:
    .byte 0xB2, 0x37 # 07A3
    mov    cx,0x40b2                             # 07A5: B9 B2 40
    mov    cx,0x3fb2                             # 07A8: B9 B2 3F
    mov    cx,0x32b2                             # 07AB: B9 B2 32
    mov    cx,0x43b2                             # 07AE: B9 B2 43
    mov    cx,0x3ab2                             # 07B1: B9 B2 3A
    jmp    L_07D8                                # 07B4: EB 22
    .byte 0x8B, 0x1E, 0x37, 0x03, 0x89, 0x1E, 0x2E, 0x00 # 07B6
SNERR:
    mov    dl,0x2                                # 07BE: B2 02
    mov    cx,0xbb2                              # 07C0: B9 B2 0B
    .byte 0xB9 # 07C3
L_07C4:
    .byte 0xB2, 0x01, 0xB9 # 07C4
L_07C7:
    .byte 0xB2, 0x0A, 0xB9 # 07C7
L_07CA:
    .byte 0xB2, 0x12, 0xB9 # 07CA
L_07CD:
    .byte 0xB2, 0x14, 0xB9 # 07CD
L_07D0:
    .byte 0xB2, 0x06, 0xB9 # 07D0
L_07D3:
    .byte 0xB2, 0x16, 0xB9 # 07D3
L_07D6:
    .byte 0xB2, 0x0D # 07D6
L_07D8:
    .byte 0x32, 0xC0 # 07D8
    mov    ds:NLONLY,al                           # 07DA: A2 36 05
    mov    ds:BASIC_PROGRAM_FILE_FLAG,al                            # 07DD: A2 5F 00
    mov    ds:SAVE_PROTECT_FLAG,al                           # 07E0: A2 62 04
    mov    ds:BINARY_ADDR_PARAM_SWITCH,al                            # 07E3: A2 60 00
    mov    bx,WORD PTR ds:CURLIN                   # 07E6: 8B 1E 2E 00
    mov    WORD PTR ds:ERRLIN,bx                  # 07EA: 89 1E 47 03
    .byte 0x32, 0xC0 # 07EE
    mov    ds:MRGFLG,al                           # 07F0: A2 65 04
    mov    ds:CHNFLG,al                           # 07F3: A2 6B 04
    .byte 0x8A, 0xC7, 0x22, 0xC3 # 07F6
    inc    al                                    # 07FA: FE C0
    je     L_0802                                # 07FC: 74 04
    mov    WORD PTR ds:DOT,bx                  # 07FE: 89 1E 49 03
L_0802:
    mov    cx,0x80c                              # 0802: B9 0C 08
L_0805:
    mov    bx,WORD PTR ds:SAVSTK                  # 0805: 8B 1E 45 03
    jmp    L_2DBD                                # 0809: E9 B1 25
    .byte 0x59, 0x8A, 0xC2, 0x8A, 0xCA, 0xA2, 0x28, 0x00, 0x8B, 0x1E, 0x43, 0x03 # 080C
    .byte 0x89, 0x1E, 0x4B, 0x03, 0x87, 0xDA, 0x8B, 0x1E, 0x47, 0x03, 0x8A, 0xC7 # 0818
    .byte 0x22, 0xC3, 0xFE, 0xC0, 0x74, 0x0A, 0x89, 0x1E, 0x54, 0x03, 0x87, 0xDA # 0824
    .byte 0x89, 0x1E, 0x56, 0x03, 0x8B, 0x1E, 0x4D, 0x03, 0x0B, 0xDB, 0x87, 0xDA # 0830
    .byte 0xBB, 0x4F, 0x03, 0x74, 0x0B, 0x22, 0x07, 0x75, 0x07, 0xFE, 0x0F, 0x87 # 083C
    .byte 0xDA, 0xE9, 0x73, 0x06, 0x32, 0xC0, 0x88, 0x07, 0x8A, 0xD1, 0xE8, 0x08 # 0848
    .byte 0x24, 0xBB, 0xB4, 0x03, 0xCD, 0x87, 0x8A, 0xC2, 0x3C, 0x44, 0x73, 0x08 # 0854
    .byte 0x3C, 0x32, 0x73, 0x06, 0x3C, 0x1F, 0x72, 0x06 # 0860
L_0868:
    mov    al,0x28                               # 0868: B0 28
    sub    al,0x13                               # 086A: 2C 13
    .byte 0x8A, 0xD0 # 086C
L_086E:
    mov    al,BYTE PTR cs:[bx]                   # 086E: 2E 8A 07
    inc    bx                                    # 0871: 43
    .byte 0x0A, 0xC0 # 0872
    jne    L_086E                                # 0874: 75 F8
    dec    bx                                    # 0876: 4B
    inc    bx                                    # 0877: 43
    dec    dl                                    # 0878: FE CA
    jne    L_086E                                # 087A: 75 F2
    push   bx                                    # 087C: 53
    mov    bx,WORD PTR ds:ERRLIN                  # 087D: 8B 1E 47 03
    pop    si                                    # 0881: 5E
    xchg   si,bx                                 # 0882: 87 DE
    push   si                                    # 0884: 56
L_0885:
    int    0x88                                  # 0885: CD 88
    mov    al,BYTE PTR cs:[bx]                   # 0887: 2E 8A 07
    cmp    al,0x3f                               # 088A: 3C 3F
    jne    L_0894                                # 088C: 75 06
    pop    bx                                    # 088E: 5B
    mov    bx,0x3b4                              # 088F: BB B4 03
    jmp    L_0868                                # 0892: EB D4
L_0894:
    call   STROUT                                # 0894: E8 BE 72
    pop    bx                                    # 0897: 5B
    mov    dx,0xfffe                             # 0898: BA FE FF
    .byte 0x3B, 0xDA # 089B
    int    0x89                                  # 089D: CD 89
    jne    L_08A4                                # 089F: 75 03
    jmp    COLD_START                            # 08A1: E9 EE 75
L_08A4:
    .byte 0x8A, 0xC7, 0x22, 0xC3 # 08A4
    inc    al                                    # 08A8: FE C0
    je     L_08AF                                # 08AA: 74 03
    call   L_6548                                # 08AC: E8 99 5C
L_08AF:
    mov    al,0xff                               # 08AF: B0 FF
    call   OUTDO                                # 08B1: E8 F1 22
    .byte 0xB0 # 08B4
STPRDY:
    .byte 0x59 # 08B5
READY:
    int    0x8a                                  # 08B6: CD 8A
    .byte 0x32, 0xC0 # 08B8
    mov    ds:CNTOFL,al                            # 08BA: A2 6F 00
    call   PRGFIN                                # 08BD: E8 3B 3C
    call   CRDONZ                                # 08C0: E8 9A 23
    mov    bx,0x72d                              # 08C3: BB 2D 07
    call   STROUT                                # 08C6: E8 8C 72
    mov    al,ds:ERRFLG                            # 08C9: A0 28 00
    sub    al,0x2                                # 08CC: 2C 02
    jne    MAIN                                # 08CE: 75 03
    call   ERREDT                                # 08D0: E8 EE 2D
MAIN:
    int    0x8b                                  # 08D3: CD 8B
    mov    bx,0xffff                             # 08D5: BB FF FF
    mov    WORD PTR ds:CURLIN,bx                   # 08D8: 89 1E 2E 00
    mov    al,ds:AUTFLG                           # 08DC: A0 3E 03
    .byte 0x0A, 0xC0 # 08DF
    je     NTAUTO                                # 08E1: 74 49
    mov    bx,WORD PTR ds:AUTLIN                  # 08E3: 8B 1E 3F 03
    push   bx                                    # 08E7: 53
    call   LINPRT                                # 08E8: E8 65 5C
    pop    dx                                    # 08EB: 5A
    push   dx                                    # 08EC: 52
    call   FNDLIN                                # 08ED: E8 77 01
    mov    al,0x2a                               # 08F0: B0 2A
    jb     AUTELN                                # 08F2: 72 02
    mov    al,0x20                               # 08F4: B0 20
AUTELN:
    call   OUTDO                                # 08F6: E8 AC 22
    call   PINLIN                                # 08F9: E8 84 28
    pop    dx                                    # 08FC: 5A
    jae    L_090D                                # 08FD: 73 0E
    .byte 0x32, 0xC0 # 08FF
    mov    ds:AUTFLG,al                           # 0901: A2 3E 03
    jmp    READY                                # 0904: EB B0
AUTRES:
    .byte 0x32, 0xC0 # 0906
    mov    ds:AUTFLG,al                           # 0908: A2 3E 03
    jmp    L_0922                                # 090B: EB 15
L_090D:
    mov    bx,WORD PTR ds:AUTINC                  # 090D: 8B 1E 41 03
    .byte 0x03, 0xDA # 0911
    jb     AUTRES                                # 0913: 72 F1
    push   dx                                    # 0915: 52
    mov    dx,0xfff9                             # 0916: BA F9 FF
    .byte 0x3B, 0xDA # 0919
    pop    dx                                    # 091B: 5A
    jae    AUTRES                                # 091C: 73 E8
    mov    WORD PTR ds:AUTLIN,bx                  # 091E: 89 1E 3F 03
L_0922:
    mov    al,ds:BUF                           # 0922: A0 F7 01
    .byte 0x0A, 0xC0 # 0925
    je     MAIN                                # 0927: 74 AA
    jmp    L_36D4                                # 0929: E9 A8 2D
NTAUTO:
    call   PINLIN                                # 092C: E8 51 28
    jb     MAIN                                # 092F: 72 A2
    call   CHRGTR                                # 0931: E8 E9 05
    inc    al                                    # 0934: FE C0
    dec    al                                    # 0936: FE C8
    je     MAIN                                # 0938: 74 99
    pushf                                        # 093A: 9C
    call   LINGET                                # 093B: E8 2D 07
    jae    MAINBX                                # 093E: 73 08
    call   ISFLIO                                # 0940: E8 93 26
    jne    MAINBX                                # 0943: 75 03
    jmp    SNERR                                 # 0945: E9 76 FE
MAINBX:
    call   BAKSP                                # 0948: E8 38 04
    mov    al,BYTE PTR [bx]                      # 094B: 8A 07
    cmp    al,0x20                               # 094D: 3C 20
    jne    EDENT                                # 094F: 75 03
    call   L_6544                                # 0951: E8 F0 5B
EDENT:
    push   dx                                    # 0954: 52
    call   CRUNCH                                # 0955: E8 31 01
    pop    dx                                    # 0958: 5A
    popf                                         # 0959: 9D
    mov    WORD PTR ds:SAVTXT,bx                  # 095A: 89 1E 43 03
    int    0x8c                                  # 095E: CD 8C
    jb     L_0965                                # 0960: 72 03
    jmp    L_44D4                                # 0962: E9 6F 3B
L_0965:
    push   dx                                    # 0965: 52
    push   cx                                    # 0966: 51
    call   PROCHK                                # 0967: E8 EE 3D
    call   CHRGTR                                # 096A: E8 B0 05
    .byte 0x0A, 0xC0 # 096D
    pushf                                        # 096F: 9C
    mov    WORD PTR ds:DOT,dx                  # 0970: 89 16 49 03
    call   FNDLIN                                # 0974: E8 F0 00
    jb     L_0982                                # 0977: 72 09
    popf                                         # 0979: 9D
    pushf                                        # 097A: 9C
    jne    L_0980                                # 097B: 75 03
    jmp    L_1130                                # 097D: E9 B0 07
L_0980:
    .byte 0x0A, 0xC0 # 0980
L_0982:
    push   cx                                    # 0982: 51
    pushf                                        # 0983: 9C
    push   bx                                    # 0984: 53
    call   DEPTR                                # 0985: E8 AD 1A
    pop    bx                                    # 0988: 5B
    popf                                         # 0989: 9D
    pop    cx                                    # 098A: 59
    push   cx                                    # 098B: 51
    jae    L_0991                                # 098C: 73 03
    call   DEL                                # 098E: E8 D6 18
L_0991:
    pop    dx                                    # 0991: 5A
    popf                                         # 0992: 9D
    push   dx                                    # 0993: 52
    je     FINI                                # 0994: 74 47
    pop    dx                                    # 0996: 5A
    mov    al,ds:CHNFLG                           # 0997: A0 6B 04
    .byte 0x0A, 0xC0 # 099A
    jne    LEVFRE                                # 099C: 75 08
    mov    bx,WORD PTR ds:MEMSIZ                  # 099E: 8B 1E 0A 03
    mov    WORD PTR ds:FRETOP,bx                  # 09A2: 89 1E 2F 03
LEVFRE:
    mov    bx,WORD PTR ds:VARTAB                  # 09A6: 8B 1E 58 03
    pop    si                                    # 09AA: 5E
    xchg   si,bx                                 # 09AB: 87 DE
    push   si                                    # 09AD: 56
    pop    cx                                    # 09AE: 59
    push   bx                                    # 09AF: 53
    .byte 0x03, 0xD9 # 09B0
    push   bx                                    # 09B2: 53
    call   BLTU                                # 09B3: E8 15 5B
    pop    bx                                    # 09B6: 5B
    mov    WORD PTR ds:VARTAB,bx                  # 09B7: 89 1E 58 03
    xchg   dx,bx                                 # 09BB: 87 DA
    mov    BYTE PTR [bx],bh                      # 09BD: 88 3F
    pop    cx                                    # 09BF: 59
    pop    dx                                    # 09C0: 5A
    push   bx                                    # 09C1: 53
    inc    bx                                    # 09C2: 43
    inc    bx                                    # 09C3: 43
    mov    WORD PTR [bx],dx                      # 09C4: 89 17
    inc    bx                                    # 09C6: 43
    inc    bx                                    # 09C7: 43
    mov    dx,KBUF                               # 09C8: BA B8 00
    dec    cx                                    # 09CB: 49
    dec    cx                                    # 09CC: 49
    dec    cx                                    # 09CD: 49
    dec    cx                                    # 09CE: 49
MLOOPR:
    .byte 0x8B, 0xF2 # 09CF
    lods   al,BYTE PTR ds:[si]                   # 09D1: AC
    mov    BYTE PTR [bx],al                      # 09D2: 88 07
    inc    bx                                    # 09D4: 43
    inc    dx                                    # 09D5: 42
    dec    cx                                    # 09D6: 49
    .byte 0x8A, 0xC1, 0x0A, 0xC5 # 09D7
    jne    MLOOPR                                # 09DB: 75 F2
FINI:
    int    0x8d                                  # 09DD: CD 8D
    pop    dx                                    # 09DF: 5A
    call   CHEAD                                # 09E0: E8 1E 00
    mov    bx,WORD PTR ds:PTRFIL                  # 09E3: 8B 1E E9 04
    mov    WORD PTR ds:TEMP2,bx                  # 09E7: 89 1E 52 03
    call   RUNC                                # 09EB: E8 49 23
    int    0x8e                                  # 09EE: CD 8E
    mov    bx,WORD PTR ds:TEMP2                  # 09F0: 8B 1E 52 03
    mov    WORD PTR ds:PTRFIL,bx                  # 09F4: 89 1E E9 04
    jmp    MAIN                                # 09F8: E9 D8 FE
LINKER:
    mov    bx,WORD PTR ds:TXTTAB                   # 09FB: 8B 1E 30 00
    xchg   dx,bx                                 # 09FF: 87 DA
CHEAD:
    .byte 0x8A, 0xFE, 0x8A, 0xDA # 0A01
    mov    al,BYTE PTR [bx]                      # 0A05: 8A 07
    inc    bx                                    # 0A07: 43
    or     al,BYTE PTR [bx]                      # 0A08: 0A 07
    jne    L_0A0D                                # 0A0A: 75 01
L_0A0C:
    ret                                          # 0A0C: C3
L_0A0D:
    inc    bx                                    # 0A0D: 43
    inc    bx                                    # 0A0E: 43
CZLOOP:
    inc    bx                                    # 0A0F: 43
    mov    al,BYTE PTR [bx]                      # 0A10: 8A 07
CZLOO2:
    .byte 0x0A, 0xC0 # 0A12
    je     CZLIN                                # 0A14: 74 10
    cmp    al,0x20                               # 0A16: 3C 20
    jae    CZLOOP                                # 0A18: 73 F5
    cmp    al,0xb                                # 0A1A: 3C 0B
    jb     CZLOOP                                # 0A1C: 72 F1
    call   CHRGT2                                # 0A1E: E8 FD 04
    call   CHRGTR                                # 0A21: E8 F9 04
    jmp    CZLOO2                                # 0A24: EB EC
CZLIN:
    inc    bx                                    # 0A26: 43
    xchg   dx,bx                                 # 0A27: 87 DA
    mov    WORD PTR [bx],dx                      # 0A29: 89 17
    jmp    CHEAD                                # 0A2B: EB D4
SCNLIN:
    mov    dx,0x0                                # 0A2D: BA 00 00
    push   dx                                    # 0A30: 52
    je     L_0A4A                                # 0A31: 74 17
    cmp    al,0x2c                               # 0A33: 3C 2C
    je     L_0A4A                                # 0A35: 74 13
    pop    dx                                    # 0A37: 5A
    call   L_105E                                # 0A38: E8 23 06
    push   dx                                    # 0A3B: 52
    je     L_0A5B                                # 0A3C: 74 1D
    cmp    al,0x2c                               # 0A3E: 3C 2C
    je     L_0A5B                                # 0A40: 74 19
    call   SYNCHR                                # 0A42: E8 AF 23
    .byte TK_MINUS                             # 0A45: EA -- SYNCHR inline operand
    je     L_0A4A                                # 0A46: 74 02
    cmp    al,','                                # 0A48: 3C 2C
L_0A4A:
    mov    dx,0xfffa                             # 0A4A: BA FA FF
    je     L_0A52                                # 0A4D: 74 03
    call   L_105E                                # 0A4F: E8 0C 06
L_0A52:
    je     L_0A5B                                # 0A52: 74 07
    cmp    al,0x2c                               # 0A54: 3C 2C
    je     L_0A5B                                # 0A56: 74 03
    jmp    SNERR                                 # 0A58: E9 63 FD
L_0A5B:
    mov    WORD PTR ds:TEMP,bx                  # 0A5B: 89 1E 3B 03
    xchg   dx,bx                                 # 0A5F: 87 DA
    pop    dx                                    # 0A61: 5A
FNDLN1:
    pop    si                                    # 0A62: 5E
    xchg   si,bx                                 # 0A63: 87 DE
    push   si                                    # 0A65: 56
    push   bx                                    # 0A66: 53
FNDLIN:
    mov    bx,WORD PTR ds:TXTTAB                   # 0A67: 8B 1E 30 00
L_0A6B:
    .byte 0x8B, 0xCB # 0A6B
    mov    al,BYTE PTR [bx]                      # 0A6D: 8A 07
    inc    bx                                    # 0A6F: 43
    or     al,BYTE PTR [bx]                      # 0A70: 0A 07
    lahf                                         # 0A72: 9F
    dec    bx                                    # 0A73: 4B
    sahf                                         # 0A74: 9E
    je     L_0A0C                                # 0A75: 74 95
    inc    bx                                    # 0A77: 43
    inc    bx                                    # 0A78: 43
    mov    bx,WORD PTR [bx]                      # 0A79: 8B 1F
    .byte 0x3B, 0xDA, 0x8B, 0xD9 # 0A7B
    mov    bx,WORD PTR [bx]                      # 0A7F: 8B 1F
    cmc                                          # 0A81: F5
    je     L_0A0C                                # 0A82: 74 88
    cmc                                          # 0A84: F5
    jae    L_0A0C                                # 0A85: 73 85
    jmp    L_0A6B                                # 0A87: EB E2
CRUNCH:
    .byte 0x32, 0xC0 # 0A89
    mov    ds:DONUM,al                           # 0A8B: A2 FD 02
    mov    ds:DORES,al                           # 0A8E: A2 FC 02
    int    0x8f                                  # 0A91: CD 8F
    mov    cx,KBFLEN-3                          # 0A93: B9 3B 01
    mov    dx,KBUF                               # 0A96: BA B8 00
L_0A99:
    mov    al,BYTE PTR [bx]                      # 0A99: 8A 07
    .byte 0x0A, 0xC0 # 0A9B
    jne    L_0ABF                                # 0A9D: 75 20
L_0A9F:
    mov    bx,KBFLEN+2                          # 0A9F: BB 40 01
    .byte 0x8A, 0xC3, 0x2A, 0xC1, 0x8A, 0xC8, 0x8A, 0xC7, 0x1A, 0xC5, 0x8A, 0xE8 # 0AA2
    mov    bx,0xb7                               # 0AAE: BB B7 00
    .byte 0x32, 0xC0, 0x8B, 0xFA # 0AB1
    stos   BYTE PTR es:[di],al                   # 0AB5: AA
    inc    dx                                    # 0AB6: 42
    .byte 0x8B, 0xFA # 0AB7
    stos   BYTE PTR es:[di],al                   # 0AB9: AA
    inc    dx                                    # 0ABA: 42
    .byte 0x8B, 0xFA # 0ABB
    stos   BYTE PTR es:[di],al                   # 0ABD: AA
    ret                                          # 0ABE: C3
L_0ABF:
    cmp    al,0x22                               # 0ABF: 3C 22
    jne    L_0AC6                                # 0AC1: 75 03
    .byte 0xE9, 0x33, 0x00 # 0AC3
L_0AC6:
    cmp    al,0x20                               # 0AC6: 3C 20
    je     L_0AD3                                # 0AC8: 74 09
    mov    al,ds:DORES                           # 0ACA: A0 FC 02
    .byte 0x0A, 0xC0 # 0ACD
    mov    al,BYTE PTR [bx]                      # 0ACF: 8A 07
    je     L_0B02                                # 0AD1: 74 2F
L_0AD3:
    inc    bx                                    # 0AD3: 43
    push   ax                                    # 0AD4: 50
    call   KRNSAV                                # 0AD5: E8 54 02
    pop    ax                                    # 0AD8: 58
    sub    al,0x3a                               # 0AD9: 2C 3A
    je     L_0AE3                                # 0ADB: 74 06
    cmp    al,0x4a                               # 0ADD: 3C 4A
    jne    L_0AE9                                # 0ADF: 75 08
    mov    al,0x1                                # 0AE1: B0 01
L_0AE3:
    mov    ds:DORES,al                           # 0AE3: A2 FC 02
    mov    ds:DONUM,al                           # 0AE6: A2 FD 02
L_0AE9:
    sub    al,0x55                               # 0AE9: 2C 55
    jne    L_0A99                                # 0AEB: 75 AC
    push   ax                                    # 0AED: 50
L_0AEE:
    mov    al,BYTE PTR [bx]                      # 0AEE: 8A 07
    .byte 0x0A, 0xC0 # 0AF0
    pop    ax                                    # 0AF2: 58
    je     L_0A9F                                # 0AF3: 74 AA
    cmp    al,BYTE PTR [bx]                      # 0AF5: 3A 07
    je     L_0AD3                                # 0AF7: 74 DA
L_0AF9:
    push   ax                                    # 0AF9: 50
    mov    al,BYTE PTR [bx]                      # 0AFA: 8A 07
L_0AFC:
    inc    bx                                    # 0AFC: 43
    call   KRNSAV                                # 0AFD: E8 2C 02
    jmp    L_0AEE                                # 0B00: EB EC
L_0B02:
    inc    bx                                    # 0B02: 43
    .byte 0x0A, 0xC0 # 0B03
    js     L_0A99                                # 0B05: 78 92
    dec    bx                                    # 0B07: 4B
    cmp    al,0x3f                               # 0B08: 3C 3F
    mov    al,0x91                               # 0B0A: B0 91
    push   dx                                    # 0B0C: 52
    push   cx                                    # 0B0D: 51
    jne    L_0B13                                # 0B0E: 75 03
    jmp    L_0BF5                                # 0B10: E9 E2 00
L_0B13:
    mov    dx,0x36b                              # 0B13: BA 6B 03
    call   MAKUPL                                # 0B16: E8 D2 0E
    call   ISLET2                                # 0B19: E8 29 24
    jae    L_0B21                                # 0B1C: 73 03
    jmp    L_0C4F                                # 0B1E: E9 2E 01
L_0B21:
    push   bx                                    # 0B21: 53
    mov    dx,0xb5e                              # 0B22: BA 5E 0B
    call   L_0B48                                # 0B25: E8 20 00
    jne    L_0B68                                # 0B28: 75 3E
    call   CHRGTR                                # 0B2A: E8 F0 03
    mov    dx,0xb62                              # 0B2D: BA 62 0B
    call   L_0B48                                # 0B30: E8 15 00
    mov    al,0x89                               # 0B33: B0 89
    jne    L_0B3A                                # 0B35: 75 03
    jmp    L_0B44                                # 0B37: EB 0B
    .byte 0x90 # 0B39
L_0B3A:
    mov    dx,0xb65                              # 0B3A: BA 65 0B
    call   L_0B48                                # 0B3D: E8 08 00
    jne    L_0B68                                # 0B40: 75 26
    mov    al,0x8d                               # 0B42: B0 8D
L_0B44:
    pop    cx                                    # 0B44: 59
    jmp    L_0BF5                                # 0B45: E9 AD 00
L_0B48:
    .byte 0x8B, 0xF2 # 0B48
    lods   al,BYTE PTR cs:[si]                   # 0B4A: 2E AC
    .byte 0x0A, 0xC0 # 0B4C
    jne    L_0B51                                # 0B4E: 75 01
L_0B50:
    ret                                          # 0B50: C3
L_0B51:
    .byte 0x8A, 0xC8 # 0B51
    call   MAKUPL                                # 0B53: E8 95 0E
    .byte 0x3A, 0xC1 # 0B56
    jne    L_0B50                                # 0B58: 75 F6
    inc    bx                                    # 0B5A: 43
    inc    dx                                    # 0B5B: 42
    jmp    L_0B48                                # 0B5C: EB EA
    .byte 0x47, 0x4F, 0x20, 0x00, 0x54, 0x4F, 0x00, 0x55, 0x42, 0x00 # 0B5E
L_0B68:
    pop    bx                                    # 0B68: 5B
    call   MAKUPL                                # 0B69: E8 7F 0E
    push   bx                                    # 0B6C: 53
    int    0x90                                  # 0B6D: CD 90
    mov    bx,0x103                              # 0B6F: BB 03 01
    sub    al,0x41                               # 0B72: 2C 41
    .byte 0x02, 0xC0, 0x8A, 0xC8 # 0B74
    mov    ch,0x0                                # 0B78: B5 00
    .byte 0x03, 0xD9 # 0B7A
    mov    dx,WORD PTR cs:[bx]                   # 0B7C: 2E 8B 17
    pop    bx                                    # 0B7F: 5B
    inc    bx                                    # 0B80: 43
L_0B81:
    push   bx                                    # 0B81: 53
L_0B82:
    call   MAKUPL                                # 0B82: E8 66 0E
    .byte 0x8A, 0xC8, 0x8B, 0xF2 # 0B85
    lods   al,BYTE PTR cs:[si]                   # 0B89: 2E AC
    and    al,0x7f                               # 0B8B: 24 7F
    jne    L_0B92                                # 0B8D: 75 03
    jmp    L_0D3D                                # 0B8F: E9 AB 01
L_0B92:
    inc    bx                                    # 0B92: 43
    .byte 0x3A, 0xC1 # 0B93
    jne    L_0BE7                                # 0B95: 75 50
    .byte 0x8B, 0xF2 # 0B97
    lods   al,BYTE PTR cs:[si]                   # 0B99: 2E AC
    inc    dx                                    # 0B9B: 42
    .byte 0x0A, 0xC0 # 0B9C
    jns    L_0B82                                # 0B9E: 79 E2
    .byte 0x8A, 0xC1 # 0BA0
    cmp    al,0x28                               # 0BA2: 3C 28
    je     L_0BC3                                # 0BA4: 74 1D
    .byte 0x8B, 0xF2 # 0BA6
    lods   al,BYTE PTR cs:[si]                   # 0BA8: 2E AC
    cmp    al,0xd1                               # 0BAA: 3C D1
    je     L_0BC3                                # 0BAC: 74 15
    cmp    al,0xd0                               # 0BAE: 3C D0
    je     L_0BC3                                # 0BB0: 74 11
    call   MAKUPL                                # 0BB2: E8 36 0E
    cmp    al,0x2e                               # 0BB5: 3C 2E
    je     L_0BBC                                # 0BB7: 74 03
    call   L_2183                                # 0BB9: E8 C7 15
L_0BBC:
    mov    al,0x0                                # 0BBC: B0 00
    jb     L_0BC3                                # 0BBE: 72 03
    jmp    L_0D3D                                # 0BC0: E9 7A 01
L_0BC3:
    pop    ax                                    # 0BC3: 58
    .byte 0x8B, 0xF2 # 0BC4
    lods   al,BYTE PTR cs:[si]                   # 0BC6: 2E AC
    int    0x91                                  # 0BC8: CD 91
    .byte 0x0A, 0xC0 # 0BCA
    jns    L_0BD1                                # 0BCC: 79 03
    .byte 0xE9, 0x23, 0x00 # 0BCE
L_0BD1:
    pop    cx                                    # 0BD1: 59
    pop    dx                                    # 0BD2: 5A
    or     al,0x80                               # 0BD3: 0C 80
    push   ax                                    # 0BD5: 50
    mov    al,0xff                               # 0BD6: B0 FF
    call   KRNSAV                                # 0BD8: E8 51 01
    .byte 0x32, 0xC0 # 0BDB
    mov    ds:DONUM,al                           # 0BDD: A2 FD 02
    pop    ax                                    # 0BE0: 58
    call   KRNSAV                                # 0BE1: E8 48 01
    jmp    L_0A99                                # 0BE4: E9 B2 FE
L_0BE7:
    pop    bx                                    # 0BE7: 5B
L_0BE8:
    .byte 0x8B, 0xF2 # 0BE8
    lods   al,BYTE PTR cs:[si]                   # 0BEA: 2E AC
    inc    dx                                    # 0BEC: 42
    .byte 0x0A, 0xC0 # 0BED
    jns    L_0BE8                                # 0BEF: 79 F7
    inc    dx                                    # 0BF1: 42
    jmp    L_0B81                                # 0BF2: EB 8D
L_0BF4:
    dec    bx                                    # 0BF4: 4B
L_0BF5:
    push   ax                                    # 0BF5: 50
    int    0x92                                  # 0BF6: CD 92
    mov    dx,0xc0c                              # 0BF8: BA 0C 0C
    .byte 0x8A, 0xC8 # 0BFB
L_0BFD:
    .byte 0x8B, 0xF2 # 0BFD
    lods   al,BYTE PTR cs:[si]                   # 0BFF: 2E AC
    .byte 0x0A, 0xC0 # 0C01
    je     L_0C1C                                # 0C03: 74 17
    inc    dx                                    # 0C05: 42
    .byte 0x3A, 0xC1 # 0C06
    jne    L_0BFD                                # 0C08: 75 F3
    jmp    L_0C20                                # 0C0A: EB 14
    .byte 0x8C, 0xAA, 0xAB, 0xA9, 0xA6, 0xA8, 0xD4, 0xA1, 0x8A, 0x93, 0x9E, 0x89 # 0C0C
    .byte 0x8E, 0xCD, 0x8D, 0x00 # 0C18
L_0C1C:
    .byte 0x32, 0xC0 # 0C1C
    jmp    L_0C22                                # 0C1E: EB 02
L_0C20:
    mov    al,0x1                                # 0C20: B0 01
L_0C22:
    mov    ds:DONUM,al                           # 0C22: A2 FD 02
    pop    ax                                    # 0C25: 58
    pop    cx                                    # 0C26: 59
    pop    dx                                    # 0C27: 5A
    cmp    al,0xa1                               # 0C28: 3C A1
    push   ax                                    # 0C2A: 50
    jne    L_0C30                                # 0C2B: 75 03
    call   KRNSVC                                # 0C2D: E8 FA 00
L_0C30:
    pop    ax                                    # 0C30: 58
    cmp    al,0xb1                               # 0C31: 3C B1
    jne    L_0C3A                                # 0C33: 75 05
    call   KRNSAV                                # 0C35: E8 F4 00
    mov    al,0xe9                               # 0C38: B0 E9
L_0C3A:
    cmp    al,0xd9                               # 0C3A: 3C D9
    je     L_0C41                                # 0C3C: 74 03
    jmp    L_0D07                                # 0C3E: E9 C6 00
L_0C41:
    push   ax                                    # 0C41: 50
    call   KRNSVC                                # 0C42: E8 E5 00
    mov    al,0x8f                               # 0C45: B0 8F
    call   KRNSAV                                # 0C47: E8 E2 00
    pop    ax                                    # 0C4A: 58
    push   ax                                    # 0C4B: 50
    jmp    L_0AFC                                # 0C4C: E9 AD FE
L_0C4F:
    mov    al,BYTE PTR [bx]                      # 0C4F: 8A 07
    cmp    al,0x2e                               # 0C51: 3C 2E
    je     L_0C63                                # 0C53: 74 0E
    cmp    al,0x3a                               # 0C55: 3C 3A
    jb     L_0C5C                                # 0C57: 72 03
    jmp    L_0CEC                                # 0C59: E9 90 00
L_0C5C:
    cmp    al,0x30                               # 0C5C: 3C 30
    jae    L_0C63                                # 0C5E: 73 03
    jmp    L_0CEC                                # 0C60: E9 89 00
L_0C63:
    mov    al,ds:DONUM                           # 0C63: A0 FD 02
    .byte 0x0A, 0xC0 # 0C66
    mov    al,BYTE PTR [bx]                      # 0C68: 8A 07
    pop    cx                                    # 0C6A: 59
    pop    dx                                    # 0C6B: 5A
    jns    L_0C71                                # 0C6C: 79 03
    jmp    L_0AD3                                # 0C6E: E9 62 FE
L_0C71:
    je     L_0C9A                                # 0C71: 74 27
    cmp    al,0x2e                               # 0C73: 3C 2E
    jne    L_0C7A                                # 0C75: 75 03
    jmp    L_0AD3                                # 0C77: E9 59 FE
L_0C7A:
    mov    al,0xe                                # 0C7A: B0 0E
    call   KRNSAV                                # 0C7C: E8 AD 00
    push   dx                                    # 0C7F: 52
    call   LINGET                                # 0C80: E8 E8 03
    call   BAKSP                                # 0C83: E8 FD 00
L_0C86:
    pop    si                                    # 0C86: 5E
    xchg   si,bx                                 # 0C87: 87 DE
    push   si                                    # 0C89: 56
    xchg   dx,bx                                 # 0C8A: 87 DA
L_0C8C:
    .byte 0x8A, 0xC3 # 0C8C
    call   KRNSAV                                # 0C8E: E8 9B 00
    .byte 0x8A, 0xC7 # 0C91
L_0C93:
    pop    bx                                    # 0C93: 5B
    call   KRNSAV                                # 0C94: E8 95 00
    jmp    L_0A99                                # 0C97: E9 FF FD
L_0C9A:
    push   dx                                    # 0C9A: 52
    push   cx                                    # 0C9B: 51
    mov    al,BYTE PTR [bx]                      # 0C9C: 8A 07
    call   L_69C0                                # 0C9E: E8 1F 5D
    call   BAKSP                                # 0CA1: E8 DF 00
    pop    cx                                    # 0CA4: 59
    pop    dx                                    # 0CA5: 5A
    push   bx                                    # 0CA6: 53
    mov    al,ds:VALTYP                           # 0CA7: A0 FB 02
    cmp    al,0x2                                # 0CAA: 3C 02
    jne    L_0CC8                                # 0CAC: 75 1A
    mov    bx,WORD PTR ds:FACLO                  # 0CAE: 8B 1E A3 04
    .byte 0x8A, 0xC7, 0x0A, 0xC0 # 0CB2
    mov    al,0x2                                # 0CB6: B0 02
    jne    L_0CC8                                # 0CB8: 75 0E
    .byte 0x8A, 0xC3, 0x8A, 0xFB # 0CBA
    mov    bl,0xf                                # 0CBE: B3 0F
    cmp    al,0xa                                # 0CC0: 3C 0A
    jae    L_0C8C                                # 0CC2: 73 C8
    add    al,0x11                               # 0CC4: 04 11
    jmp    L_0C93                                # 0CC6: EB CB
L_0CC8:
    push   ax                                    # 0CC8: 50
    ror    al,1                                  # 0CC9: D0 C8
    add    al,0x1b                               # 0CCB: 04 1B
    call   KRNSAV                                # 0CCD: E8 5C 00
    mov    bx,0x4a3                              # 0CD0: BB A3 04
    call   GETYPR                                # 0CD3: E8 4F 0E
    jb     L_0CDB                                # 0CD6: 72 03
    mov    bx,DFACL                              # 0CD8: BB 9F 04
L_0CDB:
    pop    ax                                    # 0CDB: 58
L_0CDC:
    push   ax                                    # 0CDC: 50
    mov    al,BYTE PTR [bx]                      # 0CDD: 8A 07
    call   KRNSAV                                # 0CDF: E8 4A 00
    pop    ax                                    # 0CE2: 58
    inc    bx                                    # 0CE3: 43
    dec    al                                    # 0CE4: FE C8
    jne    L_0CDC                                # 0CE6: 75 F4
    pop    bx                                    # 0CE8: 5B
    jmp    L_0A99                                # 0CE9: E9 AD FD
L_0CEC:
    mov    dx,0x36a                              # 0CEC: BA 6A 03
L_0CEF:
    inc    dx                                    # 0CEF: 42
    .byte 0x8B, 0xF2 # 0CF0
    lods   al,BYTE PTR cs:[si]                   # 0CF2: 2E AC
    and    al,0x7f                               # 0CF4: 24 7F
    jne    L_0CFB                                # 0CF6: 75 03
    .byte 0xE9, 0x6B, 0x00 # 0CF8
L_0CFB:
    inc    dx                                    # 0CFB: 42
    cmp    al,BYTE PTR [bx]                      # 0CFC: 3A 07
    .byte 0x8B, 0xF2 # 0CFE
    lods   al,BYTE PTR cs:[si]                   # 0D00: 2E AC
    jne    L_0CEF                                # 0D02: 75 EB
    .byte 0xE9, 0x6F, 0x00 # 0D04
L_0D07:
    cmp    al,0x26                               # 0D07: 3C 26
    je     L_0D0E                                # 0D09: 74 03
    jmp    L_0AD3                                # 0D0B: E9 C5 FD
L_0D0E:
    push   bx                                    # 0D0E: 53
    call   CHRGTR                                # 0D0F: E8 0B 02
    pop    bx                                    # 0D12: 5B
    call   MAKUPS                                # 0D13: E8 D7 0C
    cmp    al,0x48                               # 0D16: 3C 48
    mov    al,0xb                                # 0D18: B0 0B
    jne    L_0D1E                                # 0D1A: 75 02
    mov    al,0xc                                # 0D1C: B0 0C
L_0D1E:
    call   KRNSAV                                # 0D1E: E8 0B 00
    push   dx                                    # 0D21: 52
    push   cx                                    # 0D22: 51
    call   L_19FF                                # 0D23: E8 D9 0C
    pop    cx                                    # 0D26: 59
    jmp    L_0C86                                # 0D27: E9 5C FF
KRNSVC:
    mov    al,0x3a                               # 0D2A: B0 3A
KRNSAV:
    .byte 0x8B, 0xFA # 0D2C
    stos   BYTE PTR es:[di],al                   # 0D2E: AA
    inc    dx                                    # 0D2F: 42
    dec    cx                                    # 0D30: 49
    .byte 0x8A, 0xC1, 0x0A, 0xC5 # 0D31
    je     L_0D38                                # 0D35: 74 01
    ret                                          # 0D37: C3
L_0D38:
    mov    dl,0x17                               # 0D38: B2 17
    jmp    L_07D8                                # 0D3A: E9 9B FA
L_0D3D:
    int    0x93                                  # 0D3D: CD 93
    pop    bx                                    # 0D3F: 5B
    dec    bx                                    # 0D40: 4B
    dec    al                                    # 0D41: FE C8
    mov    ds:DONUM,al                           # 0D43: A2 FD 02
    pop    cx                                    # 0D46: 59
    pop    dx                                    # 0D47: 5A
    call   MAKUPL                                # 0D48: E8 A0 0C
L_0D4B:
    call   KRNSAV                                # 0D4B: E8 DE FF
    inc    bx                                    # 0D4E: 43
    call   MAKUPL                                # 0D4F: E8 99 0C
    call   ISLET2                                # 0D52: E8 F0 21
    jae    L_0D4B                                # 0D55: 73 F4
    cmp    al,0x3a                               # 0D57: 3C 3A
    jae    L_0D63                                # 0D59: 73 08
    cmp    al,0x30                               # 0D5B: 3C 30
    jae    L_0D4B                                # 0D5D: 73 EC
    cmp    al,0x2e                               # 0D5F: 3C 2E
    je     L_0D4B                                # 0D61: 74 E8
L_0D63:
    jmp    L_0A99                                # 0D63: E9 33 FD
L_0D66:
    mov    al,BYTE PTR [bx]                      # 0D66: 8A 07
    cmp    al,0x20                               # 0D68: 3C 20
    jae    L_0D76                                # 0D6A: 73 0A
    cmp    al,0x9                                # 0D6C: 3C 09
    je     L_0D76                                # 0D6E: 74 06
    cmp    al,0xa                                # 0D70: 3C 0A
    je     L_0D76                                # 0D72: 74 02
    mov    al,0x20                               # 0D74: B0 20
L_0D76:
    push   ax                                    # 0D76: 50
    mov    al,ds:DONUM                           # 0D77: A0 FD 02
    inc    al                                    # 0D7A: FE C0
    je     L_0D80                                # 0D7C: 74 02
    dec    al                                    # 0D7E: FE C8
L_0D80:
    jmp    L_0C22                                # 0D80: E9 9F FE
BAKSP:
    dec    bx                                    # 0D83: 4B
    mov    al,BYTE PTR [bx]                      # 0D84: 8A 07
    cmp    al,0x20                               # 0D86: 3C 20
    je     BAKSP                                # 0D88: 74 F9
    cmp    al,0x9                                # 0D8A: 3C 09
    je     BAKSP                                # 0D8C: 74 F5
    cmp    al,0xa                                # 0D8E: 3C 0A
    je     BAKSP                                # 0D90: 74 F1
    inc    bx                                    # 0D92: 43
    ret                                          # 0D93: C3
FOR:
    mov    al,0x64                               # 0D94: B0 64
    mov    ds:SUBFLG,al                           # 0D96: A2 39 03
    call   PTRGET                                # 0D99: E8 D2 29
    call   SYNCHR                                # 0D9C: E8 55 20
    .byte TK_EQUAL                             # 0D9F: E7 -- SYNCHR inline operand
    .byte 0x52 # 0DA0 -- decoded continuation: push   dx
    mov    WORD PTR ds:TEMP,dx                  # 0DA1: 89 16 3B 03
    mov    al,ds:VALTYP                           # 0DA5: A0 FB 02
    push   ax                                    # 0DA8: 50
    call   FRMEVL                                # 0DA9: E8 7B 09
    pop    ax                                    # 0DAC: 58
    push   bx                                    # 0DAD: 53
    call   L_1DDA                                # 0DAE: E8 29 10
    mov    bx,0x456                              # 0DB1: BB 56 04
    call   L_63FC                                # 0DB4: E8 45 56
    pop    bx                                    # 0DB7: 5B
    pop    dx                                    # 0DB8: 5A
    pop    cx                                    # 0DB9: 59
    push   bx                                    # 0DBA: 53
    call   DATAS                                 # 0DBB: E8 9D 03
    mov    WORD PTR ds:ENDFOR,bx                  # 0DBE: 89 1E 35 03
    mov    bx,0x2                                # 0DC2: BB 02 00
    .byte 0x03, 0xDC # 0DC5
L_0DC7:
    call   L_073D                                # 0DC7: E8 73 F9
    jne    L_0DEA                                # 0DCA: 75 1E
    .byte 0x03, 0xD9 # 0DCC
    push   dx                                    # 0DCE: 52
    dec    bx                                    # 0DCF: 4B
    mov    dh,BYTE PTR [bx]                      # 0DD0: 8A 37
    dec    bx                                    # 0DD2: 4B
    mov    dl,BYTE PTR [bx]                      # 0DD3: 8A 17
    inc    bx                                    # 0DD5: 43
    inc    bx                                    # 0DD6: 43
    push   bx                                    # 0DD7: 53
    mov    bx,WORD PTR ds:ENDFOR                  # 0DD8: 8B 1E 35 03
    .byte 0x3B, 0xDA # 0DDC
    pop    bx                                    # 0DDE: 5B
    pop    dx                                    # 0DDF: 5A
    jne    L_0DC7                                # 0DE0: 75 E5
    pop    dx                                    # 0DE2: 5A
    .byte 0x8B, 0xE3 # 0DE3
    mov    WORD PTR ds:SAVSTK,bx                  # 0DE5: 89 1E 45 03
    .byte 0xB1 # 0DE9
L_0DEA:
    .byte 0x5A # 0DEA
    xchg   dx,bx                                 # 0DEB: 87 DA
    mov    cl,0x8                                # 0DED: B1 08
    call   GETSTK                                # 0DEF: E8 E3 1E
    push   bx                                    # 0DF2: 53
    mov    bx,WORD PTR ds:ENDFOR                  # 0DF3: 8B 1E 35 03
    pop    si                                    # 0DF7: 5E
    xchg   si,bx                                 # 0DF8: 87 DE
    push   si                                    # 0DFA: 56
    push   bx                                    # 0DFB: 53
    mov    bx,WORD PTR ds:CURLIN                   # 0DFC: 8B 1E 2E 00
    pop    si                                    # 0E00: 5E
    xchg   si,bx                                 # 0E01: 87 DE
    push   si                                    # 0E03: 56
    call   SYNCHR                                # 0E04: E8 ED 1F
    .byte TOK_TO                               # 0E07: CC -- SYNCHR inline operand
    call   GETYPR                                # 0E08: E8 1A 0D
    jne    L_0E10                                # 0E0B: 75 03
    jmp    L_07D6                                # 0E0D: E9 C6 F9
L_0E10:
    jb     L_0E15                                # 0E10: 72 03
    jmp    L_07D6                                # 0E12: E9 C1 F9
L_0E15:
    pushf                                        # 0E15: 9C
    call   FRMEVL                                # 0E16: E8 0E 09
    popf                                         # 0E19: 9D
    push   bx                                    # 0E1A: 53
    js     L_0E20                                # 0E1B: 78 03
    .byte 0xE9, 0x1C, 0x00 # 0E1D
L_0E20:
    call   FRCINT                                # 0E20: E8 8A 5D
    pop    si                                    # 0E23: 5E
    xchg   si,bx                                 # 0E24: 87 DE
    push   si                                    # 0E26: 56
    mov    dx,0x1                                # 0E27: BA 01 00
    mov    al,BYTE PTR [bx]                      # 0E2A: 8A 07
    cmp    al,0xcf                               # 0E2C: 3C CF
    jne    L_0E33                                # 0E2E: 75 03
    call   GETINT                                # 0E30: E8 D4 10
L_0E33:
    push   dx                                    # 0E33: 52
    push   bx                                    # 0E34: 53
    xchg   dx,bx                                 # 0E35: 87 DA
    call   L_6500                                # 0E37: E8 C6 56
    jmp    L_0E63                                # 0E3A: EB 27
L_0E3C:
    call   FRCSNG                                # 0E3C: E8 12 5D
    call   L_63F3                                # 0E3F: E8 B1 55
    pop    bx                                    # 0E42: 5B
    push   cx                                    # 0E43: 51
    push   dx                                    # 0E44: 52
    mov    cx,0x8100                             # 0E45: B9 00 81
    .byte 0x8A, 0xF1, 0x8A, 0xD6 # 0E48
    int    0x94                                  # 0E4C: CD 94
    mov    al,BYTE PTR [bx]                      # 0E4E: 8A 07
    cmp    al,0xcf                               # 0E50: 3C CF
    mov    al,0x1                                # 0E52: B0 01
    jne    L_0E64                                # 0E54: 75 0E
    call   FRMCHK                                # 0E56: E8 CF 08
    push   bx                                    # 0E59: 53
    call   FRCSNG                                # 0E5A: E8 F4 5C
    call   L_63F3                                # 0E5D: E8 93 55
    call   SIGN                                # 0E60: E8 12 6D
L_0E63:
    pop    bx                                    # 0E63: 5B
L_0E64:
    push   cx                                    # 0E64: 51
    push   dx                                    # 0E65: 52
    .byte 0x8A, 0xC8 # 0E66
    call   GETYPR                                # 0E68: E8 BA 0C
    .byte 0x8A, 0xE8 # 0E6B
    push   cx                                    # 0E6D: 51
    dec    bx                                    # 0E6E: 4B
    call   CHRGTR                                # 0E6F: E8 AB 00
    je     L_0E77                                # 0E72: 74 03
    jmp    SNERR                                 # 0E74: E9 47 F9
L_0E77:
    call   NXTSCN                                # 0E77: E8 81 16
    call   CHRGTR                                # 0E7A: E8 A0 00
    push   bx                                    # 0E7D: 53
    push   bx                                    # 0E7E: 53
    mov    bx,WORD PTR ds:NXTLIN                  # 0E7F: 8B 1E 5A 04
    mov    WORD PTR ds:CURLIN,bx                   # 0E83: 89 1E 2E 00
    mov    bx,WORD PTR ds:TEMP                  # 0E87: 8B 1E 3B 03
    pop    si                                    # 0E8B: 5E
    xchg   si,bx                                 # 0E8C: 87 DE
    push   si                                    # 0E8E: 56
    mov    ch,0x82                               # 0E8F: B5 82
    push   cx                                    # 0E91: 51
    lahf                                         # 0E92: 9F
    xchg   ah,al                                 # 0E93: 86 C4
    push   ax                                    # 0E95: 50
    xchg   ah,al                                 # 0E96: 86 C4
    lahf                                         # 0E98: 9F
    xchg   ah,al                                 # 0E99: 86 C4
    push   ax                                    # 0E9B: 50
    xchg   ah,al                                 # 0E9C: 86 C4
    jmp    L_7370                                # 0E9E: E9 CF 64
L_0EA1:
    mov    ch,0x82                               # 0EA1: B5 82
    push   cx                                    # 0EA3: 51
    jmp    L_0EE8                                # 0EA4: EB 42
L_0EA6:
    jmp    L_0774                                # 0EA6: E9 CB F8
L_0EA9:
    jmp    SNERR                                 # 0EA9: E9 12 F9
L_0EAC:
    ret                                          # 0EAC: C3
L_0EAD:
    call   CHRCON                                # 0EAD: E8 75 00
    jmp    L_0F02                                # 0EB0: EB 50
L_0EB2:
    int    0x95                                  # 0EB2: CD 95
    jmp    L_1E1A                                # 0EB4: E9 63 0F
L_0EB7:
    jmp    LET                                   # 0EB7: E9 D5 02
L_0EBA:
    .byte 0x0A, 0xC0 # 0EBA
    jne    L_0EA9                                # 0EBC: 75 EB
    inc    bx                                    # 0EBE: 43
    mov    al,BYTE PTR [bx]                      # 0EBF: 8A 07
    inc    bx                                    # 0EC1: 43
    or     al,BYTE PTR [bx]                      # 0EC2: 0A 07
    je     L_0EA6                                # 0EC4: 74 E0
    inc    bx                                    # 0EC6: 43
    mov    dx,WORD PTR [bx]                      # 0EC7: 8B 17
    inc    bx                                    # 0EC9: 43
    mov    WORD PTR ds:CURLIN,dx                   # 0ECA: 89 16 2E 00
    test   BYTE PTR ds:TRCFLG,0xff                # 0ECE: F6 06 76 04 FF
    je     L_0EFB                                # 0ED3: 74 26
    push   bx                                    # 0ED5: 53
    mov    al,0x5b                               # 0ED6: B0 5B
    call   OUTDO                                # 0ED8: E8 CA 1C
    xchg   dx,bx                                 # 0EDB: 87 DA
    call   LINPRT                                # 0EDD: E8 70 56
    mov    al,0x5d                               # 0EE0: B0 5D
    call   OUTDO                                # 0EE2: E8 C0 1C
    pop    bx                                    # 0EE5: 5B
    jmp    L_0EFB                                # 0EE6: EB 13
L_0EE8:
    int    0x96                                  # 0EE8: CD 96
    call   L_2C88                                # 0EEA: E8 9B 1D
    mov    WORD PTR ds:SAVSTK,sp                  # 0EED: 89 26 45 03
    mov    WORD PTR ds:SAVTXT,bx                  # 0EF1: 89 1E 43 03
    mov    al,BYTE PTR [bx]                      # 0EF5: 8A 07
    cmp    al,0x3a                               # 0EF7: 3C 3A
    jne    L_0EBA                                # 0EF9: 75 BF
L_0EFB:
    inc    bx                                    # 0EFB: 43
    mov    al,BYTE PTR [bx]                      # 0EFC: 8A 07
    cmp    al,0x3a                               # 0EFE: 3C 3A
    jb     L_0EAD                                # 0F00: 72 AB
L_0F02:
    mov    dx,0xee8                              # 0F02: BA E8 0E
    push   dx                                    # 0F05: 52
    je     L_0EAC                                # 0F06: 74 A4
L_0F08:
    sub    al,0x81                               # 0F08: 2C 81
    jb     L_0EB7                                # 0F0A: 72 AB
    cmp    al,0x4a                               # 0F0C: 3C 4A
    jae    L_0EB2                                # 0F0E: 73 A2
    .byte 0x32, 0xE4, 0x02, 0xC0, 0x8B, 0xF0 # 0F10
    int    0x97                                  # 0F16: CD 97
    .byte 0x2E, 0xFF, 0xB4, 0x25, 0x00 # 0F18
CHRGTR:
    inc    bx                                    # 0F1D: 43
CHRGT2:
    mov    al,BYTE PTR [bx]                      # 0F1E: 8A 07
    cmp    al,0x3a                               # 0F20: 3C 3A
    jb     CHRCON                                # 0F22: 72 01
    ret                                          # 0F24: C3
CHRCON:
    cmp    al,0x20                               # 0F25: 3C 20
    je     CHRGTR                                # 0F27: 74 F4
    jb     L_0F33                                # 0F29: 72 08
    cmp    al,0x30                               # 0F2B: 3C 30
    cmc                                          # 0F2D: F5
    inc    al                                    # 0F2E: FE C0
    dec    al                                    # 0F30: FE C8
L_0F32:
    ret                                          # 0F32: C3
L_0F33:
    .byte 0x0A, 0xC0 # 0F33
    je     L_0F32                                # 0F35: 74 FB
    cmp    al,0xb                                # 0F37: 3C 0B
    jb     L_0FAD                                # 0F39: 72 72
    cmp    al,0x1e                               # 0F3B: 3C 1E
    jne    L_0F45                                # 0F3D: 75 06
    mov    al,ds:CONSAV                           # 0F3F: A0 00 03
    .byte 0x0A, 0xC0 # 0F42
    ret                                          # 0F44: C3
L_0F45:
    cmp    al,0x10                               # 0F45: 3C 10
    je     L_0F85                                # 0F47: 74 3C
    push   ax                                    # 0F49: 50
    inc    bx                                    # 0F4A: 43
    mov    ds:CONSAV,al                           # 0F4B: A2 00 03
    sub    al,0x1c                               # 0F4E: 2C 1C
    jae    L_0F8B                                # 0F50: 73 39
    sub    al,0xf5                               # 0F52: 2C F5
    jae    L_0F5D                                # 0F54: 73 07
    cmp    al,0xfe                               # 0F56: 3C FE
    jne    L_0F75                                # 0F58: 75 1B
    mov    al,BYTE PTR [bx]                      # 0F5A: 8A 07
    inc    bx                                    # 0F5C: 43
L_0F5D:
    mov    WORD PTR ds:CONTXT,bx                  # 0F5D: 89 1E FE 02
    mov    bh,0x0                                # 0F61: B7 00
L_0F63:
    .byte 0x8A, 0xD8 # 0F63
    mov    WORD PTR ds:CONLO,bx                  # 0F65: 89 1E 02 03
    mov    al,0x2                                # 0F69: B0 02
    mov    ds:CONTYP,al                           # 0F6B: A2 01 03
    mov    bx,NUMCON                            # 0F6E: BB 04 00
    pop    ax                                    # 0F71: 58
    .byte 0x0A, 0xC0 # 0F72
    ret                                          # 0F74: C3
L_0F75:
    mov    al,BYTE PTR [bx]                      # 0F75: 8A 07
    inc    bx                                    # 0F77: 43
    inc    bx                                    # 0F78: 43
    mov    WORD PTR ds:CONTXT,bx                  # 0F79: 89 1E FE 02
    dec    bx                                    # 0F7D: 4B
    mov    bh,BYTE PTR [bx]                      # 0F7E: 8A 3F
    jmp    L_0F63                                # 0F80: EB E1
L_0F82:
    call   L_0FBC                                # 0F82: E8 37 00
L_0F85:
    mov    bx,WORD PTR ds:CONTXT                  # 0F85: 8B 1E FE 02
    jmp    CHRGT2                                # 0F89: EB 93
L_0F8B:
    inc    al                                    # 0F8B: FE C0
    rol    al,1                                  # 0F8D: D0 C0
    mov    ds:CONTYP,al                           # 0F8F: A2 01 03
    push   dx                                    # 0F92: 52
    push   cx                                    # 0F93: 51
    mov    dx,0x302                              # 0F94: BA 02 03
    xchg   dx,bx                                 # 0F97: 87 DA
    .byte 0x8A, 0xE8 # 0F99
    call   L_64B1                                # 0F9B: E8 13 55
    xchg   dx,bx                                 # 0F9E: 87 DA
    pop    cx                                    # 0FA0: 59
    pop    dx                                    # 0FA1: 5A
    mov    WORD PTR ds:CONTXT,bx                  # 0FA2: 89 1E FE 02
    pop    ax                                    # 0FA6: 58
    mov    bx,NUMCON                            # 0FA7: BB 04 00
    .byte 0x0A, 0xC0 # 0FAA
    ret                                          # 0FAC: C3
L_0FAD:
    cmp    al,0x9                                # 0FAD: 3C 09
    jb     L_0FB4                                # 0FAF: 72 03
    jmp    CHRGTR                                # 0FB1: E9 69 FF
L_0FB4:
    cmp    al,0x30                               # 0FB4: 3C 30
    cmc                                          # 0FB6: F5
    inc    al                                    # 0FB7: FE C0
    dec    al                                    # 0FB9: FE C8
    ret                                          # 0FBB: C3
L_0FBC:
    mov    al,ds:CONSAV                           # 0FBC: A0 00 03
    cmp    al,0xf                                # 0FBF: 3C 0F
    jae    L_0FDA                                # 0FC1: 73 17
    cmp    al,0xd                                # 0FC3: 3C 0D
    jb     L_0FDA                                # 0FC5: 72 13
    mov    bx,WORD PTR ds:CONLO                  # 0FC7: 8B 1E 02 03
    jne    L_0FD7                                # 0FCB: 75 0A
    inc    bx                                    # 0FCD: 43
    inc    bx                                    # 0FCE: 43
    inc    bx                                    # 0FCF: 43
    mov    dl,BYTE PTR [bx]                      # 0FD0: 8A 17
    inc    bx                                    # 0FD2: 43
    mov    dh,BYTE PTR [bx]                      # 0FD3: 8A 37
    xchg   dx,bx                                 # 0FD5: 87 DA
L_0FD7:
    jmp    L_6444                                # 0FD7: E9 6A 54
L_0FDA:
    mov    al,ds:CONTYP                           # 0FDA: A0 01 03
    mov    ds:VALTYP,al                           # 0FDD: A2 FB 02
    cmp    al,0x8                                # 0FE0: 3C 08
    je     L_0FF5                                # 0FE2: 74 11
    mov    bx,WORD PTR ds:CONLO                  # 0FE4: 8B 1E 02 03
    mov    WORD PTR ds:FACLO,bx                  # 0FE8: 89 1E A3 04
    mov    bx,WORD PTR ds:CONHI                  # 0FEC: 8B 1E 04 03
    mov    WORD PTR ds:FACSGN,bx                  # 0FF0: 89 1E A5 04
L_0FF4:
    ret                                          # 0FF4: C3
L_0FF5:
    mov    bx,CONLO                             # 0FF5: BB 02 03
    jmp    L_6498                                # 0FF8: E9 9D 54
DEFSTR:
    mov    dl,0x3                                # 0FFB: B2 03
    .byte 0xB9 # 0FFD
DEFINT:
    .byte 0xB2, 0x02, 0xB9 # 0FFE
DEFREA:
    .byte 0xB2, 0x04, 0xB9 # 1001
DEFDBL:
    .byte 0xB2, 0x08 # 1004
L_1006:
    call   ISLET                                # 1006: E8 3A 1F
    mov    cx,0x7be                              # 1009: B9 BE 07
    push   cx                                    # 100C: 51
    jb     L_0FF4                                # 100D: 72 E5
    sub    al,0x41                               # 100F: 2C 41
    .byte 0x8A, 0xC8, 0x8A, 0xE8 # 1011
    call   CHRGTR                                # 1015: E8 05 FF
    cmp    al,0xea                               # 1018: 3C EA
    jne    L_102B                                # 101A: 75 0F
    call   CHRGTR                                # 101C: E8 FE FE
    call   ISLET                                # 101F: E8 21 1F
    jb     L_0FF4                                # 1022: 72 D0
    sub    al,0x41                               # 1024: 2C 41
    .byte 0x8A, 0xE8 # 1026
    call   CHRGTR                                # 1028: E8 F2 FE
L_102B:
    .byte 0x8A, 0xC5, 0x2A, 0xC1 # 102B
    jb     L_0FF4                                # 102F: 72 C3
    inc    al                                    # 1031: FE C0
    pop    si                                    # 1033: 5E
    xchg   si,bx                                 # 1034: 87 DE
    push   si                                    # 1036: 56
    mov    bx,0x360                              # 1037: BB 60 03
    mov    ch,0x0                                # 103A: B5 00
    .byte 0x03, 0xD9 # 103C
L_103E:
    mov    BYTE PTR [bx],dl                      # 103E: 88 17
    inc    bx                                    # 1040: 43
    dec    al                                    # 1041: FE C8
    jne    L_103E                                # 1043: 75 F9
    pop    bx                                    # 1045: 5B
    mov    al,BYTE PTR [bx]                      # 1046: 8A 07
    cmp    al,0x2c                               # 1048: 3C 2C
    jne    L_0FF4                                # 104A: 75 A8
    call   CHRGTR                                # 104C: E8 CE FE
    jmp    L_1006                                # 104F: EB B5
L_1051:
    call   CHRGTR                                # 1051: E8 C9 FE
L_1054:
    call   GETIN2                                # 1054: E8 B3 0E
    jns    L_0FF4                                # 1057: 79 9B
FCERR:
    mov    dl,0x5                                # 1059: B2 05
    jmp    L_07D8                                # 105B: E9 7A F7
L_105E:
    mov    al,BYTE PTR [bx]                      # 105E: 8A 07
    cmp    al,0x2e                               # 1060: 3C 2E
    mov    dx,WORD PTR ds:DOT                  # 1062: 8B 16 49 03
    jne    LINGET                                # 1066: 75 03
    jmp    CHRGTR                                # 1068: E9 B2 FE
LINGET:
    dec    bx                                    # 106B: 4B
L_106C:
    call   CHRGTR                                # 106C: E8 AE FE
    cmp    al,0xe                                # 106F: 3C 0E
    je     L_1075                                # 1071: 74 02
    cmp    al,0xd                                # 1073: 3C 0D
L_1075:
    mov    dx,WORD PTR ds:CONLO                  # 1075: 8B 16 02 03
    jne    L_107E                                # 1079: 75 03
    jmp    CHRGTR                                # 107B: E9 9F FE
L_107E:
    .byte 0x32, 0xC0 # 107E
    mov    ds:CONSAV,al                           # 1080: A2 00 03
    dec    bx                                    # 1083: 4B
    mov    dx,0x0                                # 1084: BA 00 00
L_1087:
    call   CHRGTR                                # 1087: E8 93 FE
    jb     L_108D                                # 108A: 72 01
    ret                                          # 108C: C3
L_108D:
    push   bx                                    # 108D: 53
    lahf                                         # 108E: 9F
    push   ax                                    # 108F: 50
    mov    bx,0x1998                             # 1090: BB 98 19
    .byte 0x3B, 0xDA # 1093
    jb     L_10B2                                # 1095: 72 1B
    .byte 0x8A, 0xFE, 0x8A, 0xDA, 0x03, 0xDA, 0x03, 0xDB, 0x03, 0xDA, 0x03, 0xDB # 1097
    pop    ax                                    # 10A3: 58
    sahf                                         # 10A4: 9E
    sub    al,0x30                               # 10A5: 2C 30
    .byte 0x8A, 0xD0 # 10A7
    mov    dh,0x0                                # 10A9: B6 00
    .byte 0x03, 0xDA # 10AB
    xchg   dx,bx                                 # 10AD: 87 DA
    pop    bx                                    # 10AF: 5B
    jmp    L_1087                                # 10B0: EB D5
L_10B2:
    pop    ax                                    # 10B2: 58
    sahf                                         # 10B3: 9E
    pop    bx                                    # 10B4: 5B
L_10B5:
    ret                                          # 10B5: C3
RUN:
    jne    L_10BB                                # 10B6: 75 03
    jmp    RUNC                                # 10B8: E9 7C 1C
L_10BB:
    cmp    al,0xe                                # 10BB: 3C 0E
    je     L_10C6                                # 10BD: 74 07
    cmp    al,0xd                                # 10BF: 3C 0D
    je     L_10C6                                # 10C1: 74 03
    jmp    L_4169                                # 10C3: E9 A3 30
L_10C6:
    call   L_2D3E                                # 10C6: E8 75 1C
    mov    cx,0xee8                              # 10C9: B9 E8 0E
    jmp    L_10EC                                # 10CC: EB 1E
GOSUB:
    mov    cl,0x3                                # 10CE: B1 03
    call   GETSTK                                # 10D0: E8 02 1C
    call   LINGET                                # 10D3: E8 95 FF
    pop    cx                                    # 10D6: 59
    push   bx                                    # 10D7: 53
    push   bx                                    # 10D8: 53
    mov    bx,WORD PTR ds:CURLIN                   # 10D9: 8B 1E 2E 00
    pop    si                                    # 10DD: 5E
    xchg   si,bx                                 # 10DE: 87 DE
    push   si                                    # 10E0: 56
    mov    al,0x8d                               # 10E1: B0 8D
    lahf                                         # 10E3: 9F
    xchg   ah,al                                 # 10E4: 86 C4
    push   ax                                    # 10E6: 50
    xchg   ah,al                                 # 10E7: 86 C4
    push   cx                                    # 10E9: 51
    jmp    L_10F0                                # 10EA: EB 04
L_10EC:
    push   cx                                    # 10EC: 51
GOTO:
    call   LINGET                                # 10ED: E8 7B FF
L_10F0:
    mov    al,ds:CONSAV                           # 10F0: A0 00 03
    cmp    al,0xd                                # 10F3: 3C 0D
    xchg   dx,bx                                 # 10F5: 87 DA
    je     L_10B5                                # 10F7: 74 BC
    cmp    al,0xe                                # 10F9: 3C 0E
    je     L_1100                                # 10FB: 74 03
    jmp    SNERR                                 # 10FD: E9 BE F6
L_1100:
    xchg   dx,bx                                 # 1100: 87 DA
    push   bx                                    # 1102: 53
    mov    bx,WORD PTR ds:CONTXT                  # 1103: 8B 1E FE 02
    pop    si                                    # 1107: 5E
    xchg   si,bx                                 # 1108: 87 DE
    push   si                                    # 110A: 56
    call   REM                                   # 110B: E8 51 00
    inc    bx                                    # 110E: 43
    push   bx                                    # 110F: 53
    mov    bx,WORD PTR ds:CURLIN                   # 1110: 8B 1E 2E 00
    .byte 0x3B, 0xDA # 1114
    pop    bx                                    # 1116: 5B
    jae    L_111C                                # 1117: 73 03
    call   L_0A6B                                # 1119: E8 4F F9
L_111C:
    jb     L_1121                                # 111C: 72 03
    call   FNDLIN                                # 111E: E8 46 F9
L_1121:
    jae    L_1130                                # 1121: 73 0D
    dec    cx                                    # 1123: 49
    mov    al,0xd                                # 1124: B0 0D
    mov    ds:PTRFLG,al                           # 1126: A2 3D 03
    pop    bx                                    # 1129: 5B
    call   L_2429                                # 112A: E8 FC 12
    .byte 0x8B, 0xD9 # 112D
L_112F:
    ret                                          # 112F: C3
L_1130:
    mov    dl,0x8                                # 1130: B2 08
    jmp    L_07D8                                # 1132: E9 A3 F6
RETURN:
    int    0x98                                  # 1135: CD 98
    jne    L_112F                                # 1137: 75 F6
    mov    dh,0xff                               # 1139: B6 FF
    call   CODE_BODY_START                       # 113B: E8 FA F5
    .byte 0x8B, 0xE3 # 113E
    mov    WORD PTR ds:SAVSTK,bx                  # 1140: 89 1E 45 03
    cmp    al,0x8d                               # 1144: 3C 8D
    mov    dl,0x3                                # 1146: B2 03
    je     L_114D                                # 1148: 74 03
    jmp    L_07D8                                # 114A: E9 8B F6
L_114D:
    pop    bx                                    # 114D: 5B
    mov    WORD PTR ds:CURLIN,bx                   # 114E: 89 1E 2E 00
    mov    bx,0xee8                              # 1152: BB E8 0E
    pop    si                                    # 1155: 5E
    xchg   si,bx                                 # 1156: 87 DE
    push   si                                    # 1158: 56
    mov    al,0x5b                               # 1159: B0 5B
DATAS:
    mov    cl,0x3a                               # 115B: B1 3A
    jmp    L_1161                                # 115D: EB 02
REM:
ELSES:
    mov    cl,0x0                                # 115F: B1 00
L_1161:
    mov    ch,0x0                                # 1161: B5 00
L_1163:
    .byte 0x8A, 0xC1, 0x8A, 0xCD, 0x8A, 0xE8 # 1163
L_1169:
    dec    bx                                    # 1169: 4B
L_116A:
    call   CHRGTR                                # 116A: E8 B0 FD
    .byte 0x0A, 0xC0 # 116D
    je     L_112F                                # 116F: 74 BE
    .byte 0x3A, 0xC5 # 1171
    je     L_112F                                # 1173: 74 BA
    inc    bx                                    # 1175: 43
    cmp    al,0x22                               # 1176: 3C 22
    je     L_1163                                # 1178: 74 E9
    inc    al                                    # 117A: FE C0
    je     L_116A                                # 117C: 74 EC
    sub    al,0x8c                               # 117E: 2C 8C
    jne    L_1169                                # 1180: 75 E7
    .byte 0x3A, 0xC5, 0x12, 0xC6, 0x8A, 0xF0 # 1182
    jmp    L_1169                                # 1188: EB DF
    .byte 0x58, 0x04, 0x03, 0xEB, 0x14 # 118A
LET:
    call   PTRGET                                # 118F: E8 DC 25
    call   SYNCHR                                # 1192: E8 5F 1C
    .byte TK_EQUAL                             # 1195: E7 -- SYNCHR inline operand
    .byte 0x89 # 1196 -- decoded continuation: mov    WORD PTR ds:TEMP,dx
    push   ss                                    # 1197: 16
    cmp    ax,WORD PTR [bp+di]                   # 1198: 3B 03
    push   dx                                    # 119A: 52
    mov    al,ds:VALTYP                           # 119B: A0 FB 02
    push   ax                                    # 119E: 50
    call   FRMEVL                                # 119F: E8 85 05
    pop    ax                                    # 11A2: 58
    pop    si                                    # 11A3: 5E
    xchg   si,bx                                 # 11A4: 87 DE
    push   si                                    # 11A6: 56
L_11A7:
    .byte 0x8A, 0xE8 # 11A7
    mov    al,ds:VALTYP                           # 11A9: A0 FB 02
    .byte 0x3A, 0xC5, 0x8A, 0xC5 # 11AC
    je     L_11B8                                # 11B0: 74 06
    call   L_1DDA                                # 11B2: E8 25 0C
L_11B5:
    mov    al,ds:VALTYP                           # 11B5: A0 FB 02
L_11B8:
    mov    dx,0x4a3                              # 11B8: BA A3 04
    cmp    al,0x5                                # 11BB: 3C 05
    jb     L_11C2                                # 11BD: 72 03
    mov    dx,DFACL                              # 11BF: BA 9F 04
L_11C2:
    push   bx                                    # 11C2: 53
    cmp    al,0x3                                # 11C3: 3C 03
    jne    L_11F8                                # 11C5: 75 31
    mov    bx,WORD PTR ds:FACLO                  # 11C7: 8B 1E A3 04
    push   bx                                    # 11CB: 53
    inc    bx                                    # 11CC: 43
    mov    dx,WORD PTR [bx]                      # 11CD: 8B 17
    mov    bx,WORD PTR ds:TXTTAB                   # 11CF: 8B 1E 30 00
    .byte 0x3B, 0xDA # 11D3
    jae    L_11E8                                # 11D5: 73 11
    mov    bx,WORD PTR ds:STREND                  # 11D7: 8B 1E 5C 03
    .byte 0x3B, 0xDA # 11DB
    pop    dx                                    # 11DD: 5A
    jae    L_11F1                                # 11DE: 73 11
    mov    bx,0x32c                              # 11E0: BB 2C 03
    .byte 0x3B, 0xDA # 11E3
    jae    L_11F1                                # 11E5: 73 0A
    .byte 0xB0 # 11E7
L_11E8:
    .byte 0x5A # 11E8
    call   L_28D2                                # 11E9: E8 E6 16
    xchg   dx,bx                                 # 11EC: 87 DA
    call   L_2624                                # 11EE: E8 33 14
L_11F1:
    call   L_28D2                                # 11F1: E8 DE 16
    pop    si                                    # 11F4: 5E
    xchg   si,bx                                 # 11F5: 87 DE
    push   si                                    # 11F7: 56
L_11F8:
    call   L_64B9                                # 11F8: E8 BE 52
    pop    dx                                    # 11FB: 5A
    pop    bx                                    # 11FC: 5B
L_11FD:
    ret                                          # 11FD: C3
ONGOTO:
    cmp    al,0xa7                               # 11FE: 3C A7
    jne    L_1234                                # 1200: 75 32
    call   CHRGTR                                # 1202: E8 18 FD
    call   SYNCHR                                # 1205: E8 EC 1B
    .byte TOK_GOTO                             # 1208: 89 -- SYNCHR inline operand
    .byte 0xE8 # 1209 -- decoded continuation: call   0x106b
    pop    di                                    # 120A: 5F
    dec    BYTE PTR [bp+di]                      # 120B: FE 0B
    .byte 0xD2, 0x74, 0x0D # 120D
    call   FNDLN1                                # 1210: E8 4F F8
    .byte 0x8A, 0xF5, 0x8A, 0xD1 # 1213
    pop    bx                                    # 1217: 5B
    jb     L_121D                                # 1218: 72 03
    jmp    L_1130                                # 121A: E9 13 FF
L_121D:
    mov    WORD PTR ds:ONELIN,dx                  # 121D: 89 16 4D 03
    jb     L_11FD                                # 1221: 72 DA
    mov    al,ds:ONEFLG                           # 1223: A0 4F 03
    .byte 0x0A, 0xC0, 0x8A, 0xC2 # 1226
    je     L_11FD                                # 122A: 74 D1
    mov    al,ds:ERRFLG                            # 122C: A0 28 00
    .byte 0x8A, 0xD0 # 122F
    jmp    L_0802                                # 1231: E9 CE F5
L_1234:
    call   GETBYT                                # 1234: E8 E5 0C
    mov    al,BYTE PTR [bx]                      # 1237: 8A 07
    .byte 0x8A, 0xE8 # 1239
    cmp    al,0x8d                               # 123B: 3C 8D
    je     L_1244                                # 123D: 74 05
    call   SYNCHR                                # 123F: E8 B2 1B
    .byte TOK_GOTO                             # 1242: 89 -- SYNCHR inline operand
    .byte 0x4B # 1243 -- decoded continuation: dec    bx
L_1244:
    .byte 0x8A, 0xCA # 1244
L_1246:
    .byte 0xFE, 0xC9, 0x8A, 0xC5 # 1246
    jne    L_124F                                # 124A: 75 03
    jmp    L_0F08                                # 124C: E9 B9 FC
L_124F:
    call   L_106C                                # 124F: E8 1A FE
    cmp    al,0x2c                               # 1252: 3C 2C
    jne    L_11FD                                # 1254: 75 A7
    jmp    L_1246                                # 1256: EB EE
RESUME:
    mov    al,ds:ONEFLG                           # 1258: A0 4F 03
    .byte 0x0A, 0xC0 # 125B
    jne    L_1267                                # 125D: 75 08
    .byte 0x33, 0xC0 # 125F
    mov    ds:ONELIN,ax                           # 1261: A3 4D 03
    jmp    L_07CD                                # 1264: E9 66 F5
L_1267:
    inc    al                                    # 1267: FE C0
    mov    ds:ERRFLG,al                            # 1269: A2 28 00
    cmp    BYTE PTR [bx],0x83                    # 126C: 80 3F 83
    je     L_1283                                # 126F: 74 12
    call   LINGET                                # 1271: E8 F7 FD
    jne    L_1282                                # 1274: 75 0C
    .byte 0x0B, 0xD2 # 1276
    je     L_128A                                # 1278: 74 10
    call   L_10F0                                # 127A: E8 73 FE
    .byte 0x32, 0xC0 # 127D
    mov    ds:ONEFLG,al                           # 127F: A2 4F 03
L_1282:
    ret                                          # 1282: C3
L_1283:
    call   CHRGTR                                # 1283: E8 97 FC
    jne    L_1282                                # 1286: 75 FA
L_1288:
    jmp    L_1291                                # 1288: EB 07
L_128A:
    .byte 0x32, 0xC0 # 128A
    mov    ds:ONEFLG,al                           # 128C: A2 4F 03
    inc    al                                    # 128F: FE C0
L_1291:
    mov    ax,ds:ERRLIN                           # 1291: A1 47 03
    mov    ds:CURLIN,ax                            # 1294: A3 2E 00
    mov    bx,WORD PTR ds:ERRTXT                  # 1297: 8B 1E 4B 03
    jne    L_1282                                # 129B: 75 E5
    cmp    BYTE PTR [bx],0x0                     # 129D: 80 3F 00
    jne    L_12A5                                # 12A0: 75 03
    add    bx,0x4                                # 12A2: 83 C3 04
L_12A5:
    inc    bx                                    # 12A5: 43
    jmp    L_2BC0                                # 12A6: E9 17 19
ERRORS:
    call   GETBYT                                # 12A9: E8 70 0C
    jne    L_1288                                # 12AC: 75 DA
    .byte 0x0A, 0xC0 # 12AE
    jne    L_12B5                                # 12B0: 75 03
    jmp    FCERR                                # 12B2: E9 A4 FD
L_12B5:
    jmp    L_07D8                                # 12B5: E9 20 F5
AUTO:
    mov    dx,0xa                                # 12B8: BA 0A 00
    push   dx                                    # 12BB: 52
    je     L_12DD                                # 12BC: 74 1F
    call   L_105E                                # 12BE: E8 9D FD
    xchg   dx,bx                                 # 12C1: 87 DA
    pop    si                                    # 12C3: 5E
    xchg   si,bx                                 # 12C4: 87 DE
    push   si                                    # 12C6: 56
    je     L_12DF                                # 12C7: 74 16
    xchg   dx,bx                                 # 12C9: 87 DA
    call   SYNCHR                                # 12CB: E8 26 1B
    .byte ','                                  # 12CE: 2C -- SYNCHR inline operand
    .byte 0x8B # 12CF -- decoded continuation: mov    dx,WORD PTR ds:AUTINC
    push   ss                                    # 12D0: 16
    inc    cx                                    # 12D1: 41
    add    si,WORD PTR [si+0x8]                  # 12D2: 03 74 08
    call   LINGET                                # 12D5: E8 93 FD
    je     L_12DD                                # 12D8: 74 03
    jmp    SNERR                                 # 12DA: E9 E1 F4
L_12DD:
    xchg   dx,bx                                 # 12DD: 87 DA
L_12DF:
    .byte 0x8A, 0xC7, 0x0A, 0xC3 # 12DF
    jne    L_12E8                                # 12E3: 75 03
    jmp    FCERR                                # 12E5: E9 71 FD
L_12E8:
    mov    WORD PTR ds:AUTINC,bx                  # 12E8: 89 1E 41 03
    mov    ds:AUTFLG,al                           # 12EC: A2 3E 03
    pop    bx                                    # 12EF: 5B
    mov    WORD PTR ds:AUTLIN,bx                  # 12F0: 89 1E 3F 03
    pop    cx                                    # 12F4: 59
    jmp    MAIN                                # 12F5: E9 DB F5
IFS:
    call   FRMEVL                                # 12F8: E8 2C 04
    mov    al,BYTE PTR [bx]                      # 12FB: 8A 07
    cmp    al,0x2c                               # 12FD: 3C 2C
    jne    L_1304                                # 12FF: 75 03
    call   CHRGTR                                # 1301: E8 19 FC
L_1304:
    cmp    al,0x89                               # 1304: 3C 89
    je     L_130D                                # 1306: 74 05
    call   SYNCHR                                # 1308: E8 E9 1A
    .byte TOK_THEN                             # 130B: CD -- SYNCHR inline operand
    .byte 0x4B # 130C -- decoded continuation: dec    bx
L_130D:
    push   bx                                    # 130D: 53
    call   L_64E3                                # 130E: E8 D2 51
    pop    bx                                    # 1311: 5B
    je     L_132D                                # 1312: 74 19
L_1314:
    call   CHRGTR                                # 1314: E8 06 FC
    jne    L_131A                                # 1317: 75 01
    ret                                          # 1319: C3
L_131A:
    cmp    al,0xe                                # 131A: 3C 0E
    jne    L_1321                                # 131C: 75 03
    jmp    GOTO                                  # 131E: E9 CC FD
L_1321:
    cmp    al,0xd                                # 1321: 3C 0D
    je     L_1328                                # 1323: 74 03
    jmp    L_0F08                                # 1325: E9 E0 FB
L_1328:
    mov    bx,WORD PTR ds:CONLO                  # 1328: 8B 1E 02 03
L_132C:
    ret                                          # 132C: C3
L_132D:
    mov    dh,0x1                                # 132D: B6 01
L_132F:
    call   DATAS                                 # 132F: E8 29 FE
    .byte 0x0A, 0xC0 # 1332
    je     L_132C                                # 1334: 74 F6
    call   CHRGTR                                # 1336: E8 E4 FB
    cmp    al,0xa1                               # 1339: 3C A1
    jne    L_132F                                # 133B: 75 F2
    dec    dh                                    # 133D: FE CE
    jne    L_132F                                # 133F: 75 EE
    jmp    L_1314                                # 1341: EB D1
LPRINT:
    call   L_14B0                                # 1343: E8 6A 01
    jmp    L_134B                                # 1346: EB 03
PRINT:
    call   L_44E6                                # 1348: E8 9B 31
L_134B:
    dec    bx                                    # 134B: 4B
    call   CHRGTR                                # 134C: E8 CE FB
    jne    L_1354                                # 134F: 75 03
    call   CRDO                                # 1351: E8 1D 19
L_1354:
    jne    L_1359                                # 1354: 75 03
    jmp    L_1498                                # 1356: E9 3F 01
L_1359:
    cmp    al,0xd7                               # 1359: 3C D7
    jne    L_1360                                # 135B: 75 03
    jmp    PRINUS                                # 135D: E9 6B 27
L_1360:
    cmp    al,0xce                               # 1360: 3C CE
    jne    L_1367                                # 1362: 75 03
    jmp    L_1412                                # 1364: E9 AB 00
L_1367:
    cmp    al,0xd2                               # 1367: 3C D2
    jne    L_136E                                # 1369: 75 03
    jmp    L_1412                                # 136B: E9 A4 00
L_136E:
    push   bx                                    # 136E: 53
    cmp    al,0x2c                               # 136F: 3C 2C
    je     L_13E0                                # 1371: 74 6D
    cmp    al,0x3b                               # 1373: 3C 3B
    jne    L_137A                                # 1375: 75 03
    jmp    L_1491                                # 1377: E9 17 01
L_137A:
    pop    cx                                    # 137A: 59
    call   FRMEVL                                # 137B: E8 A9 03
    push   bx                                    # 137E: 53
    call   GETYPR                                # 137F: E8 A3 07
    je     L_1393                                # 1382: 74 0F
    call   L_70C8                                # 1384: E8 41 5D
    call   L_264C                                # 1387: E8 C2 12
    mov    BYTE PTR [bx],0x20                    # 138A: C6 07 20
    mov    bx,WORD PTR ds:FACLO                  # 138D: 8B 1E A3 04
    inc    BYTE PTR [bx]                         # 1391: FE 07
L_1393:
    int    0x99                                  # 1393: CD 99
    mov    bx,WORD PTR ds:FACLO                  # 1395: 8B 1E A3 04
    push   bx                                    # 1399: 53
    call   ISFLIO                                # 139A: E8 39 1C
    je     L_13AC                                # 139D: 74 0D
    call   L_14D3                                # 139F: E8 31 01
    js     L_13A7                                # 13A2: 78 03
    .byte 0xE9, 0x31, 0x00 # 13A4
L_13A7:
    call   L_592B                                # 13A7: E8 81 45
    jmp    L_13AF                                # 13AA: EB 03
L_13AC:
    mov    al,ds:CRTWID                            # 13AC: A0 29 00
L_13AF:
    .byte 0x8A, 0xE8 # 13AF
    inc    al                                    # 13B1: FE C0
    je     L_13D8                                # 13B3: 74 23
    call   ISFLIO                                # 13B5: E8 1E 1C
    je     L_13C1                                # 13B8: 74 07
    call   L_5923                                # 13BA: E8 66 45
    mov    al,BYTE PTR [bx]                      # 13BD: 8A 07
    jmp    L_13C4                                # 13BF: EB 03
L_13C1:
    call   PTRGPS                                # 13C1: E8 68 3B
L_13C4:
    pop    bx                                    # 13C4: 5B
    push   bx                                    # 13C5: 53
    .byte 0x0A, 0xC0 # 13C6
    je     L_13D8                                # 13C8: 74 0E
    add    al,BYTE PTR [bx]                      # 13CA: 02 07
    cmc                                          # 13CC: F5
    jae    L_13D3                                # 13CD: 73 04
    dec    al                                    # 13CF: FE C8
    .byte 0x3A, 0xC5 # 13D1
L_13D3:
    jb     L_13D8                                # 13D3: 72 03
    call   CRDO                                # 13D5: E8 99 18
L_13D8:
    pop    bx                                    # 13D8: 5B
    call   L_26BA                                # 13D9: E8 DE 12
    pop    bx                                    # 13DC: 5B
    jmp    L_134B                                # 13DD: E9 6B FF
L_13E0:
    int    0x9a                                  # 13E0: CD 9A
    mov    cx,0x32                               # 13E2: B9 32 00
    mov    bx,WORD PTR ds:PTRFIL                  # 13E5: 8B 1E E9 04
    .byte 0x03, 0xD9 # 13E9
    call   ISFLIO                                # 13EB: E8 E8 1B
    mov    al,BYTE PTR [bx]                      # 13EE: 8A 07
    jne    L_140A                                # 13F0: 75 18
    mov    al,ds:PRINT_ZONE_LIMIT                            # 13F2: A0 2A 00
    .byte 0x8A, 0xE8 # 13F5
    call   PTRGPS                                # 13F7: E8 32 3B
    cmp    al,0xff                               # 13FA: 3C FF
    je     L_140A                                # 13FC: 74 0C
    .byte 0x3A, 0xC5 # 13FE
    jb     L_1405                                # 1400: 72 03
    call   CRDO                                # 1402: E8 6C 18
L_1405:
    jb     L_140A                                # 1405: 72 03
    jmp    L_1491                                # 1407: E9 87 00
L_140A:
    sub    al,0xe                                # 140A: 2C 0E
    jae    L_140A                                # 140C: 73 FC
    not    al                                    # 140E: F6 D0
    jmp    L_1484                                # 1410: EB 72
L_1412:
    push   ax                                    # 1412: 50
    call   CHRGTR                                # 1413: E8 07 FB
    call   GETIN2                                # 1416: E8 F1 0A
    pop    ax                                    # 1419: 58
    push   ax                                    # 141A: 50
    cmp    al,0xd2                               # 141B: 3C D2
    je     L_1420                                # 141D: 74 01
    dec    dx                                    # 141F: 4A
L_1420:
    .byte 0x8A, 0xC6, 0x0A, 0xC0 # 1420
    js     L_1429                                # 1424: 78 03
    .byte 0xE9, 0x03, 0x00 # 1426
L_1429:
    mov    dx,0x0                                # 1429: BA 00 00
L_142C:
    push   bx                                    # 142C: 53
    call   ISFLIO                                # 142D: E8 A6 1B
    je     L_143F                                # 1430: 74 0D
    call   L_14D3                                # 1432: E8 9E 00
    js     L_143A                                # 1435: 78 03
    .byte 0xE9, 0x15, 0x00 # 1437
L_143A:
    call   L_592B                                # 143A: E8 EE 44
    jmp    L_1442                                # 143D: EB 03
L_143F:
    mov    al,ds:CRTWID                            # 143F: A0 29 00
L_1442:
    .byte 0x8A, 0xD8 # 1442
    inc    al                                    # 1444: FE C0
    je     L_144F                                # 1446: 74 07
    mov    bh,0x0                                # 1448: B7 00
    call   IMOD                                # 144A: E8 7C 51
    xchg   dx,bx                                 # 144D: 87 DA
L_144F:
    pop    bx                                    # 144F: 5B
    call   SYNCHR                                # 1450: E8 A1 19
    .byte ')'                                  # 1453: 29 -- SYNCHR inline operand
    .byte 0x4B, 0x58 # 1454 -- decoded continuation: dec    bx ; pop    ax
    sub    al,0xd2                               # 1456: 2C D2
    push   bx                                    # 1458: 53
    je     L_146E                                # 1459: 74 13
    mov    cx,0x32                               # 145B: B9 32 00
    mov    bx,WORD PTR ds:PTRFIL                  # 145E: 8B 1E E9 04
    .byte 0x03, 0xD9 # 1462
    call   ISFLIO                                # 1464: E8 6F 1B
    mov    al,BYTE PTR [bx]                      # 1467: 8A 07
    jne    L_146E                                # 1469: 75 03
    call   PTRGPS                                # 146B: E8 BE 3A
L_146E:
    not    al                                    # 146E: F6 D0
    .byte 0x02, 0xC2 # 1470
    jb     L_1484                                # 1472: 72 10
    inc    al                                    # 1474: FE C0
    je     L_1491                                # 1476: 74 19
    call   CRDO                                # 1478: E8 F6 17
    .byte 0x8A, 0xC2 # 147B
    dec    al                                    # 147D: FE C8
    jns    L_1484                                # 147F: 79 03
    .byte 0xE9, 0x0D, 0x00 # 1481
L_1484:
    inc    al                                    # 1484: FE C0
    .byte 0x8A, 0xE8 # 1486
    mov    al,0x20                               # 1488: B0 20
L_148A:
    call   OUTDO                                # 148A: E8 18 17
    dec    ch                                    # 148D: FE CD
    jne    L_148A                                # 148F: 75 F9
L_1491:
    pop    bx                                    # 1491: 5B
    call   CHRGTR                                # 1492: E8 88 FA
    jmp    L_1354                                # 1495: E9 BC FE
L_1498:
    int    0x9b                                  # 1498: CD 9B
    .byte 0x32, 0xC0 # 149A
    push   bx                                    # 149C: 53
    push   dx                                    # 149D: 52
    push   cx                                    # 149E: 51
    call   L_4128                                # 149F: E8 86 2C
    pop    cx                                    # 14A2: 59
    pop    dx                                    # 14A3: 5A
    .byte 0x32, 0xC0, 0x8A, 0xF8, 0x8A, 0xD8 # 14A4
    mov    WORD PTR ds:PTRFIL,bx                  # 14AA: 89 1E E9 04
    pop    bx                                    # 14AE: 5B
    ret                                          # 14AF: C3
L_14B0:
    push   bx                                    # 14B0: 53
    .byte 0x32, 0xC0 # 14B1
    lahf                                         # 14B3: 9F
    xchg   ah,al                                 # 14B4: 86 C4
    push   ax                                    # 14B6: 50
    xchg   ah,al                                 # 14B7: 86 C4
    call   GET_FILE_BLOCK                                # 14B9: E8 E9 2A
    je     L_14C1                                # 14BC: 74 03
    jmp    L_07A3                                # 14BE: E9 E2 F2
L_14C1:
    push   bx                                    # 14C1: 53
    mov    cx,0x2e                               # 14C2: B9 2E 00
    mov    dl,0x2                                # 14C5: B2 02
    mov    dh,0xfd                               # 14C7: B6 FD
    .byte 0x03, 0xD9 # 14C9
    mov    BYTE PTR [bx],dh                      # 14CB: 88 37
    mov    al,0x0                                # 14CD: B0 00
    pop    bx                                    # 14CF: 5B
    jmp    L_3EB9                                # 14D0: E9 E6 29
L_14D3:
    call   L_4309                                # 14D3: E8 33 2E
    .byte 0x0A, 0xC0 # 14D6
    ret                                          # 14D8: C3
LINE:
    cmp    al,0x85                               # 14D9: 3C 85
    je     L_14E0                                # 14DB: 74 03
    jmp    L_4882                                # 14DD: E9 A2 33
L_14E0:
    call   SYNCHR                                # 14E0: E8 11 19
    .byte TOK_INPUT                            # 14E3: 85 -- SYNCHR inline operand
    .byte 0x3C # 14E4 -- decoded continuation: cmp    al,0x23
    and    si,WORD PTR [di+0x3]                  # 14E5: 23 75 03
    jmp    L_4513                                # 14E8: E9 28 30
    .byte 0xE8, 0x30, 0x1D, 0xE8, 0x73, 0x00, 0xE8, 0x7A, 0x22, 0xE8, 0x44, 0x4F # 14EB
    .byte 0x52, 0x53, 0xE8, 0xA7, 0x1C, 0x5A, 0x59, 0x73, 0x03, 0xE9, 0x45, 0x19 # 14F7
    .byte 0x51, 0x52, 0xB5, 0x00, 0xE8, 0x45, 0x11, 0x5B, 0xB0, 0x03, 0xE9, 0x93 # 1503
    .byte 0xFC, 0x3F, 0x52, 0x65, 0x64, 0x6F, 0x20, 0x66, 0x72, 0x6F, 0x6D, 0x20 # 150F
    .byte 0x73, 0x74, 0x61, 0x72, 0x74, 0x0D, 0x00, 0x43, 0x8A, 0x07, 0x0A, 0xC0 # 151B
    .byte 0x75, 0x03, 0xE9, 0x92, 0xF2, 0x3C, 0x22, 0x75, 0xF2, 0xE9, 0x9B, 0x00 # 1527
    .byte 0x5B, 0x5B, 0xEB, 0x0C, 0xCD, 0x9C, 0xA0, 0x3A, 0x03, 0x0A, 0xC0, 0x74 # 1533
    .byte 0x03, 0xE9, 0x73, 0xF2, 0x59, 0xBB, 0x10, 0x15, 0xE8, 0x0B, 0x66, 0x8B # 153F
    .byte 0x1E, 0x43, 0x03 # 154B
L_154E:
    ret                                          # 154E: C3
L_154F:
    call   L_44E6                                # 154F: E8 94 2F
    push   bx                                    # 1552: 53
    mov    bx,0x1f6                              # 1553: BB F6 01
    jmp    L_1639                                # 1556: E9 E0 00
INPUT:
    cmp    al,0x23                               # 1559: 3C 23
    je     L_154F                                # 155B: 74 F2
    call   L_321E                                # 155D: E8 BE 1C
    mov    cx,0x158c                             # 1560: B9 8C 15
    push   cx                                    # 1563: 51
    cmp    al,0x22                               # 1564: 3C 22
    mov    al,0x0                                # 1566: B0 00
    mov    al,0xff                               # 1568: B0 FF
    mov    ds:TEMPA+1,al                           # 156A: A2 5F 04
    jne    L_154E                                # 156D: 75 DF
    call   L_264D                                # 156F: E8 DB 10
    mov    al,BYTE PTR [bx]                      # 1572: 8A 07
    cmp    al,0x2c                               # 1574: 3C 2C
    jne    L_1582                                # 1576: 75 0A
    .byte 0x32, 0xC0 # 1578
    mov    ds:TEMPA+1,al                           # 157A: A2 5F 04
    call   CHRGTR                                # 157D: E8 9D F9
    jmp    L_1586                                # 1580: EB 04
L_1582:
    call   SYNCHR                                # 1582: E8 6F 18
    .byte ';'                                  # 1585: 3B -- SYNCHR inline operand
L_1586:
    .byte 0x53, 0xE8, 0x30, 0x11 # 1586
    pop    bx                                    # 158A: 5B
    ret                                          # 158B: C3
    .byte 0x53, 0xA0, 0x5F, 0x04, 0x0A, 0xC0, 0x74, 0x0A, 0xB0, 0x3F, 0xE8, 0x0C # 158C
    .byte 0x16, 0xB0, 0x20, 0xE8, 0x07, 0x16, 0xE8, 0x02, 0x1C, 0x59, 0x73, 0x03 # 1598
    .byte 0xE9, 0xA1, 0x18, 0x51, 0x32, 0xC0, 0xA2, 0x3A, 0x03, 0xC6, 0x07, 0x2C # 15A4
    .byte 0x87, 0xDA, 0x5B, 0x53, 0x52, 0x52, 0x4B, 0xB0, 0x80, 0xA2, 0x39, 0x03 # 15B0
    .byte 0xE8, 0x5E, 0xF9, 0xE8, 0xA5, 0x22, 0x8A, 0x07, 0x4B, 0x3C, 0x28, 0x75 # 15BC
    .byte 0x20, 0x43, 0xB5, 0x00, 0xFE, 0xC5, 0xE8, 0x4C, 0xF9, 0x75, 0x03, 0xE9 # 15C8
    .byte 0xE8, 0xF1, 0x3C, 0x22, 0x75, 0x03, 0xE9, 0x45, 0xFF, 0x3C, 0x28, 0x74 # 15D4
    .byte 0xEB, 0x3C, 0x29, 0x75, 0xE9, 0xFE, 0xCD, 0x75, 0xE5, 0xE8, 0x31, 0xF9 # 15E0
    .byte 0x74, 0x07, 0x3C, 0x2C, 0x74, 0x03, 0xE9, 0xC9, 0xF1, 0x5E, 0x87, 0xDE # 15EC
    .byte 0x56, 0x8A, 0x07, 0x3C, 0x2C, 0x74, 0x03, 0xE9, 0x31, 0xFF, 0xB0, 0x01 # 15F8
    .byte 0xA2, 0xA9, 0x04, 0xE8, 0x62, 0x00, 0xA0, 0xA9, 0x04, 0xFE, 0xC8, 0x74 # 1604
    .byte 0x03, 0xE9, 0x1F, 0xFF, 0x53, 0xE8, 0x0D, 0x05, 0x75, 0x03, 0xE8, 0x8C # 1610
    .byte 0x12, 0x5B, 0x4B, 0xE8, 0xFB, 0xF8, 0x5E, 0x87, 0xDE, 0x56, 0x8A, 0x07 # 161C
    .byte 0x3C, 0x2C, 0x74, 0x8B, 0x5B, 0x4B, 0xE8, 0xEC, 0xF8, 0x0A, 0xC0, 0x5B # 1628
    .byte 0x74, 0x03, 0xE9, 0x0A, 0xFF # 1634
L_1639:
    mov    BYTE PTR [bx],0x2c                    # 1639: C6 07 2C
    jmp    L_1644                                # 163C: EB 06
READ:
    push   bx                                    # 163E: 53
    mov    bx,WORD PTR ds:DATPTR                  # 163F: 8B 1E 5E 03
    .byte 0x0D # 1643
L_1644:
    .byte 0x32, 0xC0 # 1644
    mov    ds:FLGINP,al                           # 1646: A2 3A 03
    pop    si                                    # 1649: 5E
    xchg   si,bx                                 # 164A: 87 DE
    push   si                                    # 164C: 56
    jmp    L_1653                                # 164D: EB 04
    call   SYNCHR                                # 164F: E8 A2 17
    .byte ','                                    # 1652: SYNCHR inline operand
L_1653:
    call   PTRGET                                # 1653: E8 18 21
    pop    si                                    # 1656: 5E
    xchg   si,bx                                 # 1657: 87 DE
    push   si                                    # 1659: 56
    push   dx                                    # 165A: 52
    mov    al,BYTE PTR [bx]                      # 165B: 8A 07
    cmp    al,0x2c                               # 165D: 3C 2C
    je     DATBK                                # 165F: 74 0A
    mov    al,ds:FLGINP                           # 1661: A0 3A 03
    .byte 0x0A, 0xC0 # 1664
    je     DATBK                                # 1666: 74 03
    jmp    L_16F6                                # 1668: E9 8B 00
DATBK:
    .byte 0x0D                                  # 166B: old Microsoft one-byte SKIP prefix; entering here forces AL nonzero
SCNVAL:
    .byte 0x32, 0xC0                          # 166C: XOR AL,AL exact historical encoding
    mov    ds:INPPAS,al                           # 166E: A2 52 04
    call   ISFLIO                                # 1671: E8 62 19
    je     L_1679                                # 1674: 74 03
    jmp    L_4504                                # 1676: E9 8B 2E
L_1679:
    call   GETYPR                                # 1679: E8 A9 04
    push   ax                                    # 167C: 50
    jne    L_16B7                                # 167D: 75 38
    call   CHRGTR                                # 167F: E8 9B F8
    .byte 0x8A, 0xF0, 0x8A, 0xE8 # 1682
    cmp    al,0x22                               # 1686: 3C 22
    je     L_1698                                # 1688: 74 0E
    mov    al,ds:FLGINP                           # 168A: A0 3A 03
    .byte 0x0A, 0xC0, 0x8A, 0xF0 # 168D
    je     L_1695                                # 1691: 74 02
    mov    dh,0x3a                               # 1693: B6 3A
L_1695:
    mov    ch,0x2c                               # 1695: B5 2C
    dec    bx                                    # 1697: 4B
L_1698:
    call   L_2651                                # 1698: E8 B6 0F
    pop    ax                                    # 169B: 58
    add    al,0x3                                # 169C: 04 03
    .byte 0x8A, 0xC8 # 169E
    mov    al,ds:INPPAS                           # 16A0: A0 52 04
    .byte 0x0A, 0xC0 # 16A3
    jne    L_16A8                                # 16A5: 75 01
    ret                                          # 16A7: C3
L_16A8:
    .byte 0x8A, 0xC1 # 16A8
    xchg   dx,bx                                 # 16AA: 87 DA
    mov    bx,0x16ca                             # 16AC: BB CA 16
    pop    si                                    # 16AF: 5E
    xchg   si,bx                                 # 16B0: 87 DE
    push   si                                    # 16B2: 56
    push   dx                                    # 16B3: 52
    jmp    L_11A7                                # 16B4: E9 F0 FA
L_16B7:
    call   CHRGTR                                # 16B7: E8 63 F8
    pop    ax                                    # 16BA: 58
    push   ax                                    # 16BB: 50
    cmp    al,0x5                                # 16BC: 3C 05
    mov    cx,0x169b                             # 16BE: B9 9B 16
    push   cx                                    # 16C1: 51
    jae    L_16C7                                # 16C2: 73 03
    jmp    L_69C0                                # 16C4: E9 F9 52
L_16C7:
    jmp    L_69C7                                # 16C7: E9 FD 52
    .byte 0x4B, 0xE8, 0x4F, 0xF8, 0x74, 0x07, 0x3C, 0x2C, 0x74, 0x03, 0xE9, 0x60 # 16CA
    .byte 0xFE, 0x5E, 0x87, 0xDE, 0x56, 0x4B, 0xE8, 0x3E, 0xF8, 0x74, 0x03, 0xE9 # 16D6
    .byte 0x6B, 0xFF, 0x5A, 0xA0, 0x3A, 0x03, 0x0A, 0xC0, 0x87, 0xDA, 0x74, 0x03 # 16E2
    .byte 0xE9, 0x35, 0x17, 0x52, 0x5B, 0xE9, 0xA2, 0xFD # 16EE
L_16F6:
    call   DATAS                                 # 16F6: E8 62 FA
    .byte 0x0A, 0xC0 # 16F9
    jne    L_1712                                # 16FB: 75 15
    inc    bx                                    # 16FD: 43
    mov    al,BYTE PTR [bx]                      # 16FE: 8A 07
    inc    bx                                    # 1700: 43
    or     al,BYTE PTR [bx]                      # 1701: 0A 07
    mov    dl,0x4                                # 1703: B2 04
    jne    L_170A                                # 1705: 75 03
    jmp    L_07D8                                # 1707: E9 CE F0
L_170A:
    inc    bx                                    # 170A: 43
    mov    dx,WORD PTR [bx]                      # 170B: 8B 17
    inc    bx                                    # 170D: 43
    mov    WORD PTR ds:DATLIN,dx                  # 170E: 89 16 37 03
L_1712:
    call   CHRGTR                                # 1712: E8 08 F8
    cmp    al,0x84                               # 1715: 3C 84
    jne    L_16F6                                # 1717: 75 DD
    jmp    DATBK                                # 1719: E9 4F FF
L_171C:
    call   SYNCHR                                # 171C: E8 D5 16
    .byte TK_EQUAL                             # 171F: E7 -- SYNCHR inline operand
    .byte 0xE9 # 1720 -- decoded continuation: jmp    0x1727
    add    al,0x0                                # 1721: 04 00
L_1723:
    call   SYNCHR                                # 1723: E8 CE 16
    .byte '('                                  # 1726: 28 -- SYNCHR inline operand
FRMEVL:
    dec    bx                                    # 1727: 4B
FRMCHK:
    mov    dh,0x00                               # 1728: B6 00
LPOPER:
    push   dx                                    # 172A: 52
    mov    cl,0x01                               # 172B: B1 01
    call   GETSTK                                # 172D: E8 A5 15
    int    0x9d                                  # 1730: CD 9D -- IBM ROM hook
    call   EVAL                                  # 1732: E8 B2 01
    .byte 0x32, 0xC0                             # 1735: XOR AL,AL; historical direction-bit encoding
    mov    ds:FLGOVC,al                          # 1737: A2 A8 04
TSTOP:
    mov    WORD PTR ds:TEMP2,bx                  # 173A: 89 1E 52 03
RETAOP:
    mov    bx,WORD PTR ds:TEMP2                  # 173E: 8B 1E 52 03
    pop    cx                                    # 1742: 59
NOTSTV:
    mov    al,BYTE PTR [bx]                      # 1743: 8A 07
    mov    WORD PTR ds:TEMP3,bx                  # 1745: 89 1E 31 03
    cmp    al,0xe6                               # 1749: 3C E6
    jae    L_174E                                # 174B: 73 01
L_174D:
    ret                                          # 174D: C3
L_174E:
    cmp    al,0xe9                               # 174E: 3C E9
    jb     L_17C7                                # 1750: 72 75
    sub    al,0xe9                               # 1752: 2C E9
    .byte 0x8A, 0xD0 # 1754
    jne    L_1764                                # 1756: 75 0C
    mov    al,ds:VALTYP                           # 1758: A0 FB 02
    cmp    al,0x3                                # 175B: 3C 03
    .byte 0x8A, 0xC2 # 175D
    jne    L_1764                                # 175F: 75 03
    jmp    L_283A                                # 1761: E9 D6 10
L_1764:
    cmp    al,0xc                                # 1764: 3C 0C
    jae    L_174D                                # 1766: 73 E5
    mov    bx,0x380                              # 1768: BB 80 03
    mov    dh,0x0                                # 176B: B6 00
    .byte 0x03, 0xDA, 0x8A, 0xC5 # 176D
    mov    dh,BYTE PTR cs:[bx]                   # 1771: 2E 8A 37
    .byte 0x3A, 0xC6 # 1774
    jae    L_174D                                # 1776: 73 D5
    push   cx                                    # 1778: 51
    mov    cx,0x173e                             # 1779: B9 3E 17
    push   cx                                    # 177C: 51
    .byte 0x8A, 0xC6 # 177D
    int    0x9e                                  # 177F: CD 9E
    cmp    al,0x7f                               # 1781: 3C 7F
    je     L_17E9                                # 1783: 74 64
    cmp    al,0x51                               # 1785: 3C 51
    jb     L_17F6                                # 1787: 72 6D
    and    al,0xfe                               # 1789: 24 FE
    cmp    al,0x7a                               # 178B: 3C 7A
    je     L_17F6                                # 178D: 74 67
L_178F:
    mov    al,ds:VALTYP                           # 178F: A0 FB 02
    sub    al,0x3                                # 1792: 2C 03
    jne    L_1799                                # 1794: 75 03
    jmp    L_07D6                                # 1796: E9 3D F0
L_1799:
    .byte 0x0A, 0xC0 # 1799
    push   WORD PTR ds:FACLO                     # 179B: FF 36 A3 04
    jns    L_17A4                                # 179F: 79 03
    .byte 0xE9, 0x11, 0x00 # 17A1
L_17A4:
    push   WORD PTR ds:FACSGN                     # 17A4: FF 36 A5 04
    jp     L_17AD                                # 17A8: 7A 03
    .byte 0xE9, 0x08, 0x00 # 17AA
L_17AD:
    push   WORD PTR ds:DFACL                     # 17AD: FF 36 9F 04
    push   WORD PTR ds:DFACL+2                     # 17B1: FF 36 A1 04
L_17B5:
    add    al,0x3                                # 17B5: 04 03
    .byte 0x8A, 0xCA, 0x8A, 0xE8 # 17B7
    push   cx                                    # 17BB: 51
    mov    cx,0x1823                             # 17BC: B9 23 18
L_17BF:
    push   cx                                    # 17BF: 51
    mov    bx,WORD PTR ds:TEMP3                  # 17C0: 8B 1E 31 03
    jmp    LPOPER                                # 17C4: E9 63 FF
L_17C7:
    mov    dh,0x0                                # 17C7: B6 00
L_17C9:
    sub    al,0xe6                               # 17C9: 2C E6
    jb     L_1801                                # 17CB: 72 34
    cmp    al,0x3                                # 17CD: 3C 03
    jae    L_1801                                # 17CF: 73 30
    cmp    al,0x1                                # 17D1: 3C 01
    rcl    al,1                                  # 17D3: D0 D0
    .byte 0x32, 0xC6, 0x3A, 0xC6, 0x8A, 0xF0 # 17D5
    jae    L_17E0                                # 17DB: 73 03
    jmp    SNERR                                 # 17DD: E9 DE EF
L_17E0:
    mov    WORD PTR ds:TEMP3,bx                  # 17E0: 89 1E 31 03
    call   CHRGTR                                # 17E4: E8 36 F7
    jmp    L_17C9                                # 17E7: EB E0
L_17E9:
    call   FRCSNG                                # 17E9: E8 65 53
    call   L_6426                                # 17EC: E8 37 4C
    mov    cx,0x6529                             # 17EF: B9 29 65
    mov    dh,0x7f                               # 17F2: B6 7F
    jmp    L_17BF                                # 17F4: EB C9
L_17F6:
    push   dx                                    # 17F6: 52
    call   FRCINT                                # 17F7: E8 B3 53
    pop    dx                                    # 17FA: 5A
    push   bx                                    # 17FB: 53
    mov    cx,0x1b31                             # 17FC: B9 31 1B
    jmp    L_17BF                                # 17FF: EB BE
L_1801:
    .byte 0x8A, 0xC5 # 1801
    cmp    al,0x64                               # 1803: 3C 64
    jb     L_1808                                # 1805: 72 01
    ret                                          # 1807: C3
L_1808:
    push   cx                                    # 1808: 51
    push   dx                                    # 1809: 52
    mov    dx,0x6404                             # 180A: BA 04 64
    mov    bx,0x1b03                             # 180D: BB 03 1B
    push   bx                                    # 1810: 53
    call   GETYPR                                # 1811: E8 11 03
    je     L_1819                                # 1814: 74 03
    jmp    L_178F                                # 1816: E9 76 FF
L_1819:
    mov    bx,WORD PTR ds:FACLO                  # 1819: 8B 1E A3 04
    push   bx                                    # 181D: 53
    mov    cx,0x25c8                             # 181E: B9 C8 25
    jmp    L_17BF                                # 1821: EB 9C
    .byte 0x59, 0x8A, 0xC1, 0xA2, 0xFC, 0x02, 0xA0, 0xFB, 0x02, 0x3A, 0xC5, 0x75 # 1823
    .byte 0x0D, 0x3C, 0x02, 0x74, 0x28, 0x3C, 0x04, 0x75, 0x03, 0xE9, 0x7F, 0x00 # 182F
    .byte 0x73, 0x39, 0x8A, 0xF0, 0x8A, 0xC5, 0x3C, 0x08, 0x74, 0x2E, 0x8A, 0xC6 # 183B
    .byte 0x3C, 0x08, 0x74, 0x57, 0x8A, 0xC5, 0x3C, 0x04, 0x74, 0x66, 0x8A, 0xC6 # 1847
    .byte 0x3C, 0x03, 0x75, 0x03, 0xE9, 0x7C, 0xEF, 0x73, 0x65, 0xBB, 0xAA, 0x03 # 1853
    .byte 0xB5, 0x00, 0x03, 0xD9, 0x03, 0xD9, 0x2E, 0x8A, 0x0F, 0x43, 0x2E, 0x8A # 185F
    .byte 0x2F, 0x5A, 0x8B, 0x1E, 0xA3, 0x04, 0x51, 0xC3, 0xE8, 0x0C, 0x53, 0xE8 # 186B
    .byte 0x25, 0x4C, 0x5B, 0x89, 0x1E, 0xA1, 0x04, 0x5B, 0x89, 0x1E, 0x9F, 0x04 # 1877
    .byte 0x59, 0x5A, 0xE8, 0x5A, 0x4B, 0xE8, 0xF7, 0x52, 0xBB, 0x96, 0x03, 0xA0 # 1883
    .byte 0xFC, 0x02, 0xD0, 0xC0, 0x02, 0xC3, 0x8A, 0xD8, 0x12, 0xC7, 0x2A, 0xC3 # 188F
    .byte 0x8A, 0xF8, 0x2E, 0x8B, 0x1F, 0xFF, 0xE3, 0x8A, 0xC5, 0x50, 0xE8, 0xF6 # 189B
    .byte 0x4B, 0x58, 0xA2, 0xFB, 0x02, 0x3C, 0x04, 0x74, 0xD3, 0x5B, 0x89, 0x1E # 18A7
    .byte 0xA3, 0x04, 0xEB, 0xD1, 0xE8, 0x97, 0x52, 0x59, 0x5A, 0xBB, 0xA0, 0x03 # 18B3
    .byte 0xEB, 0xCD, 0x5B, 0xE8, 0x61, 0x4B, 0xE8, 0x65, 0x4A, 0xE8, 0x28, 0x4B # 18BF
    .byte 0x5B, 0x89, 0x1E, 0xA5, 0x04, 0x5B, 0x89, 0x1E, 0xA3, 0x04, 0xEB, 0xE5 # 18CB
    .byte 0x53, 0x87, 0xDA, 0xE8, 0x50, 0x4A, 0x5B, 0xE8, 0x45, 0x4B, 0xE8, 0x49 # 18D7
    .byte 0x4A, 0xE9, 0x3B, 0x4C # 18E3
EVAL:
    call   CHRGTR                                # 18E7: E8 33 F6
    jne    L_18EF                                # 18EA: 75 03
    jmp    L_07D3                                # 18EC: E9 E4 EE
L_18EF:
    jae    L_18F4                                # 18EF: 73 03
    jmp    L_69C0                                # 18F1: E9 CC 50
L_18F4:
    call   ISLET2                                # 18F4: E8 4E 16
    jb     L_18FC                                # 18F7: 72 03
    jmp    L_19D7                                # 18F9: E9 DB 00
L_18FC:
    cmp    al,0x20                               # 18FC: 3C 20
    jae    L_1903                                # 18FE: 73 03
    jmp    L_0F82                                # 1900: E9 7F F6
L_1903:
    int    0x9f                                  # 1903: CD 9F
    inc    al                                    # 1905: FE C0
    jne    L_190C                                # 1907: 75 03
    jmp    L_1A76                                # 1909: E9 6A 01
L_190C:
    dec    al                                    # 190C: FE C8
    cmp    al,0xe9                               # 190E: 3C E9
    je     EVAL                                # 1910: 74 D5
    cmp    al,0xea                               # 1912: 3C EA
    jne    L_1919                                # 1914: 75 03
    jmp    L_19C8                                # 1916: E9 AF 00
L_1919:
    cmp    al,0x22                               # 1919: 3C 22
    jne    L_1920                                # 191B: 75 03
    jmp    L_264D                                # 191D: E9 2D 0D
L_1920:
    cmp    al,0xd3                               # 1920: 3C D3
    jne    L_1927                                # 1922: 75 03
    jmp    L_1B13                                # 1924: E9 EC 01
L_1927:
    cmp    al,0x26                               # 1927: 3C 26
    jne    L_192E                                # 1929: 75 03
    jmp    L_19FF                                # 192B: E9 D1 00
L_192E:
    cmp    al,0xd5                               # 192E: 3C D5
    jne    L_193E                                # 1930: 75 0C
    call   CHRGTR                                # 1932: E8 E8 F5
    mov    al,ds:ERRFLG                            # 1935: A0 28 00
    push   bx                                    # 1938: 53
    call   L_1B7F                                # 1939: E8 43 02
    pop    bx                                    # 193C: 5B
    ret                                          # 193D: C3
L_193E:
    cmp    al,0xd4                               # 193E: 3C D4
    jne    L_194F                                # 1940: 75 0D
    call   CHRGTR                                # 1942: E8 D8 F5
    push   bx                                    # 1945: 53
    mov    bx,WORD PTR ds:ERRLIN                  # 1946: 8B 1E 47 03
    call   L_6444                                # 194A: E8 F7 4A
    pop    bx                                    # 194D: 5B
    ret                                          # 194E: C3
L_194F:
    cmp    al,0xda                               # 194F: 3C DA
    jne    L_1981                                # 1951: 75 2E
    call   CHRGTR                                # 1953: E8 C7 F5
    call   SYNCHR                                # 1956: E8 9B 14
    .byte '('                                  # 1959: 28 -- SYNCHR inline operand
    .byte 0x3C # 195A -- decoded continuation: cmp    al,0x23
    and    si,WORD PTR [di+0xd]                  # 195B: 23 75 0D
    call   GTBYTC                                # 195E: E8 B8 05
    push   bx                                    # 1961: 53
    call   GET_FILE_BLOCK                                # 1962: E8 40 26
    xchg   dx,bx                                 # 1965: 87 DA
    pop    bx                                    # 1967: 5B
    .byte 0xE9, 0x03, 0x00, 0xE8, 0xF9, 0x1E # 1968
L_196E:
    call   SYNCHR                                # 196E: E8 83 14
    .byte ')'                                  # 1971: 29 -- SYNCHR inline operand
    .byte 0x53, 0x87 # 1972 -- decoded continuation: push   bx ; xchg   dx,bx
    fimul  DWORD PTR [bp+di]                     # 1974: DA 0B
    .byte 0xDB, 0x75, 0x03, 0xE9, 0xDD, 0xF6, 0xE8, 0x8D, 0x4B, 0x5B, 0xC3 # 1976
L_1981:
    cmp    al,0xd0                               # 1981: 3C D0
    jne    L_1988                                # 1983: 75 03
    jmp    USR                                # 1985: E9 00 02
L_1988:
    cmp    al,0xd8                               # 1988: 3C D8
    jne    L_198F                                # 198A: 75 03
    jmp    L_2A1A                                # 198C: E9 8B 10
L_198F:
    cmp    al,0xc8                               # 198F: 3C C8
    jne    L_1996                                # 1991: 75 03
    jmp    L_5566                                # 1993: E9 D0 3B
L_1996:
    cmp    al,0xdc                               # 1996: 3C DC
    jne    L_199D                                # 1998: 75 03
    jmp    L_47E9                                # 199A: E9 4C 2E
L_199D:
    cmp    al,0xde                               # 199D: 3C DE
    jne    L_19A4                                # 199F: 75 03
    jmp    L_2C9D                                # 19A1: E9 F9 12
L_19A4:
    cmp    al,0xd6                               # 19A4: 3C D6
    jne    L_19AB                                # 19A6: 75 03
    jmp    L_291B                                # 19A8: E9 70 0F
L_19AB:
    cmp    al,0x85                               # 19AB: 3C 85
    jne    L_19B2                                # 19AD: 75 03
    jmp    L_43EA                                # 19AF: E9 38 2A
L_19B2:
    cmp    al,0xdb                               # 19B2: 3C DB
    jne    L_19B9                                # 19B4: 75 03
    jmp    L_555D                                # 19B6: E9 A4 3B
L_19B9:
    cmp    al,0xd1                               # 19B9: 3C D1
    jne    L_19C0                                # 19BB: 75 03
    jmp    L_1C3E                                # 19BD: E9 7E 02
L_19C0:
    call   L_1723                                # 19C0: E8 60 FD
    call   SYNCHR                                # 19C3: E8 2E 14
    .byte ')'                                  # 19C6: 29 -- SYNCHR inline operand
    .byte 0xC3 # 19C7 -- decoded continuation: ret
L_19C8:
    mov    dh,0x7d                               # 19C8: B6 7D
    call   LPOPER                                # 19CA: E8 5D FD
    mov    bx,WORD PTR ds:TEMP2                  # 19CD: 8B 1E 52 03
    push   bx                                    # 19D1: 53
    call   VNEG                                # 19D2: E8 D6 63
    pop    bx                                    # 19D5: 5B
    ret                                          # 19D6: C3
L_19D7:
    call   PTRGET                                # 19D7: E8 94 1D
    push   bx                                    # 19DA: 53
    xchg   dx,bx                                 # 19DB: 87 DA
    mov    WORD PTR ds:FACLO,bx                  # 19DD: 89 1E A3 04
    call   GETYPR                                # 19E1: E8 41 01
    je     L_19E9                                # 19E4: 74 03
    call   L_6498                                # 19E6: E8 AF 4A
L_19E9:
    pop    bx                                    # 19E9: 5B
L_19EA:
    ret                                          # 19EA: C3
MAKUPL:
    mov    al,BYTE PTR [bx]                      # 19EB: 8A 07
MAKUPS:
    cmp    al,0x61                               # 19ED: 3C 61
    jb     L_19EA                                # 19EF: 72 F9
    cmp    al,0x7b                               # 19F1: 3C 7B
    jae    L_19EA                                # 19F3: 73 F5
    and    al,0x5f                               # 19F5: 24 5F
L_19F7:
    ret                                          # 19F7: C3
    .byte 0x3C, 0x26, 0x74, 0x03, 0xE9, 0x6C, 0xF6 # 19F8
L_19FF:
    mov    dx,0x0                                # 19FF: BA 00 00
    call   CHRGTR                                # 1A02: E8 18 F5
    call   MAKUPS                                # 1A05: E8 E5 FF
    cmp    al,0x4f                               # 1A08: 3C 4F
    je     L_1A45                                # 1A0A: 74 39
    cmp    al,0x48                               # 1A0C: 3C 48
    jne    L_1A44                                # 1A0E: 75 34
    mov    ch,0x5                                # 1A10: B5 05
L_1A12:
    inc    bx                                    # 1A12: 43
    mov    al,BYTE PTR [bx]                      # 1A13: 8A 07
    call   MAKUPS                                # 1A15: E8 D5 FF
    call   ISLET2                                # 1A18: E8 2A 15
    xchg   dx,bx                                 # 1A1B: 87 DA
    jae    L_1A29                                # 1A1D: 73 0A
    cmp    al,0x3a                               # 1A1F: 3C 3A
    jae    L_1A70                                # 1A21: 73 4D
    sub    al,0x30                               # 1A23: 2C 30
    jb     L_1A70                                # 1A25: 72 49
    jmp    L_1A2F                                # 1A27: EB 06
L_1A29:
    cmp    al,0x47                               # 1A29: 3C 47
    jae    L_1A70                                # 1A2B: 73 43
    sub    al,0x37                               # 1A2D: 2C 37
L_1A2F:
    .byte 0x03, 0xDB, 0x03, 0xDB, 0x03, 0xDB, 0x03, 0xDB, 0x0A, 0xC3, 0x8A, 0xD8 # 1A2F
    xchg   dx,bx                                 # 1A3B: 87 DA
    dec    ch                                    # 1A3D: FE CD
    jne    L_1A12                                # 1A3F: 75 D1
    jmp    L_07D0                                # 1A41: E9 8C ED
L_1A44:
    dec    bx                                    # 1A44: 4B
L_1A45:
    call   CHRGTR                                # 1A45: E8 D5 F4
    xchg   dx,bx                                 # 1A48: 87 DA
    jae    L_1A70                                # 1A4A: 73 24
    cmp    al,0x38                               # 1A4C: 3C 38
    jb     L_1A53                                # 1A4E: 72 03
    jmp    SNERR                                 # 1A50: E9 6B ED
L_1A53:
    mov    cx,0x7d0                              # 1A53: B9 D0 07
    push   cx                                    # 1A56: 51
    .byte 0x03, 0xDB # 1A57
    jb     L_19F7                                # 1A59: 72 9C
    .byte 0x03, 0xDB # 1A5B
    jb     L_19F7                                # 1A5D: 72 98
    .byte 0x03, 0xDB # 1A5F
    jb     L_19F7                                # 1A61: 72 94
    pop    cx                                    # 1A63: 59
    mov    ch,0x0                                # 1A64: B5 00
    sub    al,0x30                               # 1A66: 2C 30
    .byte 0x8A, 0xC8, 0x03, 0xD9 # 1A68
    xchg   dx,bx                                 # 1A6C: 87 DA
    jmp    L_1A45                                # 1A6E: EB D5
L_1A70:
    call   MAKINT                                # 1A70: E8 99 4A
    xchg   dx,bx                                 # 1A73: 87 DA
    ret                                          # 1A75: C3
L_1A76:
    inc    bx                                    # 1A76: 43
    mov    al,BYTE PTR [bx]                      # 1A77: 8A 07
    sub    al,0x81                               # 1A79: 2C 81
    cmp    al,0x7                                # 1A7B: 3C 07
    jne    L_1A8D                                # 1A7D: 75 0E
    push   bx                                    # 1A7F: 53
    call   CHRGTR                                # 1A80: E8 9A F4
    cmp    al,0x28                               # 1A83: 3C 28
    pop    bx                                    # 1A85: 5B
    je     L_1A8B                                # 1A86: 74 03
    jmp    L_646B                                # 1A88: E9 E0 49
L_1A8B:
    mov    al,0x7                                # 1A8B: B0 07
L_1A8D:
    mov    ch,0x0                                # 1A8D: B5 00
    rol    al,1                                  # 1A8F: D0 C0
    .byte 0x8A, 0xC8 # 1A91
    push   cx                                    # 1A93: 51
    call   CHRGTR                                # 1A94: E8 86 F4
    .byte 0x8A, 0xC1 # 1A97
    cmp    al,0x5                                # 1A99: 3C 05
    jae    L_1ABF                                # 1A9B: 73 22
    call   L_1723                                # 1A9D: E8 83 FC
    call   SYNCHR                                # 1AA0: E8 51 13
    .byte ','                                  # 1AA3: 2C -- SYNCHR inline operand
    .byte 0xE8 # 1AA4 -- decoded continuation: call   0x643b
    xchg   sp,ax                                 # 1AA5: 94
    dec    cx                                    # 1AA6: 49
    xchg   dx,bx                                 # 1AA7: 87 DA
    mov    bx,WORD PTR ds:FACLO                  # 1AA9: 8B 1E A3 04
    pop    si                                    # 1AAD: 5E
    xchg   si,bx                                 # 1AAE: 87 DE
    push   si                                    # 1AB0: 56
    push   bx                                    # 1AB1: 53
    xchg   dx,bx                                 # 1AB2: 87 DA
    call   GETBYT                                # 1AB4: E8 65 04
    xchg   dx,bx                                 # 1AB7: 87 DA
    pop    si                                    # 1AB9: 5E
    xchg   si,bx                                 # 1ABA: 87 DE
    push   si                                    # 1ABC: 56
    jmp    L_1AE0                                # 1ABD: EB 21
L_1ABF:
    call   L_19C0                                # 1ABF: E8 FE FE
    pop    si                                    # 1AC2: 5E
    xchg   si,bx                                 # 1AC3: 87 DE
    push   si                                    # 1AC5: 56
    .byte 0x8A, 0xC3 # 1AC6
    cmp    al,0xc                                # 1AC8: 3C 0C
    jb     L_1AD7                                # 1ACA: 72 0B
    cmp    al,0x1b                               # 1ACC: 3C 1B
    int    0xa1                                  # 1ACE: CD A1
    push   bx                                    # 1AD0: 53
    jae    L_1AD6                                # 1AD1: 73 03
    call   FRCSNG                                # 1AD3: E8 7B 50
L_1AD6:
    pop    bx                                    # 1AD6: 5B
L_1AD7:
    mov    dx,0x19d5                             # 1AD7: BA D5 19
    push   dx                                    # 1ADA: 52
    mov    al,0x1                                # 1ADB: B0 01
    mov    ds:FLGOVC,al                           # 1ADD: A2 A8 04
L_1AE0:
    mov    cx,0xb9                               # 1AE0: B9 B9 00
    int    0xa0                                  # 1AE3: CD A0
L_1AE5:
    .byte 0x03, 0xD9 # 1AE5
    jmp    WORD PTR cs:[bx]                      # 1AE7: 2E FF 27
    .byte 0xFE, 0xCE, 0x3C, 0xEA, 0x74, 0x85, 0x3C, 0x2D, 0x74, 0x81, 0xFE, 0xC6 # 1AEA
    .byte 0x3C, 0x2B, 0x75, 0x01, 0xC3, 0x3C, 0xE9, 0x74, 0xFB, 0x9F, 0x4B, 0x9E # 1AF6
    .byte 0xC3, 0xFE, 0xC0, 0x12, 0xC0, 0x59, 0x22, 0xC5, 0x04, 0xFF, 0x1A, 0xC0 # 1B02
    .byte 0xE8, 0xF8, 0x49, 0xEB, 0x0F # 1B0E
L_1B13:
    mov    dh,0x5a                               # 1B13: B6 5A
    call   LPOPER                                # 1B15: E8 12 FC
    call   FRCINT                                # 1B18: E8 92 50
    not    bx                                    # 1B1B: F7 D3
    mov    WORD PTR ds:FACLO,bx                  # 1B1D: 89 1E A3 04
    pop    cx                                    # 1B21: 59
    jmp    RETAOP                                # 1B22: E9 19 FC
GETYPR:
    mov    al,ds:VALTYP                           # 1B25: A0 FB 02
    cmp    al,0x8                                # 1B28: 3C 08
    dec    al                                    # 1B2A: FE C8
    dec    al                                    # 1B2C: FE C8
    dec    al                                    # 1B2E: FE C8
    ret                                          # 1B30: C3
    .byte 0x8A, 0xC5, 0x50, 0xE8, 0x76, 0x50, 0x58, 0x5A, 0x3C, 0x7A, 0x75, 0x03 # 1B31
    .byte 0xE9, 0x89, 0x4A, 0x3C, 0x7B, 0x75, 0x03, 0xE9, 0x66, 0x48, 0xB9, 0x0C # 1B3D
    .byte 0x65, 0x51, 0x3C, 0x46, 0x75, 0x03, 0x0B, 0xDA, 0xC3, 0x3C, 0x50, 0x75 # 1B49
    .byte 0x03, 0x23, 0xDA, 0xC3, 0x3C, 0x3C, 0x75, 0x03, 0x33, 0xDA, 0xC3, 0x3C # 1B55
    .byte 0x32, 0x75, 0x05, 0x33, 0xDA, 0xF7, 0xD3, 0xC3, 0xF7, 0xD3, 0x23, 0xDA # 1B61
    .byte 0xF7, 0xD3, 0xC3 # 1B6D
L_1B70:
    .byte 0x2B, 0xDA # 1B70
    jmp    L_6444                                # 1B72: E9 CF 48
LPOS:
    mov    al,ds:LPT_POSITION                            # 1B75: A0 63 00
    jmp    L_1B7D                                # 1B78: EB 03
POS:
    call   PTRGPS                                # 1B7A: E8 AF 33
L_1B7D:
    inc    al                                    # 1B7D: FE C0
L_1B7F:
    .byte 0x8A, 0xD8, 0x32, 0xC0, 0x8A, 0xF8 # 1B7F
    jmp    MAKINT                                # 1B85: E9 84 49
# USR dispatch. C1.10 compares only DL with FFh. C1.20 attempts a full
# DX==FFFFh sentinel test, but the supplied C1.20 bytes also consume the
# following JNZ opcode; keep that C1.20 anomaly open pending independent proof.
USR:
    call   SCNUSR                                # 1B88: E8 2E 00
    push   dx                                    # 1B8B: 52
    call   L_19C0                                # 1B8C: E8 31 FE
    pop    si                                    # 1B8F: 5E
    xchg   si,bx                                 # 1B90: 87 DE
    push   si                                    # 1B92: 56
    mov    dx,WORD PTR [bx]                      # 1B93: 8B 17
    cmp    dl,0xff                               # 1B95: 80 FA FF
    jne    L_1B9D                                # 1B98: 75 03
    jmp    FCERR                                # 1B9A: E9 BC F4
L_1B9D:
    push   cs                                    # 1B9D: 0E
    mov    bx,0x6507                             # 1B9E: BB 07 65
    push   bx                                    # 1BA1: 53
    push   WORD PTR ds:SAVSEG                     # 1BA2: FF 36 50 03
    push   dx                                    # 1BA6: 52
    mov    al,ds:VALTYP                           # 1BA7: A0 FB 02
    push   ax                                    # 1BAA: 50
    cmp    al,0x3                                # 1BAB: 3C 03
    jne    L_1BB2                                # 1BAD: 75 03
    call   L_28A9                                # 1BAF: E8 F7 0C
L_1BB2:
    pop    ax                                    # 1BB2: 58
    xchg   dx,bx                                 # 1BB3: 87 DA
    mov    bx,0x4a3                              # 1BB5: BB A3 04
    retf                                         # 1BB8: CB
SCNUSR:
    call   CHRGTR                                # 1BB9: E8 61 F3
    mov    cx,0x0                                # 1BBC: B9 00 00
    cmp    al,0x1b                               # 1BBF: 3C 1B
    jae    L_1BD3                                # 1BC1: 73 10
    cmp    al,0x11                               # 1BC3: 3C 11
    jb     L_1BD3                                # 1BC5: 72 0C
    call   CHRGTR                                # 1BC7: E8 53 F3
    mov    al,ds:CONLO                           # 1BCA: A0 02 03
    .byte 0x0A, 0xC0 # 1BCD
    rcl    al,1                                  # 1BCF: D0 D0
    .byte 0x8A, 0xC8 # 1BD1
L_1BD3:
    xchg   dx,bx                                 # 1BD3: 87 DA
    mov    bx,0x12                               # 1BD5: BB 12 00
    .byte 0x03, 0xD9 # 1BD8
    xchg   dx,bx                                 # 1BDA: 87 DA
    ret                                          # 1BDC: C3
DEFUSR:
    call   SCNUSR                                # 1BDD: E8 D9 FF
    push   dx                                    # 1BE0: 52
    call   SYNCHR                                # 1BE1: E8 10 12
    .byte TK_EQUAL                             # 1BE4: E7 -- SYNCHR inline operand
    .byte 0xE8 # 1BE5 -- decoded continuation: call   0x22aa
    ret    0x5e06                                # 1BE6: C2 06 5E
    .byte 0x87, 0xDE, 0x56, 0x89, 0x17, 0x5B, 0xC3 # 1BE9
DEF:
    cmp    al,0xd0                               # 1BF0: 3C D0
    je     DEFUSR                                # 1BF2: 74 E9
    cmp    al,0xd1                               # 1BF4: 3C D1
    je     L_1C14                                # 1BF6: 74 1C
    call   SYNCHR                                # 1BF8: E8 F9 11
    .byte 'S'                                  # 1BFB: 53 -- SYNCHR inline operand
    call   SYNCHR                                # 1BFC: E8 F5 11
    .byte 'E'                                  # 1BFF: 45 -- SYNCHR inline operand
    call   SYNCHR                                # 1C00: E8 F1 11
    .byte 'G'                                  # 1C03: 47 -- SYNCHR inline operand
    mov    dx,ds                                 # 1C04: 8C DA
    je     L_1C0F                                # 1C06: 74 07
    call   SYNCHR                                # 1C08: E8 E9 11
    .byte TK_EQUAL                             # 1C0B: E7 -- SYNCHR inline operand
    .byte 0xE8 # 1C0C -- decoded continuation: call   0x22aa
    fwait                                        # 1C0D: 9B
    push   es                                    # 1C0E: 06
L_1C0F:
    mov    WORD PTR ds:SAVSEG,dx                  # 1C0F: 89 16 50 03
    ret                                          # 1C13: C3
L_1C14:
    call   L_1E0A                                # 1C14: E8 F3 01
    call   L_1DFA                                # 1C17: E8 E0 01
    xchg   dx,bx                                 # 1C1A: 87 DA
    mov    WORD PTR [bx],dx                      # 1C1C: 89 17
    xchg   dx,bx                                 # 1C1E: 87 DA
    mov    al,BYTE PTR [bx]                      # 1C20: 8A 07
    cmp    al,0x28                               # 1C22: 3C 28
    je     L_1C29                                # 1C24: 74 03
    jmp    DATAS                                 # 1C26: E9 32 F5
L_1C29:
    call   CHRGTR                                # 1C29: E8 F1 F2
    call   PTRGET                                # 1C2C: E8 3F 1B
    mov    al,BYTE PTR [bx]                      # 1C2F: 8A 07
    cmp    al,0x29                               # 1C31: 3C 29
    jne    L_1C38                                # 1C33: 75 03
    jmp    DATAS                                 # 1C35: E9 23 F5
L_1C38:
    call   SYNCHR                                # 1C38: E8 B9 11
    .byte ','                                  # 1C3B: 2C -- SYNCHR inline operand
    .byte 0xEB # 1C3C -- decoded continuation: jmp    0x1c2c
    out    dx,al                                 # 1C3D: EE
L_1C3E:
    call   L_1E0A                                # 1C3E: E8 C9 01
    mov    al,ds:VALTYP                           # 1C41: A0 FB 02
    .byte 0x0A, 0xC0 # 1C44
    push   ax                                    # 1C46: 50
    mov    WORD PTR ds:TEMP2,bx                  # 1C47: 89 1E 52 03
    xchg   dx,bx                                 # 1C4B: 87 DA
    mov    bx,WORD PTR [bx]                      # 1C4D: 8B 1F
    .byte 0x0B, 0xDB # 1C4F
    jne    L_1C56                                # 1C51: 75 03
    jmp    L_07CA                                # 1C53: E9 74 EB
L_1C56:
    mov    al,BYTE PTR [bx]                      # 1C56: 8A 07
    cmp    al,0x28                               # 1C58: 3C 28
    je     L_1C5F                                # 1C5A: 74 03
    jmp    FINVLS                                # 1C5C: E9 CE 00
L_1C5F:
    call   CHRGTR                                # 1C5F: E8 BB F2
    mov    WORD PTR ds:TEMP3,bx                  # 1C62: 89 1E 31 03
    xchg   dx,bx                                 # 1C66: 87 DA
    mov    bx,WORD PTR ds:TEMP2                  # 1C68: 8B 1E 52 03
    call   SYNCHR                                # 1C6C: E8 85 11
    .byte '('                                  # 1C6F: 28 -- SYNCHR inline operand
    .byte 0x32, 0xC0                            # 1C70: XOR AL,AL; historical direction-bit encoding
    push   ax                                     # 1C72: 50
    push   bx                                     # 1C73: 53
    xchg   dx,bx                                  # 1C74: 87 DA
    mov    al,0x80                                # 1C76: B0 80
    mov    ds:SUBFLG,al                           # 1C78: A2 39 03
    call   PTRGET                                # 1C7B: E8 F0 1A
    xchg   dx,bx                                 # 1C7E: 87 DA
    pop    si                                    # 1C80: 5E
    xchg   si,bx                                 # 1C81: 87 DE
    push   si                                    # 1C83: 56
    mov    al,ds:VALTYP                           # 1C84: A0 FB 02
    push   ax                                    # 1C87: 50
    push   dx                                    # 1C88: 52
    call   FRMEVL                                # 1C89: E8 9B FA
    mov    WORD PTR ds:TEMP2,bx                  # 1C8C: 89 1E 52 03
    pop    bx                                    # 1C90: 5B
    mov    WORD PTR ds:TEMP3,bx                  # 1C91: 89 1E 31 03
    pop    ax                                    # 1C95: 58
    call   L_1DDA                                # 1C96: E8 41 01
    mov    cl,0x4                                # 1C99: B1 04
    call   GETSTK                                # 1C9B: E8 37 10
    mov    bx,0xfff8                             # 1C9E: BB F8 FF
    .byte 0x03, 0xDC, 0x8B, 0xE3 # 1CA1
    call   L_64A1                                # 1CA5: E8 F9 47
    mov    al,ds:VALTYP                           # 1CA8: A0 FB 02
    push   ax                                    # 1CAB: 50
    mov    bx,WORD PTR ds:TEMP2                  # 1CAC: 8B 1E 52 03
    mov    al,BYTE PTR [bx]                      # 1CB0: 8A 07
    cmp    al,0x29                               # 1CB2: 3C 29
    je     L_1CC9                                # 1CB4: 74 13
    call   SYNCHR                                # 1CB6: E8 3B 11
    .byte ','                                  # 1CB9: 2C -- SYNCHR inline operand
    .byte 0x53 # 1CBA -- decoded continuation: push   bx
    mov    bx,WORD PTR ds:TEMP3                  # 1CBB: 8B 1E 31 03
    call   SYNCHR                                # 1CBF: E8 32 11
    .byte ','                                  # 1CC2: 2C -- SYNCHR inline operand
    .byte 0xEB # 1CC3 -- decoded continuation: jmp    0x1c76
    mov    cl,0x58                               # 1CC4: B1 58
    mov    ds:PRMLN2,al                           # 1CC6: A2 E4 03
L_1CC9:
    pop    ax                                    # 1CC9: 58
    .byte 0x0A, 0xC0 # 1CCA
    je     L_1D1C                                # 1CCC: 74 4E
    mov    ds:VALTYP,al                           # 1CCE: A2 FB 02
    mov    bx,0x0                                # 1CD1: BB 00 00
    .byte 0x03, 0xDC # 1CD4
    call   L_6498                                # 1CD6: E8 BF 47
    mov    bx,0x8                                # 1CD9: BB 08 00
    .byte 0x03, 0xDC, 0x8B, 0xE3 # 1CDC
    pop    dx                                    # 1CE0: 5A
    mov    bl,0x3                                # 1CE1: B3 03
L_1CE3:
    inc    bl                                    # 1CE3: FE C3
    dec    dx                                    # 1CE5: 4A
    .byte 0x8B, 0xF2 # 1CE6
    lods   al,BYTE PTR ds:[si]                   # 1CE8: AC
    .byte 0x0A, 0xC0 # 1CE9
    js     L_1CE3                                # 1CEB: 78 F6
    dec    dx                                    # 1CED: 4A
    dec    dx                                    # 1CEE: 4A
    dec    dx                                    # 1CEF: 4A
    mov    al,ds:VALTYP                           # 1CF0: A0 FB 02
    .byte 0x02, 0xC3, 0x8A, 0xE8 # 1CF3
    mov    al,ds:PRMLN2                           # 1CF7: A0 E4 03
    .byte 0x8A, 0xC8, 0x02, 0xC5 # 1CFA
    cmp    al,0x64                               # 1CFE: 3C 64
    jb     L_1D05                                # 1D00: 72 03
    jmp    FCERR                                # 1D02: E9 54 F3
L_1D05:
    push   ax                                    # 1D05: 50
    .byte 0x8A, 0xC3 # 1D06
    mov    ch,0x0                                # 1D08: B5 00
    mov    bx,0x3e6                              # 1D0A: BB E6 03
    .byte 0x03, 0xD9, 0x8A, 0xC8 # 1D0D
    call   L_1DF3                                # 1D11: E8 DF 00
    mov    cx,0x1cc5                             # 1D14: B9 C5 1C
    push   cx                                    # 1D17: 51
    push   cx                                    # 1D18: 51
    jmp    L_11B5                                # 1D19: E9 99 F4
L_1D1C:
    mov    bx,WORD PTR ds:TEMP2                  # 1D1C: 8B 1E 52 03
    call   CHRGTR                                # 1D20: E8 FA F1
    push   bx                                    # 1D23: 53
    mov    bx,WORD PTR ds:TEMP3                  # 1D24: 8B 1E 31 03
    call   SYNCHR                                # 1D28: E8 C9 10
    .byte ')'                                  # 1D2B: 29 -- SYNCHR inline operand
    .byte 0xB0 # 1D2C -- decoded continuation: mov    al,0x52
# C1.20 changes the ROR below to SHR when converting the parameter-frame
# byte count to a word count. This is a source-level C1.10->C1.20 fix/hardening.
FINVLS:
    .byte 0x52, 0x89, 0x1E, 0x31, 0x03 # 1D2D
    mov    al,ds:PRMLEN                           # 1D32: A0 7C 03
    add    al,0x4                                # 1D35: 04 04
    push   ax                                    # 1D37: 50
    ror    al,1                                  # 1D38: D0 C8
    .byte 0x8A, 0xC8 # 1D3A
    call   GETSTK                                # 1D3C: E8 96 0F
    pop    ax                                    # 1D3F: 58
    .byte 0x8A, 0xC8 # 1D40
    not    al                                    # 1D42: F6 D0
    inc    al                                    # 1D44: FE C0
    .byte 0x8A, 0xD8 # 1D46
    mov    bh,0xff                               # 1D48: B7 FF
    .byte 0x03, 0xDC, 0x8B, 0xE3 # 1D4A
    push   bx                                    # 1D4E: 53
    mov    dx,0x37a                              # 1D4F: BA 7A 03
    call   L_1DF3                                # 1D52: E8 9E 00
    pop    bx                                    # 1D55: 5B
    mov    WORD PTR ds:PRMSTK,bx                  # 1D56: 89 1E 7A 03
    mov    bx,WORD PTR ds:PRMLN2                  # 1D5A: 8B 1E E4 03
    mov    WORD PTR ds:PRMLEN,bx                  # 1D5E: 89 1E 7C 03
    .byte 0x8B, 0xCB # 1D62
    mov    bx,0x37e                              # 1D64: BB 7E 03
    mov    dx,0x3e6                              # 1D67: BA E6 03
    call   L_1DF3                                # 1D6A: E8 86 00
    .byte 0x8A, 0xF8, 0x8A, 0xD8 # 1D6D
    mov    WORD PTR ds:PRMLN2,bx                  # 1D71: 89 1E E4 03
    mov    bx,WORD PTR ds:FUNACT                  # 1D75: 8B 1E 50 04
    inc    bx                                    # 1D79: 43
    mov    WORD PTR ds:FUNACT,bx                  # 1D7A: 89 1E 50 04
    .byte 0x8A, 0xC7, 0x0A, 0xC3 # 1D7E
    mov    ds:NOFUNS,al                           # 1D82: A2 4D 04
    mov    bx,WORD PTR ds:TEMP3                  # 1D85: 8B 1E 31 03
    call   L_171C                                # 1D89: E8 90 F9
    dec    bx                                    # 1D8C: 4B
    call   CHRGTR                                # 1D8D: E8 8D F1
    je     L_1D95                                # 1D90: 74 03
    jmp    SNERR                                 # 1D92: E9 29 EA
L_1D95:
    call   GETYPR                                # 1D95: E8 8D FD
    jne    L_1DAB                                # 1D98: 75 11
    mov    dx,0x32c                              # 1D9A: BA 2C 03
    mov    bx,WORD PTR ds:FACLO                  # 1D9D: 8B 1E A3 04
    .byte 0x3B, 0xDA # 1DA1
    jb     L_1DAB                                # 1DA3: 72 06
    call   L_2624                                # 1DA5: E8 7C 08
    call   PUTTMP                                # 1DA8: E8 E6 08
L_1DAB:
    mov    bx,WORD PTR ds:PRMSTK                  # 1DAB: 8B 1E 7A 03
    .byte 0x8A, 0xF7, 0x8A, 0xD3 # 1DAF
    inc    bx                                    # 1DB3: 43
    inc    bx                                    # 1DB4: 43
    mov    cl,BYTE PTR [bx]                      # 1DB5: 8A 0F
    inc    bx                                    # 1DB7: 43
    mov    ch,BYTE PTR [bx]                      # 1DB8: 8A 2F
    inc    cx                                    # 1DBA: 41
    inc    cx                                    # 1DBB: 41
    inc    cx                                    # 1DBC: 41
    inc    cx                                    # 1DBD: 41
    mov    bx,0x37a                              # 1DBE: BB 7A 03
    call   L_1DF3                                # 1DC1: E8 2F 00
    xchg   dx,bx                                 # 1DC4: 87 DA
    .byte 0x8B, 0xE3 # 1DC6
    mov    bx,WORD PTR ds:FUNACT                  # 1DC8: 8B 1E 50 04
    dec    bx                                    # 1DCC: 4B
    mov    WORD PTR ds:FUNACT,bx                  # 1DCD: 89 1E 50 04
    .byte 0x8A, 0xC7, 0x0A, 0xC3 # 1DD1
    mov    ds:NOFUNS,al                           # 1DD5: A2 4D 04
    pop    bx                                    # 1DD8: 5B
    pop    ax                                    # 1DD9: 58
L_1DDA:
    push   bx                                    # 1DDA: 53
    and    al,0x7                                # 1DDB: 24 07
    mov    bx,0x38c                              # 1DDD: BB 8C 03
    .byte 0x8A, 0xC8 # 1DE0
    mov    ch,0x0                                # 1DE2: B5 00
    .byte 0x03, 0xD9 # 1DE4
    call   L_1AE5                                # 1DE6: E8 FC FC
    pop    bx                                    # 1DE9: 5B
    ret                                          # 1DEA: C3
L_1DEB:
    .byte 0x8B, 0xF2 # 1DEB
    lods   al,BYTE PTR ds:[si]                   # 1DED: AC
    mov    BYTE PTR [bx],al                      # 1DEE: 88 07
    inc    bx                                    # 1DF0: 43
    inc    dx                                    # 1DF1: 42
    dec    cx                                    # 1DF2: 49
L_1DF3:
    .byte 0x8A, 0xC5, 0x0A, 0xC1 # 1DF3
    jne    L_1DEB                                # 1DF7: 75 F2
L_1DF9:
    ret                                          # 1DF9: C3
L_1DFA:
    push   bx                                    # 1DFA: 53
    mov    bx,WORD PTR ds:CURLIN                   # 1DFB: 8B 1E 2E 00
    inc    bx                                    # 1DFF: 43
    .byte 0x0B, 0xDB # 1E00
    pop    bx                                    # 1E02: 5B
    jne    L_1DF9                                # 1E03: 75 F4
    mov    dl,0xc                                # 1E05: B2 0C
    jmp    L_07D8                                # 1E07: E9 CE E9
L_1E0A:
    call   SYNCHR                                # 1E0A: E8 E7 0F
    .byte TOK_FN                               # 1E0D: D1 -- SYNCHR inline operand
    .byte 0xB0, 0x80, 0xA2 # 1E0E -- decoded continuation: mov    al,0x80 ; mov    ds:SUBFLG,al
    cmp    WORD PTR [bp+di],ax                   # 1E11: 39 03
    or     al,BYTE PTR [bx]                      # 1E13: 0A 07
    .byte 0x8A, 0xC8 # 1E15
    jmp    PTRGT2                                # 1E17: E9 5B 19
L_1E1A:
    cmp    al,0x7e                               # 1E1A: 3C 7E
    je     L_1E21                                # 1E1C: 74 03
    jmp    SNERR                                 # 1E1E: E9 9D E9
L_1E21:
    inc    bx                                    # 1E21: 43
    mov    al,BYTE PTR [bx]                      # 1E22: 8A 07
    inc    bx                                    # 1E24: 43
    cmp    al,0x83                               # 1E25: 3C 83
    jne    L_1E2C                                # 1E27: 75 03
    jmp    L_2AD0                                # 1E29: E9 A4 0C
L_1E2C:
    cmp    al,0xa0                               # 1E2C: 3C A0
    jne    L_1E33                                # 1E2E: 75 03
    jmp    L_55E2                                # 1E30: E9 AF 37
L_1E33:
    cmp    al,0xa2                               # 1E33: 3C A2
    jne    L_1E3A                                # 1E35: 75 03
    jmp    L_56FA                                # 1E37: E9 C0 38
L_1E3A:
    jmp    SNERR                                 # 1E3A: E9 81 E9
FNINP:
    call   L_22B5                                # 1E3D: E8 75 04
    xchg   dx,bx                                 # 1E40: 87 DA
    in     al,dx                                 # 1E42: EC
    jmp    L_1B7F                                # 1E43: E9 39 FD
L_1E46:
    call   L_22AA                                # 1E46: E8 61 04
    push   dx                                    # 1E49: 52
    call   SYNCHR                                # 1E4A: E8 A7 0F
    .byte ','                                  # 1E4D: 2C -- SYNCHR inline operand
    .byte 0xE8 # 1E4E -- decoded continuation: call   0x1f1c
    retf                                         # 1E4F: CB
    .byte 0x00, 0x5A, 0xC3 # 1E50
FNOUT:
    call   L_1E46                                # 1E53: E8 F0 FF
    out    dx,al                                 # 1E56: EE
    ret                                          # 1E57: C3
FNWAIT:
    call   L_1E46                                # 1E58: E8 EB FF
    push   dx                                    # 1E5B: 52
    push   ax                                    # 1E5C: 50
    mov    dl,0x0                                # 1E5D: B2 00
    dec    bx                                    # 1E5F: 4B
    call   CHRGTR                                # 1E60: E8 BA F0
    je     L_1E6C                                # 1E63: 74 07
    call   SYNCHR                                # 1E65: E8 8C 0F
    .byte ','                                  # 1E68: 2C -- SYNCHR inline operand
    .byte 0xE8 # 1E69 -- decoded continuation: call   0x1f1c
    mov    al,0x0                                # 1E6A: B0 00
L_1E6C:
    pop    ax                                    # 1E6C: 58
    .byte 0x8A, 0xF0 # 1E6D
    pop    si                                    # 1E6F: 5E
    xchg   si,bx                                 # 1E70: 87 DE
    push   si                                    # 1E72: 56
L_1E73:
    mov    al,ds:CTRL_BREAK_PENDING                            # 1E73: A0 5E 00
    .byte 0x0A, 0xC0 # 1E76
    jne    L_1E85                                # 1E78: 75 0B
    xchg   dx,bx                                 # 1E7A: 87 DA
    in     al,dx                                 # 1E7C: EC
    xchg   dx,bx                                 # 1E7D: 87 DA
    .byte 0x32, 0xC2, 0x22, 0xC6 # 1E7F
    je     L_1E73                                # 1E83: 74 EE
L_1E85:
    pop    bx                                    # 1E85: 5B
    ret                                          # 1E86: C3
    .byte 0xE9, 0x34, 0xE9 # 1E87
WIDTHS:
    cmp    al,0x23                               # 1E8A: 3C 23
    je     L_1ECA                                # 1E8C: 74 3C
    call   FRMEVL                                # 1E8E: E8 96 F8
    call   GETYPR                                # 1E91: E8 91 FC
    jne    L_1EEE                                # 1E94: 75 58
    call   L_3F16                                # 1E96: E8 7D 20
    .byte 0x8A, 0xC6 # 1E99
    mov    dh,0x0                                # 1E9B: B6 00
    not    al                                    # 1E9D: F6 D0
    .byte 0x0A, 0xC0 # 1E9F
    jns    L_1EA6                                # 1EA1: 79 03
    jmp    FCERR                                # 1EA3: E9 B3 F1
L_1EA6:
    .byte 0x8A, 0xD0 # 1EA6
    push   dx                                    # 1EA8: 52
    call   SYNCHR                                # 1EA9: E8 48 0F
    .byte ','                                  # 1EAC: 2C -- SYNCHR inline operand
    call   GETBYT                                # 1EAD: E8 6C 00
    pop    dx                                     # 1EB0: 5A
    lahf                                          # 1EB1: 9F
    xchg   ah,al                                 # 1EB2: 86 C4
    push   ax                                    # 1EB4: 50
    xchg   ah,al                                 # 1EB5: 86 C4
    push   bx                                    # 1EB7: 53
    push   dx                                    # 1EB8: 52
    .byte 0x8A, 0xC2, 0x02, 0xC0, 0x8A, 0xD0 # 1EB9
    mov    al,0x14                               # 1EBF: B0 14
    lahf                                         # 1EC1: 9F
    xchg   ah,al                                 # 1EC2: 86 C4
    push   ax                                    # 1EC4: 50
    xchg   ah,al                                 # 1EC5: 86 C4
    jmp    L_3ED2                                # 1EC7: E9 08 20
L_1ECA:
    call   CHRGTR                                # 1ECA: E8 50 F0
    call   GETBYT                                # 1ECD: E8 4C 00
    push   ax                                    # 1ED0: 50
    call   SYNCHR                                # 1ED1: E8 20 0F
    .byte ','                                  # 1ED4: 2C -- SYNCHR inline operand
    call   GETBYT                                # 1ED5: E8 44 00
    pop    ax                                     # 1ED8: 58
    push   bx                                     # 1ED9: 53
    push   dx                                    # 1EDA: 52
    call   GET_FILE_BLOCK                                # 1EDB: E8 C7 20
    call   L_5913                                # 1EDE: E8 32 3A
    .byte 0x0A, 0xC0 # 1EE1
    jns    L_1EE8                                # 1EE3: 79 03
    jmp    FCERR                                # 1EE5: E9 71 F1
L_1EE8:
    inc    bx                                    # 1EE8: 43
    pop    dx                                    # 1EE9: 5A
    mov    BYTE PTR [bx],dl                      # 1EEA: 88 17
    pop    bx                                    # 1EEC: 5B
    ret                                          # 1EED: C3
L_1EEE:
    call   CONINT                                # 1EEE: E8 2E 00
    call   L_52AC                                # 1EF1: E8 B8 33
    mov    ds:CRTWID,al                            # 1EF4: A2 29 00
L_1EF7:
    sub    al,0xe                                # 1EF7: 2C 0E
    jae    L_1EF7                                # 1EF9: 73 FC
    add    al,0x1c                               # 1EFB: 04 1C
    not    al                                    # 1EFD: F6 D0
    inc    al                                    # 1EFF: FE C0
    .byte 0x02, 0xC2 # 1F01
    mov    ds:PRINT_ZONE_LIMIT,al                            # 1F03: A2 2A 00
    ret                                          # 1F06: C3
GETINT:
    call   CHRGTR                                # 1F07: E8 13 F0
GETIN2:
    call   FRMEVL                                # 1F0A: E8 1A F8
INTFR2:
    push   bx                                    # 1F0D: 53
    call   FRCINT                                # 1F0E: E8 9C 4C
    xchg   dx,bx                                 # 1F11: 87 DA
    pop    bx                                    # 1F13: 5B
    .byte 0x8A, 0xC6, 0x0A, 0xC0 # 1F14
    ret                                          # 1F18: C3
GTBYTC:
    call   CHRGTR                                # 1F19: E8 01 F0
GETBYT:
    call   FRMEVL                                # 1F1C: E8 08 F8
CONINT:
    call   INTFR2                                # 1F1F: E8 EB FF
    je     CONINT_OK                                # 1F22: 74 03
    jmp    FCERR                                # 1F24: E9 32 F1
CONINT_OK:
    dec    bx                                    # 1F27: 4B
    call   CHRGTR                                # 1F28: E8 F2 EF
    .byte 0x8A, 0xC2 # 1F2B
    ret                                          # 1F2D: C3
LLIST:
    call   L_14B0                                # 1F2E: E8 7F F5
    dec    bx                                    # 1F31: 4B
    call   CHRGTR                                # 1F32: E8 E8 EF
LIST:
    int    0xa2                                  # 1F35: CD A2
    pop    cx                                    # 1F37: 59
    call   SCNLIN                                # 1F38: E8 F2 EA
    push   cx                                    # 1F3B: 51
    call   PROCHK                                # 1F3C: E8 19 28
    mov    bx,WORD PTR ds:TEMP                  # 1F3F: 8B 1E 3B 03
    dec    bx                                    # 1F43: 4B
    call   CHRGTR                                # 1F44: E8 D6 EF
    je     L_1F57                                # 1F47: 74 0E
    call   SYNCHR                                # 1F49: E8 A8 0E
    .byte ','                                  # 1F4C: 2C -- SYNCHR inline operand
    .byte 0xE8 # 1F4D -- decoded continuation: call   0x3f13
    ret                                          # 1F4E: C3
    .byte 0x1F, 0xB2, 0x02, 0x32, 0xC0, 0xE8, 0x96, 0x21 # 1F4F
L_1F57:
    mov    bx,0xffff                             # 1F57: BB FF FF
    mov    WORD PTR ds:CURLIN,bx                   # 1F5A: 89 1E 2E 00
    call   ISFLIO                                # 1F5E: E8 75 10
    jne    L_1F68                                # 1F61: 75 05
    mov    al,0x1                                # 1F63: B0 01
    mov    ds:CNTOFL,al                            # 1F65: A2 6F 00
L_1F68:
    pop    bx                                    # 1F68: 5B
    pop    dx                                    # 1F69: 5A
    mov    cl,BYTE PTR [bx]                      # 1F6A: 8A 0F
    inc    bx                                    # 1F6C: 43
    mov    ch,BYTE PTR [bx]                      # 1F6D: 8A 2F
    inc    bx                                    # 1F6F: 43
    .byte 0x8A, 0xC5, 0x0A, 0xC1 # 1F70
    jne    L_1F79                                # 1F74: 75 03
    jmp    READY                                # 1F76: E9 3D E9
L_1F79:
    call   L_000C                                # 1F79: E8 90 E0
    jne    L_1F81                                # 1F7C: 75 03
    call   L_2C88                                # 1F7E: E8 07 0D
L_1F81:
    push   cx                                    # 1F81: 51
    mov    cl,BYTE PTR [bx]                      # 1F82: 8A 0F
    inc    bx                                    # 1F84: 43
    mov    ch,BYTE PTR [bx]                      # 1F85: 8A 2F
    inc    bx                                    # 1F87: 43
    push   cx                                    # 1F88: 51
    pop    si                                    # 1F89: 5E
    xchg   si,bx                                 # 1F8A: 87 DE
    push   si                                    # 1F8C: 56
    xchg   dx,bx                                 # 1F8D: 87 DA
    .byte 0x3B, 0xDA # 1F8F
    pop    cx                                    # 1F91: 59
    jae    L_1F97                                # 1F92: 73 03
    jmp    STPRDY                                # 1F94: E9 1E E9
L_1F97:
    pop    si                                    # 1F97: 5E
    xchg   si,bx                                 # 1F98: 87 DE
    push   si                                    # 1F9A: 56
    push   bx                                    # 1F9B: 53
    push   cx                                    # 1F9C: 51
    xchg   dx,bx                                 # 1F9D: 87 DA
    mov    WORD PTR ds:DOT,bx                  # 1F9F: 89 1E 49 03
    call   LINPRT                                # 1FA3: E8 AA 45
    pop    bx                                    # 1FA6: 5B
    mov    al,BYTE PTR [bx]                      # 1FA7: 8A 07
    cmp    al,0x9                                # 1FA9: 3C 09
    je     L_1FB2                                # 1FAB: 74 05
    mov    al,0x20                               # 1FAD: B0 20
    call   OUTDO                                # 1FAF: E8 F3 0B
L_1FB2:
    call   L_1FCD                                # 1FB2: E8 18 00
    mov    bx,0x1f7                              # 1FB5: BB F7 01
    call   L_1FC0                                # 1FB8: E8 05 00
    call   CRDO                                # 1FBB: E8 B3 0C
    jmp    L_1F57                                # 1FBE: EB 97
L_1FC0:
    mov    al,BYTE PTR [bx]                      # 1FC0: 8A 07
    .byte 0x0A, 0xC0 # 1FC2
    jne    L_1FC7                                # 1FC4: 75 01
L_1FC6:
    ret                                          # 1FC6: C3
L_1FC7:
    call   L_3733                                # 1FC7: E8 69 17
    inc    bx                                    # 1FCA: 43
    jmp    L_1FC0                                # 1FCB: EB F3
L_1FCD:
    mov    cx,0x1f7                              # 1FCD: B9 F7 01
    mov    dh,0xff                               # 1FD0: B6 FF
    .byte 0x32, 0xC0 # 1FD2
    mov    ds:DORES,al                           # 1FD4: A2 FC 02
    .byte 0x32, 0xC0 # 1FD7
    mov    ds:TEMPA,al                           # 1FD9: A2 5E 04
    call   PROCHK                                # 1FDC: E8 79 27
    jmp    L_1FE7                                # 1FDF: EB 06
L_1FE1:
    inc    cx                                    # 1FE1: 41
    inc    bx                                    # 1FE2: 43
    dec    dh                                    # 1FE3: FE CE
    je     L_1FC6                                # 1FE5: 74 DF
L_1FE7:
    mov    al,BYTE PTR [bx]                      # 1FE7: 8A 07
    .byte 0x0A, 0xC0, 0x8B, 0xF9 # 1FE9
    stos   BYTE PTR es:[di],al                   # 1FED: AA
    je     L_1FC6                                # 1FEE: 74 D6
    cmp    al,0xb                                # 1FF0: 3C 0B
    jb     L_201C                                # 1FF2: 72 28
    cmp    al,0x20                               # 1FF4: 3C 20
    .byte 0x8A, 0xD0 # 1FF6
    jb     L_2032                                # 1FF8: 72 38
    cmp    al,0x22                               # 1FFA: 3C 22
    jne    L_2008                                # 1FFC: 75 0A
    mov    al,ds:DORES                           # 1FFE: A0 FC 02
    xor    al,0x1                                # 2001: 34 01
    mov    ds:DORES,al                           # 2003: A2 FC 02
    mov    al,0x22                               # 2006: B0 22
L_2008:
    cmp    al,0x3a                               # 2008: 3C 3A
    jne    L_201C                                # 200A: 75 10
    mov    al,ds:DORES                           # 200C: A0 FC 02
    rcr    al,1                                  # 200F: D0 D8
    jb     L_201A                                # 2011: 72 07
    rcl    al,1                                  # 2013: D0 D0
    and    al,0xfd                               # 2015: 24 FD
    mov    ds:DORES,al                           # 2017: A2 FC 02
L_201A:
    mov    al,0x3a                               # 201A: B0 3A
L_201C:
    .byte 0x0A, 0xC0 # 201C
    jns    L_2023                                # 201E: 79 03
    .byte 0xE9, 0x3C, 0x00 # 2020
L_2023:
    .byte 0x8A, 0xD0 # 2023
    cmp    al,0x2e                               # 2025: 3C 2E
    je     L_2032                                # 2027: 74 09
    call   L_2183                                # 2029: E8 57 01
    jae    L_2032                                # 202C: 73 04
    .byte 0x32, 0xC0 # 202E
    jmp    L_204A                                # 2030: EB 18
L_2032:
    mov    al,ds:TEMPA                           # 2032: A0 5E 04
    .byte 0x0A, 0xC0 # 2035
    je     L_2048                                # 2037: 74 0F
    inc    al                                    # 2039: FE C0
    jne    L_2048                                # 203B: 75 0B
    mov    al,0x20                               # 203D: B0 20
    .byte 0x8B, 0xF9 # 203F
    stos   BYTE PTR es:[di],al                   # 2041: AA
    inc    cx                                    # 2042: 41
    dec    dh                                    # 2043: FE CE
    jne    L_2048                                # 2045: 75 01
L_2047:
    ret                                          # 2047: C3
L_2048:
    mov    al,0x1                                # 2048: B0 01
L_204A:
    mov    ds:TEMPA,al                           # 204A: A2 5E 04
    .byte 0x8A, 0xC2 # 204D
    cmp    al,0xb                                # 204F: 3C 0B
    jb     L_205A                                # 2051: 72 07
    cmp    al,0x20                               # 2053: 3C 20
    jae    L_205A                                # 2055: 73 03
    jmp    L_2191                                # 2057: E9 37 01
L_205A:
    .byte 0x8B, 0xF9 # 205A
    stos   BYTE PTR es:[di],al                   # 205C: AA
    jmp    L_1FE1                                # 205D: EB 82
L_205F:
    mov    al,ds:DORES                           # 205F: A0 FC 02
    rcr    al,1                                  # 2062: D0 D8
    jb     L_20A9                                # 2064: 72 43
    rcr    al,1                                  # 2066: D0 D8
    rcr    al,1                                  # 2068: D0 D8
    jae    L_20BE                                # 206A: 73 52
    mov    al,BYTE PTR [bx]                      # 206C: 8A 07
    cmp    al,0xd9                               # 206E: 3C D9
    push   bx                                    # 2070: 53
    push   cx                                    # 2071: 51
    mov    bx,0x20a5                             # 2072: BB A5 20
    push   bx                                    # 2075: 53
    jne    L_2047                                # 2076: 75 CF
    dec    cx                                    # 2078: 49
    .byte 0x8B, 0xF1 # 2079
    lods   al,BYTE PTR ds:[si]                   # 207B: AC
    cmp    al,0x4d                               # 207C: 3C 4D
    jne    L_2047                                # 207E: 75 C7
    dec    cx                                    # 2080: 49
    .byte 0x8B, 0xF1 # 2081
    lods   al,BYTE PTR ds:[si]                   # 2083: AC
    cmp    al,0x45                               # 2084: 3C 45
    jne    L_2047                                # 2086: 75 BF
    dec    cx                                    # 2088: 49
    .byte 0x8B, 0xF1 # 2089
    lods   al,BYTE PTR ds:[si]                   # 208B: AC
    cmp    al,0x52                               # 208C: 3C 52
    jne    L_2047                                # 208E: 75 B7
    dec    cx                                    # 2090: 49
    .byte 0x8B, 0xF1 # 2091
    lods   al,BYTE PTR ds:[si]                   # 2093: AC
    cmp    al,0x3a                               # 2094: 3C 3A
    jne    L_2047                                # 2096: 75 AF
    pop    ax                                    # 2098: 58
    pop    ax                                    # 2099: 58
    pop    bx                                    # 209A: 5B
    inc    dh                                    # 209B: FE C6
    inc    dh                                    # 209D: FE C6
    inc    dh                                    # 209F: FE C6
    inc    dh                                    # 20A1: FE C6
    jmp    L_20D2                                # 20A3: EB 2D
    .byte 0x59, 0x5B, 0x8A, 0x07 # 20A5
L_20A9:
    jmp    L_1FE1                                # 20A9: E9 35 FF
L_20AC:
    mov    al,ds:DORES                           # 20AC: A0 FC 02
    or     al,0x2                                # 20AF: 0C 02
L_20B1:
    mov    ds:DORES,al                           # 20B1: A2 FC 02
    .byte 0x32, 0xC0 # 20B4
    ret                                          # 20B6: C3
L_20B7:
    mov    al,ds:DORES                           # 20B7: A0 FC 02
    or     al,0x4                                # 20BA: 0C 04
    jmp    L_20B1                                # 20BC: EB F3
L_20BE:
    rcl    al,1                                  # 20BE: D0 D0
    jb     L_20A9                                # 20C0: 72 E7
    mov    al,BYTE PTR [bx]                      # 20C2: 8A 07
    cmp    al,0x84                               # 20C4: 3C 84
    jne    L_20CB                                # 20C6: 75 03
    call   L_20AC                                # 20C8: E8 E1 FF
L_20CB:
    cmp    al,0x8f                               # 20CB: 3C 8F
    jne    L_20D2                                # 20CD: 75 03
    call   L_20B7                                # 20CF: E8 E5 FF
L_20D2:
    mov    al,BYTE PTR [bx]                      # 20D2: 8A 07
    inc    al                                    # 20D4: FE C0
    mov    al,BYTE PTR [bx]                      # 20D6: 8A 07
    jne    L_20DF                                # 20D8: 75 05
    inc    bx                                    # 20DA: 43
    mov    al,BYTE PTR [bx]                      # 20DB: 8A 07
    and    al,0x7f                               # 20DD: 24 7F
L_20DF:
    inc    bx                                    # 20DF: 43
    cmp    al,0xa1                               # 20E0: 3C A1
    jne    L_20E7                                # 20E2: 75 03
    call   L_64DF                                # 20E4: E8 F8 43
L_20E7:
    cmp    al,0xb1                               # 20E7: 3C B1
    jne    L_20F5                                # 20E9: 75 0A
    mov    al,BYTE PTR [bx]                      # 20EB: 8A 07
    inc    bx                                    # 20ED: 43
    cmp    al,0xe9                               # 20EE: 3C E9
    mov    al,0xb1                               # 20F0: B0 B1
    je     L_20F5                                # 20F2: 74 01
    dec    bx                                    # 20F4: 4B
L_20F5:
    push   bx                                    # 20F5: 53
    push   cx                                    # 20F6: 51
    push   dx                                    # 20F7: 52
    int    0xa3                                  # 20F8: CD A3
    mov    bx,0x136                              # 20FA: BB 36 01
    .byte 0x8A, 0xE8 # 20FD
    mov    cl,0x40                               # 20FF: B1 40
L_2101:
    inc    cl                                    # 2101: FE C1
L_2103:
    inc    bx                                    # 2103: 43
    .byte 0x8A, 0xF7, 0x8A, 0xD3 # 2104
L_2108:
    mov    al,BYTE PTR cs:[bx]                   # 2108: 2E 8A 07
    .byte 0x0A, 0xC0 # 210B
    je     L_2101                                # 210D: 74 F2
    lahf                                         # 210F: 9F
    inc    bx                                    # 2110: 43
    sahf                                         # 2111: 9E
    jns    L_2108                                # 2112: 79 F4
    mov    al,BYTE PTR cs:[bx]                   # 2114: 2E 8A 07
    .byte 0x3A, 0xC5 # 2117
    jne    L_2103                                # 2119: 75 E8
    xchg   dx,bx                                 # 211B: 87 DA
    cmp    al,0xd0                               # 211D: 3C D0
    je     L_2123                                # 211F: 74 02
    cmp    al,0xd1                               # 2121: 3C D1
L_2123:
    .byte 0x8A, 0xC1 # 2123
    pop    dx                                    # 2125: 5A
    pop    cx                                    # 2126: 59
    .byte 0x8A, 0xD0 # 2127
    jne    L_2137                                # 2129: 75 0C
    mov    al,ds:TEMPA                           # 212B: A0 5E 04
    .byte 0x0A, 0xC0 # 212E
    mov    al,0x0                                # 2130: B0 00
    mov    ds:TEMPA,al                           # 2132: A2 5E 04
    jmp    L_214C                                # 2135: EB 15
L_2137:
    cmp    al,0x5b                               # 2137: 3C 5B
    jne    L_2142                                # 2139: 75 07
    .byte 0x32, 0xC0 # 213B
    mov    ds:TEMPA,al                           # 213D: A2 5E 04
    jmp    L_215F                                # 2140: EB 1D
L_2142:
    mov    al,ds:TEMPA                           # 2142: A0 5E 04
    .byte 0x0A, 0xC0 # 2145
    mov    al,0xff                               # 2147: B0 FF
    mov    ds:TEMPA,al                           # 2149: A2 5E 04
L_214C:
    je     L_215B                                # 214C: 74 0D
    mov    al,0x20                               # 214E: B0 20
    .byte 0x8B, 0xF9 # 2150
    stos   BYTE PTR es:[di],al                   # 2152: AA
    inc    cx                                    # 2153: 41
    dec    dh                                    # 2154: FE CE
    jne    L_215B                                # 2156: 75 03
    jmp    L_26FF                                # 2158: E9 A4 05
L_215B:
    .byte 0x8A, 0xC2 # 215B
    jmp    L_2165                                # 215D: EB 06
L_215F:
    mov    al,BYTE PTR cs:[bx]                   # 215F: 2E 8A 07
    inc    bx                                    # 2162: 43
    .byte 0x8A, 0xD0 # 2163
L_2165:
    and    al,0x7f                               # 2165: 24 7F
    .byte 0x8B, 0xF9 # 2167
    stos   BYTE PTR es:[di],al                   # 2169: AA
    inc    cx                                    # 216A: 41
    dec    dh                                    # 216B: FE CE
    jne    L_2172                                # 216D: 75 03
    jmp    L_26FF                                # 216F: E9 8D 05
L_2172:
    .byte 0x0A, 0xC2 # 2172
    jns    L_215F                                # 2174: 79 E9
    cmp    al,0xa8                               # 2176: 3C A8
    jne    L_217F                                # 2178: 75 05
    .byte 0x32, 0xC0 # 217A
    mov    ds:TEMPA,al                           # 217C: A2 5E 04
L_217F:
    pop    bx                                    # 217F: 5B
    jmp    L_1FE7                                # 2180: E9 64 FE
L_2183:
    call   ISLET2                                # 2183: E8 BF 0D
    jb     L_2189                                # 2186: 72 01
L_2188:
    ret                                          # 2188: C3
L_2189:
    cmp    al,0x30                               # 2189: 3C 30
    jb     L_2188                                # 218B: 72 FB
    cmp    al,0x3a                               # 218D: 3C 3A
    cmc                                          # 218F: F5
    ret                                          # 2190: C3
L_2191:
    dec    bx                                    # 2191: 4B
    call   CHRGTR                                # 2192: E8 88 ED
    push   dx                                    # 2195: 52
    push   cx                                    # 2196: 51
    push   ax                                    # 2197: 50
    call   L_0FBC                                # 2198: E8 21 EE
    pop    ax                                    # 219B: 58
    mov    cx,0x21b5                             # 219C: B9 B5 21
    push   cx                                    # 219F: 51
    cmp    al,0xb                                # 21A0: 3C 0B
    jne    L_21A7                                # 21A2: 75 03
    jmp    L_6407                                # 21A4: E9 60 42
L_21A7:
    cmp    al,0xc                                # 21A7: 3C 0C
    jne    L_21AE                                # 21A9: 75 03
    jmp    L_6411                                # 21AB: E9 63 42
L_21AE:
    mov    bx,WORD PTR ds:CONLO                  # 21AE: 8B 1E 02 03
    jmp    L_70C8                                # 21B2: E9 13 4F
    .byte 0x59, 0x5A, 0xA0, 0x00, 0x03, 0xB2, 0x4F, 0x3C, 0x0B, 0x74, 0x06, 0x3C # 21B5
    .byte 0x0C, 0xB2, 0x48, 0x75, 0x14, 0xB0, 0x26, 0x8B, 0xF9, 0xAA, 0x41, 0xFE # 21C1
    .byte 0xCE, 0x74, 0xC0, 0x8A, 0xC2, 0x8B, 0xF9, 0xAA, 0x41, 0xFE, 0xCE, 0x74 # 21CD
    .byte 0xB6, 0xA0, 0x01, 0x03, 0x3C, 0x04, 0xB2, 0x00, 0x72, 0x06, 0xB2, 0x21 # 21D9
    .byte 0x74, 0x02, 0xB2, 0x23, 0x8A, 0x07, 0x3C, 0x20, 0x75, 0x03, 0xE8, 0x52 # 21E5
    .byte 0x43, 0x8A, 0x07, 0x43, 0x0A, 0xC0, 0x74, 0x2A, 0x8B, 0xF9, 0xAA, 0x41 # 21F1
    .byte 0xFE, 0xCE, 0x74, 0x8F, 0xA0, 0x01, 0x03, 0x3C, 0x04, 0x72, 0xEA, 0x9F # 21FD
    .byte 0x49, 0x9E, 0x8B, 0xF1, 0xAC, 0x9F, 0x41, 0x9E, 0x75, 0x04, 0x3C, 0x2E # 2209
    .byte 0x74, 0x08, 0x3C, 0x44, 0x74, 0x04, 0x3C, 0x45, 0x75, 0xD3, 0xB2, 0x00 # 2215
    .byte 0xEB, 0xCF, 0x8A, 0xC2, 0x0A, 0xC0, 0x74, 0x09, 0x8B, 0xF9, 0xAA, 0x41 # 2221
    .byte 0xFE, 0xCE, 0x75, 0x01, 0xC3, 0x8B, 0x1E, 0xFE, 0x02, 0xE9, 0xAE, 0xFD # 222D
DELETE:
    call   SCNLIN                                # 2239: E8 F1 E7
    push   cx                                    # 223C: 51
    call   DEPTR                                # 223D: E8 F5 01
    pop    cx                                    # 2240: 59
    pop    dx                                    # 2241: 5A
    push   cx                                    # 2242: 51
    push   cx                                    # 2243: 51
    call   FNDLIN                                # 2244: E8 20 E8
    jae    L_2254                                # 2247: 73 0B
    .byte 0x8A, 0xF7, 0x8A, 0xD3 # 2249
    pop    si                                    # 224D: 5E
    xchg   si,bx                                 # 224E: 87 DE
    push   si                                    # 2250: 56
    push   bx                                    # 2251: 53
    .byte 0x3B, 0xDA # 2252
L_2254:
    jb     L_2259                                # 2254: 72 03
    jmp    FCERR                                # 2256: E9 00 EE
L_2259:
    mov    bx,0x72d                              # 2259: BB 2D 07
    call   STROUT                                # 225C: E8 F6 58
    pop    cx                                    # 225F: 59
    mov    bx,0x9dd                              # 2260: BB DD 09
    pop    si                                    # 2263: 5E
    xchg   si,bx                                 # 2264: 87 DE
    push   si                                    # 2266: 56
DEL:
    xchg   dx,bx                                 # 2267: 87 DA
    mov    bx,WORD PTR ds:VARTAB                  # 2269: 8B 1E 58 03
L_226D:
    .byte 0x8B, 0xF2 # 226D
    lods   al,BYTE PTR ds:[si]                   # 226F: AC
    .byte 0x8B, 0xF9 # 2270
    stos   BYTE PTR es:[di],al                   # 2272: AA
    inc    cx                                    # 2273: 41
    inc    dx                                    # 2274: 42
    .byte 0x3B, 0xDA # 2275
    jne    L_226D                                # 2277: 75 F4
    .byte 0x8B, 0xD9 # 2279
    mov    WORD PTR ds:VARTAB,bx                  # 227B: 89 1E 58 03
    ret                                          # 227F: C3
PEEK:
    call   L_22B5                                # 2280: E8 32 00
    call   L_4749                                # 2283: E8 C3 24
    push   ds                                    # 2286: 1E
    mov    ds,WORD PTR ds:SAVSEG                  # 2287: 8E 1E 50 03
    mov    al,BYTE PTR [bx]                      # 228B: 8A 07
    pop    ds                                    # 228D: 1F
    jmp    L_1B7F                                # 228E: E9 EE F8
POKE:
    call   L_22AA                                # 2291: E8 16 00
    push   dx                                    # 2294: 52
    call   L_4749                                # 2295: E8 B1 24
    call   SYNCHR                                # 2298: E8 59 0B
L_229B:
    .byte ','                                  # 229B: 2C -- SYNCHR inline operand
    .byte 0xE8 # 229C -- decoded continuation: call   0x1f1c
    jge    L_229B                                # 229D: 7D FC
    pop    dx                                    # 229F: 5A
    push   es                                    # 22A0: 06
    mov    es,WORD PTR ds:SAVSEG                  # 22A1: 8E 06 50 03
    .byte 0x8B, 0xFA # 22A5
    stos   BYTE PTR es:[di],al                   # 22A7: AA
    pop    es                                    # 22A8: 07
    ret                                          # 22A9: C3
L_22AA:
    call   FRMEVL                                # 22AA: E8 7A F4
    push   bx                                    # 22AD: 53
    call   L_22B5                                # 22AE: E8 04 00
    xchg   dx,bx                                 # 22B1: 87 DA
    pop    bx                                    # 22B3: 5B
L_22B4:
    ret                                          # 22B4: C3
L_22B5:
    mov    cx,0x6bad                             # 22B5: B9 AD 6B
    push   cx                                    # 22B8: 51
    call   GETYPR                                # 22B9: E8 69 F8
    js     L_22B4                                # 22BC: 78 F6
    int    0xa4                                  # 22BE: CD A4
    mov    al,ds:FACEXP                           # 22C0: A0 A6 04
    cmp    al,0x90                               # 22C3: 3C 90
    jne    L_22B4                                # 22C5: 75 ED
    call   SIGN                                # 22C7: E8 AB 58
    js     L_22B4                                # 22CA: 78 E8
    call   FRCSNG                                # 22CC: E8 82 48
    mov    cx,0x9180                             # 22CF: B9 80 91
    mov    dx,0x0                                # 22D2: BA 00 00
    jmp    L_6312                                # 22D5: E9 3A 40
RESEQ:
    mov    cx,0xa                                # 22D8: B9 0A 00
    push   cx                                    # 22DB: 51
    .byte 0x8A, 0xF5, 0x8A, 0xD5 # 22DC
    je     L_2317                                # 22E0: 74 35
    cmp    al,0x2c                               # 22E2: 3C 2C
    je     L_22F1                                # 22E4: 74 0B
    push   dx                                    # 22E6: 52
    call   L_105E                                # 22E7: E8 74 ED
    .byte 0x8A, 0xEE, 0x8A, 0xCA # 22EA
    pop    dx                                    # 22EE: 5A
    je     L_2317                                # 22EF: 74 26
L_22F1:
    call   SYNCHR                                # 22F1: E8 00 0B
    .byte ','                                  # 22F4: 2C -- SYNCHR inline operand
    call   L_105E                                # 22F5: E8 66 ED
    je     L_2317                                # 22F8: 74 1D
    pop    ax                                    # 22FA: 58
    call   SYNCHR                                # 22FB: E8 F6 0A
    .byte ','                                  # 22FE: 2C -- SYNCHR inline operand
    .byte 0x52 # 22FF -- decoded continuation: push   dx
    call   LINGET                                # 2300: E8 68 ED
    je     L_2308                                # 2303: 74 03
    jmp    SNERR                                 # 2305: E9 B6 E4
L_2308:
    .byte 0x0B, 0xD2 # 2308
    jne    L_230F                                # 230A: 75 03
    jmp    FCERR                                # 230C: E9 4A ED
L_230F:
    xchg   dx,bx                                 # 230F: 87 DA
    pop    si                                    # 2311: 5E
    xchg   si,bx                                 # 2312: 87 DE
    push   si                                    # 2314: 56
    xchg   dx,bx                                 # 2315: 87 DA
L_2317:
    push   cx                                    # 2317: 51
    call   FNDLIN                                # 2318: E8 4C E7
    pop    dx                                    # 231B: 5A
    push   dx                                    # 231C: 52
    push   cx                                    # 231D: 51
    call   FNDLIN                                # 231E: E8 46 E7
    .byte 0x8B, 0xD9 # 2321
    pop    dx                                    # 2323: 5A
    .byte 0x3B, 0xDA # 2324
    xchg   dx,bx                                 # 2326: 87 DA
    jae    L_232D                                # 2328: 73 03
    jmp    FCERR                                # 232A: E9 2C ED
L_232D:
    pop    dx                                    # 232D: 5A
    pop    cx                                    # 232E: 59
    pop    ax                                    # 232F: 58
    push   bx                                    # 2330: 53
    push   dx                                    # 2331: 52
    jmp    L_2349                                # 2332: EB 15
L_2334:
    .byte 0x03, 0xD9 # 2334
    jae    L_233B                                # 2336: 73 03
    jmp    FCERR                                # 2338: E9 1E ED
L_233B:
    xchg   dx,bx                                 # 233B: 87 DA
    push   bx                                    # 233D: 53
    mov    bx,0xfff9                             # 233E: BB F9 FF
    .byte 0x3B, 0xDA # 2341
    pop    bx                                    # 2343: 5B
    jae    L_2349                                # 2344: 73 03
    jmp    FCERR                                # 2346: E9 10 ED
L_2349:
    push   dx                                    # 2349: 52
    mov    dx,WORD PTR [bx]                      # 234A: 8B 17
    .byte 0x0B, 0xD2 # 234C
    xchg   dx,bx                                 # 234E: 87 DA
    pop    dx                                    # 2350: 5A
    je     L_235F                                # 2351: 74 0C
    mov    al,BYTE PTR [bx]                      # 2353: 8A 07
    inc    bx                                    # 2355: 43
    or     al,BYTE PTR [bx]                      # 2356: 0A 07
    lahf                                         # 2358: 9F
    dec    bx                                    # 2359: 4B
    sahf                                         # 235A: 9E
    xchg   dx,bx                                 # 235B: 87 DA
    jne    L_2334                                # 235D: 75 D5
L_235F:
    push   cx                                    # 235F: 51
    call   L_2387                                # 2360: E8 24 00
    pop    cx                                    # 2363: 59
    pop    dx                                    # 2364: 5A
    pop    bx                                    # 2365: 5B
L_2366:
    push   dx                                    # 2366: 52
    mov    dx,WORD PTR [bx]                      # 2367: 8B 17
    inc    bx                                    # 2369: 43
    .byte 0x0B, 0xD2 # 236A
    je     L_2382                                # 236C: 74 14
    xchg   dx,bx                                 # 236E: 87 DA
    pop    si                                    # 2370: 5E
    xchg   si,bx                                 # 2371: 87 DE
    push   si                                    # 2373: 56
    xchg   dx,bx                                 # 2374: 87 DA
    inc    bx                                    # 2376: 43
    mov    WORD PTR [bx],dx                      # 2377: 89 17
    xchg   dx,bx                                 # 2379: 87 DA
    .byte 0x03, 0xD9 # 237B
    xchg   dx,bx                                 # 237D: 87 DA
    pop    bx                                    # 237F: 5B
    jmp    L_2366                                # 2380: EB E4
L_2382:
    mov    cx,0x8b5                              # 2382: B9 B5 08
    push   cx                                    # 2385: 51
    .byte 0x3C # 2386
L_2387:
    .byte 0x0D # 2387
L_2388:
    .byte 0x32, 0xC0 # 2388
    mov    ds:PTRFLG,al                           # 238A: A2 3D 03
    mov    bx,WORD PTR ds:TXTTAB                   # 238D: 8B 1E 30 00
    dec    bx                                    # 2391: 4B
L_2392:
    inc    bx                                    # 2392: 43
    mov    al,BYTE PTR [bx]                      # 2393: 8A 07
    inc    bx                                    # 2395: 43
    or     al,BYTE PTR [bx]                      # 2396: 0A 07
    jne    L_239B                                # 2398: 75 01
    ret                                          # 239A: C3
L_239B:
    inc    bx                                    # 239B: 43
    mov    dx,WORD PTR [bx]                      # 239C: 8B 17
    inc    bx                                    # 239E: 43
L_239F:
    call   CHRGTR                                # 239F: E8 7B EB
L_23A2:
    .byte 0x0A, 0xC0 # 23A2
    je     L_2392                                # 23A4: 74 EC
    .byte 0x8A, 0xC8 # 23A6
    mov    al,ds:PTRFLG                           # 23A8: A0 3D 03
    .byte 0x0A, 0xC0, 0x8A, 0xC1 # 23AB
    je     L_240C                                # 23AF: 74 5B
    int    0xa5                                  # 23B1: CD A5
    cmp    al,0xa7                               # 23B3: 3C A7
    jne    L_23CF                                # 23B5: 75 18
    call   CHRGTR                                # 23B7: E8 63 EB
    cmp    al,0x89                               # 23BA: 3C 89
    jne    L_23A2                                # 23BC: 75 E4
    call   CHRGTR                                # 23BE: E8 5C EB
    cmp    al,0xe                                # 23C1: 3C 0E
    jne    L_23A2                                # 23C3: 75 DD
    push   dx                                    # 23C5: 52
    call   L_1075                                # 23C6: E8 AC EC
    .byte 0x0B, 0xD2 # 23C9
    jne    L_23D7                                # 23CB: 75 0A
    jmp    L_23F8                                # 23CD: EB 29
L_23CF:
    cmp    al,0xe                                # 23CF: 3C 0E
    jne    L_239F                                # 23D1: 75 CC
    push   dx                                    # 23D3: 52
    call   L_1075                                # 23D4: E8 9E EC
L_23D7:
    push   bx                                    # 23D7: 53
    call   FNDLIN                                # 23D8: E8 8C E6
    lahf                                         # 23DB: 9F
    dec    cx                                    # 23DC: 49
    sahf                                         # 23DD: 9E
    mov    al,0xd                                # 23DE: B0 0D
    jb     L_2421                                # 23E0: 72 3F
    call   CRDONZ                                # 23E2: E8 78 08
    mov    bx,0x23fc                             # 23E5: BB FC 23
    push   dx                                    # 23E8: 52
    call   STROUT                                # 23E9: E8 69 57
    pop    bx                                    # 23EC: 5B
    call   LINPRT                                # 23ED: E8 60 41
    pop    cx                                    # 23F0: 59
    pop    bx                                    # 23F1: 5B
    push   bx                                    # 23F2: 53
    push   cx                                    # 23F3: 51
    call   L_6548                                # 23F4: E8 51 41
    pop    bx                                    # 23F7: 5B
L_23F8:
    pop    dx                                    # 23F8: 5A
    dec    bx                                    # 23F9: 4B
L_23FA:
    jmp    L_239F                                # 23FA: EB A3
    .byte 0x55, 0x6E, 0x64, 0x65, 0x66, 0x69, 0x6E, 0x65, 0x64, 0x20, 0x6C, 0x69 # 23FC
    .byte 0x6E, 0x65, 0x20, 0x00 # 2408
L_240C:
    cmp    al,0xd                                # 240C: 3C 0D
    jne    L_23FA                                # 240E: 75 EA
    push   dx                                    # 2410: 52
    call   L_1075                                # 2411: E8 61 EC
    push   bx                                    # 2414: 53
    xchg   dx,bx                                 # 2415: 87 DA
    inc    bx                                    # 2417: 43
    inc    bx                                    # 2418: 43
    inc    bx                                    # 2419: 43
    mov    cl,BYTE PTR [bx]                      # 241A: 8A 0F
    inc    bx                                    # 241C: 43
    mov    ch,BYTE PTR [bx]                      # 241D: 8A 2F
    mov    al,0xe                                # 241F: B0 0E
L_2421:
    mov    bx,0x23f7                             # 2421: BB F7 23
    push   bx                                    # 2424: 53
    mov    bx,WORD PTR ds:CONTXT                  # 2425: 8B 1E FE 02
L_2429:
    push   bx                                    # 2429: 53
    dec    bx                                    # 242A: 4B
    mov    BYTE PTR [bx],ch                      # 242B: 88 2F
    dec    bx                                    # 242D: 4B
    mov    BYTE PTR [bx],cl                      # 242E: 88 0F
    dec    bx                                    # 2430: 4B
    mov    BYTE PTR [bx],al                      # 2431: 88 07
    pop    bx                                    # 2433: 5B
L_2434:
    ret                                          # 2434: C3
DEPTR:
    mov    al,ds:PTRFLG                           # 2435: A0 3D 03
    .byte 0x0A, 0xC0 # 2438
    je     L_2434                                # 243A: 74 F8
    jmp    L_2388                                # 243C: E9 49 FF
OPTION:
    call   SYNCHR                                # 243F: E8 B2 09
    .byte 'B'                                  # 2442: 42 -- SYNCHR inline operand
    call   SYNCHR                                # 2443: E8 AE 09
    .byte 'A'                                  # 2446: 41 -- SYNCHR inline operand
    call   SYNCHR                                # 2447: E8 AA 09
    .byte 'S'                                  # 244A: 53 -- SYNCHR inline operand
    call   SYNCHR                                # 244B: E8 A6 09
    .byte 'E'                                  # 244E: 45 -- SYNCHR inline operand
    mov    al,ds:OPTFLG                           # 244F: A0 5D 04
    .byte 0x0A, 0xC0 # 2452
    je     L_2459                                # 2454: 74 03
    jmp    L_07C7                                # 2456: E9 6E E3
L_2459:
    push   bx                                    # 2459: 53
    mov    bx,WORD PTR ds:ARYTAB                  # 245A: 8B 1E 5A 03
    xchg   dx,bx                                 # 245E: 87 DA
    mov    bx,WORD PTR ds:STREND                  # 2460: 8B 1E 5C 03
    .byte 0x3B, 0xDA # 2464
    je     L_246B                                # 2466: 74 03
    jmp    L_07C7                                # 2468: E9 5C E3
L_246B:
    pop    bx                                    # 246B: 5B
    mov    al,BYTE PTR [bx]                      # 246C: 8A 07
    sub    al,0x30                               # 246E: 2C 30
    jae    L_2475                                # 2470: 73 03
    jmp    SNERR                                 # 2472: E9 49 E3
L_2475:
    cmp    al,0x2                                # 2475: 3C 02
    jb     L_247C                                # 2477: 72 03
    jmp    SNERR                                 # 2479: E9 42 E3
L_247C:
    mov    ds:OPTVAL,al                           # 247C: A2 5C 04
    inc    al                                    # 247F: FE C0
    mov    ds:OPTFLG,al                           # 2481: A2 5D 04
    call   CHRGTR                                # 2484: E8 96 EA
L_2487:
    ret                                          # 2487: C3
L_2488:
    mov    al,BYTE PTR cs:[bx]                   # 2488: 2E 8A 07
    .byte 0x0A, 0xC0 # 248B
    je     L_2487                                # 248D: 74 F8
    call   L_2495                                # 248F: E8 03 00
    inc    bx                                    # 2492: 43
    jmp    L_2488                                # 2493: EB F3
L_2495:
    lahf                                         # 2495: 9F
    xchg   ah,al                                 # 2496: 86 C4
    push   ax                                    # 2498: 50
    xchg   ah,al                                 # 2499: 86 C4
    jmp    L_2BB7                                # 249B: E9 19 07
RANDOM:
    je     L_24A9                                # 249E: 74 09
    call   FRMEVL                                # 24A0: E8 84 F2
    push   bx                                    # 24A3: 53
    call   FRCINT                                # 24A4: E8 06 47
    jmp    L_24C9                                # 24A7: EB 20
L_24A9:
    push   bx                                    # 24A9: 53
L_24AA:
    mov    bx,0x24d2                             # 24AA: BB D2 24
    call   STROUT                                # 24AD: E8 A5 56
    call   L_3194                                # 24B0: E8 E1 0C
    pop    dx                                    # 24B3: 5A
    jae    L_24B9                                # 24B4: 73 03
    jmp    L_2E48                                # 24B6: E9 8F 09
L_24B9:
    push   dx                                    # 24B9: 52
    inc    bx                                    # 24BA: 43
    mov    al,BYTE PTR [bx]                      # 24BB: 8A 07
    call   L_69C0                                # 24BD: E8 00 45
    mov    al,BYTE PTR [bx]                      # 24C0: 8A 07
    .byte 0x0A, 0xC0 # 24C2
    jne    L_24AA                                # 24C4: 75 E4
    call   FRCINT                                # 24C6: E8 E4 46
L_24C9:
    mov    WORD PTR ds:RNDX+1,bx                    # 24C9: 89 1E 0C 00
    call   L_646E                                # 24CD: E8 9E 3F
    pop    bx                                    # 24D0: 5B
    ret                                          # 24D1: C3
    .byte 0x52, 0x61, 0x6E, 0x64, 0x6F, 0x6D, 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65 # 24D2
    .byte 0x72, 0x20, 0x73, 0x65, 0x65, 0x64, 0x20, 0x28, 0x2D, 0x33, 0x32, 0x37 # 24DE
    .byte 0x36, 0x38, 0x20, 0x74, 0x6F, 0x20, 0x33, 0x32, 0x37, 0x36, 0x37, 0x29 # 24EA
    .byte 0x00 # 24F6
WNDSCN:
    mov    cl,0x1d                               # 24F7: B1 1D
    jmp    SCNCNT                                # 24F9: EB 02
NXTSCN:
    mov    cl,0x1a                               # 24FB: B1 1A
SCNCNT:
    mov    ch,0x0                                # 24FD: B5 00
    xchg   dx,bx                                 # 24FF: 87 DA
    mov    bx,WORD PTR ds:CURLIN                   # 2501: 8B 1E 2E 00
    mov    WORD PTR ds:NXTLIN,bx                  # 2505: 89 1E 5A 04
    xchg   dx,bx                                 # 2509: 87 DA
FORINC:
    inc    ch                                    # 250B: FE C5
FNLOP:
    dec    bx                                    # 250D: 4B
SCANWF:
    call   CHRGTR                                # 250E: E8 0C EA
    je     L_252A                                # 2511: 74 17
    cmp    al,0x22                               # 2513: 3C 22
    jne    L_2522                                # 2515: 75 0B
L_2517:
    call   CHRGTR                                # 2517: E8 03 EA
    .byte 0x0A, 0xC0 # 251A
    je     L_252A                                # 251C: 74 0C
    cmp    al,0x22                               # 251E: 3C 22
    jne    L_2517                                # 2520: 75 F5
L_2522:
    cmp    al,0xa1                               # 2522: 3C A1
    je     L_2543                                # 2524: 74 1D
    cmp    al,0xcd                               # 2526: 3C CD
    jne    SCANWF                                # 2528: 75 E4
L_252A:
    .byte 0x0A, 0xC0 # 252A
    jne    L_2543                                # 252C: 75 15
    inc    bx                                    # 252E: 43
    mov    al,BYTE PTR [bx]                      # 252F: 8A 07
    inc    bx                                    # 2531: 43
    or     al,BYTE PTR [bx]                      # 2532: 0A 07
    .byte 0x8A, 0xD1 # 2534
    jne    L_253B                                # 2536: 75 03
    jmp    L_07D8                                # 2538: E9 9D E2
L_253B:
    inc    bx                                    # 253B: 43
    mov    dx,WORD PTR [bx]                      # 253C: 8B 17
    inc    bx                                    # 253E: 43
    mov    WORD PTR ds:NXTLIN,dx                  # 253F: 89 16 5A 04
L_2543:
    call   CHRGTR                                # 2543: E8 D7 E9
    cmp    al,0x8f                               # 2546: 3C 8F
    jne    L_2551                                # 2548: 75 07
    push   cx                                    # 254A: 51
    call   REM                                   # 254B: E8 11 EC
    pop    cx                                    # 254E: 59
    jmp    L_252A                                # 254F: EB D9
L_2551:
    cmp    al,0x84                               # 2551: 3C 84
    jne    L_255C                                # 2553: 75 07
    push   cx                                    # 2555: 51
    call   DATAS                                 # 2556: E8 02 EC
    pop    cx                                    # 2559: 59
    jmp    L_252A                                # 255A: EB CE
L_255C:
    .byte 0x8A, 0xC1 # 255C
    cmp    al,0x1a                               # 255E: 3C 1A
    mov    al,BYTE PTR [bx]                      # 2560: 8A 07
    je     L_2571                                # 2562: 74 0D
    cmp    al,0xb1                               # 2564: 3C B1
    je     FORINC                                # 2566: 74 A3
    cmp    al,0xb2                               # 2568: 3C B2
    jne    FNLOP                                # 256A: 75 A1
    dec    ch                                    # 256C: FE CD
    jne    FNLOP                                # 256E: 75 9D
L_2570:
    ret                                          # 2570: C3
L_2571:
    cmp    al,0x82                               # 2571: 3C 82
    je     FORINC                                # 2573: 74 96
    cmp    al,0x83                               # 2575: 3C 83
    jne    FNLOP                                # 2577: 75 94
    dec    ch                                    # 2579: FE CD
    je     L_2570                                # 257B: 74 F3
    call   CHRGTR                                # 257D: E8 9D E9
    je     L_252A                                # 2580: 74 A8
    xchg   dx,bx                                 # 2582: 87 DA
    mov    bx,WORD PTR ds:CURLIN                   # 2584: 8B 1E 2E 00
    push   bx                                    # 2588: 53
    mov    bx,WORD PTR ds:NXTLIN                  # 2589: 8B 1E 5A 04
    mov    WORD PTR ds:CURLIN,bx                   # 258D: 89 1E 2E 00
    xchg   dx,bx                                 # 2591: 87 DA
    push   cx                                    # 2593: 51
    call   PTRGET                                # 2594: E8 D7 11
    pop    cx                                    # 2597: 59
    dec    bx                                    # 2598: 4B
    call   CHRGTR                                # 2599: E8 81 E9
    mov    dx,0x252a                             # 259C: BA 2A 25
    je     L_25A9                                # 259F: 74 08
    call   SYNCHR                                # 25A1: E8 50 08
    .byte ','                                  # 25A4: 2C -- SYNCHR inline operand
    .byte 0x4B # 25A5 -- decoded continuation: dec    bx
    mov    dx,0x2579                             # 25A6: BA 79 25
L_25A9:
    pop    si                                    # 25A9: 5E
    xchg   si,bx                                 # 25AA: 87 DE
    push   si                                    # 25AC: 56
    mov    WORD PTR ds:CURLIN,bx                   # 25AD: 89 1E 2E 00
    pop    bx                                    # 25B1: 5B
    push   dx                                    # 25B2: 52
    ret                                          # 25B3: C3
    .byte 0x9F, 0x50, 0xA0, 0xA8, 0x04, 0xA2, 0xA9, 0x04, 0x58, 0x9E # 25B4
L_25BE:
    lahf                                         # 25BE: 9F
    push   ax                                    # 25BF: 50
    .byte 0x32, 0xC0 # 25C0
    mov    ds:FLGOVC,al                           # 25C2: A2 A8 04
    pop    ax                                    # 25C5: 58
    sahf                                         # 25C6: 9E
    ret                                          # 25C7: C3
    .byte 0xE8, 0xDB, 0x02, 0x8A, 0x07, 0x43, 0x8A, 0x0F, 0x43, 0x8A, 0x2F, 0x5A # 25C8
    .byte 0x51, 0x50, 0xE8, 0xD6, 0x02, 0x58, 0x8A, 0xF0, 0x8A, 0x17, 0x43, 0x8A # 25D4
    .byte 0x0F, 0x43, 0x8A, 0x2F, 0x5B, 0x8A, 0xC2, 0x0A, 0xC6, 0x75, 0x01, 0xC3 # 25E0
    .byte 0x8A, 0xC6, 0x2C, 0x01, 0x72, 0xF9, 0x32, 0xC0, 0x3A, 0xC2, 0xFE, 0xC0 # 25EC
    .byte 0x73, 0xF1, 0xFE, 0xCE, 0xFE, 0xCA, 0x8B, 0xF1, 0xAC, 0x41, 0x3A, 0x07 # 25F8
    .byte 0x9F, 0x43, 0x9E, 0x74, 0xDC, 0xF5, 0xE9, 0x72, 0x3F # 2604
STRO_DOLLAR:
    call   L_6407                                # 260D: E8 F7 3D
    jmp    L_261A                                # 2610: EB 08
STRH_DOLLAR:
    call   L_6411                                # 2612: E8 FC 3D
    jmp    L_261A                                # 2615: EB 03
STR_DOLLAR:
    call   L_70C8                                # 2617: E8 AE 4A
L_261A:
    call   L_264C                                # 261A: E8 2F 00
    call   L_28A9                                # 261D: E8 89 02
    mov    cx,0x2917                             # 2620: B9 17 29
    push   cx                                    # 2623: 51
L_2624:
    mov    al,BYTE PTR [bx]                      # 2624: 8A 07
    inc    bx                                    # 2626: 43
    push   bx                                    # 2627: 53
    call   GETSPA                                # 2628: E8 AB 00
    pop    bx                                    # 262B: 5B
    mov    cl,BYTE PTR [bx]                      # 262C: 8A 0F
    inc    bx                                    # 262E: 43
    mov    ch,BYTE PTR [bx]                      # 262F: 8A 2F
    call   STRAD2                                # 2631: E8 0D 00
    push   bx                                    # 2634: 53
    .byte 0x8A, 0xD8 # 2635
    call   L_2895                                # 2637: E8 5B 02
    pop    dx                                    # 263A: 5A
    ret                                          # 263B: C3
STRIN1:
    mov    al,0x1                                # 263C: B0 01
STRINI:
    call   GETSPA                                # 263E: E8 95 00
STRAD2:
    mov    bx,DSCTMP                             # 2641: BB 2C 03
STRAD1:
    push   bx                                    # 2644: 53
    mov    BYTE PTR [bx],al                      # 2645: 88 07
    inc    bx                                    # 2647: 43
    mov    WORD PTR [bx],dx                      # 2648: 89 17
    pop    bx                                    # 264A: 5B
L_264B:
    ret                                          # 264B: C3
L_264C:
    dec    bx                                    # 264C: 4B
L_264D:
    mov    ch,0x22                               # 264D: B5 22
L_264F:
    .byte 0x8A, 0xF5 # 264F
L_2651:
    push   bx                                    # 2651: 53
    mov    cl,0xff                               # 2652: B1 FF
L_2654:
    inc    bx                                    # 2654: 43
    mov    al,BYTE PTR [bx]                      # 2655: 8A 07
    inc    cl                                    # 2657: FE C1
    .byte 0x0A, 0xC0 # 2659
    je     L_2665                                # 265B: 74 08
    .byte 0x3A, 0xC6 # 265D
    je     L_2665                                # 265F: 74 04
    .byte 0x3A, 0xC5 # 2661
    jne    L_2654                                # 2663: 75 EF
L_2665:
    cmp    al,0x22                               # 2665: 3C 22
    jne    L_266C                                # 2667: 75 03
    call   CHRGTR                                # 2669: E8 B1 E8
L_266C:
    push   bx                                    # 266C: 53
    .byte 0x8A, 0xC5 # 266D
    cmp    al,0x2c                               # 266F: 3C 2C
    jne    L_2680                                # 2671: 75 0D
    inc    cl                                    # 2673: FE C1
L_2675:
    dec    cl                                    # 2675: FE C9
    je     L_2680                                # 2677: 74 07
    dec    bx                                    # 2679: 4B
    mov    al,BYTE PTR [bx]                      # 267A: 8A 07
    cmp    al,0x20                               # 267C: 3C 20
    je     L_2675                                # 267E: 74 F5
L_2680:
    pop    bx                                    # 2680: 5B
    pop    si                                    # 2681: 5E
    xchg   si,bx                                 # 2682: 87 DE
    push   si                                    # 2684: 56
    inc    bx                                    # 2685: 43
    xchg   dx,bx                                 # 2686: 87 DA
    .byte 0x8A, 0xC1 # 2688
    call   STRAD2                                # 268A: E8 B4 FF
PUTNEW:
    mov    dx,DSCTMP                             # 268D: BA 2C 03
    .byte 0xB0 # 2690
PUTTMP:
    .byte 0x52 # 2691
    mov    bx,WORD PTR ds:TEMPPT                  # 2692: 8B 1E 0C 03
    mov    WORD PTR ds:FACLO,bx                  # 2696: 89 1E A3 04
    mov    al,0x3                                # 269A: B0 03
    mov    ds:VALTYP,al                           # 269C: A2 FB 02
    call   L_64B9                                # 269F: E8 17 3E
    mov    dx,DSCTMP+3                           # 26A2: BA 2F 03
    .byte 0x3B, 0xDA # 26A5
    mov    WORD PTR ds:TEMPPT,bx                  # 26A7: 89 1E 0C 03
    pop    bx                                    # 26AB: 5B
    mov    al,BYTE PTR [bx]                      # 26AC: 8A 07
    jne    L_264B                                # 26AE: 75 9B
    mov    dx,0x10                               # 26B0: BA 10 00
    jmp    L_07D8                                # 26B3: E9 22 E1
    .byte 0x43 # 26B6
L_26B7:
    call   L_264C                                # 26B7: E8 92 FF
L_26BA:
    call   L_28A9                                # 26BA: E8 EC 01
    call   L_653C                                # 26BD: E8 7C 3E
    inc    dh                                    # 26C0: FE C6
L_26C2:
    dec    dh                                    # 26C2: FE CE
    je     L_264B                                # 26C4: 74 85
    .byte 0x8B, 0xF1 # 26C6
    lods   al,BYTE PTR ds:[si]                   # 26C8: AC
    call   OUTDO                                # 26C9: E8 D9 04
    cmp    al,0xd                                # 26CC: 3C 0D
    jne    L_26D3                                # 26CE: 75 03
    call   L_2C78                                # 26D0: E8 A5 05
L_26D3:
    inc    cx                                    # 26D3: 41
    jmp    L_26C2                                # 26D4: EB EC
GETSPA:
    .byte 0x0A, 0xC0 # 26D6
    jmp    L_26DC                                # 26D8: EB 02
    .byte 0x58, 0x9E # 26DA
L_26DC:
    lahf                                         # 26DC: 9F
    push   ax                                    # 26DD: 50
    mov    bx,WORD PTR ds:STREND                  # 26DE: 8B 1E 5C 03
    xchg   dx,bx                                 # 26E2: 87 DA
    mov    bx,WORD PTR ds:FRETOP                  # 26E4: 8B 1E 2F 03
    not    al                                    # 26E8: F6 D0
    .byte 0x8A, 0xC8 # 26EA
    mov    ch,0xff                               # 26EC: B5 FF
    .byte 0x03, 0xD9 # 26EE
    inc    bx                                    # 26F0: 43
    .byte 0x3B, 0xDA # 26F1
    jb     L_2704                                # 26F3: 72 0F
    mov    WORD PTR ds:FRETOP,bx                  # 26F5: 89 1E 2F 03
    inc    bx                                    # 26F9: 43
    xchg   dx,bx                                 # 26FA: 87 DA
    pop    ax                                    # 26FC: 58
    sahf                                         # 26FD: 9E
    ret                                          # 26FE: C3
L_26FF:
    pop    ax                                    # 26FF: 58
    xchg   ah,al                                 # 2700: 86 C4
    sahf                                         # 2702: 9E
    ret                                          # 2703: C3
L_2704:
    pop    ax                                    # 2704: 58
    sahf                                         # 2705: 9E
    mov    dx,0xe                                # 2706: BA 0E 00
    jne    L_270E                                # 2709: 75 03
    jmp    L_07D8                                # 270B: E9 CA E0
L_270E:
    .byte 0x3A, 0xC0 # 270E
    lahf                                         # 2710: 9F
    push   ax                                    # 2711: 50
    mov    cx,0x26da                             # 2712: B9 DA 26
    push   cx                                    # 2715: 51
GARBA2:
    mov    bx,WORD PTR ds:MEMSIZ                  # 2716: 8B 1E 0A 03
FNDVAR:
    mov    WORD PTR ds:FRETOP,bx                  # 271A: 89 1E 2F 03
    mov    bx,0x0                                # 271E: BB 00 00
    push   bx                                    # 2721: 53
    mov    bx,WORD PTR ds:STREND                  # 2722: 8B 1E 5C 03
    push   bx                                    # 2726: 53
    mov    bx,TEMPST                              # 2727: BB 0E 03
    mov    dx,WORD PTR ds:TEMPPT                  # 272A: 8B 16 0C 03
    .byte 0x3B, 0xDA # 272E
    mov    cx,0x272a                             # 2730: B9 2A 27
    je     L_2738                                # 2733: 74 03
    jmp    L_27D4                                # 2735: E9 9C 00
L_2738:
    mov    bx,0x3e2                              # 2738: BB E2 03
    mov    WORD PTR ds:TEMP9,bx                  # 273B: 89 1E 4E 04
    mov    bx,WORD PTR ds:ARYTAB                  # 273F: 8B 1E 5A 03
    mov    WORD PTR ds:ARYTA2,bx                  # 2743: 89 1E 4B 04
    mov    bx,WORD PTR ds:VARTAB                  # 2747: 8B 1E 58 03
L_274B:
    mov    dx,WORD PTR ds:ARYTA2                  # 274B: 8B 16 4B 04
    .byte 0x3B, 0xDA # 274F
    je     L_276E                                # 2751: 74 1B
    mov    al,BYTE PTR [bx]                      # 2753: 8A 07
    inc    bx                                    # 2755: 43
    inc    bx                                    # 2756: 43
    inc    bx                                    # 2757: 43
    push   ax                                    # 2758: 50
    call   L_3AA1                                # 2759: E8 45 13
    pop    ax                                    # 275C: 58
    cmp    al,0x3                                # 275D: 3C 03
    jne    L_2766                                # 275F: 75 05
    call   L_27D5                                # 2761: E8 71 00
    .byte 0x32, 0xC0 # 2764
L_2766:
    .byte 0x8A, 0xD0 # 2766
    mov    dh,0x0                                # 2768: B6 00
    .byte 0x03, 0xDA # 276A
    jmp    L_274B                                # 276C: EB DD
L_276E:
    mov    bx,WORD PTR ds:TEMP9                  # 276E: 8B 1E 4E 04
    mov    dx,WORD PTR [bx]                      # 2772: 8B 17
    .byte 0x0B, 0xD2 # 2774
    mov    bx,WORD PTR ds:ARYTAB                  # 2776: 8B 1E 5A 03
    je     L_2795                                # 277A: 74 19
    xchg   dx,bx                                 # 277C: 87 DA
    mov    WORD PTR ds:TEMP9,bx                  # 277E: 89 1E 4E 04
    inc    bx                                    # 2782: 43
    inc    bx                                    # 2783: 43
    mov    dx,WORD PTR [bx]                      # 2784: 8B 17
    inc    bx                                    # 2786: 43
    inc    bx                                    # 2787: 43
    xchg   dx,bx                                 # 2788: 87 DA
    .byte 0x03, 0xDA # 278A
    mov    WORD PTR ds:ARYTA2,bx                  # 278C: 89 1E 4B 04
    xchg   dx,bx                                 # 2790: 87 DA
    jmp    L_274B                                # 2792: EB B7
L_2794:
    pop    cx                                    # 2794: 59
L_2795:
    mov    dx,WORD PTR ds:STREND                  # 2795: 8B 16 5C 03
    .byte 0x3B, 0xDA # 2799
    jne    L_27A0                                # 279B: 75 03
    .byte 0xE9, 0x6C, 0x00 # 279D
L_27A0:
    mov    al,BYTE PTR [bx]                      # 27A0: 8A 07
    inc    bx                                    # 27A2: 43
    push   ax                                    # 27A3: 50
    inc    bx                                    # 27A4: 43
    inc    bx                                    # 27A5: 43
    call   L_3AA1                                # 27A6: E8 F8 12
    mov    cl,BYTE PTR [bx]                      # 27A9: 8A 0F
    inc    bx                                    # 27AB: 43
    mov    ch,BYTE PTR [bx]                      # 27AC: 8A 2F
    inc    bx                                    # 27AE: 43
    pop    ax                                    # 27AF: 58
    push   bx                                    # 27B0: 53
    .byte 0x03, 0xD9 # 27B1
    cmp    al,0x3                                # 27B3: 3C 03
    jne    L_2794                                # 27B5: 75 DD
    mov    WORD PTR ds:TEMP8,bx                  # 27B7: 89 1E 33 03
    pop    bx                                    # 27BB: 5B
    mov    cl,BYTE PTR [bx]                      # 27BC: 8A 0F
    mov    ch,0x0                                # 27BE: B5 00
    .byte 0x03, 0xD9, 0x03, 0xD9 # 27C0
    inc    bx                                    # 27C4: 43
    xchg   dx,bx                                 # 27C5: 87 DA
    mov    bx,WORD PTR ds:TEMP8                  # 27C7: 8B 1E 33 03
    xchg   dx,bx                                 # 27CB: 87 DA
    .byte 0x3B, 0xDA # 27CD
    je     L_2795                                # 27CF: 74 C4
    mov    cx,0x27c5                             # 27D1: B9 C5 27
L_27D4:
    push   cx                                    # 27D4: 51
L_27D5:
    .byte 0x32, 0xC0 # 27D5
    or     al,BYTE PTR [bx]                      # 27D7: 0A 07
    lahf                                         # 27D9: 9F
    inc    bx                                    # 27DA: 43
    sahf                                         # 27DB: 9E
    mov    dl,BYTE PTR [bx]                      # 27DC: 8A 17
    lahf                                         # 27DE: 9F
    inc    bx                                    # 27DF: 43
    sahf                                         # 27E0: 9E
    mov    dh,BYTE PTR [bx]                      # 27E1: 8A 37
    lahf                                         # 27E3: 9F
    inc    bx                                    # 27E4: 43
    sahf                                         # 27E5: 9E
    jne    L_27E9                                # 27E6: 75 01
L_27E8:
    ret                                          # 27E8: C3
L_27E9:
    .byte 0x8B, 0xCB # 27E9
    mov    bx,WORD PTR ds:FRETOP                  # 27EB: 8B 1E 2F 03
    .byte 0x3B, 0xDA, 0x8B, 0xD9 # 27EF
    jb     L_27E8                                # 27F3: 72 F3
    pop    bx                                    # 27F5: 5B
    pop    si                                    # 27F6: 5E
    xchg   si,bx                                 # 27F7: 87 DE
    push   si                                    # 27F9: 56
    .byte 0x3B, 0xDA # 27FA
    pop    si                                    # 27FC: 5E
    xchg   si,bx                                 # 27FD: 87 DE
    push   si                                    # 27FF: 56
    push   bx                                    # 2800: 53
    .byte 0x8B, 0xD9 # 2801
    jae    L_27E8                                # 2803: 73 E3
    pop    cx                                    # 2805: 59
    pop    ax                                    # 2806: 58
    pop    ax                                    # 2807: 58
    push   bx                                    # 2808: 53
    push   dx                                    # 2809: 52
    push   cx                                    # 280A: 51
L_280B:
    ret                                          # 280B: C3
L_280C:
    pop    dx                                    # 280C: 5A
    pop    bx                                    # 280D: 5B
    .byte 0x0B, 0xDB # 280E
    je     L_280B                                # 2810: 74 F9
    dec    bx                                    # 2812: 4B
    mov    ch,BYTE PTR [bx]                      # 2813: 8A 2F
    dec    bx                                    # 2815: 4B
    mov    cl,BYTE PTR [bx]                      # 2816: 8A 0F
    push   bx                                    # 2818: 53
    dec    bx                                    # 2819: 4B
    mov    bl,BYTE PTR [bx]                      # 281A: 8A 1F
    mov    bh,0x0                                # 281C: B7 00
    .byte 0x03, 0xD9, 0x8A, 0xF5, 0x8A, 0xD1 # 281E
    dec    bx                                    # 2824: 4B
    .byte 0x8B, 0xCB # 2825
    mov    bx,WORD PTR ds:FRETOP                  # 2827: 8B 1E 2F 03
    call   L_64CE                                # 282B: E8 A0 3C
    pop    bx                                    # 282E: 5B
    mov    BYTE PTR [bx],cl                      # 282F: 88 0F
    inc    bx                                    # 2831: 43
    mov    BYTE PTR [bx],ch                      # 2832: 88 2F
    .byte 0x8B, 0xD9 # 2834
    dec    bx                                    # 2836: 4B
    jmp    FNDVAR                                # 2837: E9 E0 FE
L_283A:
    push   cx                                    # 283A: 51
    push   bx                                    # 283B: 53
    mov    bx,WORD PTR ds:FACLO                  # 283C: 8B 1E A3 04
    pop    si                                    # 2840: 5E
    xchg   si,bx                                 # 2841: 87 DE
    push   si                                    # 2843: 56
    call   EVAL                                # 2844: E8 A0 F0
    pop    si                                    # 2847: 5E
    xchg   si,bx                                 # 2848: 87 DE
    push   si                                    # 284A: 56
    call   L_643B                                # 284B: E8 ED 3B
    mov    al,BYTE PTR [bx]                      # 284E: 8A 07
    push   bx                                    # 2850: 53
    mov    bx,WORD PTR ds:FACLO                  # 2851: 8B 1E A3 04
    push   bx                                    # 2855: 53
    add    al,BYTE PTR [bx]                      # 2856: 02 07
    mov    dx,0xf                                # 2858: BA 0F 00
    jae    L_2860                                # 285B: 73 03
    jmp    L_07D8                                # 285D: E9 78 DF
L_2860:
    call   STRINI                                # 2860: E8 DB FD
    pop    dx                                    # 2863: 5A
    call   L_28AF                                # 2864: E8 48 00
    pop    si                                    # 2867: 5E
    xchg   si,bx                                 # 2868: 87 DE
    push   si                                    # 286A: 56
    call   L_28AD                                # 286B: E8 3F 00
    push   bx                                    # 286E: 53
    mov    bx,WORD PTR ds:DSCTMP+1                  # 286F: 8B 1E 2D 03
    xchg   dx,bx                                 # 2873: 87 DA
    call   L_2886                                # 2875: E8 0E 00
    call   L_2886                                # 2878: E8 0B 00
    mov    bx,0x173a                             # 287B: BB 3A 17
    pop    si                                    # 287E: 5E
    xchg   si,bx                                 # 287F: 87 DE
    push   si                                    # 2881: 56
    push   bx                                    # 2882: 53
    jmp    PUTNEW                                # 2883: E9 07 FE
L_2886:
    pop    bx                                    # 2886: 5B
    pop    si                                    # 2887: 5E
    xchg   si,bx                                 # 2888: 87 DE
    push   si                                    # 288A: 56
    mov    al,BYTE PTR [bx]                      # 288B: 8A 07
    inc    bx                                    # 288D: 43
    mov    cl,BYTE PTR [bx]                      # 288E: 8A 0F
    inc    bx                                    # 2890: 43
    mov    ch,BYTE PTR [bx]                      # 2891: 8A 2F
    .byte 0x8A, 0xD8 # 2893
L_2895:
    inc    bl                                    # 2895: FE C3
L_2897:
    dec    bl                                    # 2897: FE CB
    jne    L_289C                                # 2899: 75 01
L_289B:
    ret                                          # 289B: C3
L_289C:
    .byte 0x8B, 0xF1 # 289C
    lods   al,BYTE PTR ds:[si]                   # 289E: AC
    .byte 0x8B, 0xFA # 289F
    stos   BYTE PTR es:[di],al                   # 28A1: AA
    inc    cx                                    # 28A2: 41
    inc    dx                                    # 28A3: 42
    jmp    L_2897                                # 28A4: EB F1
L_28A6:
    call   L_643B                                # 28A6: E8 92 3B
L_28A9:
    mov    bx,WORD PTR ds:FACLO                  # 28A9: 8B 1E A3 04
L_28AD:
    xchg   dx,bx                                 # 28AD: 87 DA
L_28AF:
    call   L_28D2                                # 28AF: E8 20 00
    xchg   dx,bx                                 # 28B2: 87 DA
    jne    L_289B                                # 28B4: 75 E5
    push   dx                                    # 28B6: 52
    .byte 0x8A, 0xF5, 0x8A, 0xD1 # 28B7
    dec    dx                                    # 28BB: 4A
    mov    cl,BYTE PTR [bx]                      # 28BC: 8A 0F
    mov    bx,WORD PTR ds:FRETOP                  # 28BE: 8B 1E 2F 03
    .byte 0x3B, 0xDA # 28C2
    jne    L_28D0                                # 28C4: 75 0A
    .byte 0x32, 0xC0, 0x8A, 0xE8, 0x03, 0xD9 # 28C6
    mov    WORD PTR ds:FRETOP,bx                  # 28CC: 89 1E 2F 03
L_28D0:
    pop    bx                                    # 28D0: 5B
L_28D1:
    ret                                          # 28D1: C3
L_28D2:
    int    0xee                                  # 28D2: CD EE
    mov    bx,WORD PTR ds:TEMPPT                  # 28D4: 8B 1E 0C 03
    dec    bx                                    # 28D8: 4B
    mov    ch,BYTE PTR [bx]                      # 28D9: 8A 2F
    dec    bx                                    # 28DB: 4B
    mov    cl,BYTE PTR [bx]                      # 28DC: 8A 0F
    dec    bx                                    # 28DE: 4B
    .byte 0x3B, 0xDA # 28DF
    jne    L_28D1                                # 28E1: 75 EE
    mov    WORD PTR ds:TEMPPT,bx                  # 28E3: 89 1E 0C 03
    ret                                          # 28E7: C3
LEN:
    mov    cx,0x1b7f                             # 28E8: B9 7F 1B
    push   cx                                    # 28EB: 51
L_28EC:
    call   L_28A6                                # 28EC: E8 B7 FF
    .byte 0x32, 0xC0, 0x8A, 0xF0 # 28EF
    mov    al,BYTE PTR [bx]                      # 28F3: 8A 07
    .byte 0x0A, 0xC0 # 28F5
    ret                                          # 28F7: C3
ASC:
    mov    cx,0x1b7f                             # 28F8: B9 7F 1B
    push   cx                                    # 28FB: 51
L_28FC:
    call   L_28EC                                # 28FC: E8 ED FF
    jne    L_2904                                # 28FF: 75 03
    jmp    FCERR                                # 2901: E9 55 E7
L_2904:
    inc    bx                                    # 2904: 43
    mov    dx,WORD PTR [bx]                      # 2905: 8B 17
    .byte 0x8B, 0xF2 # 2907
    lods   al,BYTE PTR ds:[si]                   # 2909: AC
    ret                                          # 290A: C3
CHR_DOLLAR:
    call   STRIN1                                # 290B: E8 2E FD
    call   CONINT                                # 290E: E8 0E F6
L_2911:
    mov    bx,WORD PTR ds:DSCTMP+1                  # 2911: 8B 1E 2D 03
    mov    BYTE PTR [bx],dl                      # 2915: 88 17
L_2917:
    pop    cx                                    # 2917: 59
    jmp    PUTNEW                                # 2918: E9 72 FD
L_291B:
    call   CHRGTR                                # 291B: E8 FF E5
    call   SYNCHR                                # 291E: E8 D3 04
    .byte '('                                  # 2921: 28 -- SYNCHR inline operand
    .byte 0xE8 # 2922 -- decoded continuation: call   0x1f1c
    div    bp                                    # 2923: F7 F5
    push   dx                                    # 2925: 52
    call   SYNCHR                                # 2926: E8 CB 04
    .byte ','                                  # 2929: 2C -- SYNCHR inline operand
    .byte 0xE8 # 292A -- decoded continuation: call   0x1727
    cli                                          # 292B: FA
    in     ax,dx                                 # 292C: ED
    call   SYNCHR                                # 292D: E8 C4 04
    .byte ')'                                  # 2930: 29 -- SYNCHR inline operand
    .byte 0x5E, 0x87 # 2931 -- decoded continuation: pop    si ; xchg   si,bx
    ficom  WORD PTR [bp+0x53]                    # 2933: DE 56 53
    call   GETYPR                                # 2936: E8 EC F1
    je     L_2940                                # 2939: 74 05
    call   CONINT                                # 293B: E8 E1 F5
    jmp    L_2943                                # 293E: EB 03
L_2940:
    call   L_28FC                                # 2940: E8 B9 FF
L_2943:
    pop    dx                                    # 2943: 5A
    call   L_294C                                # 2944: E8 05 00
SPACE_DOLLAR:
    call   CONINT                                # 2947: E8 D5 F5
    mov    al,0x20                               # 294A: B0 20
L_294C:
    push   ax                                    # 294C: 50
    .byte 0x8A, 0xC2 # 294D
    call   STRINI                                # 294F: E8 EC FC
    .byte 0x8A, 0xE8 # 2952
    pop    ax                                    # 2954: 58
    inc    ch                                    # 2955: FE C5
    dec    ch                                    # 2957: FE CD
    je     L_2917                                # 2959: 74 BC
    mov    bx,WORD PTR ds:DSCTMP+1                  # 295B: 8B 1E 2D 03
L_295F:
    mov    BYTE PTR [bx],al                      # 295F: 88 07
    inc    bx                                    # 2961: 43
    dec    ch                                    # 2962: FE CD
    jne    L_295F                                # 2964: 75 F9
    jmp    L_2917                                # 2966: EB AF
LEFT_DOLLAR:
    call   L_2A0E                                # 2968: E8 A3 00
    .byte 0x32, 0xC0 # 296B
L_296D:
    pop    si                                    # 296D: 5E
    xchg   si,bx                                 # 296E: 87 DE
    push   si                                    # 2970: 56
    .byte 0x8A, 0xC8, 0xB0 # 2971
L_2974:
    .byte 0x53 # 2974
    push   bx                                    # 2975: 53
    mov    al,BYTE PTR [bx]                      # 2976: 8A 07
    .byte 0x3A, 0xC5 # 2978
    jb     L_297F                                # 297A: 72 03
    .byte 0x8A, 0xC5, 0xBA # 297C
L_297F:
    .byte 0xB1, 0x00 # 297F
    push   cx                                    # 2981: 51
    call   GETSPA                                # 2982: E8 51 FD
    pop    cx                                    # 2985: 59
    pop    bx                                    # 2986: 5B
    push   bx                                    # 2987: 53
    inc    bx                                    # 2988: 43
    mov    ch,BYTE PTR [bx]                      # 2989: 8A 2F
    inc    bx                                    # 298B: 43
    mov    bh,BYTE PTR [bx]                      # 298C: 8A 3F
    .byte 0x8A, 0xDD # 298E
    mov    ch,0x0                                # 2990: B5 00
    .byte 0x03, 0xD9, 0x8B, 0xCB # 2992
    call   STRAD2                                # 2996: E8 A8 FC
    .byte 0x8A, 0xD8 # 2999
    call   L_2895                                # 299B: E8 F7 FE
    pop    dx                                    # 299E: 5A
    call   L_28AF                                # 299F: E8 0D FF
    jmp    PUTNEW                                # 29A2: E9 E8 FC
RIGHT_DOLLAR:
    call   L_2A0E                                # 29A5: E8 66 00
    pop    dx                                    # 29A8: 5A
    push   dx                                    # 29A9: 52
    .byte 0x8B, 0xF2 # 29AA
    lods   al,BYTE PTR ds:[si]                   # 29AC: AC
    .byte 0x2A, 0xC5 # 29AD
    jmp    L_296D                                # 29AF: EB BC
MID_DOLLAR:
    xchg   dx,bx                                 # 29B1: 87 DA
    mov    al,BYTE PTR [bx]                      # 29B3: 8A 07
    call   L_2A14                                # 29B5: E8 5C 00
    inc    ch                                    # 29B8: FE C5
    dec    ch                                    # 29BA: FE CD
    jne    L_29C1                                # 29BC: 75 03
    jmp    FCERR                                # 29BE: E9 98 E6
L_29C1:
    push   cx                                    # 29C1: 51
    call   L_2B7A                                # 29C2: E8 B5 01
    pop    ax                                    # 29C5: 58
    xchg   ah,al                                 # 29C6: 86 C4
    sahf                                         # 29C8: 9E
    pop    si                                    # 29C9: 5E
    xchg   si,bx                                 # 29CA: 87 DE
    push   si                                    # 29CC: 56
    mov    cx,0x2975                             # 29CD: B9 75 29
    push   cx                                    # 29D0: 51
    dec    al                                    # 29D1: FE C8
    cmp    al,BYTE PTR [bx]                      # 29D3: 3A 07
    mov    ch,0x0                                # 29D5: B5 00
    jb     L_29DA                                # 29D7: 72 01
L_29D9:
    ret                                          # 29D9: C3
L_29DA:
    .byte 0x8A, 0xC8 # 29DA
    mov    al,BYTE PTR [bx]                      # 29DC: 8A 07
    .byte 0x2A, 0xC1, 0x3A, 0xC2, 0x8A, 0xE8 # 29DE
    jb     L_29D9                                # 29E4: 72 F3
    .byte 0x8A, 0xEA # 29E6
    ret                                          # 29E8: C3
VAL:
    call   L_28EC                                # 29E9: E8 00 FF
    jne    L_29F1                                # 29EC: 75 03
    jmp    L_1B7F                                # 29EE: E9 8E F1
L_29F1:
    .byte 0x8A, 0xD0 # 29F1
    inc    bx                                    # 29F3: 43
    mov    bx,WORD PTR [bx]                      # 29F4: 8B 1F
    push   bx                                    # 29F6: 53
    .byte 0x03, 0xDA # 29F7
    mov    ch,BYTE PTR [bx]                      # 29F9: 8A 2F
    mov    BYTE PTR [bx],dh                      # 29FB: 88 37
    pop    si                                    # 29FD: 5E
    xchg   si,bx                                 # 29FE: 87 DE
    push   si                                    # 2A00: 56
    push   cx                                    # 2A01: 51
    dec    bx                                    # 2A02: 4B
    call   CHRGTR                                # 2A03: E8 17 E5
    call   L_69C7                                # 2A06: E8 BE 3F
    pop    cx                                    # 2A09: 59
    pop    bx                                    # 2A0A: 5B
    mov    BYTE PTR [bx],ch                      # 2A0B: 88 2F
    ret                                          # 2A0D: C3
L_2A0E:
    xchg   dx,bx                                 # 2A0E: 87 DA
    call   SYNCHR                                # 2A10: E8 E1 03
    .byte ')'                                  # 2A13: 29 -- SYNCHR inline operand
L_2A14:
    .byte 0x59, 0x5A # 2A14
    push   cx                                    # 2A16: 51
    .byte 0x8A, 0xEA # 2A17
L_2A19:
    ret                                          # 2A19: C3
L_2A1A:
    call   CHRGTR                                # 2A1A: E8 00 E5
    call   L_1723                                # 2A1D: E8 03 ED
    call   GETYPR                                # 2A20: E8 02 F1
    mov    al,0x1                                # 2A23: B0 01
    push   ax                                    # 2A25: 50
    je     L_2A3E                                # 2A26: 74 16
    pop    ax                                    # 2A28: 58
    call   CONINT                                # 2A29: E8 F3 F4
    .byte 0x0A, 0xC0 # 2A2C
    jne    L_2A33                                # 2A2E: 75 03
    jmp    FCERR                                # 2A30: E9 26 E6
L_2A33:
    push   ax                                    # 2A33: 50
    call   SYNCHR                                # 2A34: E8 BD 03
    .byte ','                                  # 2A37: 2C -- SYNCHR inline operand
    .byte 0xE8 # 2A38 -- decoded continuation: call   0x1727
    in     al,dx                                 # 2A39: EC
    in     al,dx                                 # 2A3A: EC
    call   L_643B                                # 2A3B: E8 FD 39
L_2A3E:
    call   SYNCHR                                # 2A3E: E8 B3 03
    .byte ','                                  # 2A41: 2C -- SYNCHR inline operand
    .byte 0x53 # 2A42 -- decoded continuation: push   bx
    mov    bx,WORD PTR ds:FACLO                  # 2A43: 8B 1E A3 04
    pop    si                                    # 2A47: 5E
    xchg   si,bx                                 # 2A48: 87 DE
    push   si                                    # 2A4A: 56
    call   FRMEVL                                # 2A4B: E8 D9 EC
    call   SYNCHR                                # 2A4E: E8 A3 03
    .byte ')'                                  # 2A51: 29 -- SYNCHR inline operand
    .byte 0x53, 0xE8 # 2A52 -- decoded continuation: push   bx ; call   0x28a6
    push   ax                                    # 2A54: 50
    inc    BYTE PTR [bx+0x59da]                  # 2A55: FE 87 DA 59
    pop    bx                                    # 2A59: 5B
    pop    ax                                    # 2A5A: 58
    push   cx                                    # 2A5B: 51
    mov    cx,0x6507                             # 2A5C: B9 07 65
    push   cx                                    # 2A5F: 51
    mov    cx,0x1b7f                             # 2A60: B9 7F 1B
    push   cx                                    # 2A63: 51
    push   ax                                    # 2A64: 50
    push   dx                                    # 2A65: 52
    call   L_28AD                                # 2A66: E8 44 FE
    pop    dx                                    # 2A69: 5A
    pop    ax                                    # 2A6A: 58
    .byte 0x8A, 0xE8 # 2A6B
    dec    al                                    # 2A6D: FE C8
    .byte 0x8A, 0xC8 # 2A6F
    cmp    al,BYTE PTR [bx]                      # 2A71: 3A 07
    mov    al,0x0                                # 2A73: B0 00
    jae    L_2A19                                # 2A75: 73 A2
    .byte 0x8B, 0xF2 # 2A77
    lods   al,BYTE PTR ds:[si]                   # 2A79: AC
    .byte 0x0A, 0xC0, 0x8A, 0xC5 # 2A7A
    je     L_2A19                                # 2A7E: 74 99
    mov    al,BYTE PTR [bx]                      # 2A80: 8A 07
    inc    bx                                    # 2A82: 43
    mov    ch,BYTE PTR [bx]                      # 2A83: 8A 2F
    inc    bx                                    # 2A85: 43
    mov    bh,BYTE PTR [bx]                      # 2A86: 8A 3F
    .byte 0x8A, 0xDD # 2A88
    mov    ch,0x0                                # 2A8A: B5 00
    .byte 0x03, 0xD9, 0x2A, 0xC1, 0x8A, 0xE8 # 2A8C
    push   cx                                    # 2A92: 51
    push   dx                                    # 2A93: 52
    pop    si                                    # 2A94: 5E
    xchg   si,bx                                 # 2A95: 87 DE
    push   si                                    # 2A97: 56
    mov    cl,BYTE PTR [bx]                      # 2A98: 8A 0F
    inc    bx                                    # 2A9A: 43
    mov    dx,WORD PTR [bx]                      # 2A9B: 8B 17
    pop    bx                                    # 2A9D: 5B
L_2A9E:
    push   bx                                    # 2A9E: 53
    push   dx                                    # 2A9F: 52
    push   cx                                    # 2AA0: 51
L_2AA1:
    .byte 0x8B, 0xF2 # 2AA1
    lods   al,BYTE PTR ds:[si]                   # 2AA3: AC
    cmp    al,BYTE PTR [bx]                      # 2AA4: 3A 07
    jne    L_2AC6                                # 2AA6: 75 1E
    inc    dx                                    # 2AA8: 42
    dec    cl                                    # 2AA9: FE C9
    je     L_2AB9                                # 2AAB: 74 0C
    inc    bx                                    # 2AAD: 43
    dec    ch                                    # 2AAE: FE CD
    jne    L_2AA1                                # 2AB0: 75 EF
    pop    dx                                    # 2AB2: 5A
    pop    dx                                    # 2AB3: 5A
    pop    cx                                    # 2AB4: 59
L_2AB5:
    pop    dx                                    # 2AB5: 5A
    .byte 0x32, 0xC0 # 2AB6
    ret                                          # 2AB8: C3
L_2AB9:
    pop    bx                                    # 2AB9: 5B
    pop    dx                                    # 2ABA: 5A
    pop    dx                                    # 2ABB: 5A
    pop    cx                                    # 2ABC: 59
    .byte 0x8A, 0xC5, 0x2A, 0xC7, 0x02, 0xC1 # 2ABD
    inc    al                                    # 2AC3: FE C0
L_2AC5:
    ret                                          # 2AC5: C3
L_2AC6:
    pop    cx                                    # 2AC6: 59
    pop    dx                                    # 2AC7: 5A
    pop    bx                                    # 2AC8: 5B
    inc    bx                                    # 2AC9: 43
    dec    ch                                    # 2ACA: FE CD
    jne    L_2A9E                                # 2ACC: 75 D0
    jmp    L_2AB5                                # 2ACE: EB E5
L_2AD0:
    call   SYNCHR                                # 2AD0: E8 21 03
    .byte '('                                  # 2AD3: 28 -- SYNCHR inline operand
    call   PTRGET                                # 2AD4: E8 97 0C
    call   L_643B                                # 2AD7: E8 61 39
    push   bx                                     # 2ADA: 53
    push   dx                                     # 2ADB: 52
    xchg   dx,bx                                 # 2ADC: 87 DA
    inc    bx                                    # 2ADE: 43
    mov    dx,WORD PTR [bx]                      # 2ADF: 8B 17
    mov    bx,WORD PTR ds:STREND                  # 2AE1: 8B 1E 5C 03
    .byte 0x3B, 0xDA # 2AE5
    jb     L_2AFB                                # 2AE7: 72 12
    mov    bx,WORD PTR ds:TXTTAB                   # 2AE9: 8B 1E 30 00
    .byte 0x3B, 0xDA # 2AED
    jae    L_2AFB                                # 2AEF: 73 0A
    pop    bx                                    # 2AF1: 5B
    push   bx                                    # 2AF2: 53
    call   L_2624                                # 2AF3: E8 2E FB
    pop    bx                                    # 2AF6: 5B
    push   bx                                    # 2AF7: 53
    call   L_64B9                                # 2AF8: E8 BE 39
L_2AFB:
    pop    bx                                    # 2AFB: 5B
    pop    si                                    # 2AFC: 5E
    xchg   si,bx                                 # 2AFD: 87 DE
    push   si                                    # 2AFF: 56
    call   SYNCHR                                # 2B00: E8 F1 02
    .byte ','                                  # 2B03: 2C -- SYNCHR inline operand
    .byte 0xE8 # 2B04 -- decoded continuation: call   0x1f1c
    adc    ax,0xaf4                              # 2B05: 15 F4 0A
    .byte 0xC0, 0x75, 0x03, 0xE9 # 2B08
    dec    bx                                    # 2B0C: 4B
    in     ax,0x50                               # 2B0D: E5 50
    mov    al,BYTE PTR [bx]                      # 2B0F: 8A 07
    call   L_2B7A                                # 2B11: E8 66 00
    push   dx                                    # 2B14: 52
    call   L_171C                                # 2B15: E8 04 EC
    push   bx                                    # 2B18: 53
    call   L_28A6                                # 2B19: E8 8A FD
    xchg   dx,bx                                 # 2B1C: 87 DA
    pop    bx                                    # 2B1E: 5B
    pop    cx                                    # 2B1F: 59
    pop    ax                                    # 2B20: 58
    .byte 0x8A, 0xE8 # 2B21
    pop    si                                    # 2B23: 5E
    xchg   si,bx                                 # 2B24: 87 DE
    push   si                                    # 2B26: 56
    push   bx                                    # 2B27: 53
    mov    bx,0x6507                             # 2B28: BB 07 65
    pop    si                                    # 2B2B: 5E
    xchg   si,bx                                 # 2B2C: 87 DE
    push   si                                    # 2B2E: 56
    .byte 0x8A, 0xC1, 0x0A, 0xC0 # 2B2F
    je     L_2AC5                                # 2B33: 74 90
    mov    al,BYTE PTR [bx]                      # 2B35: 8A 07
    .byte 0x2A, 0xC5 # 2B37
    jae    L_2B3E                                # 2B39: 73 03
    jmp    FCERR                                # 2B3B: E9 1B E5
L_2B3E:
    inc    al                                    # 2B3E: FE C0
    .byte 0x3A, 0xC1 # 2B40
    jb     L_2B46                                # 2B42: 72 02
    .byte 0x8A, 0xC1 # 2B44
L_2B46:
    .byte 0x8A, 0xCD # 2B46
    dec    cl                                    # 2B48: FE C9
    mov    ch,0x0                                # 2B4A: B5 00
    push   dx                                    # 2B4C: 52
    inc    bx                                    # 2B4D: 43
    mov    dl,BYTE PTR [bx]                      # 2B4E: 8A 17
    inc    bx                                    # 2B50: 43
    mov    bh,BYTE PTR [bx]                      # 2B51: 8A 3F
    .byte 0x8A, 0xDA, 0x03, 0xD9, 0x8A, 0xE8 # 2B53
    pop    dx                                    # 2B59: 5A
    xchg   dx,bx                                 # 2B5A: 87 DA
    mov    cl,BYTE PTR [bx]                      # 2B5C: 8A 0F
    inc    bx                                    # 2B5E: 43
    mov    bx,WORD PTR [bx]                      # 2B5F: 8B 1F
    xchg   dx,bx                                 # 2B61: 87 DA
    .byte 0x8A, 0xC1, 0x0A, 0xC0 # 2B63
    jne    L_2B6A                                # 2B67: 75 01
L_2B69:
    ret                                          # 2B69: C3
L_2B6A:
    .byte 0x8B, 0xF2 # 2B6A
    lods   al,BYTE PTR ds:[si]                   # 2B6C: AC
    mov    BYTE PTR [bx],al                      # 2B6D: 88 07
    inc    dx                                    # 2B6F: 42
    inc    bx                                    # 2B70: 43
    dec    cl                                    # 2B71: FE C9
    je     L_2B69                                # 2B73: 74 F4
    dec    ch                                    # 2B75: FE CD
    jne    L_2B6A                                # 2B77: 75 F1
    ret                                          # 2B79: C3
L_2B7A:
    mov    dl,0xff                               # 2B7A: B2 FF
    cmp    al,0x29                               # 2B7C: 3C 29
    je     L_2B87                                # 2B7E: 74 07
    call   SYNCHR                                # 2B80: E8 71 02
    .byte ','                                  # 2B83: 2C -- SYNCHR inline operand
    .byte 0xE8 # 2B84 -- decoded continuation: call   0x1f1c
    xchg   bp,ax                                 # 2B85: 95
    .byte 0xF3 # 2B86
L_2B87:
    .byte 0xE8, 0x6A, 0x02 # 2B87
    .byte ')'                                  # 2B8A: 29 -- SYNCHR inline operand
    .byte 0xC3 # 2B8B -- decoded continuation: ret
FRE:
    call   GETYPR                                # 2B8C: E8 96 EF
    je     L_2B94                                # 2B8F: 74 03
    .byte 0xE9, 0x06, 0x00 # 2B91
L_2B94:
    call   L_28A9                                # 2B94: E8 12 FD
    call   GARBA2                                # 2B97: E8 7C FB
L_2B9A:
    mov    dx,WORD PTR ds:STREND                  # 2B9A: 8B 16 5C 03
    mov    bx,WORD PTR ds:FRETOP                  # 2B9E: 8B 1E 2F 03
    jmp    L_1B70                                # 2BA2: E9 CB EF
OUTDO:
    int    0xb4                                  # 2BA5: CD B4
    lahf                                         # 2BA7: 9F
    xchg   ah,al                                 # 2BA8: 86 C4
    push   ax                                    # 2BAA: 50
    xchg   ah,al                                 # 2BAB: 86 C4
    push   bx                                    # 2BAD: 53
    call   ISFLIO                                # 2BAE: E8 25 04
    je     L_2BB6                                # 2BB1: 74 03
    jmp    L_4393                                # 2BB3: E9 DD 17
L_2BB6:
    pop    bx                                    # 2BB6: 5B
L_2BB7:
    pop    ax                                    # 2BB7: 58
    xchg   ah,al                                 # 2BB8: 86 C4
    sahf                                         # 2BBA: 9E
    push   cx                                    # 2BBB: 51
    lahf                                         # 2BBC: 9F
    push   ax                                    # 2BBD: 50
    jmp    L_2BD2                                # 2BBE: EB 12
L_2BC0:
    .byte 0x32, 0xC0 # 2BC0
    mov    ds:ONEFLG,al                           # 2BC2: A2 4F 03
    jmp    DATAS                                 # 2BC5: E9 93 E5
    .byte 0x19, 0xFE, 0xC8, 0xE8, 0x63, 0x23, 0xB0, 0x08, 0xEB, 0x38 # 2BC8
L_2BD2:
    cmp    al,0x9                                # 2BD2: 3C 09
    jne    L_2BE6                                # 2BD4: 75 10
L_2BD6:
    mov    al,0x20                               # 2BD6: B0 20
    call   OUTDO                                # 2BD8: E8 CA FF
    call   PTRGPS                                # 2BDB: E8 4E 23
    and    al,0x7                                # 2BDE: 24 07
    jne    L_2BD6                                # 2BE0: 75 F4
    pop    ax                                    # 2BE2: 58
    sahf                                         # 2BE3: 9E
    pop    cx                                    # 2BE4: 59
    ret                                          # 2BE5: C3
L_2BE6:
    cmp    al,0x20                               # 2BE6: 3C 20
    jb     L_2C0A                                # 2BE8: 72 20
    mov    al,ds:CRTWID                            # 2BEA: A0 29 00
    .byte 0x8A, 0xE8 # 2BED
    call   PTRGPS                                # 2BEF: E8 3A 23
    inc    ch                                    # 2BF2: FE C5
    je     L_2C01                                # 2BF4: 74 0B
    dec    ch                                    # 2BF6: FE CD
    .byte 0x3A, 0xC5 # 2BF8
    jne    L_2BFF                                # 2BFA: 75 03
    call   CRDO                                # 2BFC: E8 72 00
L_2BFF:
    je     L_2C0A                                # 2BFF: 74 09
L_2C01:
    cmp    al,0xff                               # 2C01: 3C FF
    je     L_2C0A                                # 2C03: 74 05
    inc    al                                    # 2C05: FE C0
    call   L_4F31                                # 2C07: E8 27 23
L_2C0A:
    pop    ax                                    # 2C0A: 58
    sahf                                         # 2C0B: 9E
    pop    cx                                    # 2C0C: 59
    lahf                                         # 2C0D: 9F
    push   ax                                    # 2C0E: 50
    pop    ax                                    # 2C0F: 58
    sahf                                         # 2C10: 9E
    call   L_4E90                                # 2C11: E8 7C 22
L_2C14:
    ret                                          # 2C14: C3
L_2C15:
    int    0xb5                                  # 2C15: CD B5
    call   ISFLIO                                # 2C17: E8 BC 03
    je     L_2C59                                # 2C1A: 74 3D
    call   L_43D5                                # 2C1C: E8 B6 17
    jae    L_2C14                                # 2C1F: 73 F3
    push   cx                                    # 2C21: 51
    push   dx                                    # 2C22: 52
    push   bx                                    # 2C23: 53
    mov    al,ds:NLONLY                           # 2C24: A0 36 05
    and    al,0xc8                               # 2C27: 24 C8
    mov    ds:NLONLY,al                           # 2C29: A2 36 05
    call   PRGFIN                                # 2C2C: E8 CC 18
    pop    bx                                    # 2C2F: 5B
    pop    dx                                    # 2C30: 5A
    pop    cx                                    # 2C31: 59
    mov    al,ds:CHNFLG                           # 2C32: A0 6B 04
    .byte 0x0A, 0xC0 # 2C35
    je     L_2C3C                                # 2C37: 74 03
    jmp    L_5D46                                # 2C39: E9 0A 31
L_2C3C:
    mov    al,ds:RUNFLG                           # 2C3C: A0 EF 04
    .byte 0x0A, 0xC0 # 2C3F
    je     L_2C4A                                # 2C41: 74 07
    mov    bx,0xee8                              # 2C43: BB E8 0E
    push   bx                                    # 2C46: 53
    jmp    RUNC                                # 2C47: E9 ED 00
L_2C4A:
    push   bx                                    # 2C4A: 53
    push   cx                                    # 2C4B: 51
    push   dx                                    # 2C4C: 52
    mov    bx,0x72d                              # 2C4D: BB 2D 07
    call   STROUT                                # 2C50: E8 02 4F
    pop    dx                                    # 2C53: 5A
    pop    cx                                    # 2C54: 59
    mov    al,0xd                                # 2C55: B0 0D
    pop    bx                                    # 2C57: 5B
    ret                                          # 2C58: C3
L_2C59:
    call   L_4D6E                                # 2C59: E8 12 21
L_2C5C:
    ret                                          # 2C5C: C3
CRDONZ:
    call   PTRGPS                                # 2C5D: E8 CC 22
    .byte 0x0A, 0xC0 # 2C60
    je     L_2C5C                                # 2C62: 74 F8
    jmp    CRDO                                # 2C64: EB 0B
    .byte 0xC6, 0x07, 0x00, 0xE8, 0x6A, 0x03, 0xBB, 0xF6, 0x01, 0x75, 0x07 # 2C66
CRDO:
    int    0xb6                                  # 2C71: CD B6
    mov    al,0xd                                # 2C73: B0 0D
    call   OUTDO                                # 2C75: E8 2D FF
L_2C78:
    call   ISFLIO                                # 2C78: E8 5B 03
    je     L_2C80                                # 2C7B: 74 03
    .byte 0x32, 0xC0 # 2C7D
    ret                                          # 2C7F: C3
L_2C80:
    .byte 0x32, 0xC0 # 2C80
    call   L_4F31                                # 2C82: E8 AC 22
    .byte 0x32, 0xC0 # 2C85
    ret                                          # 2C87: C3
L_2C88:
    int    0xb7                                  # 2C88: CD B7
    mov    al,ds:CTRL_BREAK_PENDING                            # 2C8A: A0 5E 00
    .byte 0x0A, 0xC0 # 2C8D
    jne    L_2C92                                # 2C8F: 75 01
    ret                                          # 2C91: C3
L_2C92:
    call   L_2C59                                # 2C92: E8 C4 FF
    jne    L_2C9A                                # 2C95: 75 03
    call   L_2E76                                # 2C97: E8 DC 01
L_2C9A:
    jmp    STOP                                  # 2C9A: E9 90 01
L_2C9D:
    call   L_5F8F                                # 2C9D: E8 EF 32
    push   bx                                    # 2CA0: 53
    call   L_4D53                                # 2CA1: E8 AF 20
    je     L_2CC7                                # 2CA4: 74 21
    call   L_2C59                                # 2CA6: E8 B0 FF
    .byte 0x0A, 0xC0 # 2CA9
    jne    L_2CBD                                # 2CAB: 75 10
    push   ax                                    # 2CAD: 50
    mov    al,0x2                                # 2CAE: B0 02
    call   STRINI                                # 2CB0: E8 8B F9
    mov    bx,WORD PTR ds:DSCTMP+1                  # 2CB3: 8B 1E 2D 03
    pop    dx                                    # 2CB7: 5A
    mov    WORD PTR [bx],dx                      # 2CB8: 89 17
    jmp    PUTNEW                                # 2CBA: E9 D0 F9
L_2CBD:
    push   ax                                    # 2CBD: 50
    call   STRIN1                                # 2CBE: E8 7B F9
    pop    ax                                    # 2CC1: 58
    .byte 0x8A, 0xD0 # 2CC2
    call   L_2911                                # 2CC4: E8 4A FC
L_2CC7:
    mov    bx,0x6                                # 2CC7: BB 06 00
    mov    WORD PTR ds:FACLO,bx                  # 2CCA: 89 1E A3 04
    mov    al,0x3                                # 2CCE: B0 03
    mov    ds:VALTYP,al                           # 2CD0: A2 FB 02
    pop    bx                                    # 2CD3: 5B
    ret                                          # 2CD4: C3
GETSTK:
    push   bx                                    # 2CD5: 53
    mov    bx,WORD PTR ds:MEMSIZ                  # 2CD6: 8B 1E 0A 03
    mov    ch,0x0                                # 2CDA: B5 00
    .byte 0x03, 0xD9, 0x03, 0xD9 # 2CDC
    mov    al,0x26                               # 2CE0: B0 26
    .byte 0x2A, 0xC3, 0x8A, 0xD8 # 2CE2
    mov    al,0xff                               # 2CE6: B0 FF
    .byte 0x1A, 0xC7, 0x8A, 0xF8 # 2CE8
    jb     L_2CF4                                # 2CEC: 72 06
    .byte 0x03, 0xDC # 2CEE
    pop    bx                                    # 2CF0: 5B
    jae    L_2CF4                                # 2CF1: 73 01
L_2CF3:
    ret                                          # 2CF3: C3
L_2CF4:
    mov    bx,WORD PTR ds:TOPMEM                   # 2CF4: 8B 1E 2C 00
    dec    bx                                    # 2CF8: 4B
    dec    bx                                    # 2CF9: 4B
    mov    WORD PTR ds:SAVSTK,bx                  # 2CFA: 89 1E 45 03
L_2CFE:
    mov    dx,0x7                                # 2CFE: BA 07 00
    jmp    L_07D8                                # 2D01: E9 D4 DA
L_2D04:
    cmp    WORD PTR ds:FRETOP,bx                  # 2D04: 39 1E 2F 03
    jae    L_2CF3                                # 2D08: 73 E9
    push   cx                                    # 2D0A: 51
    push   dx                                    # 2D0B: 52
    push   bx                                    # 2D0C: 53
    call   GARBA2                                # 2D0D: E8 06 FA
    pop    bx                                    # 2D10: 5B
    pop    dx                                    # 2D11: 5A
    pop    cx                                    # 2D12: 59
    cmp    WORD PTR ds:FRETOP,bx                  # 2D13: 39 1E 2F 03
    jae    L_2CF3                                # 2D17: 73 DA
    jmp    L_2CFE                                # 2D19: EB E3
SCRATH:
    jne    L_2CF3                                # 2D1B: 75 D6
L_2D1D:
    mov    bx,WORD PTR ds:TXTTAB                   # 2D1D: 8B 1E 30 00
    call   TOFF                                  # 2D21: E8 79 01
    mov    ds:PROFLG,al                           # 2D24: A2 64 04
    mov    ds:AUTFLG,al                           # 2D27: A2 3E 03
    mov    ds:PTRFLG,al                           # 2D2A: A2 3D 03
    mov    BYTE PTR [bx],al                      # 2D2D: 88 07
    inc    bx                                    # 2D2F: 43
    mov    BYTE PTR [bx],al                      # 2D30: 88 07
    inc    bx                                    # 2D32: 43
    mov    WORD PTR ds:VARTAB,bx                  # 2D33: 89 1E 58 03
RUNC:
    int    0xae                                  # 2D37: CD AE
    mov    bx,WORD PTR ds:TXTTAB                   # 2D39: 8B 1E 30 00
    dec    bx                                    # 2D3D: 4B
L_2D3E:
    int    0xaf                                  # 2D3E: CD AF
    mov    WORD PTR ds:TEMP,bx                  # 2D40: 89 1E 3B 03
    mov    al,ds:MRGFLG                           # 2D44: A0 65 04
    .byte 0x0A, 0xC0 # 2D47
    jne    L_2D62                                # 2D49: 75 17
    .byte 0x32, 0xC0 # 2D4B
    mov    ds:OPTFLG,al                           # 2D4D: A2 5D 04
    mov    ds:OPTVAL,al                           # 2D50: A2 5C 04
    mov    ch,0x1a                               # 2D53: B5 1A
    mov    bx,0x360                              # 2D55: BB 60 03
    int    0xb0                                  # 2D58: CD B0
L_2D5A:
    mov    BYTE PTR [bx],0x4                     # 2D5A: C6 07 04
    inc    bx                                    # 2D5D: 43
    dec    ch                                    # 2D5E: FE CD
    jne    L_2D5A                                # 2D60: 75 F8
L_2D62:
    mov    dx,0x7                                # 2D62: BA 07 00
    mov    bx,0xb                                # 2D65: BB 0B 00
    call   L_6531                                # 2D68: E8 C6 37
    .byte 0x32, 0xC0 # 2D6B
    mov    ds:ONEFLG,al                           # 2D6D: A2 4F 03
    .byte 0x8A, 0xD8, 0x8A, 0xF8 # 2D70
    mov    WORD PTR ds:ONELIN,bx                  # 2D74: 89 1E 4D 03
    mov    WORD PTR ds:OLDTXT,bx                  # 2D78: 89 1E 56 03
    mov    bx,WORD PTR ds:MEMSIZ                  # 2D7C: 8B 1E 0A 03
    mov    al,ds:CHNFLG                           # 2D80: A0 6B 04
    .byte 0x0A, 0xC0 # 2D83
    jne    L_2D8B                                # 2D85: 75 04
    mov    WORD PTR ds:FRETOP,bx                  # 2D87: 89 1E 2F 03
L_2D8B:
    .byte 0x32, 0xC0 # 2D8B
    call   RESTORE                               # 2D8D: E8 7C 00
    mov    bx,WORD PTR ds:VARTAB                  # 2D90: 8B 1E 58 03
    mov    WORD PTR ds:ARYTAB,bx                  # 2D94: 89 1E 5A 03
    mov    WORD PTR ds:STREND,bx                  # 2D98: 89 1E 5C 03
    mov    al,ds:MRGFLG                           # 2D9C: A0 65 04
    .byte 0x0A, 0xC0 # 2D9F
    jne    L_2DA6                                # 2DA1: 75 03
    call   L_435A                                # 2DA3: E8 B4 15
L_2DA6:
    mov    al,ds:NLONLY                           # 2DA6: A0 36 05
    and    al,0x1                                # 2DA9: 24 01
    jne    L_2DB0                                # 2DAB: 75 03
    mov    ds:NLONLY,al                           # 2DAD: A2 36 05
L_2DB0:
    pop    cx                                    # 2DB0: 59
    mov    bx,WORD PTR ds:TOPMEM                   # 2DB1: 8B 1E 2C 00
    dec    bx                                    # 2DB5: 4B
    dec    bx                                    # 2DB6: 4B
    mov    WORD PTR ds:SAVSTK,bx                  # 2DB7: 89 1E 45 03
    inc    bx                                    # 2DBB: 43
    inc    bx                                    # 2DBC: 43
L_2DBD:
    int    0xb1                                  # 2DBD: CD B1
    .byte 0x8B, 0xE3 # 2DBF
    mov    bx,TEMPST                              # 2DC1: BB 0E 03
    mov    WORD PTR ds:TEMPPT,bx                  # 2DC4: 89 1E 0C 03
    call   L_25BE                                # 2DC8: E8 F3 F7
    call   L_1498                                # 2DCB: E8 CA E6
    .byte 0x32, 0xC0, 0x8A, 0xF8, 0x8A, 0xD8 # 2DCE
    mov    WORD PTR ds:PRMLEN,bx                  # 2DD4: 89 1E 7C 03
    mov    ds:NOFUNS,al                           # 2DD8: A2 4D 04
    mov    WORD PTR ds:PRMLN2,bx                  # 2DDB: 89 1E E4 03
    mov    WORD PTR ds:FUNACT,bx                  # 2DDF: 89 1E 50 04
    mov    WORD PTR ds:PRMSTK,bx                  # 2DE3: 89 1E 7A 03
    mov    ds:SUBFLG,al                           # 2DE7: A2 39 03
    push   bx                                    # 2DEA: 53
    push   cx                                    # 2DEB: 51
    mov    bx,WORD PTR ds:TEMP                  # 2DEC: 8B 1E 3B 03
    ret                                          # 2DF0: C3
    .byte 0x3B, 0xDA, 0xC3 # 2DF1
SYNCHR:
    pop    si                                    # 2DF4: 5E
    .byte 0x8B, 0xFB # 2DF5
    cld                                          # 2DF7: FC
    cmps   BYTE PTR cs:[si],BYTE PTR es:[di]     # 2DF8: 2E A6
    push   si                                    # 2DFA: 56
    .byte 0x8B, 0xDF # 2DFB
    jne    SYNERR                                # 2DFD: 75 0A
    mov    al,BYTE PTR [bx]                      # 2DFF: 8A 07
    cmp    al,0x3a                               # 2E01: 3C 3A
    jb     SYNCON                                # 2E03: 72 01
    ret                                          # 2E05: C3
SYNCON:
    jmp    CHRCON                                # 2E06: E9 1C E1
SYNERR:
    jmp    SNERR                                 # 2E09: E9 B2 D9
RESTORE:
    xchg   dx,bx                                 # 2E0C: 87 DA
    mov    bx,WORD PTR ds:TXTTAB                   # 2E0E: 8B 1E 30 00
    je     L_2E25                                # 2E12: 74 11
    xchg   dx,bx                                 # 2E14: 87 DA
    call   LINGET                                # 2E16: E8 52 E2
    push   bx                                    # 2E19: 53
    call   FNDLIN                                # 2E1A: E8 4A DC
    .byte 0x8B, 0xD9 # 2E1D
    pop    dx                                    # 2E1F: 5A
    jb     L_2E25                                # 2E20: 72 03
    jmp    L_1130                                # 2E22: E9 0B E3
L_2E25:
    dec    bx                                    # 2E25: 4B
    mov    WORD PTR ds:DATPTR,bx                  # 2E26: 89 1E 5E 03
    xchg   dx,bx                                 # 2E2A: 87 DA
L_2E2C:
    ret                                          # 2E2C: C3
STOP:
    jne    L_2E2C                                # 2E2D: 75 FD
    inc    al                                    # 2E2F: FE C0
    jmp    L_2E3C                                # 2E31: EB 09
ENDST:
    jne    L_2E2C                                # 2E33: 75 F7
    pushf                                        # 2E35: 9C
    jne    L_2E3B                                # 2E36: 75 03
    call   L_38DA                                # 2E38: E8 9F 0A
L_2E3B:
    popf                                         # 2E3B: 9D
L_2E3C:
    mov    WORD PTR ds:SAVTXT,bx                  # 2E3C: 89 1E 43 03
    mov    bx,TEMPST                              # 2E40: BB 0E 03
    mov    WORD PTR ds:TEMPPT,bx                  # 2E43: 89 1E 0C 03
    .byte 0xBB # 2E47
L_2E48:
    .byte 0x0C, 0xFF # 2E48
    pop    cx                                    # 2E4A: 59
L_2E4B:
    mov    bx,WORD PTR ds:CURLIN                   # 2E4B: 8B 1E 2E 00
    push   bx                                    # 2E4F: 53
    pushf                                        # 2E50: 9C
    .byte 0x8A, 0xC3, 0x22, 0xC7 # 2E51
    inc    al                                    # 2E55: FE C0
    je     L_2E65                                # 2E57: 74 0C
    mov    WORD PTR ds:OLDLIN,bx                  # 2E59: 89 1E 54 03
    mov    bx,WORD PTR ds:SAVTXT                  # 2E5D: 8B 1E 43 03
    mov    WORD PTR ds:OLDTXT,bx                  # 2E61: 89 1E 56 03
L_2E65:
    call   CRDONZ                                # 2E65: E8 F5 FD
    popf                                         # 2E68: 9D
    mov    bx,0x732                              # 2E69: BB 32 07
    je     L_2E71                                # 2E6C: 74 03
    jmp    L_0885                                # 2E6E: E9 14 DA
L_2E71:
    jmp    STPRDY                                # 2E71: E9 41 DA
    .byte 0xB0, 0x0F # 2E74
L_2E76:
    push   ax                                    # 2E76: 50
    mov    al,0x5e                               # 2E77: B0 5E
    call   OUTDO                                # 2E79: E8 29 FD
    pop    ax                                    # 2E7C: 58
    add    al,0x40                               # 2E7D: 04 40
    call   OUTDO                                # 2E7F: E8 23 FD
    jmp    CRDO                                # 2E82: E9 EC FD
CONT:
    mov    bx,WORD PTR ds:OLDTXT                  # 2E85: 8B 1E 56 03
    .byte 0x0B, 0xDB # 2E89
    mov    dx,0x11                               # 2E8B: BA 11 00
    jne    L_2E93                                # 2E8E: 75 03
    jmp    L_07D8                                # 2E90: E9 45 D9
L_2E93:
    mov    dx,WORD PTR ds:OLDLIN                  # 2E93: 8B 16 54 03
    mov    WORD PTR ds:CURLIN,dx                   # 2E97: 89 16 2E 00
    ret                                          # 2E9B: C3
TON:
    .byte 0xB8 # 2E9C
TOFF:
    .byte 0x32, 0xC0 # 2E9D
    mov    ds:TRCFLG,al                           # 2E9F: A2 76 04
    ret                                          # 2EA2: C3
SWAP:
    call   PTRGET                                # 2EA3: E8 C8 08
    push   dx                                    # 2EA6: 52
    push   bx                                    # 2EA7: 53
    mov    bx,0x46e                              # 2EA8: BB 6E 04
    call   L_64B9                                # 2EAB: E8 0B 36
    mov    bx,WORD PTR ds:ARYTAB                  # 2EAE: 8B 1E 5A 03
    pop    si                                    # 2EB2: 5E
    xchg   si,bx                                 # 2EB3: 87 DE
    push   si                                    # 2EB5: 56
    call   GETYPR                                # 2EB6: E8 6C EC
    push   ax                                    # 2EB9: 50
    call   SYNCHR                                # 2EBA: E8 37 FF
    .byte ','                                  # 2EBD: 2C -- SYNCHR inline operand
    .byte 0xE8 # 2EBE -- decoded continuation: call   0x376e
    lods   ax,WORD PTR ds:[si]                   # 2EBF: AD
    or     BYTE PTR [bx+si-0x76],bl              # 2EC0: 08 58 8A
    call   0x8dae                                # 2EC3: E8 E8 5E
    in     al,dx                                 # 2EC6: EC
    .byte 0x3A, 0xC5 # 2EC7
    je     L_2ECE                                # 2EC9: 74 03
    jmp    L_07D6                                # 2ECB: E9 08 D9
L_2ECE:
    pop    si                                    # 2ECE: 5E
    xchg   si,bx                                 # 2ECF: 87 DE
    push   si                                    # 2ED1: 56
    xchg   dx,bx                                 # 2ED2: 87 DA
    push   bx                                    # 2ED4: 53
    mov    bx,WORD PTR ds:ARYTAB                  # 2ED5: 8B 1E 5A 03
    .byte 0x3B, 0xDA # 2ED9
    jne    L_2EF0                                # 2EDB: 75 13
    pop    dx                                    # 2EDD: 5A
    pop    bx                                    # 2EDE: 5B
    pop    si                                    # 2EDF: 5E
    xchg   si,bx                                 # 2EE0: 87 DE
    push   si                                    # 2EE2: 56
    push   dx                                    # 2EE3: 52
    call   L_64B9                                # 2EE4: E8 D2 35
    pop    bx                                    # 2EE7: 5B
    mov    dx,0x46e                              # 2EE8: BA 6E 04
    call   L_64B9                                # 2EEB: E8 CB 35
    pop    bx                                    # 2EEE: 5B
L_2EEF:
    ret                                          # 2EEF: C3
L_2EF0:
    jmp    FCERR                                # 2EF0: E9 66 E1
ERASE:
    mov    al,0x1                                # 2EF3: B0 01
    mov    ds:SUBFLG,al                           # 2EF5: A2 39 03
    call   PTRGET                                # 2EF8: E8 73 08
    jne    L_2EF0                                # 2EFB: 75 F3
    push   bx                                    # 2EFD: 53
    mov    ds:SUBFLG,al                           # 2EFE: A2 39 03
    .byte 0x8A, 0xFD, 0x8A, 0xD9 # 2F01
    dec    cx                                    # 2F05: 49
    dec    cx                                    # 2F06: 49
    dec    cx                                    # 2F07: 49
L_2F08:
    .byte 0x8B, 0xF1 # 2F08
    lods   al,BYTE PTR ds:[si]                   # 2F0A: AC
    dec    cx                                    # 2F0B: 49
    .byte 0x0A, 0xC0 # 2F0C
    js     L_2F08                                # 2F0E: 78 F8
    dec    cx                                    # 2F10: 49
    dec    cx                                    # 2F11: 49
    .byte 0x03, 0xDA # 2F12
    xchg   dx,bx                                 # 2F14: 87 DA
    mov    bx,WORD PTR ds:STREND                  # 2F16: 8B 1E 5C 03
L_2F1A:
    .byte 0x3B, 0xDA, 0x8B, 0xF2 # 2F1A
    lods   al,BYTE PTR ds:[si]                   # 2F1E: AC
    .byte 0x8B, 0xF9 # 2F1F
    stos   BYTE PTR es:[di],al                   # 2F21: AA
    lahf                                         # 2F22: 9F
    inc    dx                                    # 2F23: 42
    sahf                                         # 2F24: 9E
    lahf                                         # 2F25: 9F
    inc    cx                                    # 2F26: 41
    sahf                                         # 2F27: 9E
    jne    L_2F1A                                # 2F28: 75 F0
    dec    cx                                    # 2F2A: 49
    .byte 0x8B, 0xD9 # 2F2B
    mov    WORD PTR ds:STREND,bx                  # 2F2D: 89 1E 5C 03
    pop    bx                                    # 2F31: 5B
    mov    al,BYTE PTR [bx]                      # 2F32: 8A 07
    cmp    al,0x2c                               # 2F34: 3C 2C
    jne    L_2EEF                                # 2F36: 75 B7
    call   CHRGTR                                # 2F38: E8 E2 DF
    jmp    ERASE                                 # 2F3B: EB B6
    .byte 0x58, 0x86, 0xC4, 0x9E, 0x5B # 2F3D
L_2F42:
    ret                                          # 2F42: C3
ISLET:
    mov    al,BYTE PTR [bx]                      # 2F43: 8A 07
ISLET2:
    cmp    al,0x41                               # 2F45: 3C 41
    jb     L_2F42                                # 2F47: 72 F9
    cmp    al,0x5b                               # 2F49: 3C 5B
    cmc                                          # 2F4B: F5
    ret                                          # 2F4C: C3
L_2F4D:
    jmp    L_2D3E                                # 2F4D: E9 EE FD
CLEAR:
    je     L_2F4D                                # 2F50: 74 FB
    cmp    al,0x2c                               # 2F52: 3C 2C
    je     L_2F5F                                # 2F54: 74 09
    call   L_1054                                # 2F56: E8 FB E0
    dec    bx                                    # 2F59: 4B
    call   CHRGTR                                # 2F5A: E8 C0 DF
    je     L_2F4D                                # 2F5D: 74 EE
L_2F5F:
    call   SYNCHR                                # 2F5F: E8 92 FE
    .byte ','                                  # 2F62: 2C -- SYNCHR inline operand
    .byte 0x74 # 2F63 -- decoded continuation: je     0x2f4d
    call   L_45F2                                # 2F64: E8 8B 16
    sub    al,0x0                                # 2F67: 2C 00
    cmp    al,0x2c                               # 2F69: 3C 2C
    je     L_2F70                                # 2F6B: 74 03
    call   L_2FB7                                # 2F6D: E8 47 00
L_2F70:
    dec    bx                                    # 2F70: 4B
    call   CHRGTR                                # 2F71: E8 A9 DF
    push   dx                                    # 2F74: 52
    je     L_2FC5                                # 2F75: 74 4E
    call   SYNCHR                                # 2F77: E8 7A FE
    .byte ','                                  # 2F7A: 2C -- SYNCHR inline operand
    .byte 0x74 # 2F7B -- decoded continuation: je     0x2fc5
    dec    ax                                    # 2F7C: 48
    call   L_2FB7                                # 2F7D: E8 37 00
    dec    bx                                    # 2F80: 4B
    call   CHRGTR                                # 2F81: E8 99 DF
    je     L_2F89                                # 2F84: 74 03
    jmp    SNERR                                 # 2F86: E9 35 D8
L_2F89:
    pop    si                                    # 2F89: 5E
    xchg   si,bx                                 # 2F8A: 87 DE
    push   si                                    # 2F8C: 56
    push   bx                                    # 2F8D: 53
    mov    bx,0xee                               # 2F8E: BB EE 00
    .byte 0x3B, 0xDA # 2F91
    jae    L_2FC2                                # 2F93: 73 2D
    pop    bx                                    # 2F95: 5B
    call   L_2FCF                                # 2F96: E8 36 00
    jb     L_2FC2                                # 2F99: 72 27
    push   bx                                    # 2F9B: 53
    mov    bx,WORD PTR ds:VARTAB                  # 2F9C: 8B 1E 58 03
    mov    cx,0x14                               # 2FA0: B9 14 00
    .byte 0x03, 0xD9, 0x3B, 0xDA # 2FA3
    jae    L_2FC2                                # 2FA7: 73 19
    xchg   dx,bx                                 # 2FA9: 87 DA
    mov    WORD PTR ds:MEMSIZ,bx                  # 2FAB: 89 1E 0A 03
    pop    bx                                    # 2FAF: 5B
    mov    WORD PTR ds:TOPMEM,bx                   # 2FB0: 89 1E 2C 00
    pop    bx                                    # 2FB4: 5B
    jmp    L_2F4D                                # 2FB5: EB 96
L_2FB7:
    call   L_22AA                                # 2FB7: E8 F0 F2
    .byte 0x0B, 0xD2 # 2FBA
    jne    L_2FC1                                # 2FBC: 75 03
    jmp    FCERR                                # 2FBE: E9 98 E0
L_2FC1:
    ret                                          # 2FC1: C3
L_2FC2:
    jmp    L_2CF4                                # 2FC2: E9 2F FD
L_2FC5:
    mov    dx,WORD PTR ds:TOPMEM                   # 2FC5: 8B 16 2C 00
    sub    dx,WORD PTR ds:MEMSIZ                  # 2FC9: 2B 16 0A 03
    jmp    L_2F89                                # 2FCD: EB BA
L_2FCF:
    .byte 0x8B, 0xC3, 0x2B, 0xC2, 0x8B, 0xD0 # 2FCF
    ret                                          # 2FD5: C3
ISFLIO:
    int    0xb2                                  # 2FD6: CD B2
    push   bx                                    # 2FD8: 53
    mov    bx,WORD PTR ds:PTRFIL                  # 2FD9: 8B 1E E9 04
    .byte 0x0B, 0xDB # 2FDD
    pop    bx                                    # 2FDF: 5B
    ret                                          # 2FE0: C3
    .byte 0x01, 0x30, 0x4E, 0x30, 0xE1, 0x30, 0xFD, 0x2F, 0xF1, 0x2F, 0x5B, 0x30 # 2FE1
    .byte 0x30, 0x30, 0x1B, 0x30 # 2FED
L_2FF1:
    mov    bx,WORD PTR ds:CSRY                   # 2FF1: 8B 1E 56 00
    call   L_3042                                # 2FF5: E8 4A 00
    je     L_2FFB                                # 2FF8: 74 01
L_2FFA:
    ret                                          # 2FFA: C3
L_2FFB:
    jmp    L_3001                                # 2FFB: EB 04
    .byte 0xB0, 0x01, 0xEB, 0x02 # 2FFD
L_3001:
    mov    al,0xff                               # 3001: B0 FF
    mov    ds:F_EDIT,al                           # 3003: A2 70 00
    inc    al                                    # 3006: FE C0
    call   L_3170                                # 3008: E8 65 01
    mov    bh,0x1                                # 300B: B7 01
    call   L_301B                                # 300D: E8 0B 00
    jne    L_2FFA                                # 3010: 75 E8
    call   L_4F20                                # 3012: E8 0B 1F
    call   L_3076                                # 3015: E8 5E 00
    .byte 0x32, 0xC0 # 3018
L_301A:
    ret                                          # 301A: C3
L_301B:
    mov    al,ds:WDOBOT                            # 301B: A0 5C 00
    .byte 0x3A, 0xC3 # 301E
    je     L_301A                                # 3020: 74 F8
    jae    L_302B                                # 3022: 73 07
    .byte 0x8A, 0xD8, 0x32, 0xC0 # 3024
    jmp    L_4F20                                # 3028: E9 F5 1E
L_302B:
    inc    bl                                    # 302B: FE C3
    jmp    L_4F20                                # 302D: E9 F0 1E
    .byte 0xA0, 0x5B, 0x00, 0x3A, 0xC3, 0x74, 0xE3, 0xB0, 0x01, 0x3A, 0xC3, 0x74 # 3030
    .byte 0xDD, 0xFE, 0xCB, 0xE9, 0xDE, 0x1E # 303C
L_3042:
    mov    al,ds:CRTWID                            # 3042: A0 29 00
    .byte 0x3A, 0xC7 # 3045
    je     L_301A                                # 3047: 74 D1
    inc    bh                                    # 3049: FE C7
    jmp    L_4F20                                # 304B: E9 D2 1E
L_304E:
    mov    bx,WORD PTR ds:WDOTOP                   # 304E: 8B 1E 5B 00
    mov    bh,0x1                                # 3052: B7 01
    mov    WORD PTR ds:FSTLIN,bx                   # 3054: 89 1E 58 00
    jmp    L_4F20                                # 3058: E9 C5 1E
    .byte 0x8B, 0x1E, 0x56, 0x00, 0xE8, 0x09, 0x00, 0x75, 0xB6, 0xA0, 0x29, 0x00 # 305B
    .byte 0x8A, 0xF8, 0xEB, 0xC5, 0xB0, 0x01, 0x3A, 0xC7, 0x74, 0xA9, 0xFE, 0xCF # 3067
    .byte 0xE9, 0xAA, 0x1E # 3073
L_3076:
    mov    al,ds:WDOTOP                            # 3076: A0 5B 00
    .byte 0x8A, 0xF8 # 3079
    mov    al,ds:WDOBOT                            # 307B: A0 5C 00
    .byte 0x8A, 0xD8, 0x2A, 0xC7 # 307E
    jb     L_301A                                # 3082: 72 96
    inc    al                                    # 3084: FE C0
    push   ax                                    # 3086: 50
    call   L_3123                                # 3087: E8 99 00
    mov    al,ds:FSTLIN                            # 308A: A0 58 00
    inc    bl                                    # 308D: FE C3
    .byte 0x3A, 0xC3 # 308F
    dec    bl                                    # 3091: FE CB
    jae    L_30A2                                # 3093: 73 0D
    .byte 0x3A, 0xC7 # 3095
    jb     L_30A2                                # 3097: 72 09
    jne    L_309D                                # 3099: 75 02
    mov    al,0x1                                # 309B: B0 01
L_309D:
    dec    al                                    # 309D: FE C8
    mov    ds:FSTLIN,al                            # 309F: A2 58 00
L_30A2:
    pop    ax                                    # 30A2: 58
    dec    al                                    # 30A3: FE C8
    jne    L_30AA                                # 30A5: 75 03
    .byte 0xE9, 0x03, 0x00 # 30A7
L_30AA:
    call   L_4F8B                                # 30AA: E8 DE 1E
L_30AD:
    ret                                          # 30AD: C3
L_30AE:
    mov    al,ds:WDOTOP                            # 30AE: A0 5B 00
    .byte 0x8A, 0xD8 # 30B1
    mov    al,ds:WDOBOT                            # 30B3: A0 5C 00
    .byte 0x8A, 0xF8, 0x2A, 0xC3 # 30B6
    jb     L_30AD                                # 30BA: 72 F1
    inc    al                                    # 30BC: FE C0
    push   ax                                    # 30BE: 50
    call   L_3141                                # 30BF: E8 7F 00
    mov    al,ds:FSTLIN                            # 30C2: A0 58 00
    .byte 0x3A, 0xC3 # 30C5
    jb     L_30D9                                # 30C7: 72 10
    .byte 0x3A, 0xC7 # 30C9
    js     L_30D0                                # 30CB: 78 03
    .byte 0xE9, 0x09, 0x00 # 30CD
L_30D0:
    jne    L_30D4                                # 30D0: 75 02
    mov    al,0xff                               # 30D2: B0 FF
L_30D4:
    inc    al                                    # 30D4: FE C0
    mov    ds:FSTLIN,al                            # 30D6: A2 58 00
L_30D9:
    pop    ax                                    # 30D9: 58
    dec    al                                    # 30DA: FE C8
    je     L_30AD                                # 30DC: 74 CF
    jmp    L_4F9C                                # 30DE: E9 BB 1E
L_30E1:
    mov    bx,WORD PTR ds:WDOTOP                   # 30E1: 8B 1E 5B 00
    mov    al,ds:LINCNT                            # 30E5: A0 5D 00
    .byte 0x8A, 0xE8, 0x8A, 0xC5, 0x3A, 0xC3 # 30E8
    jae    L_30F2                                # 30EE: 73 02
    .byte 0x8A, 0xD8 # 30F0
L_30F2:
    .byte 0x3A, 0xC7 # 30F2
    jae    L_30F8                                # 30F4: 73 02
    .byte 0x8A, 0xF8 # 30F6
L_30F8:
    .byte 0x8A, 0xC7 # 30F8
    mov    bh,0x0                                # 30FA: B7 00
    .byte 0x2A, 0xC3 # 30FC
    inc    al                                    # 30FE: FE C0
    mov    dx,0x72                               # 3100: BA 72 00
    push   ax                                    # 3103: 50
    xchg   dx,bx                                 # 3104: 87 DA
    .byte 0x03, 0xDA # 3106
    mov    BYTE PTR [bx],al                      # 3108: 88 07
    inc    bx                                    # 310A: 43
L_310B:
    mov    BYTE PTR [bx],al                      # 310B: 88 07
    inc    bx                                    # 310D: 43
    dec    al                                    # 310E: FE C8
    jne    L_310B                                # 3110: 75 F9
    xchg   dx,bx                                 # 3112: 87 DA
    pop    ax                                    # 3114: 58
    .byte 0x32, 0xC0 # 3115
    mov    ds:FSTLIN,al                            # 3117: A2 58 00
    mov    ds:FSTCOL,al                            # 311A: A2 59 00
    mov    ds:LSTCOL,al                            # 311D: A2 5A 00
    jmp    L_304E                                # 3120: E9 2B FF
L_3123:
    push   ax                                    # 3123: 50
    call   L_315E                                # 3124: E8 37 00
    mov    ch,0x1                                # 3127: B5 01
    .byte 0x8A, 0xC8 # 3129
L_312B:
    .byte 0x8A, 0xC5, 0x8B, 0xFA # 312B
    stos   BYTE PTR es:[di],al                   # 312F: AA
    dec    dx                                    # 3130: 4A
    .byte 0x8B, 0xF2 # 3131
    lods   al,BYTE PTR ds:[si]                   # 3133: AC
    .byte 0x8A, 0xE9, 0x8A, 0xC8 # 3134
    pop    ax                                    # 3138: 58
    dec    al                                    # 3139: FE C8
    jne    L_313E                                # 313B: 75 01
L_313D:
    ret                                          # 313D: C3
L_313E:
    push   ax                                    # 313E: 50
    jmp    L_312B                                # 313F: EB EA
L_3141:
    push   ax                                    # 3141: 50
    mov    ch,0x1                                # 3142: B5 01
    call   L_315E                                # 3144: E8 17 00
    .byte 0x8A, 0xC8 # 3147
L_3149:
    .byte 0x8A, 0xC5, 0x8B, 0xFA # 3149
    stos   BYTE PTR es:[di],al                   # 314D: AA
    inc    dx                                    # 314E: 42
    .byte 0x8B, 0xF2 # 314F
    lods   al,BYTE PTR ds:[si]                   # 3151: AC
    .byte 0x8A, 0xE9, 0x8A, 0xC8 # 3152
    pop    ax                                    # 3156: 58
    dec    al                                    # 3157: FE C8
    je     L_313D                                # 3159: 74 E2
    push   ax                                    # 315B: 50
    jmp    L_3149                                # 315C: EB EB
L_315E:
    push   bx                                    # 315E: 53
    mov    dx,0x74                               # 315F: BA 74 00
    mov    bh,0x0                                # 3162: B7 00
    dec    bl                                    # 3164: FE CB
    .byte 0x03, 0xDA # 3166
    mov    al,BYTE PTR [bx]                      # 3168: 8A 07
    xchg   dx,bx                                 # 316A: 87 DA
    pop    bx                                    # 316C: 5B
    .byte 0x22, 0xC0 # 316D
    ret                                          # 316F: C3
L_3170:
    push   bx                                    # 3170: 53
    mov    dx,0x74                               # 3171: BA 74 00
    mov    bh,0x0                                # 3174: B7 00
    dec    bl                                    # 3176: FE CB
    .byte 0x03, 0xDA # 3178
    mov    BYTE PTR [bx],al                      # 317A: 88 07
    xchg   dx,bx                                 # 317C: 87 DA
    pop    bx                                    # 317E: 5B
    ret                                          # 317F: C3
PINLIN:
    int    0xa6                                  # 3180: CD A6
    call   L_32C6                                # 3182: E8 41 01
    mov    bx,WORD PTR ds:CSRY                   # 3185: 8B 1E 56 00
    mov    WORD PTR ds:FSTLIN,bx                   # 3189: 89 1E 58 00
    mov    al,ds:CRTWID                            # 318D: A0 29 00
    inc    al                                    # 3190: FE C0
    jmp    L_31B2                                # 3192: EB 1E
L_3194:
    mov    al,0x3f                               # 3194: B0 3F
    call   OUTDO                                # 3196: E8 0C FA
    mov    al,0x20                               # 3199: B0 20
    call   OUTDO                                # 319B: E8 07 FA
    .byte 0x32, 0xC0 # 319E
    mov    ds:LSTCHR,al                            # 31A0: A2 27 00
    int    0xa7                                  # 31A3: CD A7
    call   L_32C6                                # 31A5: E8 1E 01
    mov    bx,WORD PTR ds:CSRY                   # 31A8: 8B 1E 56 00
    mov    WORD PTR ds:FSTLIN,bx                   # 31AC: 89 1E 58 00
    .byte 0x8A, 0xC7 # 31B0
L_31B2:
    mov    ds:LSTCOL,al                            # 31B2: A2 5A 00
    call   L_3699                                # 31B5: E8 E1 04
    dec    bl                                    # 31B8: FE CB
    je     L_31C1                                # 31BA: 74 05
    mov    al,0x1                                # 31BC: B0 01
    call   L_3170                                # 31BE: E8 AF FF
L_31C1:
    call   L_54D0                                # 31C1: E8 0C 23
    call   L_5508                                # 31C4: E8 41 23
    call   L_4D6E                                # 31C7: E8 A4 1B
    call   L_54D5                                # 31CA: E8 08 23
    call   L_5508                                # 31CD: E8 38 23
    .byte 0x0A, 0xC0 # 31D0
    jne    L_31D7                                # 31D2: 75 03
    call   L_4E4E                                # 31D4: E8 77 1C
L_31D7:
    push   ax                                    # 31D7: 50
    mov    bx,WORD PTR ds:CSRY                   # 31D8: 8B 1E 56 00
    mov    ah,BYTE PTR ds:CRTWID                   # 31DC: 8A 26 29 00
    inc    ah                                    # 31E0: FE C4
    cmp    bl,BYTE PTR ds:FSTLIN                   # 31E2: 3A 1E 58 00
    jne    L_31FA                                # 31E6: 75 12
    cmp    bh,BYTE PTR ds:FSTCOL                   # 31E8: 3A 3E 59 00
    jae    L_31F2                                # 31EC: 73 04
    mov    BYTE PTR ds:FSTCOL,bh                   # 31EE: 88 3E 59 00
L_31F2:
    cmp    bh,BYTE PTR ds:LSTCOL                   # 31F2: 3A 3E 5A 00
    jbe    L_31FE                                # 31F6: 76 06
    .byte 0x8A, 0xE7 # 31F8
L_31FA:
    mov    BYTE PTR ds:LSTCOL,ah                   # 31FA: 88 26 5A 00
L_31FE:
    pop    ax                                    # 31FE: 58
    call   L_3231                                # 31FF: E8 2F 00
    jb     L_3214                                # 3202: 72 10
    je     L_31C1                                # 3204: 74 BB
    call   L_340C                                # 3206: E8 03 02
    call   OUTDO                                # 3209: E8 99 F9
    jmp    L_31C1                                # 320C: EB B3
    .byte 0x01, 0xE8, 0x93, 0xF9, 0xEB, 0xAD # 320E
L_3214:
    cmp    al,0x3                                # 3214: 3C 03
    stc                                          # 3216: F9
    je     L_321A                                # 3217: 74 01
    cmc                                          # 3219: F5
L_321A:
    mov    bx,0x1f6                              # 321A: BB F6 01
L_321D:
    ret                                          # 321D: C3
L_321E:
    cmp    al,0x3b                               # 321E: 3C 3B
    jne    L_321D                                # 3220: 75 FB
    jmp    CHRGTR                                # 3222: E9 F8 DC
L_3225:
    dec    bx                                    # 3225: 4B
L_3226:
    inc    bx                                    # 3226: 43
    dec    cl                                    # 3227: FE C9
    js     L_321D                                # 3229: 78 F2
    cmp    al,BYTE PTR cs:[bx]                   # 322B: 2E 3A 07
    jne    L_3226                                # 322E: 75 F6
    ret                                          # 3230: C3
L_3231:
    mov    bx,0x3294                             # 3231: BB 94 32
    mov    cl,0xe                                # 3234: B1 0E
    call   L_3225                                # 3236: E8 EC FF
    jns    L_323E                                # 3239: 79 03
    .byte 0xE9, 0x07, 0x00 # 323B
L_323E:
    push   ax                                    # 323E: 50
    .byte 0x32, 0xC0 # 323F
    mov    ds:F_INST,al                            # 3241: A2 72 00
    pop    ax                                    # 3244: 58
L_3245:
    mov    bx,0x32a2                             # 3245: BB A2 32
    mov    cl,0xc                                # 3248: B1 0C
    call   L_3225                                # 324A: E8 D8 FF
    jns    L_3252                                # 324D: 79 03
    .byte 0xE9, 0x20, 0x00 # 324F
L_3252:
    push   ax                                    # 3252: 50
    .byte 0x8A, 0xC1, 0x0A, 0xC0 # 3253
    rol    al,1                                  # 3257: D0 C0
    .byte 0x8A, 0xC8, 0x32, 0xC0, 0x8A, 0xE8 # 3259
    mov    bx,0x32ae                             # 325F: BB AE 32
    .byte 0x03, 0xD9 # 3262
    mov    dl,BYTE PTR cs:[bx]                   # 3264: 2E 8A 17
    inc    bx                                    # 3267: 43
    mov    dh,BYTE PTR cs:[bx]                   # 3268: 2E 8A 37
    pop    ax                                    # 326B: 58
    push   dx                                    # 326C: 52
    mov    bx,WORD PTR ds:CSRY                   # 326D: 8B 1E 56 00
    ret                                          # 3271: C3
L_3272:
    .byte 0x0A, 0xC0 # 3272
    ret                                          # 3274: C3
    .byte 0x03, 0x22, 0xC0, 0xC3 # 3275
L_3279:
    mov    bx,WORD PTR ds:CSRY                   # 3279: 8B 1E 56 00
    cmp    bh,0x1                                # 327D: 80 FF 01
    jne    L_328D                                # 3280: 75 0B
    dec    bl                                    # 3282: FE CB
    call   L_315E                                # 3284: E8 D7 FE
    jne    L_3290                                # 3287: 75 07
    mov    bh,BYTE PTR ds:CRTWID                   # 3289: 8A 3E 29 00
L_328D:
    call   L_4F20                                # 328D: E8 90 1C
L_3290:
    jmp    CRDO                                # 3290: E9 DE F9
L_3293:
    ret                                          # 3293: C3
    .byte 0x0D, 0x02, 0x06, 0x05, 0x03, 0x0B, 0x0C, 0x1C, 0x1D, 0x1E, 0x1F, 0x0E # 3294
    .byte 0x7F, 0x1B, 0x09, 0x0A, 0x08, 0x12, 0x02, 0x06, 0x05, 0x03, 0x0D, 0x0E # 32A0
    .byte 0x7F, 0x1B, 0xFF, 0x34, 0x56, 0x34, 0xCA, 0x34, 0x39, 0x33, 0xAF, 0x33 # 32AC
    .byte 0x07, 0x35, 0x25, 0x35, 0x4D, 0x35, 0x01, 0x34, 0x77, 0x34, 0xF3, 0x32 # 32B8
    .byte 0xC1, 0x33 # 32C4
L_32C6:
    call   ISFLIO                                # 32C6: E8 0D FD
    je     L_3293                                # 32C9: 74 C8
    pop    ax                                    # 32CB: 58
    mov    ch,0xfe                               # 32CC: B5 FE
    mov    bx,0x1f7                              # 32CE: BB F7 01
L_32D1:
    call   L_2C15                                # 32D1: E8 41 F9
    mov    BYTE PTR [bx],al                      # 32D4: 88 07
    cmp    al,0xd                                # 32D6: 3C 0D
    je     L_32EB                                # 32D8: 74 11
    cmp    al,0xa                                # 32DA: 3C 0A
    jne    L_32E4                                # 32DC: 75 06
    .byte 0x8A, 0xC5 # 32DE
    cmp    al,0xfe                               # 32E0: 3C FE
    je     L_32D1                                # 32E2: 74 ED
L_32E4:
    inc    bx                                    # 32E4: 43
    dec    ch                                    # 32E5: FE CD
    jne    L_32D1                                # 32E7: 75 E8
    dec    ch                                    # 32E9: FE CD
L_32EB:
    .byte 0x32, 0xC0 # 32EB
    mov    BYTE PTR [bx],al                      # 32ED: 88 07
    mov    bx,0x1f6                              # 32EF: BB F6 01
    ret                                          # 32F2: C3
    .byte 0xA0, 0x72, 0x00, 0x0A, 0xC0, 0x74, 0x3A, 0xE8, 0x61, 0xFE, 0x50, 0x87 # 32F3
    .byte 0xDA, 0xC6, 0x07, 0x00, 0x87, 0xDA, 0xFE, 0xC3, 0xE8, 0x29, 0x03, 0xA0 # 32FF
    .byte 0x29, 0x00, 0x2A, 0xC7, 0x74, 0x0B, 0xFE, 0xC0, 0x50, 0xE8, 0xF5, 0x00 # 330B
    .byte 0x58, 0xFE, 0xC8, 0x75, 0xF7, 0x8B, 0x1E, 0x56, 0x00, 0xE8, 0x3B, 0xFE # 3317
    .byte 0x58, 0x8A, 0xC8, 0x32, 0xC0, 0x8B, 0xFA, 0xAA, 0x42, 0x8A, 0xC1, 0x8B # 3323
    .byte 0xFA, 0xAA, 0x32, 0xC0, 0xC3, 0xB0, 0x0A, 0x0A, 0xC0, 0xC3, 0xE8, 0x5A # 332F
    .byte 0x02, 0xBA, 0xF7, 0x01, 0xB5, 0xFE, 0xA0, 0x58, 0x00, 0x3A, 0xC3, 0xB7 # 333B
    .byte 0x01, 0xA0, 0x29, 0x00, 0x75, 0x13, 0x8B, 0x1E, 0x58, 0x00, 0x52, 0xE8 # 3347
    .byte 0x09, 0xFE, 0x5A, 0xA0, 0x29, 0x00, 0x74, 0x05, 0xA0, 0x5A, 0x00, 0xFE # 3353
    .byte 0xC8, 0xA2, 0x5A, 0x00, 0xE8, 0x3C, 0x02, 0x8A, 0xC5, 0x22, 0xC0, 0x74 # 335F
    .byte 0x10, 0x52, 0xE8, 0xEE, 0xFD, 0x5A, 0x75, 0x09, 0xB7, 0x01, 0xFE, 0xC3 # 336B
    .byte 0xA0, 0x29, 0x00, 0xEB, 0xE4, 0x87, 0xDA, 0xB0, 0xFE, 0x2A, 0xC6, 0x8A # 3377
    .byte 0xF0, 0x4B, 0x8A, 0x07, 0x3C, 0x20, 0x74, 0x08, 0x0A, 0xC0, 0x75, 0x07 # 3383
    .byte 0xFE, 0xCE, 0x74, 0x03, 0x4B, 0xEB, 0xEF, 0x43, 0xC6, 0x07, 0x00, 0x87 # 338F
    .byte 0xDA, 0xB0, 0x0D, 0x50, 0xB7, 0x01, 0xE8, 0x7C, 0x1B, 0xB0, 0x0D, 0xE8 # 339B
    .byte 0xFC, 0xF7, 0xBB, 0xF6, 0x01, 0x58, 0xF9, 0xC3, 0x32, 0xC0, 0xA2, 0xF7 # 33A7
    .byte 0x01, 0xE8, 0xA7, 0xFD, 0x75, 0x04, 0xFE, 0xC3, 0xEB, 0xF7, 0xB0, 0x03 # 33B3
    .byte 0xEB, 0xDD, 0x8A, 0xC7, 0xFE, 0xC8, 0x24, 0xF8, 0x04, 0x08, 0xFE, 0xC0 # 33BF
    .byte 0x8A, 0xE8, 0xA0, 0x29, 0x00, 0x3A, 0xC5, 0x73, 0x02, 0x8A, 0xE8, 0x8A # 33CB
    .byte 0xC5, 0xA0, 0x72, 0x00, 0x0A, 0xC0, 0x8A, 0xC5, 0x75, 0x0C, 0x3A, 0xC7 # 33D7
    .byte 0x74, 0x05, 0x8A, 0xF8, 0xE8, 0x36, 0x1B, 0x32, 0xC0, 0xC3, 0x2A, 0xC7 # 33E3
    .byte 0x74, 0xFB, 0x50, 0xA0, 0x50, 0x00, 0xE8, 0x14, 0x00, 0xE8, 0xAA, 0xF7 # 33EF
    .byte 0x58, 0xFE, 0xC8, 0x75, 0xF1, 0xC3, 0xA0, 0x72, 0x00, 0xF6, 0xD0, 0xA2 # 33FB
    .byte 0x72, 0x00, 0x32, 0xC0, 0xC3 # 3407
L_340C:
    push   bx                                    # 340C: 53
    mov    bx,WORD PTR ds:CSRY                   # 340D: 8B 1E 56 00
    push   ax                                    # 3411: 50
    mov    al,ds:F_INST                            # 3412: A0 72 00
    .byte 0x0A, 0xC0 # 3415
    je     L_341C                                # 3417: 74 03
    call   L_341F                                # 3419: E8 03 00
L_341C:
    pop    ax                                    # 341C: 58
    pop    bx                                    # 341D: 5B
L_341E:
    ret                                          # 341E: C3
L_341F:
    mov    al,ds:FSTLIN                            # 341F: A0 58 00
    .byte 0x3A, 0xC3 # 3422
    jne    L_3436                                # 3424: 75 10
    push   bx                                    # 3426: 53
    mov    bx,0x5a                               # 3427: BB 5A 00
    inc    BYTE PTR [bx]                         # 342A: FE 07
    mov    al,ds:CRTWID                            # 342C: A0 29 00
    cmp    al,BYTE PTR [bx]                      # 342F: 3A 07
    jae    L_3435                                # 3431: 73 02
    mov    BYTE PTR [bx],al                      # 3433: 88 07
L_3435:
    pop    bx                                    # 3435: 5B
L_3436:
    mov    al,ds:EDITOR_BLANK_CHAR                            # 3436: A0 50 00
L_3439:
    .byte 0x8A, 0xC8 # 3439
    call   L_35CD                                # 343B: E8 8F 01
    jb     L_3450                                # 343E: 72 10
    je     L_341E                                # 3440: 74 DC
    push   ax                                    # 3442: 50
    .byte 0x32, 0xC0 # 3443
    call   L_3170                                # 3445: E8 28 FD
    inc    bl                                    # 3448: FE C3
    call   L_3633                                # 344A: E8 E6 01
    pop    ax                                    # 344D: 58
    dec    bl                                    # 344E: FE CB
L_3450:
    inc    bl                                    # 3450: FE C3
    mov    bh,0x1                                # 3452: B7 01
    jmp    L_3439                                # 3454: EB E3
    .byte 0x53, 0xA0, 0x29, 0x00, 0x3A, 0xC7, 0x75, 0x0B, 0xB7, 0x00, 0xA0, 0x5D # 3456
    .byte 0x00, 0x3A, 0xC3, 0x75, 0x00, 0xFE, 0xC3, 0xFE, 0xC7, 0xE8, 0x09, 0x00 # 3462
    .byte 0x5B, 0x53, 0xE8, 0xAD, 0x1A, 0x32, 0xC0, 0x5B, 0xC3, 0xB0, 0x01, 0x3A # 346E
    .byte 0xC7, 0x74, 0x04, 0xFE, 0xCF, 0xEB, 0x14, 0x53, 0xFE, 0xCB, 0x74, 0x0E # 347A
    .byte 0xA0, 0x29, 0x00, 0x8A, 0xF8, 0xE8, 0xD0, 0xFC, 0x75, 0x04, 0x5E, 0x87 # 3486
    .byte 0xDE, 0x56, 0x5B, 0xE8, 0x88, 0x1A, 0xA0, 0x58, 0x00, 0x3A, 0xC3, 0x75 # 3492
    .byte 0x0A, 0xA0, 0x5A, 0x00, 0xFE, 0xC8, 0x74, 0x03, 0xA2, 0x5A, 0x00, 0xE8 # 349E
    .byte 0x42, 0x01, 0x53, 0xE8, 0xAE, 0xFC, 0x75, 0x11, 0xFE, 0xC3, 0xB7, 0x01 # 34AA
    .byte 0xE8, 0x05, 0x02, 0x5E, 0x87, 0xDE, 0x56, 0xE8, 0xFB, 0x01, 0x5B, 0xEB # 34B6
    .byte 0xE6, 0x5B, 0xE8, 0x55, 0x1A, 0x32, 0xC0, 0xC3, 0xE8, 0x91, 0xFC, 0x75 # 34C2
    .byte 0x0B, 0xA0, 0x5B, 0x00, 0x3A, 0xC3, 0x74, 0x04, 0xFE, 0xC3, 0xEB, 0xF0 # 34CE
    .byte 0xA0, 0x29, 0x00, 0x8A, 0xF8, 0xA0, 0x50, 0x00, 0x8A, 0xC8, 0x51, 0xE8 # 34DA
    .byte 0x22, 0x1A, 0x59, 0x0A, 0xC0, 0x74, 0x0C, 0x3A, 0xC1, 0x74, 0x08, 0xFE # 34E6
    .byte 0xC7, 0xE8, 0x2A, 0x1A, 0x32, 0xC0, 0xC3, 0xFE, 0xCF, 0x74, 0xF4, 0xEB # 34F2
    .byte 0xE5, 0xE8, 0x94, 0x00, 0xB7, 0x01, 0xE8, 0x19, 0x1A, 0x53, 0xA0, 0x50 # 34FE
    .byte 0x00, 0xE8, 0xAD, 0x01, 0x5B, 0xFE, 0xC7, 0xA0, 0x29, 0x00, 0xFE, 0xC0 # 350A
    .byte 0x3A, 0xC7, 0x75, 0xED, 0xE8, 0x41, 0xFC, 0x75, 0xA5, 0xB7, 0x01, 0xFE # 3516
    .byte 0xC3, 0xEB, 0xE2, 0xC6, 0x06, 0x70, 0x00, 0x00, 0xEB, 0x08, 0xE8, 0xE5 # 3522 -- contains MOV BYTE PTR F_EDIT,0 at 3525
    .byte 0x19, 0xE8, 0x4A, 0x01, 0x72, 0x0F, 0xE8, 0x40, 0x00, 0x74, 0x13, 0xEB # 352E
    .byte 0xF1, 0xE8, 0xD6, 0x19, 0xE8, 0x3B, 0x01, 0x73, 0x07, 0xE8, 0x31, 0x00 # 353A
    .byte 0x74, 0x04, 0xEB, 0xF1, 0x32, 0xC0, 0xC3, 0x32, 0xC0, 0xA2, 0x70, 0x00 # 3546 -- contains MOV F_EDIT,AL at 354F
    .byte 0xEB, 0x08, 0xE8, 0xBD, 0x19, 0xE8, 0x22, 0x01, 0x73, 0x0F, 0xE8, 0x26 # 3552
    .byte 0x00, 0x74, 0xEB, 0xEB, 0xF1, 0xE8, 0xAE, 0x19, 0xE8, 0x13, 0x01, 0x72 # 355E
    .byte 0x07, 0xE8, 0x17, 0x00, 0x74, 0xDC, 0xEB, 0xF1, 0xE8, 0x02, 0x00, 0xEB # 356A
    .byte 0xD3, 0x8B, 0x1E, 0x56, 0x00, 0xE8, 0xC4, 0xFA, 0x75, 0xCC, 0xB7, 0x01 # 3576
    .byte 0xE9, 0x96, 0xFA, 0x8B, 0x1E, 0x56, 0x00, 0xE8, 0xDF, 0xFA, 0x75, 0xBE # 3582
    .byte 0xA0, 0x29, 0x00, 0x8A, 0xF8, 0xE9, 0x9A, 0xFA, 0xFE, 0xCB, 0x74, 0x05 # 358E
    .byte 0xE8, 0xC1, 0xFB, 0x74, 0xF7, 0xFE, 0xC3, 0xC3, 0x51, 0xA0, 0x5A, 0x00 # 359A
    .byte 0x3A, 0xC7, 0x72, 0x1A, 0xE8, 0x67, 0x19, 0xE8, 0x16, 0x00, 0x8B, 0xFA # 35A6
    .byte 0xAA, 0x42, 0x5E, 0x87, 0xDE, 0x56, 0xFE, 0xCF, 0x5E, 0x87, 0xDE, 0x56 # 35B2
    .byte 0x74, 0x04, 0xFE, 0xC7, 0xEB, 0xDF, 0x59, 0xC3, 0x0A, 0xC0, 0x75, 0x02 # 35BE
    .byte 0xB0, 0x20 # 35CA
L_35CC:
    ret                                          # 35CC: C3
L_35CD:
    call   L_3615                                # 35CD: E8 45 00
    push   ax                                    # 35D0: 50
    call   L_315E                                # 35D1: E8 8A FB
    je     L_35EB                                # 35D4: 74 15
    pop    ax                                    # 35D6: 58
    .byte 0x22, 0xC0 # 35D7
    je     L_35CC                                # 35D9: 74 F1
    cmp    al,0x20                               # 35DB: 3C 20
    je     L_35CC                                # 35DD: 74 ED
    mov    al,ds:EDITOR_BLANK_CHAR                            # 35DF: A0 50 00
    .byte 0x3A, 0xC1 # 35E2
    je     L_35CC                                # 35E4: 74 E6
    .byte 0x8A, 0xC1, 0x22, 0xC0 # 35E6
    ret                                          # 35EA: C3
L_35EB:
    pop    ax                                    # 35EB: 58
    stc                                          # 35EC: F9
    ret                                          # 35ED: C3
    .byte 0xA0, 0x29, 0x00, 0x3A, 0xC7, 0x74, 0x19, 0xFE, 0xC7, 0xE8, 0xC4, 0x00 # 35EE
    .byte 0x53, 0xFE, 0xCF, 0xE8, 0xBB, 0x00, 0x5B, 0xFE, 0xC7, 0xA0, 0x29, 0x00 # 35FA
    .byte 0xFE, 0xC0, 0x3A, 0xC7, 0x75, 0xEB, 0xFE, 0xCF, 0xA0, 0x50, 0x00, 0xE8 # 3606
    .byte 0xA7, 0x00, 0xC3 # 3612
L_3615:
    push   bx                                    # 3615: 53
L_3616:
    push   cx                                    # 3616: 51
    call   L_36BE                                # 3617: E8 A4 00
    pop    cx                                    # 361A: 59
    push   ax                                    # 361B: 50
    .byte 0x8A, 0xC1 # 361C
    call   L_36BB                                # 361E: E8 9A 00
    pop    ax                                    # 3621: 58
    .byte 0x8A, 0xC8 # 3622
    mov    al,ds:CRTWID                            # 3624: A0 29 00
    inc    al                                    # 3627: FE C0
    inc    bh                                    # 3629: FE C7
    .byte 0x3A, 0xC7 # 362B
    jne    L_3616                                # 362D: 75 E7
    .byte 0x8A, 0xC1 # 362F
    pop    bx                                    # 3631: 5B
    ret                                          # 3632: C3
L_3633:
    push   bx                                    # 3633: 53
    mov    al,ds:WDOBOT                            # 3634: A0 5C 00
    .byte 0x2A, 0xC3 # 3637
    jb     L_366A                                # 3639: 72 2F
    je     L_365F                                # 363B: 74 22
    mov    bx,WORD PTR ds:WDOTOP                   # 363D: 8B 1E 5B 00
    pop    si                                    # 3641: 5E
    xchg   si,bx                                 # 3642: 87 DE
    push   si                                    # 3644: 56
    push   bx                                    # 3645: 53
    .byte 0x8A, 0xC3 # 3646
    mov    ds:WDOTOP,al                            # 3648: A2 5B 00
    mov    al,ds:LINCNT                            # 364B: A0 5D 00
    mov    ds:WDOBOT,al                            # 364E: A2 5C 00
    call   L_30AE                                # 3651: E8 5A FA
    pop    bx                                    # 3654: 5B
    pop    si                                    # 3655: 5E
    xchg   si,bx                                 # 3656: 87 DE
    push   si                                    # 3658: 56
    mov    WORD PTR ds:WDOTOP,bx                   # 3659: 89 1E 5B 00
    pop    bx                                    # 365D: 5B
    push   bx                                    # 365E: 53
L_365F:
    mov    bh,0x1                                # 365F: B7 01
    call   L_4F5D                                # 3661: E8 F9 18
    pop    bx                                    # 3664: 5B
    mov    al,0x1                                # 3665: B0 01
    jmp    L_3170                                # 3667: E9 06 FB
L_366A:
    mov    bx,WORD PTR ds:CSRY                   # 366A: 8B 1E 56 00
    dec    bl                                    # 366E: FE CB
    je     L_3675                                # 3670: 74 03
    call   L_4F20                                # 3672: E8 AB 18
L_3675:
    call   L_3076                                # 3675: E8 FE F9
    pop    bx                                    # 3678: 5B
    dec    bl                                    # 3679: FE CB
    ret                                          # 367B: C3
    .byte 0x3C, 0x30, 0x72, 0xFB, 0x3C, 0x3A, 0x72, 0x12, 0x3C, 0x41, 0x72, 0xF3 # 367C
    .byte 0x3C, 0x5B, 0x72, 0x0A, 0x3C, 0x61, 0x72, 0xEB, 0x3C, 0x7B, 0x72, 0x02 # 3688
    .byte 0xF9, 0xC3, 0x22, 0xC0, 0xC3 # 3694
L_3699:
    push   bx                                    # 3699: 53
    mov    bh,0x1                                # 369A: B7 01
    mov    al,ds:CRTWID                            # 369C: A0 29 00
    .byte 0x8A, 0xE8 # 369F
L_36A1:
    push   cx                                    # 36A1: 51
    call   L_4F0A                                # 36A2: E8 65 18
    pop    cx                                    # 36A5: 59
    cmp    al,0xff                               # 36A6: 3C FF
    je     L_36B2                                # 36A8: 74 08
    inc    bh                                    # 36AA: FE C7
    dec    ch                                    # 36AC: FE CD
    jne    L_36A1                                # 36AE: 75 F1
    pop    bx                                    # 36B0: 5B
    ret                                          # 36B1: C3
L_36B2:
    pop    bx                                    # 36B2: 5B
    push   bx                                    # 36B3: 53
    mov    bh,0x1                                # 36B4: B7 01
    call   L_4F5D                                # 36B6: E8 A4 18
    pop    bx                                    # 36B9: 5B
L_36BA:
    ret                                          # 36BA: C3
L_36BB:
    jmp    L_4F01                                # 36BB: E9 43 18
L_36BE:
    jmp    L_4F0A                                # 36BE: E9 49 18
ERREDT:
    mov    ds:ERRFLG,al                            # 36C1: A2 28 00
    mov    bx,WORD PTR ds:ERRLIN                  # 36C4: 8B 1E 47 03
    .byte 0x0A, 0xC7, 0x22, 0xC3 # 36C8
    inc    al                                    # 36CC: FE C0
    xchg   dx,bx                                 # 36CE: 87 DA
    je     L_36BA                                # 36D0: 74 E8
    jmp    L_36E7                                # 36D2: EB 13
L_36D4:
    mov    bx,0x1f6                              # 36D4: BB F6 01
    je     L_36BA                                # 36D7: 74 E1
    stc                                          # 36D9: F9
    pushf                                        # 36DA: 9C
    inc    bx                                    # 36DB: 43
    jmp    EDENT                                # 36DC: E9 75 D2
EDIT:
    call   L_105E                                # 36DF: E8 7C D9
    je     L_36E7                                # 36E2: 74 03
    jmp    FCERR                                # 36E4: E9 72 D9
L_36E7:
    pop    bx                                    # 36E7: 5B
    mov    WORD PTR ds:DOT,dx                  # 36E8: 89 16 49 03
    call   FNDLIN                                # 36EC: E8 78 D3
    jb     L_36F4                                # 36EF: 72 03
    jmp    L_1130                                # 36F1: E9 3C DA
L_36F4:
    .byte 0x8B, 0xD9 # 36F4
    inc    bx                                    # 36F6: 43
    inc    bx                                    # 36F7: 43
    mov    dx,WORD PTR [bx]                      # 36F8: 8B 17
    inc    bx                                    # 36FA: 43
    inc    bx                                    # 36FB: 43
    push   bx                                    # 36FC: 53
    xchg   dx,bx                                 # 36FD: 87 DA
    call   LINPRT                                # 36FF: E8 4E 2E
    pop    bx                                    # 3702: 5B
    mov    al,BYTE PTR [bx]                      # 3703: 8A 07
    cmp    al,0x9                                # 3705: 3C 09
    je     L_370E                                # 3707: 74 05
    mov    al,0x20                               # 3709: B0 20
    call   OUTDO                                # 370B: E8 97 F4
L_370E:
    call   L_1FCD                                # 370E: E8 BC E8
    mov    bx,0x1f7                              # 3711: BB F7 01
    call   L_1FC0                                # 3714: E8 A9 E8
    call   L_3279                                # 3717: E8 5F FB
    mov    bx,WORD PTR ds:CSRY                   # 371A: 8B 1E 56 00
    dec    bl                                    # 371E: FE CB
    je     L_372B                                # 3720: 74 09
L_3722:
    dec    bl                                    # 3722: FE CB
    je     L_372B                                # 3724: 74 05
    call   L_315E                                # 3726: E8 35 FA
    je     L_3722                                # 3729: 74 F7
L_372B:
    inc    bl                                    # 372B: FE C3
    call   L_4F20                                # 372D: E8 F0 17
    jmp    MAIN                                # 3730: E9 A0 D1
L_3733:
    cmp    al,0xa                                # 3733: 3C 0A
    je     L_373A                                # 3735: 74 03
    jmp    OUTDO                                # 3737: E9 6B F4
L_373A:
    push   bx                                    # 373A: 53
    mov    bx,WORD PTR ds:PTRFIL                  # 373B: 8B 1E E9 04
    .byte 0x8A, 0xC7, 0x0A, 0xC3 # 373F
    pop    bx                                    # 3743: 5B
    mov    al,0xa                                # 3744: B0 0A
    jne    L_3750                                # 3746: 75 08
    push   ax                                    # 3748: 50
    mov    al,0xd                                # 3749: B0 0D
    call   OUTDO                                # 374B: E8 57 F4
    pop    ax                                    # 374E: 58
    ret                                          # 374F: C3
L_3750:
    call   OUTDO                                # 3750: E8 52 F4
    mov    al,0xd                                # 3753: B0 0D
    call   OUTDO                                # 3755: E8 4D F4
    mov    al,0xa                                # 3758: B0 0A
    ret                                          # 375A: C3
DIMCON:
    dec    bx                                    # 375B: 4B
    call   CHRGTR                                # 375C: E8 BE D7
    jne    DIMCON_MORE                           # 375F: 75 01
DIMCON_RET:
    ret                                          # 3761: C3
DIMCON_MORE:
    call   SYNCHR                                # 3762: E8 8F F6
    .byte ','                                    # 3765: SYNCHR inline operand
DIM:
    mov    cx,0x375b                             # 3766: B9 5B 37
    push   cx                                    # 3769: 51
    mov    al,0xc8                               # 376A: B0 C8
    jmp    PTRGT1                                # 376C: EB 02
PTRGET:
    .byte 0x32, 0xC0                             # 376E: XOR AL,AL; historical direction-bit encoding
PTRGT1:
    mov    ds:DIMFLG,al                           # 3770: A2 FA 02
    mov    cl,BYTE PTR [bx]                      # 3773: 8A 0F
PTRGT2:
    int    0xb3                                  # 3775: CD B3
    call   ISLET                                # 3777: E8 C9 F7
    jae    PTRGT_NAME_VALID                                # 377A: 73 03
    jmp    SNERR                                 # 377C: E9 3F D0
PTRGT_NAME_VALID:
    .byte 0x32, 0xC0                             # 377F: XOR AL,AL; historical direction-bit encoding
    .byte 0x8A, 0xE8                             # 3781: MOV CH,AL; historical direction-bit encoding
    mov    ds:NAMCNT,al                          # 3783: A2 8E 00
    inc    bx                                    # 3786: 43
    mov    al,BYTE PTR [bx]                      # 3787: 8A 07
    cmp    al,0x2e                               # 3789: 3C 2E
    jb     NOSEC                                # 378B: 72 42
    je     ISSEC                                # 378D: 74 0D
    cmp    al,0x3a                               # 378F: 3C 3A
    jae    PTRGT3                                # 3791: 73 04
    cmp    al,0x30                               # 3793: 3C 30
    jae    ISSEC                                # 3795: 73 05
PTRGT3:
    call   ISLET2                                # 3797: E8 AB F7
    jb     NOSEC                                # 379A: 72 33
ISSEC:
    .byte 0x8A, 0xE8 # 379C
    push   cx                                    # 379E: 51
    mov    ch,0xff                               # 379F: B5 FF
    mov    dx,NAMBUF-1                           # 37A1: BA 8E 00
VMORCH:
    or     al,0x80                               # 37A4: 0C 80
    inc    ch                                    # 37A6: FE C5
    .byte 0x8B, 0xFA # 37A8
    stos   BYTE PTR es:[di],al                   # 37AA: AA
    inc    dx                                    # 37AB: 42
    inc    bx                                    # 37AC: 43
    mov    al,BYTE PTR [bx]                      # 37AD: 8A 07
    cmp    al,0x3a                               # 37AF: 3C 3A
    jae    VMORC1                                # 37B1: 73 04
    cmp    al,0x30                               # 37B3: 3C 30
    jae    VMORCH                                # 37B5: 73 ED
VMORC1:
    call   ISLET2                                # 37B7: E8 8B F7
    jae    VMORCH                                # 37BA: 73 E8
    cmp    al,0x2e                               # 37BC: 3C 2E
    je     VMORCH                                # 37BE: 74 E4
    .byte 0x8A, 0xC5 # 37C0
    cmp    al,0x27                               # 37C2: 3C 27
    jb     PTRGT_NAME_DONE                                # 37C4: 72 03
    jmp    SNERR                                 # 37C6: E9 F5 CF
PTRGT_NAME_DONE:
    pop    cx                                    # 37C9: 59
    mov    ds:NAMCNT,al                            # 37CA: A2 8E 00
    mov    al,BYTE PTR [bx]                      # 37CD: 8A 07
NOSEC:
    cmp    al,0x26                               # 37CF: 3C 26
    jae    TABTYP                                # 37D1: 73 1E
    mov    dx,0x3803                             # 37D3: BA 03 38
    push   dx                                    # 37D6: 52
    mov    dh,0x2                                # 37D7: B6 02
    cmp    al,0x25                               # 37D9: 3C 25
    je     DIMCON_RET                                # 37DB: 74 84
    inc    dh                                    # 37DD: FE C6
    cmp    al,0x24                               # 37DF: 3C 24
    jne    L_37E4                                # 37E1: 75 01
HAVTYP_RET:
    ret                                          # 37E3: C3
L_37E4:
    inc    dh                                    # 37E4: FE C6
    cmp    al,0x21                               # 37E6: 3C 21
    je     HAVTYP_RET                                # 37E8: 74 F9
    mov    dh,0x8                                # 37EA: B6 08
    cmp    al,0x23                               # 37EC: 3C 23
    je     HAVTYP_RET                                # 37EE: 74 F3
    pop    ax                                    # 37F0: 58
TABTYP:
    .byte 0x8A, 0xC1 # 37F1
    and    al,0x7f                               # 37F3: 24 7F
    .byte 0x8A, 0xD0 # 37F5
    mov    dh,0x0                                # 37F7: B6 00
    push   bx                                    # 37F9: 53
    mov    bx,DEFTBL                             # 37FA: BB 1F 03
    .byte 0x03, 0xDA # 37FD
    mov    dh,BYTE PTR [bx]                      # 37FF: 8A 37
    pop    bx                                    # 3801: 5B
    dec    bx                                    # 3802: 4B
    .byte 0x8A, 0xC6 # 3803
    mov    ds:VALTYP,al                           # 3805: A2 FB 02
    call   CHRGTR                                # 3808: E8 12 D7
    mov    al,ds:SUBFLG                           # 380B: A0 39 03
    dec    al                                    # 380E: FE C8
    jne    L_3815                                # 3810: 75 03
    jmp    L_398F                                # 3812: E9 7A 01
L_3815:
    js     L_381A                                # 3815: 78 03
    .byte 0xE9, 0x10, 0x00 # 3817
L_381A:
    mov    al,BYTE PTR [bx]                      # 381A: 8A 07
    sub    al,0x28                               # 381C: 2C 28
    jne    L_3823                                # 381E: 75 03
    jmp    L_38F0                                # 3820: E9 CD 00
L_3823:
    sub    al,0x33                               # 3823: 2C 33
    jne    L_382A                                # 3825: 75 03
    jmp    L_38F0                                # 3827: E9 C6 00
L_382A:
    .byte 0x32, 0xC0 # 382A
    mov    ds:SUBFLG,al                           # 382C: A2 39 03
    push   bx                                    # 382F: 53
    mov    al,ds:NOFUNS                           # 3830: A0 4D 04
    .byte 0x0A, 0xC0 # 3833
    mov    ds:PRMFLG,al                           # 3835: A2 4A 04
    je     L_3858                                # 3838: 74 1E
    mov    bx,WORD PTR ds:PRMLEN                  # 383A: 8B 1E 7C 03
    mov    dx,0x37e                              # 383E: BA 7E 03
    .byte 0x03, 0xDA # 3841
    mov    WORD PTR ds:ARYTA2,bx                  # 3843: 89 1E 4B 04
    xchg   dx,bx                                 # 3847: 87 DA
    jmp    LOPFND                                # 3849: E9 F7 2D
L_384C:
    mov    al,ds:PRMFLG                           # 384C: A0 4A 04
    .byte 0x0A, 0xC0 # 384F
    je     L_3877                                # 3851: 74 24
    .byte 0x32, 0xC0 # 3853
    mov    ds:PRMFLG,al                           # 3855: A2 4A 04
L_3858:
    mov    bx,WORD PTR ds:ARYTAB                  # 3858: 8B 1E 5A 03
    mov    WORD PTR ds:ARYTA2,bx                  # 385C: 89 1E 4B 04
    mov    bx,WORD PTR ds:VARTAB                  # 3860: 8B 1E 58 03
    jmp    LOPFND                                # 3864: E9 DC 2D
    .byte 0xE8, 0x04, 0xFF, 0xC3 # 3867
L_386B:
    .byte 0x32, 0xC0, 0x8A, 0xF0, 0x8A, 0xD0 # 386B
    pop    cx                                    # 3871: 59
    pop    si                                    # 3872: 5E
    xchg   si,bx                                 # 3873: 87 DE
    push   si                                    # 3875: 56
    ret                                          # 3876: C3
L_3877:
    pop    bx                                    # 3877: 5B
    pop    si                                    # 3878: 5E
    xchg   si,bx                                 # 3879: 87 DE
    push   si                                    # 387B: 56
    push   dx                                    # 387C: 52
    mov    dx,0x386a                             # 387D: BA 6A 38
    .byte 0x3B, 0xDA # 3880
    je     L_386B                                # 3882: 74 E7
    mov    dx,0x19da                             # 3884: BA DA 19
    .byte 0x3B, 0xDA # 3887
    pop    dx                                    # 3889: 5A
    je     L_38D5                                # 388A: 74 49
    pop    si                                    # 388C: 5E
    xchg   si,bx                                 # 388D: 87 DE
    push   si                                    # 388F: 56
    push   bx                                    # 3890: 53
    push   cx                                    # 3891: 51
    mov    al,ds:VALTYP                           # 3892: A0 FB 02
    .byte 0x8A, 0xE8 # 3895
    mov    al,ds:NAMCNT                            # 3897: A0 8E 00
    .byte 0x02, 0xC5 # 389A
    inc    al                                    # 389C: FE C0
    .byte 0x8A, 0xC8 # 389E
    push   cx                                    # 38A0: 51
    mov    ch,0x0                                # 38A1: B5 00
    inc    cx                                    # 38A3: 41
    inc    cx                                    # 38A4: 41
    inc    cx                                    # 38A5: 41
    mov    bx,WORD PTR ds:STREND                  # 38A6: 8B 1E 5C 03
    push   bx                                    # 38AA: 53
    .byte 0x03, 0xD9 # 38AB
    pop    cx                                    # 38AD: 59
    push   bx                                    # 38AE: 53
    call   BLTU                                # 38AF: E8 19 2C
    pop    bx                                    # 38B2: 5B
    mov    WORD PTR ds:STREND,bx                  # 38B3: 89 1E 5C 03
    .byte 0x8B, 0xD9 # 38B7
    mov    WORD PTR ds:ARYTAB,bx                  # 38B9: 89 1E 5A 03
L_38BD:
    dec    bx                                    # 38BD: 4B
    mov    BYTE PTR [bx],0x0                     # 38BE: C6 07 00
    .byte 0x3B, 0xDA # 38C1
    jne    L_38BD                                # 38C3: 75 F8
    pop    dx                                    # 38C5: 5A
    mov    BYTE PTR [bx],dh                      # 38C6: 88 37
    inc    bx                                    # 38C8: 43
    pop    dx                                    # 38C9: 5A
    mov    WORD PTR [bx],dx                      # 38CA: 89 17
    inc    bx                                    # 38CC: 43
    call   L_3AAD                                # 38CD: E8 DD 01
    xchg   dx,bx                                 # 38D0: 87 DA
    inc    dx                                    # 38D2: 42
    pop    bx                                    # 38D3: 5B
    ret                                          # 38D4: C3
L_38D5:
    call   DZERO                                # 38D5: E8 86 42
    jmp    L_38E2                                # 38D8: EB 08
L_38DA:
    mov    BYTE PTR ds:ONEFLG,0x0                 # 38DA: C6 06 4F 03 00
    jmp    L_435A                                # 38DF: E9 78 0A
L_38E2:
    call   GETYPR                                # 38E2: E8 40 E2
    jne    L_38EE                                # 38E5: 75 07
    mov    bx,0x6                                # 38E7: BB 06 00
    mov    WORD PTR ds:FACLO,bx                  # 38EA: 89 1E A3 04
L_38EE:
    pop    bx                                    # 38EE: 5B
    ret                                          # 38EF: C3
L_38F0:
    push   bx                                    # 38F0: 53
    mov    bx,WORD PTR ds:DIMFLG                  # 38F1: 8B 1E FA 02
    pop    si                                    # 38F5: 5E
    xchg   si,bx                                 # 38F6: 87 DE
    push   si                                    # 38F8: 56
    .byte 0x8A, 0xF0 # 38F9
L_38FB:
    push   dx                                    # 38FB: 52
    push   cx                                    # 38FC: 51
    mov    dx,0x8e                               # 38FD: BA 8E 00
    .byte 0x8B, 0xF2 # 3900
    lods   al,BYTE PTR ds:[si]                   # 3902: AC
    .byte 0x0A, 0xC0 # 3903
    je     L_3944                                # 3905: 74 3D
    xchg   dx,bx                                 # 3907: 87 DA
    add    al,0x2                                # 3909: 04 02
    rcr    al,1                                  # 390B: D0 D8
    .byte 0x8A, 0xC8 # 390D
    call   GETSTK                                # 390F: E8 C3 F3
    .byte 0x8A, 0xC1 # 3912
L_3914:
    mov    cl,BYTE PTR [bx]                      # 3914: 8A 0F
    inc    bx                                    # 3916: 43
    mov    ch,BYTE PTR [bx]                      # 3917: 8A 2F
    inc    bx                                    # 3919: 43
    push   cx                                    # 391A: 51
    dec    al                                    # 391B: FE C8
    jne    L_3914                                # 391D: 75 F5
    push   bx                                    # 391F: 53
    mov    al,ds:NAMCNT                            # 3920: A0 8E 00
    push   ax                                    # 3923: 50
    xchg   dx,bx                                 # 3924: 87 DA
    call   L_1051                                # 3926: E8 28 D7
    pop    ax                                    # 3929: 58
    mov    WORD PTR ds:NAMTMP,bx                   # 392A: 89 1E B5 00
    pop    bx                                    # 392E: 5B
    add    al,0x2                                # 392F: 04 02
    rcr    al,1                                  # 3931: D0 D8
L_3933:
    pop    cx                                    # 3933: 59
    dec    bx                                    # 3934: 4B
    mov    BYTE PTR [bx],ch                      # 3935: 88 2F
    dec    bx                                    # 3937: 4B
    mov    BYTE PTR [bx],cl                      # 3938: 88 0F
    dec    al                                    # 393A: FE C8
    jne    L_3933                                # 393C: 75 F5
    mov    bx,WORD PTR ds:NAMTMP                   # 393E: 8B 1E B5 00
    jmp    L_394C                                # 3942: EB 08
L_3944:
    call   L_1051                                # 3944: E8 0A D7
    .byte 0x32, 0xC0 # 3947
    mov    ds:NAMCNT,al                            # 3949: A2 8E 00
L_394C:
    mov    al,ds:OPTVAL                           # 394C: A0 5C 04
    .byte 0x0A, 0xC0 # 394F
    je     L_395B                                # 3951: 74 08
    .byte 0x0B, 0xD2 # 3953
    jne    L_395A                                # 3955: 75 03
    .byte 0xE9, 0x5F, 0x00 # 3957
L_395A:
    dec    dx                                    # 395A: 4A
L_395B:
    pop    cx                                    # 395B: 59
    pop    ax                                    # 395C: 58
    xchg   ah,al                                 # 395D: 86 C4
    sahf                                         # 395F: 9E
    xchg   dx,bx                                 # 3960: 87 DA
    pop    si                                    # 3962: 5E
    xchg   si,bx                                 # 3963: 87 DE
    push   si                                    # 3965: 56
    push   bx                                    # 3966: 53
    xchg   dx,bx                                 # 3967: 87 DA
    inc    al                                    # 3969: FE C0
    .byte 0x8A, 0xF0 # 396B
    mov    al,BYTE PTR [bx]                      # 396D: 8A 07
    cmp    al,0x2c                               # 396F: 3C 2C
    je     L_38FB                                # 3971: 74 88
    cmp    al,0x29                               # 3973: 3C 29
    je     L_397E                                # 3975: 74 07
    cmp    al,0x5d                               # 3977: 3C 5D
    je     L_397E                                # 3979: 74 03
    jmp    SNERR                                 # 397B: E9 40 CE
L_397E:
    call   CHRGTR                                # 397E: E8 9C D5
    mov    WORD PTR ds:TEMP2,bx                  # 3981: 89 1E 52 03
    pop    bx                                    # 3985: 5B
    mov    WORD PTR ds:DIMFLG,bx                  # 3986: 89 1E FA 02
    mov    dl,0x0                                # 398A: B2 00
    push   dx                                    # 398C: 52
    jmp    L_3996                                # 398D: EB 07
L_398F:
    push   bx                                    # 398F: 53
    lahf                                         # 3990: 9F
    xchg   ah,al                                 # 3991: 86 C4
    push   ax                                    # 3993: 50
    xchg   ah,al                                 # 3994: 86 C4
L_3996:
    mov    bx,WORD PTR ds:ARYTAB                  # 3996: 8B 1E 5A 03
    jmp    LOPFD1                                # 399A: E9 AF 2C
L_399D:
    mov    al,ds:DIMFLG                           # 399D: A0 FA 02
    .byte 0x0A, 0xC0 # 39A0
    je     L_39A7                                # 39A2: 74 03
    jmp    L_07C7                                # 39A4: E9 20 CE
L_39A7:
    pop    ax                                    # 39A7: 58
    xchg   ah,al                                 # 39A8: 86 C4
    sahf                                         # 39AA: 9E
    .byte 0x8B, 0xCB # 39AB
    jne    L_39B2                                # 39AD: 75 03
    jmp    POPHRT                                # 39AF: E9 55 2B
L_39B2:
    sub    al,BYTE PTR [bx]                      # 39B2: 2A 07
    jne    L_39B9                                # 39B4: 75 03
    jmp    L_3A51                                # 39B6: E9 98 00
L_39B9:
    mov    dx,0x9                                # 39B9: BA 09 00
    jmp    L_07D8                                # 39BC: E9 19 CE
L_39BF:
    mov    al,ds:VALTYP                           # 39BF: A0 FB 02
    mov    BYTE PTR [bx],al                      # 39C2: 88 07
    inc    bx                                    # 39C4: 43
    .byte 0x8A, 0xD0 # 39C5
    mov    dh,0x0                                # 39C7: B6 00
    pop    ax                                    # 39C9: 58
    xchg   ah,al                                 # 39CA: 86 C4
    sahf                                         # 39CC: 9E
    jne    L_39D2                                # 39CD: 75 03
    jmp    L_3A9C                                # 39CF: E9 CA 00
L_39D2:
    mov    BYTE PTR [bx],cl                      # 39D2: 88 0F
    inc    bx                                    # 39D4: 43
    mov    BYTE PTR [bx],ch                      # 39D5: 88 2F
    call   L_3AAD                                # 39D7: E8 D3 00
    inc    bx                                    # 39DA: 43
    .byte 0x8A, 0xC8 # 39DB
    call   GETSTK                                # 39DD: E8 F5 F2
    inc    bx                                    # 39E0: 43
    inc    bx                                    # 39E1: 43
    mov    WORD PTR ds:TEMP3,bx                  # 39E2: 89 1E 31 03
    mov    BYTE PTR [bx],cl                      # 39E6: 88 0F
    inc    bx                                    # 39E8: 43
    mov    al,ds:DIMFLG                           # 39E9: A0 FA 02
    rcl    al,1                                  # 39EC: D0 D0
    .byte 0x8A, 0xC1 # 39EE
L_39F0:
    jb     L_3A01                                # 39F0: 72 0F
    lahf                                         # 39F2: 9F
    push   ax                                    # 39F3: 50
    mov    al,ds:OPTVAL                           # 39F4: A0 5C 04
    xor    al,0xb                                # 39F7: 34 0B
    .byte 0x8A, 0xC8 # 39F9
    mov    ch,0x0                                # 39FB: B5 00
    pop    ax                                    # 39FD: 58
    sahf                                         # 39FE: 9E
    jae    L_3A05                                # 39FF: 73 04
L_3A01:
    pop    cx                                    # 3A01: 59
    lahf                                         # 3A02: 9F
    inc    cx                                    # 3A03: 41
    sahf                                         # 3A04: 9E
L_3A05:
    mov    BYTE PTR [bx],cl                      # 3A05: 88 0F
    lahf                                         # 3A07: 9F
    push   ax                                    # 3A08: 50
    inc    bx                                    # 3A09: 43
    mov    BYTE PTR [bx],ch                      # 3A0A: 88 2F
    inc    bx                                    # 3A0C: 43
    call   L_648A                                # 3A0D: E8 7A 2A
    pop    ax                                    # 3A10: 58
    sahf                                         # 3A11: 9E
    dec    al                                    # 3A12: FE C8
    jne    L_39F0                                # 3A14: 75 DA
    lahf                                         # 3A16: 9F
    push   ax                                    # 3A17: 50
    .byte 0x8A, 0xEE, 0x8A, 0xCA # 3A18
    xchg   dx,bx                                 # 3A1C: 87 DA
    .byte 0x03, 0xDA # 3A1E
    jae    L_3A25                                # 3A20: 73 03
    jmp    L_2CF4                                # 3A22: E9 CF F2
L_3A25:
    call   L_2D04                                # 3A25: E8 DC F2
    mov    WORD PTR ds:STREND,bx                  # 3A28: 89 1E 5C 03
L_3A2C:
    dec    bx                                    # 3A2C: 4B
    .byte 0xC6 # 3A2D
L_3A2E:
    .byte 0x07, 0x00, 0x3B, 0xDA, 0x75, 0xF8, 0x32, 0xC0 # 3A2E
    inc    cx                                    # 3A36: 41
    .byte 0x8A, 0xF0 # 3A37
    mov    bx,WORD PTR ds:TEMP3                  # 3A39: 8B 1E 31 03
    mov    dl,BYTE PTR [bx]                      # 3A3D: 8A 17
    xchg   dx,bx                                 # 3A3F: 87 DA
    .byte 0x03, 0xDB, 0x03, 0xD9 # 3A41
    xchg   dx,bx                                 # 3A45: 87 DA
    dec    bx                                    # 3A47: 4B
    dec    bx                                    # 3A48: 4B
    mov    WORD PTR [bx],dx                      # 3A49: 89 17
    inc    bx                                    # 3A4B: 43
    inc    bx                                    # 3A4C: 43
    pop    ax                                    # 3A4D: 58
    sahf                                         # 3A4E: 9E
    jb     L_3A97                                # 3A4F: 72 46
L_3A51:
    .byte 0x8A, 0xE8, 0x8A, 0xC8 # 3A51
    mov    al,BYTE PTR [bx]                      # 3A55: 8A 07
    inc    bx                                    # 3A57: 43
    .byte 0xB6 # 3A58
L_3A59:
    .byte 0x5B # 3A59
    mov    dx,WORD PTR [bx]                      # 3A5A: 8B 17
    inc    bx                                    # 3A5C: 43
    inc    bx                                    # 3A5D: 43
    pop    si                                    # 3A5E: 5E
    xchg   si,bx                                 # 3A5F: 87 DE
    push   si                                    # 3A61: 56
    push   ax                                    # 3A62: 50
    .byte 0x3B, 0xDA # 3A63
    jb     L_3A6A                                # 3A65: 72 03
    jmp    L_39B9                                # 3A67: E9 4F FF
L_3A6A:
    call   L_648A                                # 3A6A: E8 1D 2A
    .byte 0x03, 0xDA # 3A6D
    pop    ax                                    # 3A6F: 58
    dec    al                                    # 3A70: FE C8
    .byte 0x8B, 0xCB # 3A72
    jne    L_3A59                                # 3A74: 75 E3
    mov    al,ds:VALTYP                           # 3A76: A0 FB 02
    .byte 0x8B, 0xCB, 0x03, 0xDB # 3A79
    sub    al,0x4                                # 3A7D: 2C 04
    jb     L_3A89                                # 3A7F: 72 08
    .byte 0x03, 0xDB, 0x0A, 0xC0 # 3A81
    je     L_3A92                                # 3A85: 74 0B
    .byte 0x03, 0xDB # 3A87
L_3A89:
    .byte 0x0A, 0xC0 # 3A89
    jp     L_3A90                                # 3A8B: 7A 03
    .byte 0xE9, 0x02, 0x00 # 3A8D
L_3A90:
    .byte 0x03, 0xD9 # 3A90
L_3A92:
    pop    cx                                    # 3A92: 59
    .byte 0x03, 0xD9 # 3A93
    xchg   dx,bx                                 # 3A95: 87 DA
L_3A97:
    mov    bx,WORD PTR ds:TEMP2                  # 3A97: 8B 1E 52 03
    ret                                          # 3A9B: C3
L_3A9C:
    stc                                          # 3A9C: F9
    .byte 0x1A, 0xC0 # 3A9D
    pop    bx                                    # 3A9F: 5B
    ret                                          # 3AA0: C3
L_3AA1:
    mov    al,BYTE PTR [bx]                      # 3AA1: 8A 07
    inc    bx                                    # 3AA3: 43
    push   cx                                    # 3AA4: 51
    mov    ch,0x0                                # 3AA5: B5 00
    .byte 0x8A, 0xC8, 0x03, 0xD9 # 3AA7
    pop    cx                                    # 3AAB: 59
    ret                                          # 3AAC: C3
L_3AAD:
    push   cx                                    # 3AAD: 51
    push   dx                                    # 3AAE: 52
    lahf                                         # 3AAF: 9F
    push   ax                                    # 3AB0: 50
    mov    dx,0x8e                               # 3AB1: BA 8E 00
    .byte 0x8B, 0xF2 # 3AB4
    lods   al,BYTE PTR ds:[si]                   # 3AB6: AC
    .byte 0x8A, 0xE8 # 3AB7
    inc    ch                                    # 3AB9: FE C5
L_3ABB:
    .byte 0x8B, 0xF2 # 3ABB
    lods   al,BYTE PTR ds:[si]                   # 3ABD: AC
    inc    dx                                    # 3ABE: 42
    inc    bx                                    # 3ABF: 43
    mov    BYTE PTR [bx],al                      # 3AC0: 88 07
    dec    ch                                    # 3AC2: FE CD
    jne    L_3ABB                                # 3AC4: 75 F5
    pop    ax                                    # 3AC6: 58
    sahf                                         # 3AC7: 9E
    pop    dx                                    # 3AC8: 5A
    pop    cx                                    # 3AC9: 59
    ret                                          # 3ACA: C3
PRINUS:
    call   FRMCHK                                # 3ACB: E8 5A DC
    call   L_643B                                # 3ACE: E8 6A 29
    call   SYNCHR                                # 3AD1: E8 20 F3
    .byte ';'                                  # 3AD4: 3B -- SYNCHR inline operand
    xchg   dx,bx                                 # 3AD5: 87 DA -- text pointer -> DX
    mov    bx,WORD PTR ds:FACLO                  # 3AD7: 8B 1E A3 04 -- USING string descriptor
    jmp    INIUS                                 # 3ADB: EB 0A
REUSST:
    mov    al,ds:USFLG                           # 3ADD: A0 3A 03
    .byte 0x0A, 0xC0                            # 3AE0: OR AL,AL exact historical encoding
    je     L_3AF5                                # 3AE2: 74 11
    pop    dx                                    # 3AE4: 5A
    xchg   dx,bx                                 # 3AE5: 87 DA
INIUS:
    push   bx                                    # 3AE7: 53
    .byte 0x32, 0xC0                            # 3AE8: XOR AL,AL exact historical encoding
    mov    ds:USFLG,al                           # 3AEA: A2 3A 03
    inc    al                                    # 3AED: FE C0
    pushf                                        # 3AEF: 9C
    push   dx                                    # 3AF0: 52
    mov    ch,BYTE PTR [bx]                      # 3AF1: 8A 2F
    .byte 0x0A, 0xED # 3AF3
L_3AF5:
    jne    L_3AFA                                # 3AF5: 75 03
    jmp    FCERR                                # 3AF7: E9 5F D5
L_3AFA:
    inc    bx                                    # 3AFA: 43
    mov    bx,WORD PTR [bx]                      # 3AFB: 8B 1F
    jmp    L_3B23                                # 3AFD: EB 24
L_3AFF:
    .byte 0x8A, 0xD5 # 3AFF
    push   bx                                    # 3B01: 53
    mov    cl,0x2                                # 3B02: B1 02
L_3B04:
    mov    al,BYTE PTR [bx]                      # 3B04: 8A 07
    inc    bx                                    # 3B06: 43
    cmp    al,0x5c                               # 3B07: 3C 5C
    jne    L_3B0E                                # 3B09: 75 03
    jmp    L_3CAB                                # 3B0B: E9 9D 01
L_3B0E:
    cmp    al,0x20                               # 3B0E: 3C 20
    jne    L_3B18                                # 3B10: 75 06
    inc    cl                                    # 3B12: FE C1
    dec    ch                                    # 3B14: FE CD
    jne    L_3B04                                # 3B16: 75 EC
L_3B18:
    pop    bx                                    # 3B18: 5B
    .byte 0x8A, 0xEA # 3B19
    mov    al,0x5c                               # 3B1B: B0 5C
L_3B1D:
    call   L_3CF6                                # 3B1D: E8 D6 01
    call   OUTDO                                # 3B20: E8 82 F0
L_3B23:
    .byte 0x32, 0xC0, 0x8A, 0xD0, 0x8A, 0xF0 # 3B23
L_3B29:
    call   L_3CF6                                # 3B29: E8 CA 01
    .byte 0x8A, 0xF0 # 3B2C
    mov    al,BYTE PTR [bx]                      # 3B2E: 8A 07
    inc    bx                                    # 3B30: 43
    cmp    al,0x21                               # 3B31: 3C 21
    jne    L_3B38                                # 3B33: 75 03
    jmp    L_3CA7                                # 3B35: E9 6F 01
L_3B38:
    cmp    al,0x23                               # 3B38: 3C 23
    je     L_3B8E                                # 3B3A: 74 52
    cmp    al,0x26                               # 3B3C: 3C 26
    jne    L_3B43                                # 3B3E: 75 03
    jmp    L_3CA3                                # 3B40: E9 60 01
L_3B43:
    dec    ch                                    # 3B43: FE CD
    jne    L_3B4A                                # 3B45: 75 03
    jmp    L_3C78                                # 3B47: E9 2E 01
L_3B4A:
    cmp    al,0x2b                               # 3B4A: 3C 2B
    mov    al,0x8                                # 3B4C: B0 08
    je     L_3B29                                # 3B4E: 74 D9
    dec    bx                                    # 3B50: 4B
    mov    al,BYTE PTR [bx]                      # 3B51: 8A 07
    inc    bx                                    # 3B53: 43
    cmp    al,0x2e                               # 3B54: 3C 2E
    je     L_3BAD                                # 3B56: 74 55
    cmp    al,0x5f                               # 3B58: 3C 5F
    jne    L_3B5F                                # 3B5A: 75 03
    jmp    L_3C96                                # 3B5C: E9 37 01
L_3B5F:
    cmp    al,0x5c                               # 3B5F: 3C 5C
    je     L_3AFF                                # 3B61: 74 9C
    cmp    al,BYTE PTR [bx]                      # 3B63: 3A 07
    jne    L_3B1D                                # 3B65: 75 B6
    cmp    al,0x24                               # 3B67: 3C 24
    je     L_3B83                                # 3B69: 74 18
    cmp    al,0x2a                               # 3B6B: 3C 2A
    jne    L_3B1D                                # 3B6D: 75 AE
    .byte 0x8A, 0xC5 # 3B6F
    inc    bx                                    # 3B71: 43
    cmp    al,0x2                                # 3B72: 3C 02
    jb     L_3B7A                                # 3B74: 72 04
    mov    al,BYTE PTR [bx]                      # 3B76: 8A 07
    cmp    al,0x24                               # 3B78: 3C 24
L_3B7A:
    mov    al,0x20                               # 3B7A: B0 20
    jne    L_3B88                                # 3B7C: 75 0A
    dec    ch                                    # 3B7E: FE CD
    inc    dl                                    # 3B80: FE C2
    .byte 0xBE # 3B82
L_3B83:
    .byte 0x32, 0xC0 # 3B83
    add    al,0x10                               # 3B85: 04 10
    inc    bx                                    # 3B87: 43
L_3B88:
    inc    dl                                    # 3B88: FE C2
    .byte 0x02, 0xC6, 0x8A, 0xF0 # 3B8A
L_3B8E:
    inc    dl                                    # 3B8E: FE C2
    mov    cl,0x0                                # 3B90: B1 00
    dec    ch                                    # 3B92: FE CD
    je     L_3BF7                                # 3B94: 74 61
    mov    al,BYTE PTR [bx]                      # 3B96: 8A 07
    inc    bx                                    # 3B98: 43
    cmp    al,0x2e                               # 3B99: 3C 2E
    je     L_3BBB                                # 3B9B: 74 1E
    cmp    al,0x23                               # 3B9D: 3C 23
    je     L_3B8E                                # 3B9F: 74 ED
    cmp    al,0x2c                               # 3BA1: 3C 2C
    jne    L_3BC8                                # 3BA3: 75 23
    .byte 0x8A, 0xC6 # 3BA5
    or     al,0x40                               # 3BA7: 0C 40
    .byte 0x8A, 0xF0 # 3BA9
    jmp    L_3B8E                                # 3BAB: EB E1
L_3BAD:
    mov    al,BYTE PTR [bx]                      # 3BAD: 8A 07
    cmp    al,0x23                               # 3BAF: 3C 23
    mov    al,0x2e                               # 3BB1: B0 2E
    je     L_3BB8                                # 3BB3: 74 03
    jmp    L_3B1D                                # 3BB5: E9 65 FF
L_3BB8:
    mov    cl,0x1                                # 3BB8: B1 01
    inc    bx                                    # 3BBA: 43
L_3BBB:
    inc    cl                                    # 3BBB: FE C1
    dec    ch                                    # 3BBD: FE CD
    je     L_3BF7                                # 3BBF: 74 36
    mov    al,BYTE PTR [bx]                      # 3BC1: 8A 07
    inc    bx                                    # 3BC3: 43
    cmp    al,0x23                               # 3BC4: 3C 23
    je     L_3BBB                                # 3BC6: 74 F3
L_3BC8:
    push   dx                                    # 3BC8: 52
    mov    dx,0x3bf4                             # 3BC9: BA F4 3B
    push   dx                                    # 3BCC: 52
    .byte 0x8A, 0xF7, 0x8A, 0xD3 # 3BCD
    cmp    al,0x5e                               # 3BD1: 3C 5E
    je     L_3BD6                                # 3BD3: 74 01
L_3BD5:
    ret                                          # 3BD5: C3
L_3BD6:
    cmp    al,BYTE PTR [bx]                      # 3BD6: 3A 07
    jne    L_3BD5                                # 3BD8: 75 FB
    inc    bx                                    # 3BDA: 43
    cmp    al,BYTE PTR [bx]                      # 3BDB: 3A 07
    jne    L_3BD5                                # 3BDD: 75 F6
    inc    bx                                    # 3BDF: 43
    cmp    al,BYTE PTR [bx]                      # 3BE0: 3A 07
    jne    L_3BD5                                # 3BE2: 75 F1
    inc    bx                                    # 3BE4: 43
    .byte 0x8A, 0xC5 # 3BE5
    sub    al,0x4                                # 3BE7: 2C 04
    jb     L_3BD5                                # 3BE9: 72 EA
    pop    dx                                    # 3BEB: 5A
    pop    dx                                    # 3BEC: 5A
    .byte 0x8A, 0xE8 # 3BED
    inc    dh                                    # 3BEF: FE C6
    inc    bx                                    # 3BF1: 43
    jmp    L_3BF7                                # 3BF2: EB 03
    .byte 0x87, 0xDA, 0x5A # 3BF4
L_3BF7:
    .byte 0x8A, 0xC6 # 3BF7
    dec    bx                                    # 3BF9: 4B
    inc    dl                                    # 3BFA: FE C2
    and    al,0x8                                # 3BFC: 24 08
    jne    L_3C1C                                # 3BFE: 75 1C
    dec    dl                                    # 3C00: FE CA
    .byte 0x8A, 0xC5, 0x0A, 0xC0 # 3C02
    je     L_3C1C                                # 3C06: 74 14
    mov    al,BYTE PTR [bx]                      # 3C08: 8A 07
    sub    al,0x2d                               # 3C0A: 2C 2D
    je     L_3C14                                # 3C0C: 74 06
    cmp    al,0xfe                               # 3C0E: 3C FE
    jne    L_3C1C                                # 3C10: 75 0A
    mov    al,0x8                                # 3C12: B0 08
L_3C14:
    add    al,0x4                                # 3C14: 04 04
    .byte 0x02, 0xC6, 0x8A, 0xF0 # 3C16
    dec    ch                                    # 3C1A: FE CD
L_3C1C:
    pop    bx                                    # 3C1C: 5B
    popf                                         # 3C1D: 9D
    je     L_3C85                                # 3C1E: 74 65
    push   cx                                    # 3C20: 51
    push   dx                                    # 3C21: 52
    call   FRMEVL                                # 3C22: E8 02 DB
    pop    dx                                    # 3C25: 5A
    pop    cx                                    # 3C26: 59
    push   cx                                    # 3C27: 51
    push   bx                                    # 3C28: 53
    .byte 0x8A, 0xEA, 0x8A, 0xC5, 0x02, 0xC1 # 3C29
    cmp    al,0x19                               # 3C2F: 3C 19
    jb     L_3C36                                # 3C31: 72 03
    jmp    FCERR                                # 3C33: E9 23 D4
L_3C36:
    .byte 0x8A, 0xC6 # 3C36
    or     al,0x80                               # 3C38: 0C 80
    call   L_7799                                # 3C3A: E8 5C 3B
    call   L_26B7                                # 3C3D: E8 77 EA
L_3C40:
    pop    bx                                    # 3C40: 5B
    dec    bx                                    # 3C41: 4B
    call   CHRGTR                                # 3C42: E8 D8 D2
    stc                                          # 3C45: F9
    je     L_3C59                                # 3C46: 74 11
    mov    ds:FLGINP,al                           # 3C48: A2 3A 03
    cmp    al,0x3b                               # 3C4B: 3C 3B
    je     L_3C56                                # 3C4D: 74 07
    cmp    al,0x2c                               # 3C4F: 3C 2C
    je     L_3C56                                # 3C51: 74 03
    jmp    SNERR                                 # 3C53: E9 68 CB
L_3C56:
    call   CHRGTR                                # 3C56: E8 C4 D2
L_3C59:
    pop    cx                                    # 3C59: 59
    xchg   dx,bx                                 # 3C5A: 87 DA
    pop    bx                                    # 3C5C: 5B
    push   bx                                    # 3C5D: 53
    pushf                                        # 3C5E: 9C
    push   dx                                    # 3C5F: 52
    mov    al,BYTE PTR [bx]                      # 3C60: 8A 07
    .byte 0x2A, 0xC5 # 3C62
    inc    bx                                    # 3C64: 43
    mov    dh,0x0                                # 3C65: B6 00
    .byte 0x8A, 0xD0 # 3C67
    mov    bx,WORD PTR [bx]                      # 3C69: 8B 1F
    .byte 0x03, 0xDA # 3C6B
L_3C6D:
    .byte 0x8A, 0xC5, 0x0A, 0xC0 # 3C6D
    je     L_3C76                                # 3C71: 74 03
    jmp    L_3B23                                # 3C73: E9 AD FE
L_3C76:
    jmp    L_3C7E                                # 3C76: EB 06
L_3C78:
    call   L_3CF6                                # 3C78: E8 7B 00
    call   OUTDO                                # 3C7B: E8 27 EF
L_3C7E:
    pop    bx                                    # 3C7E: 5B
    popf                                         # 3C7F: 9D
    je     L_3C85                                # 3C80: 74 03
    jmp    REUSST                                # 3C82: E9 58 FE
L_3C85:
    jae    L_3C8A                                # 3C85: 73 03
    call   CRDO                                # 3C87: E8 E7 EF
L_3C8A:
    pop    si                                    # 3C8A: 5E
    xchg   si,bx                                 # 3C8B: 87 DE
    push   si                                    # 3C8D: 56
    call   L_28AD                                # 3C8E: E8 1C EC
    pop    bx                                    # 3C91: 5B
    jmp    L_1498                                # 3C92: E9 03 D8
    .byte 0xC3 # 3C95
L_3C96:
    call   L_3CF6                                # 3C96: E8 5D 00
    dec    ch                                    # 3C99: FE CD
    mov    al,BYTE PTR [bx]                      # 3C9B: 8A 07
    inc    bx                                    # 3C9D: 43
    call   OUTDO                                # 3C9E: E8 04 EF
    jmp    L_3C6D                                # 3CA1: EB CA
L_3CA3:
    mov    cl,0x0                                # 3CA3: B1 00
    jmp    L_3CAC                                # 3CA5: EB 05
L_3CA7:
    mov    cl,0x1                                # 3CA7: B1 01
    jmp    L_3CAC                                # 3CA9: EB 01
L_3CAB:
    pop    ax                                    # 3CAB: 58
L_3CAC:
    dec    ch                                    # 3CAC: FE CD
    call   L_3CF6                                # 3CAE: E8 45 00
    pop    bx                                    # 3CB1: 5B
    popf                                         # 3CB2: 9D
    je     L_3C85                                # 3CB3: 74 D0
    push   cx                                    # 3CB5: 51
    call   FRMEVL                                # 3CB6: E8 6E DA
    call   L_643B                                # 3CB9: E8 7F 27
    pop    cx                                    # 3CBC: 59
    push   cx                                    # 3CBD: 51
    push   bx                                    # 3CBE: 53
    mov    bx,WORD PTR ds:FACLO                  # 3CBF: 8B 1E A3 04
    .byte 0x8A, 0xE9 # 3CC3
    mov    cl,0x0                                # 3CC5: B1 00
    .byte 0x8A, 0xC5 # 3CC7
    push   ax                                    # 3CC9: 50
    .byte 0x8A, 0xC5, 0x0A, 0xC0 # 3CCA
    je     L_3CD3                                # 3CCE: 74 03
    call   L_2974                                # 3CD0: E8 A1 EC
L_3CD3:
    call   L_26BA                                # 3CD3: E8 E4 E9
    mov    bx,WORD PTR ds:FACLO                  # 3CD6: 8B 1E A3 04
    pop    ax                                    # 3CDA: 58
    .byte 0x0A, 0xC0 # 3CDB
    jne    L_3CE2                                # 3CDD: 75 03
    jmp    L_3C40                                # 3CDF: E9 5E FF
L_3CE2:
    sub    al,BYTE PTR [bx]                      # 3CE2: 2A 07
    .byte 0x8A, 0xE8 # 3CE4
    mov    al,0x20                               # 3CE6: B0 20
    inc    ch                                    # 3CE8: FE C5
L_3CEA:
    dec    ch                                    # 3CEA: FE CD
    jne    L_3CF1                                # 3CEC: 75 03
    jmp    L_3C40                                # 3CEE: E9 4F FF
L_3CF1:
    call   OUTDO                                # 3CF1: E8 B1 EE
    jmp    L_3CEA                                # 3CF4: EB F4
L_3CF6:
    push   ax                                    # 3CF6: 50
    .byte 0x8A, 0xC6, 0x0A, 0xC0 # 3CF7
    mov    al,0x2b                               # 3CFB: B0 2B
    je     L_3D02                                # 3CFD: 74 03
    call   OUTDO                                # 3CFF: E8 A3 EE
L_3D02:
    pop    ax                                    # 3D02: 58
    ret                                          # 3D03: C3
WHILE:
    mov    WORD PTR ds:ENDFOR,bx                  # 3D04: 89 1E 35 03
    call   WNDSCN                                # 3D08: E8 EC E7
    call   CHRGTR                                # 3D0B: E8 0F D2
    xchg   dx,bx                                 # 3D0E: 87 DA
    call   L_3D79                                # 3D10: E8 66 00
    lahf                                         # 3D13: 9F
    inc    sp                                    # 3D14: 44
    sahf                                         # 3D15: 9E
    lahf                                         # 3D16: 9F
    inc    sp                                    # 3D17: 44
    sahf                                         # 3D18: 9E
    jne    L_3D23                                # 3D19: 75 08
    .byte 0x03, 0xD9, 0x8B, 0xE3 # 3D1B
    mov    WORD PTR ds:SAVSTK,bx                  # 3D1F: 89 1E 45 03
L_3D23:
    mov    bx,WORD PTR ds:CURLIN                   # 3D23: 8B 1E 2E 00
    push   bx                                    # 3D27: 53
    mov    bx,WORD PTR ds:ENDFOR                  # 3D28: 8B 1E 35 03
    push   bx                                    # 3D2C: 53
    push   dx                                    # 3D2D: 52
    jmp    L_3D58                                # 3D2E: EB 28
WEND:
    je     L_3D35                                # 3D30: 74 03
    jmp    SNERR                                 # 3D32: E9 89 CA
L_3D35:
    xchg   dx,bx                                 # 3D35: 87 DA
    call   L_3D79                                # 3D37: E8 3F 00
    jne    L_3DA3                                # 3D3A: 75 67
    .byte 0x8B, 0xE3 # 3D3C
    mov    WORD PTR ds:SAVSTK,bx                  # 3D3E: 89 1E 45 03
    mov    dx,WORD PTR ds:CURLIN                   # 3D42: 8B 16 2E 00
    mov    WORD PTR ds:NXTLIN,dx                  # 3D46: 89 16 5A 04
    inc    bx                                    # 3D4A: 43
    inc    bx                                    # 3D4B: 43
    mov    dx,WORD PTR [bx]                      # 3D4C: 8B 17
    inc    bx                                    # 3D4E: 43
    inc    bx                                    # 3D4F: 43
    mov    bx,WORD PTR [bx]                      # 3D50: 8B 1F
    mov    WORD PTR ds:CURLIN,bx                   # 3D52: 89 1E 2E 00
    xchg   dx,bx                                 # 3D56: 87 DA
L_3D58:
    call   FRMEVL                                # 3D58: E8 CC D9
    push   bx                                    # 3D5B: 53
    call   L_64E3                                # 3D5C: E8 84 27
    pop    bx                                    # 3D5F: 5B
    je     L_3D6B                                # 3D60: 74 09
    mov    cx,0xb1                               # 3D62: B9 B1 00
    .byte 0x8A, 0xE9 # 3D65
    push   cx                                    # 3D67: 51
    jmp    L_0EE8                                # 3D68: E9 7D D1
L_3D6B:
    mov    bx,WORD PTR ds:NXTLIN                  # 3D6B: 8B 1E 5A 04
    mov    WORD PTR ds:CURLIN,bx                   # 3D6F: 89 1E 2E 00
    pop    bx                                    # 3D73: 5B
    pop    cx                                    # 3D74: 59
    pop    cx                                    # 3D75: 59
    jmp    L_0EE8                                # 3D76: E9 6F D1
L_3D79:
    mov    bx,0x4                                # 3D79: BB 04 00
    .byte 0x03, 0xDC # 3D7C
L_3D7E:
    inc    bx                                    # 3D7E: 43
    mov    al,BYTE PTR [bx]                      # 3D7F: 8A 07
    inc    bx                                    # 3D81: 43
    mov    cx,0x82                               # 3D82: B9 82 00
    .byte 0x3A, 0xC1 # 3D85
    jne    L_3D90                                # 3D87: 75 07
    mov    cx,0x12                               # 3D89: B9 12 00
    .byte 0x03, 0xD9 # 3D8C
    jmp    L_3D7E                                # 3D8E: EB EE
L_3D90:
    mov    cx,0xb1                               # 3D90: B9 B1 00
    .byte 0x3A, 0xC1 # 3D93
    je     L_3D98                                # 3D95: 74 01
L_3D97:
    ret                                          # 3D97: C3
L_3D98:
    cmp    WORD PTR [bx],dx                      # 3D98: 39 17
    mov    cx,0x6                                # 3D9A: B9 06 00
    je     L_3D97                                # 3D9D: 74 F8
    .byte 0x03, 0xD9 # 3D9F
    jmp    L_3D7E                                # 3DA1: EB DB
L_3DA3:
    mov    dx,0x1e                               # 3DA3: BA 1E 00
    jmp    L_07D8                                # 3DA6: E9 2F CA
WRITE:
    call   L_44E6                                # 3DA9: E8 3A 07
    dec    bx                                    # 3DAC: 4B
    call   CHRGTR                                # 3DAD: E8 6D D1
    je     L_3E07                                # 3DB0: 74 55
L_3DB2:
    call   FRMEVL                                # 3DB2: E8 72 D9
    push   bx                                    # 3DB5: 53
    call   GETYPR                                # 3DB6: E8 6C DD
    je     L_3DF8                                # 3DB9: 74 3D
    call   L_70C8                                # 3DBB: E8 0A 33
    call   L_264C                                # 3DBE: E8 8B E8
    mov    bx,WORD PTR ds:FACLO                  # 3DC1: 8B 1E A3 04
    inc    bx                                    # 3DC5: 43
    mov    dl,BYTE PTR [bx]                      # 3DC6: 8A 17
    inc    bx                                    # 3DC8: 43
    mov    dh,BYTE PTR [bx]                      # 3DC9: 8A 37
    .byte 0x8B, 0xF2 # 3DCB
    lods   al,BYTE PTR ds:[si]                   # 3DCD: AC
    cmp    al,0x20                               # 3DCE: 3C 20
    jne    L_3DDB                                # 3DD0: 75 09
    inc    dx                                    # 3DD2: 42
    mov    BYTE PTR [bx],dh                      # 3DD3: 88 37
    dec    bx                                    # 3DD5: 4B
    mov    BYTE PTR [bx],dl                      # 3DD6: 88 17
    dec    bx                                    # 3DD8: 4B
    dec    BYTE PTR [bx]                         # 3DD9: FE 0F
L_3DDB:
    call   L_26BA                                # 3DDB: E8 DC E8
L_3DDE:
    pop    bx                                    # 3DDE: 5B
    dec    bx                                    # 3DDF: 4B
    call   CHRGTR                                # 3DE0: E8 3A D1
    je     L_3E07                                # 3DE3: 74 22
    cmp    al,0x3b                               # 3DE5: 3C 3B
    je     L_3DEE                                # 3DE7: 74 05
    call   SYNCHR                                # 3DE9: E8 08 F0
    .byte ','                                  # 3DEC: 2C -- SYNCHR inline operand
    .byte 0x4B # 3DED -- decoded continuation: dec    bx
L_3DEE:
    call   CHRGTR                                # 3DEE: E8 2C D1
    mov    al,0x2c                               # 3DF1: B0 2C
    call   OUTDO                                # 3DF3: E8 AF ED
    jmp    L_3DB2                                # 3DF6: EB BA
L_3DF8:
    mov    al,0x22                               # 3DF8: B0 22
    call   OUTDO                                # 3DFA: E8 A8 ED
    call   L_26BA                                # 3DFD: E8 BA E8
    mov    al,0x22                               # 3E00: B0 22
    call   OUTDO                                # 3E02: E8 A0 ED
    jmp    L_3DDE                                # 3E05: EB D7
L_3E07:
    call   CRDO                                # 3E07: E8 67 EE
    jmp    L_1498                                # 3E0A: E9 8B D6
L_3E0D:
    int    0xa8                                  # 3E0D: CD A8
    push   bx                                    # 3E0F: 53
    .byte 0x8A, 0xF2 # 3E10
    call   L_3F9C                                # 3E12: E8 87 01
    je     L_3E20                                # 3E15: 74 09
L_3E17:
    cmp    al,0x3a                               # 3E17: 3C 3A
    je     L_3E2A                                # 3E19: 74 0F
    call   L_3F9C                                # 3E1B: E8 7E 01
    jns    L_3E17                                # 3E1E: 79 F7
L_3E20:
    .byte 0x8A, 0xD6 # 3E20
    pop    bx                                    # 3E22: 5B
    .byte 0x32, 0xC0 # 3E23
    mov    al,0xfc                               # 3E25: B0 FC
    int    0xab                                  # 3E27: CD AB
    ret                                          # 3E29: C3
L_3E2A:
    .byte 0x8A, 0xC6, 0x2A, 0xC2 # 3E2A
    dec    al                                    # 3E2E: FE C8
    cmp    al,0x2                                # 3E30: 3C 02
    jae    L_3E39                                # 3E32: 73 05
    int    0xac                                  # 3E34: CD AC
    jmp    L_079A                                # 3E36: E9 61 C9
L_3E39:
    cmp    al,0x5                                # 3E39: 3C 05
    jb     L_3E40                                # 3E3B: 72 03
    jmp    L_079A                                # 3E3D: E9 5A C9
L_3E40:
    pop    cx                                    # 3E40: 59
    push   dx                                    # 3E41: 52
    push   cx                                    # 3E42: 51
    .byte 0x8A, 0xC8, 0x8A, 0xE8 # 3E43
    mov    dx,0x3e9c                             # 3E47: BA 9C 3E
    pop    si                                    # 3E4A: 5E
    xchg   si,bx                                 # 3E4B: 87 DE
    push   si                                    # 3E4D: 56
    push   bx                                    # 3E4E: 53
L_3E4F:
    mov    al,BYTE PTR [bx]                      # 3E4F: 8A 07
    cmp    al,0x61                               # 3E51: 3C 61
    jb     L_3E5B                                # 3E53: 72 06
    cmp    al,0x7b                               # 3E55: 3C 7B
    jae    L_3E5B                                # 3E57: 73 02
    sub    al,0x20                               # 3E59: 2C 20
L_3E5B:
    push   cx                                    # 3E5B: 51
    .byte 0x8A, 0xE8, 0x8B, 0xF2 # 3E5C
    lods   al,BYTE PTR cs:[si]                   # 3E60: 2E AC
    inc    bx                                    # 3E62: 43
    inc    dx                                    # 3E63: 42
    .byte 0x3A, 0xC5 # 3E64
    pop    cx                                    # 3E66: 59
    jne    L_3E7E                                # 3E67: 75 15
    dec    cl                                    # 3E69: FE C9
    jne    L_3E4F                                # 3E6B: 75 E2
L_3E6D:
    .byte 0x8B, 0xF2 # 3E6D
    lods   al,BYTE PTR cs:[si]                   # 3E6F: 2E AC
    .byte 0x0A, 0xC0 # 3E71
    js     L_3E78                                # 3E73: 78 03
    .byte 0xE9, 0x06, 0x00 # 3E75
L_3E78:
    pop    bx                                    # 3E78: 5B
    pop    bx                                    # 3E79: 5B
    pop    dx                                    # 3E7A: 5A
    .byte 0x0A, 0xC0 # 3E7B
    ret                                          # 3E7D: C3
L_3E7E:
    .byte 0x0A, 0xC0 # 3E7E
    js     L_3E6D                                # 3E80: 78 EB
L_3E82:
    .byte 0x8B, 0xF2 # 3E82
    lods   al,BYTE PTR cs:[si]                   # 3E84: 2E AC
    .byte 0x0A, 0xC0 # 3E86
    lahf                                         # 3E88: 9F
    inc    dx                                    # 3E89: 42
    sahf                                         # 3E8A: 9E
    jns    L_3E82                                # 3E8B: 79 F5
    .byte 0x8A, 0xCD # 3E8D
    pop    bx                                    # 3E8F: 5B
    push   bx                                    # 3E90: 53
    .byte 0x8B, 0xF2 # 3E91
    lods   al,BYTE PTR cs:[si]                   # 3E93: 2E AC
    .byte 0x0A, 0xC0 # 3E95
    jne    L_3E4F                                # 3E97: 75 B6
    jmp    L_079A                                # 3E99: E9 FE C8
    .byte 0x4B, 0x59, 0x42, 0x44, 0xFF, 0x53, 0x43, 0x52, 0x4E, 0xFE, 0x4C, 0x50 # 3E9C
    .byte 0x54, 0x31, 0xFD, 0x43, 0x41, 0x53, 0x31, 0xFC, 0x00, 0x7B, 0x58, 0x91 # 3EA8
    .byte 0x58, 0xA7, 0x58, 0xBD, 0x58 # 3EB4
L_3EB9:
    int    0xa9                                  # 3EB9: CD A9
    push   bx                                    # 3EBB: 53
    push   dx                                    # 3EBC: 52
    lahf                                         # 3EBD: 9F
    xchg   ah,al                                 # 3EBE: 86 C4
    push   ax                                    # 3EC0: 50
    xchg   ah,al                                 # 3EC1: 86 C4
    mov    dx,0x2e                               # 3EC3: BA 2E 00
    .byte 0x03, 0xDA # 3EC6
    mov    al,0xff                               # 3EC8: B0 FF
    sub    al,BYTE PTR [bx]                      # 3ECA: 2A 07
    .byte 0x02, 0xC0, 0x8A, 0xD0 # 3ECC
    int    0xaa                                  # 3ED0: CD AA
L_3ED2:
    mov    dh,0x0                                # 3ED2: B6 00
    mov    bx,0x3eb1                             # 3ED4: BB B1 3E
    .byte 0x03, 0xDA # 3ED7
    mov    dl,BYTE PTR cs:[bx]                   # 3ED9: 2E 8A 17
    inc    bx                                    # 3EDC: 43
    mov    dh,BYTE PTR cs:[bx]                   # 3EDD: 2E 8A 37
    pop    ax                                    # 3EE0: 58
    xchg   ah,al                                 # 3EE1: 86 C4
    sahf                                         # 3EE3: 9E
    .byte 0x8A, 0xD8 # 3EE4
    mov    bh,0x0                                # 3EE6: B7 00
    .byte 0x03, 0xDA # 3EE8
    mov    dl,BYTE PTR cs:[bx]                   # 3EEA: 2E 8A 17
    inc    bx                                    # 3EED: 43
    mov    dh,BYTE PTR cs:[bx]                   # 3EEE: 2E 8A 37
    xchg   dx,bx                                 # 3EF1: 87 DA
    pop    dx                                    # 3EF3: 5A
    pop    si                                    # 3EF4: 5E
    xchg   si,bx                                 # 3EF5: 87 DE
    push   si                                    # 3EF7: 56
    ret                                          # 3EF8: C3
    .byte 0x47, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 # 3EF9
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 # 3F05
    .byte 0x00, 0x00 # 3F11
L_3F13:
    call   FRMEVL                                # 3F13: E8 11 D8
L_3F16:
    push   bx                                    # 3F16: 53
    call   L_28A6                                # 3F17: E8 8C E9
    mov    al,BYTE PTR [bx]                      # 3F1A: 8A 07
    .byte 0x0A, 0xC0 # 3F1C
    je     L_3F6F                                # 3F1E: 74 4F
    inc    bx                                    # 3F20: 43
    mov    dl,BYTE PTR [bx]                      # 3F21: 8A 17
    inc    bx                                    # 3F23: 43
    mov    bh,BYTE PTR [bx]                      # 3F24: 8A 3F
    .byte 0x8A, 0xDA, 0x8A, 0xD0, 0x32, 0xC0 # 3F26
    mov    ds:FILENAME_DOT_SEEN,al                           # 3F2C: A2 FF 06
    call   L_3E0D                                # 3F2F: E8 DB FE
    lahf                                         # 3F32: 9F
    xchg   ah,al                                 # 3F33: 86 C4
    push   ax                                    # 3F35: 50
    xchg   ah,al                                 # 3F36: 86 C4
    mov    cx,FILENAME_83_BUFFER                              # 3F38: B9 F0 04
    mov    dh,0xb                                # 3F3B: B6 0B
    inc    dl                                    # 3F3D: FE C2
L_3F3F:
    dec    dl                                    # 3F3F: FE CA
    je     L_3F90                                # 3F41: 74 4D
    mov    al,BYTE PTR [bx]                      # 3F43: 8A 07
    cmp    al,0x20                               # 3F45: 3C 20
    jb     L_3F6F                                # 3F47: 72 26
    cmp    al,0x2e                               # 3F49: 3C 2E
    je     L_3F75                                # 3F4B: 74 28
    .byte 0x8B, 0xF9 # 3F4D
    stos   BYTE PTR es:[di],al                   # 3F4F: AA
    inc    cx                                    # 3F50: 41
    inc    bx                                    # 3F51: 43
    dec    dh                                    # 3F52: FE CE
    jne    L_3F3F                                # 3F54: 75 E9
L_3F56:
    pop    ax                                    # 3F56: 58
    xchg   ah,al                                 # 3F57: 86 C4
    sahf                                         # 3F59: 9E
    lahf                                         # 3F5A: 9F
    xchg   ah,al                                 # 3F5B: 86 C4
    push   ax                                    # 3F5D: 50
    xchg   ah,al                                 # 3F5E: 86 C4
    .byte 0x8A, 0xF0 # 3F60
    mov    al,ds:FILENAME_83_BUFFER                           # 3F62: A0 F0 04
    inc    al                                    # 3F65: FE C0
    je     L_3F6F                                # 3F67: 74 06
    pop    ax                                    # 3F69: 58
    xchg   ah,al                                 # 3F6A: 86 C4
    sahf                                         # 3F6C: 9E
    pop    bx                                    # 3F6D: 5B
    ret                                          # 3F6E: C3
L_3F6F:
    jmp    L_079A                                # 3F6F: E9 28 C8
L_3F72:
    inc    bx                                    # 3F72: 43
    jmp    L_3F3F                                # 3F73: EB CA
L_3F75:
    mov    al,0x1                                # 3F75: B0 01
    mov    ds:FILENAME_DOT_SEEN,al                           # 3F77: A2 FF 06
L_3F7A:
    .byte 0x8A, 0xC6 # 3F7A
    cmp    al,0xb                                # 3F7C: 3C 0B
    je     L_3F6F                                # 3F7E: 74 EF
    cmp    al,0x3                                # 3F80: 3C 03
    jb     L_3F6F                                # 3F82: 72 EB
    je     L_3F72                                # 3F84: 74 EC
    mov    al,0x20                               # 3F86: B0 20
    .byte 0x8B, 0xF9 # 3F88
    stos   BYTE PTR es:[di],al                   # 3F8A: AA
    inc    cx                                    # 3F8B: 41
    dec    dh                                    # 3F8C: FE CE
    jmp    L_3F7A                                # 3F8E: EB EA
L_3F90:
    mov    al,0x20                               # 3F90: B0 20
    .byte 0x8B, 0xF9 # 3F92
    stos   BYTE PTR es:[di],al                   # 3F94: AA
    inc    cx                                    # 3F95: 41
    dec    dh                                    # 3F96: FE CE
    jne    L_3F90                                # 3F98: 75 F6
    jmp    L_3F56                                # 3F9A: EB BA
L_3F9C:
    mov    al,BYTE PTR [bx]                      # 3F9C: 8A 07
    inc    bx                                    # 3F9E: 43
    dec    dl                                    # 3F9F: FE CA
L_3FA1:
    ret                                          # 3FA1: C3
GET_FILE_BLOCK_FROM_FAC:
    call   CONINT                                # 3FA2: E8 7A DF
GET_FILE_BLOCK:
    .byte 0x8A, 0xD8 # 3FA5
    mov    al,ds:MAX_FILE_NUMBER                           # 3FA7: A0 DF 04
    .byte 0x3A, 0xC3 # 3FAA
    jae    L_3FB1                                # 3FAC: 73 03
    jmp    L_079A                                # 3FAE: E9 E9 C7
L_3FB1:
    mov    bh,0x0                                # 3FB1: B7 00
    .byte 0x03, 0xDB # 3FB3
    xchg   dx,bx                                 # 3FB5: 87 DA
    mov    bx,WORD PTR ds:FILE_PTR_TABLE                  # 3FB7: 8B 1E E0 04
    .byte 0x03, 0xDA # 3FBB
    mov    bx,WORD PTR [bx]                      # 3FBD: 8B 1F
    mov    al,ds:NLONLY                           # 3FBF: A0 36 05
    inc    al                                    # 3FC2: FE C0
    je     L_3FA1                                # 3FC4: 74 DB
    mov    al,BYTE PTR [bx]                      # 3FC6: 8A 07
    .byte 0x0A, 0xC0 # 3FC8
    je     L_3FA1                                # 3FCA: 74 D5
    push   bx                                    # 3FCC: 53
    mov    dx,0x2e                               # 3FCD: BA 2E 00
    .byte 0x03, 0xDA # 3FD0
    mov    al,BYTE PTR [bx]                      # 3FD2: 8A 07
    cmp    al,0x9                                # 3FD4: 3C 09
    jae    L_3FDD                                # 3FD6: 73 05
    int    0xdc                                  # 3FD8: CD DC
    jmp    L_079D                                # 3FDA: E9 C0 C7
L_3FDD:
    pop    bx                                    # 3FDD: 5B
    mov    al,BYTE PTR [bx]                      # 3FDE: 8A 07
    .byte 0x0A, 0xC0 # 3FE0
    stc                                          # 3FE2: F9
    ret                                          # 3FE3: C3
    .byte 0x4B, 0xE8, 0x35, 0xCF, 0x3C, 0x23, 0x75, 0x03, 0xE8, 0x2E, 0xCF, 0xE8 # 3FE4
    .byte 0x2A, 0xDF, 0x5E, 0x87, 0xDE, 0x56, 0x53 # 3FF0
L_3FF7:
    call   GET_FILE_BLOCK                                # 3FF7: E8 AB FF
    jne    L_3FFF                                # 3FFA: 75 03
    jmp    L_079A                                # 3FFC: E9 9B C7
L_3FFF:
    mov    WORD PTR ds:PTRFIL,bx                  # 3FFF: 89 1E E9 04
    ret                                          # 4003: C3
OPEN:
    mov    cx,0x1498                             # 4004: B9 98 14
    push   cx                                    # 4007: 51
    call   FRMEVL                                # 4008: E8 1C D7
    mov    al,BYTE PTR [bx]                      # 400B: 8A 07
    cmp    al,0x2c                               # 400D: 3C 2C
    jne    L_406A                                # 400F: 75 59
    push   bx                                    # 4011: 53
    call   L_28A6                                # 4012: E8 91 E8
    mov    al,BYTE PTR [bx]                      # 4015: 8A 07
    .byte 0x0A, 0xC0 # 4017
    jne    L_401E                                # 4019: 75 03
    jmp    L_079A                                # 401B: E9 7C C7
L_401E:
    inc    bx                                    # 401E: 43
    mov    bx,WORD PTR [bx]                      # 401F: 8B 1F
    mov    al,BYTE PTR [bx]                      # 4021: 8A 07
    and    al,0xdf                               # 4023: 24 DF
    mov    dl,0x1                                # 4025: B2 01
    cmp    al,0x49                               # 4027: 3C 49
    je     L_4040                                # 4029: 74 15
    mov    dl,0x2                                # 402B: B2 02
    cmp    al,0x4f                               # 402D: 3C 4F
    je     L_4040                                # 402F: 74 0F
    mov    dl,0x4                                # 4031: B2 04
    cmp    al,0x52                               # 4033: 3C 52
    je     L_4040                                # 4035: 74 09
    mov    dl,0x8                                # 4037: B2 08
    cmp    al,0x41                               # 4039: 3C 41
    je     L_4040                                # 403B: 74 03
    jmp    L_0794                                # 403D: E9 54 C7
L_4040:
    pop    bx                                    # 4040: 5B
    push   dx                                    # 4041: 52
    call   SYNCHR                                # 4042: E8 AF ED
    .byte ','                                  # 4045: 2C -- SYNCHR inline operand
    .byte 0x3C # 4046 -- decoded continuation: cmp    al,0x23
    and    si,WORD PTR [di+0x3]                  # 4047: 23 75 03
    call   CHRGTR                                # 404A: E8 D0 CE
    call   GETBYT                                # 404D: E8 CC DE
    call   SYNCHR                                # 4050: E8 A1 ED
    .byte ','                                  # 4053: 2C -- SYNCHR inline operand
    .byte 0x8A # 4054 -- decoded continuation: mov    al,dl
    ret    0xc00a                                # 4055: C2 0A C0
    .byte 0x75, 0x03, 0xE9, 0x3D, 0xC7, 0x50, 0xE8, 0xB2, 0xFE, 0x58, 0x59, 0x8A # 4058
    .byte 0xD1, 0xCD, 0xDD, 0xE9, 0x83, 0x00 # 4064
L_406A:
    call   L_3F16                                # 406A: E8 A9 FE
    mov    al,BYTE PTR [bx]                      # 406D: 8A 07
    cmp    al,0x82                               # 406F: 3C 82
    mov    dl,0x4                                # 4071: B2 04
    jne    L_40CE                                # 4073: 75 59
    call   CHRGTR                                # 4075: E8 A5 CE
    cmp    al,0x85                               # 4078: 3C 85
    mov    dl,0x1                                # 407A: B2 01
    je     L_40CB                                # 407C: 74 4D
    cmp    al,0x4f                               # 407E: 3C 4F
    je     L_40A2                                # 4080: 74 20
    cmp    al,0x49                               # 4082: 3C 49
    je     L_40BD                                # 4084: 74 37
    call   SYNCHR                                # 4086: E8 6B ED
    .byte 'A'                                  # 4089: 41 -- SYNCHR inline operand
    call   SYNCHR                                # 408A: E8 67 ED
    .byte 'P'                                  # 408D: 50 -- SYNCHR inline operand
    call   SYNCHR                                # 408E: E8 63 ED
    .byte 'P'                                  # 4091: 50 -- SYNCHR inline operand
    call   SYNCHR                                # 4092: E8 5F ED
    .byte 'E'                                  # 4095: 45 -- SYNCHR inline operand
    call   SYNCHR                                # 4096: E8 5B ED
    .byte 'N'                                  # 4099: 4E -- SYNCHR inline operand
    call   SYNCHR                                # 409A: E8 57 ED
    .byte 'D'                                  # 409D: 44 -- SYNCHR inline operand
    mov    dl,0x8                                # 409E: B2 08
    jmp    L_40CE                                # 40A0: EB 2C
L_40A2:
    call   CHRGTR                                # 40A2: E8 78 CE
    call   SYNCHR                                # 40A5: E8 4C ED
    .byte 'U'                                  # 40A8: 55 -- SYNCHR inline operand
    call   SYNCHR                                # 40A9: E8 48 ED
    .byte 'T'                                  # 40AC: 54 -- SYNCHR inline operand
    call   SYNCHR                                # 40AD: E8 44 ED
    .byte 'P'                                  # 40B0: 50 -- SYNCHR inline operand
    call   SYNCHR                                # 40B1: E8 40 ED
    .byte 'U'                                  # 40B4: 55 -- SYNCHR inline operand
    call   SYNCHR                                # 40B5: E8 3C ED
    .byte 'T'                                  # 40B8: 54 -- SYNCHR inline operand
    mov    dl,0x2                                # 40B9: B2 02
    jmp    L_40CE                                # 40BB: EB 11
L_40BD:
    call   CHRGTR                                # 40BD: E8 5D CE
    call   SYNCHR                                # 40C0: E8 31 ED
    .byte 'B'                                  # 40C3: 42 -- SYNCHR inline operand
    call   SYNCHR                                # 40C4: E8 2D ED
    .byte 'M'                                  # 40C7: 4D -- SYNCHR inline operand
    mov    dl,0x20                               # 40C8: B2 20
    dec    bx                                    # 40CA: 4B
L_40CB:
    call   CHRGTR                                # 40CB: E8 4F CE
L_40CE:
    call   SYNCHR                                # 40CE: E8 23 ED
    .byte 'A'                                  # 40D1: 41 -- SYNCHR inline operand
    call   SYNCHR                                # 40D2: E8 1F ED
    .byte 'S'                                  # 40D5: 53 -- SYNCHR inline operand
    push   dx                                    # 40D6: 52
    mov    al,BYTE PTR [bx]                      # 40D7: 8A 07
    cmp    al,0x23                               # 40D9: 3C 23
    jne    L_40E0                                # 40DB: 75 03
    call   CHRGTR                                # 40DD: E8 3D CE
L_40E0:
    call   GETBYT                                # 40E0: E8 39 DE
    .byte 0x0A, 0xC0 # 40E3
    jne    L_40EA                                # 40E5: 75 03
    jmp    L_079A                                # 40E7: E9 B0 C6
L_40EA:
    int    0xde                                  # 40EA: CD DE
    .byte 0xB4 # 40EC
L_40ED:
    .byte 0x52 # 40ED
    dec    bx                                    # 40EE: 4B
    .byte 0x8A, 0xD0 # 40EF
    call   CHRGTR                                # 40F1: E8 29 CE
    je     L_40F9                                # 40F4: 74 03
    jmp    SNERR                                 # 40F6: E9 C5 C6
L_40F9:
    pop    si                                    # 40F9: 5E
    xchg   si,bx                                 # 40FA: 87 DE
    push   si                                    # 40FC: 56
    .byte 0x8A, 0xC2 # 40FD
    lahf                                         # 40FF: 9F
    xchg   ah,al                                 # 4100: 86 C4
    push   ax                                    # 4102: 50
    xchg   ah,al                                 # 4103: 86 C4
    push   bx                                    # 4105: 53
    call   GET_FILE_BLOCK                                # 4106: E8 9C FE
    je     L_410E                                # 4109: 74 03
    jmp    L_07A3                                # 410B: E9 95 C6
L_410E:
    pop    dx                                    # 410E: 5A
    .byte 0x8A, 0xC6 # 410F
    cmp    al,0x9                                # 4111: 3C 09
    int    0xdf                                  # 4113: CD DF
    jae    L_411A                                # 4115: 73 03
    jmp    L_079D                                # 4117: E9 83 C6
L_411A:
    push   bx                                    # 411A: 53
    mov    cx,0x2e                               # 411B: B9 2E 00
    .byte 0x03, 0xD9 # 411E
    mov    BYTE PTR [bx],dh                      # 4120: 88 37
    mov    al,0x0                                # 4122: B0 00
    pop    bx                                    # 4124: 5B
    jmp    L_3EB9                                # 4125: E9 91 FD
L_4128:
    push   bx                                    # 4128: 53
    .byte 0x0A, 0xC0 # 4129
    jne    L_4137                                # 412B: 75 0A
    mov    al,ds:NLONLY                           # 412D: A0 36 05
    and    al,0x1                                # 4130: 24 01
    je     L_4137                                # 4132: 74 03
    jmp    L_447D                                # 4134: E9 46 03
L_4137:
    call   GET_FILE_BLOCK                                # 4137: E8 6B FE
    je     L_4151                                # 413A: 74 15
    mov    WORD PTR ds:PTRFIL,bx                  # 413C: 89 1E E9 04
    push   bx                                    # 4140: 53
    mov    al,0x2                                # 4141: B0 02
    jae    L_4148                                # 4143: 73 03
    jmp    L_3EB9                                # 4145: E9 71 FD
L_4148:
    int    0xe0                                  # 4148: CD E0
    jmp    L_079D                                # 414A: E9 50 C6
    .byte 0xE8, 0x24, 0x03, 0x5B # 414D
L_4151:
    push   bx                                    # 4151: 53
    mov    dx,0x31                               # 4152: BA 31 00
    .byte 0x03, 0xDA # 4155
    mov    BYTE PTR [bx],al                      # 4157: 88 07
    .byte 0x8A, 0xF8, 0x8A, 0xD8 # 4159
    mov    WORD PTR ds:PTRFIL,bx                  # 415D: 89 1E E9 04
    pop    bx                                    # 4161: 5B
    add    al,BYTE PTR [bx]                      # 4162: 02 07
    mov    BYTE PTR [bx],0x0                     # 4164: C6 07 00
    pop    bx                                    # 4167: 5B
    ret                                          # 4168: C3
L_4169:
    stc                                          # 4169: F9
    jmp    L_416F                                # 416A: EB 03
LOAD:
    .byte 0x0D # 416C
MERGE:
    .byte 0x32, 0xC0 # 416D
L_416F:
    lahf                                         # 416F: 9F
    push   ax                                    # 4170: 50
    call   L_3F13                                # 4171: E8 9F FD
    int    0xe9                                  # 4174: CD E9
    pop    ax                                    # 4176: 58
    sahf                                         # 4177: 9E
    lahf                                         # 4178: 9F
    push   ax                                    # 4179: 50
    je     L_4190                                # 417A: 74 14
    mov    al,BYTE PTR [bx]                      # 417C: 8A 07
    sub    al,0x2c                               # 417E: 2C 2C
    .byte 0x0A, 0xC0 # 4180
    jne    L_4190                                # 4182: 75 0C
    call   CHRGTR                                # 4184: E8 96 CD
    call   SYNCHR                                # 4187: E8 6A EC
    .byte 'R'                                  # 418A: 52 -- SYNCHR inline operand
    pop    ax                                    # 418B: 58
    sahf                                         # 418C: 9E
    stc                                          # 418D: F9
    lahf                                         # 418E: 9F
    push   ax                                    # 418F: 50
L_4190:
    lahf                                         # 4190: 9F
    push   ax                                    # 4191: 50
    .byte 0x32, 0xC0 # 4192
    mov    dl,0x1                                # 4194: B2 01
    call   L_40ED                                # 4196: E8 54 FF
    mov    bx,WORD PTR ds:PTRFIL                  # 4199: 8B 1E E9 04
    mov    cx,0x31                               # 419D: B9 31 00
    .byte 0x03, 0xD9 # 41A0
    pop    ax                                    # 41A2: 58
    sahf                                         # 41A3: 9E
    .byte 0x1A, 0xC0 # 41A4
    and    al,0x80                               # 41A6: 24 80
    or     al,0x1                                # 41A8: 0C 01
    mov    ds:NLONLY,al                           # 41AA: A2 36 05
    pop    ax                                    # 41AD: 58
    sahf                                         # 41AE: 9E
    lahf                                         # 41AF: 9F
    push   ax                                    # 41B0: 50
    .byte 0x1A, 0xC0 # 41B1
    mov    ds:RUNFLG,al                           # 41B3: A2 EF 04
    mov    al,BYTE PTR [bx]                      # 41B6: 8A 07
    .byte 0x0A, 0xC0 # 41B8
    jns    L_41BF                                # 41BA: 79 03
    jmp    L_4297                                # 41BC: E9 D8 00
L_41BF:
    pop    ax                                    # 41BF: 58
    sahf                                         # 41C0: 9E
    je     L_41C6                                # 41C1: 74 03
    call   L_2D1D                                # 41C3: E8 57 EB
L_41C6:
    .byte 0x32, 0xC0 # 41C6
    call   L_3FF7                                # 41C8: E8 2C FE
    jmp    MAIN                                # 41CB: E9 05 C7
SAVE:
    call   L_3F13                                # 41CE: E8 42 FD
    int    0xea                                  # 41D1: CD EA
    dec    bx                                    # 41D3: 4B
    call   CHRGTR                                # 41D4: E8 46 CD
    mov    dl,0x80                               # 41D7: B2 80
    stc                                          # 41D9: F9
    jne    L_41DF                                # 41DA: 75 03
    call   PROCHK                                # 41DC: E8 79 05
L_41DF:
    je     L_41F9                                # 41DF: 74 18
    call   SYNCHR                                # 41E1: E8 10 EC
    .byte ','                                  # 41E4: 2C -- SYNCHR inline operand
    .byte 0x3C # 41E5 -- decoded continuation: cmp    al,0x50
    push   ax                                    # 41E6: 50
    mov    dl,0x92                               # 41E7: B2 92
    jne    L_41F1                                # 41E9: 75 06
    call   CHRGTR                                # 41EB: E8 2F CD
    stc                                          # 41EE: F9
    jmp    L_41F9                                # 41EF: EB 08
L_41F1:
    call   SYNCHR                                # 41F1: E8 00 EC
    .byte 'A'                                  # 41F4: 41 -- SYNCHR inline operand
    .byte 0x0A, 0xC0 # 41F5
    mov    dl,0x2                                # 41F7: B2 02
L_41F9:
    lahf                                         # 41F9: 9F
    push   ax                                    # 41FA: 50
    .byte 0x8A, 0xC2 # 41FB
    and    al,0x10                               # 41FD: 24 10
    mov    ds:SAVE_PROTECT_FLAG,al                           # 41FF: A2 62 04
    pop    ax                                    # 4202: 58
    sahf                                         # 4203: 9E
    lahf                                         # 4204: 9F
    push   ax                                    # 4205: 50
    inc    al                                    # 4206: FE C0
    mov    ds:BASIC_PROGRAM_FILE_FLAG,al                            # 4208: A2 5F 00
    .byte 0x32, 0xC0 # 420B
    call   L_40ED                                # 420D: E8 DD FE
    pop    ax                                    # 4210: 58
    sahf                                         # 4211: 9E
    push   bx                                    # 4212: 53
    mov    bx,WORD PTR ds:PTRFIL                  # 4213: 8B 1E E9 04
    mov    al,BYTE PTR [bx]                      # 4217: 8A 07
    pop    bx                                    # 4219: 5B
    and    al,0x80                               # 421A: 24 80
    jne    L_4221                                # 421C: 75 03
    jmp    LIST                                  # 421E: E9 14 DD
L_4221:
    push   bx                                    # 4221: 53
    call   L_2388                                # 4222: E8 63 E1
    mov    al,ds:SAVE_PROTECT_FLAG                           # 4225: A0 62 04
    .byte 0x0A, 0xC0 # 4228
    je     L_422F                                # 422A: 74 03
    call   L_46A8                                # 422C: E8 79 04
L_422F:
    mov    bx,WORD PTR ds:VARTAB                  # 422F: 8B 1E 58 03
    mov    WORD PTR ds:SAVE_END_ADDR,bx                  # 4233: 89 1E 04 07
    mov    bx,WORD PTR ds:TXTTAB                   # 4237: 8B 1E 30 00
    push   bx                                    # 423B: 53
    mov    bx,WORD PTR ds:PTRFIL                  # 423C: 8B 1E E9 04
    call   L_4309                                # 4240: E8 C6 00
    .byte 0x0A, 0xC0 # 4243
    jns    L_424A                                # 4245: 79 03
    .byte 0xE9, 0x16, 0x00 # 4247
L_424A:
    jmp    L_079A                                # 424A: E9 4D C5
L_424D:
    mov    al,ds:SAVE_PROTECT_FLAG                           # 424D: A0 62 04
    .byte 0x0A, 0xC0 # 4250
    je     L_4257                                # 4252: 74 03
    call   L_46F9                                # 4254: E8 A2 04
L_4257:
    pop    bx                                    # 4257: 5B
    .byte 0x32, 0xC0 # 4258
    mov    ds:SAVE_PROTECT_FLAG,al                           # 425A: A2 62 04
    jmp    L_4128                                # 425D: E9 C8 FE
L_4260:
    pop    bx                                    # 4260: 5B
    call   L_4266                                # 4261: E8 02 00
    jmp    L_424D                                # 4264: EB E7
L_4266:
    call   L_4309                                # 4266: E8 A0 00
    cmp    al,0xfc                               # 4269: 3C FC
    jne    L_4270                                # 426B: 75 03
    jmp    L_5C7D                                # 426D: E9 0D 1A
L_4270:
    int    0xeb                                  # 4270: CD EB
    jmp    L_0794                                # 4272: E9 1F C5
L_4275:
    mov    bx,WORD PTR ds:TXTTAB                   # 4275: 8B 1E 30 00
    .byte 0x0A, 0xC0 # 4279
    call   L_4281                                # 427B: E8 03 00
    .byte 0xE9, 0x46, 0x00 # 427E
L_4281:
    lahf                                         # 4281: 9F
    push   ax                                    # 4282: 50
    call   L_4309                                # 4283: E8 83 00
    cmp    al,0xfc                               # 4286: 3C FC
    jne    L_428D                                # 4288: 75 03
    jmp    L_5CC3                                # 428A: E9 36 1A
L_428D:
    pop    ax                                    # 428D: 58
    sahf                                         # 428E: 9E
    int    0xec                                  # 428F: CD EC
    jmp    L_0794                                # 4291: E9 00 C5
L_4294:
    pop    ax                                    # 4294: 58
    sahf                                         # 4295: 9E
L_4296:
    ret                                          # 4296: C3
L_4297:
    and    al,0x20                               # 4297: 24 20
    mov    ds:LOAD_PROTECT_FLAG,al                           # 4299: A2 63 04
    pop    ax                                    # 429C: 58
    sahf                                         # 429D: 9E
    jne    L_42A3                                # 429E: 75 03
    jmp    L_0794                                # 42A0: E9 F1 C4
L_42A3:
    call   L_2D1D                                # 42A3: E8 77 EA
    mov    al,ds:LOAD_PROTECT_FLAG                           # 42A6: A0 63 04
    mov    ds:PROFLG,al                           # 42A9: A2 64 04
    call   L_435A                                # 42AC: E8 AB 00
    .byte 0x32, 0xC0 # 42AF
    call   GET_FILE_BLOCK                                # 42B1: E8 F1 FC
    mov    BYTE PTR [bx],0x80                    # 42B4: C6 07 80
    mov    WORD PTR ds:PTRFIL,bx                  # 42B7: 89 1E E9 04
    call   L_4309                                # 42BB: E8 4B 00
    .byte 0x0A, 0xC0 # 42BE
    js     L_4275                                # 42C0: 78 B3
    int    0xed                                  # 42C2: CD ED
    jmp    L_079A                                # 42C4: E9 D3 C4
L_42C7:
    mov    al,ds:PROFLG                           # 42C7: A0 64 04
    .byte 0x0A, 0xC0 # 42CA
    je     L_42D1                                # 42CC: 74 03
    call   L_46F9                                # 42CE: E8 28 04
L_42D1:
    call   LINKER                                # 42D1: E8 27 C7
    inc    bx                                    # 42D4: 43
    inc    bx                                    # 42D5: 43
    mov    WORD PTR ds:VARTAB,bx                  # 42D6: 89 1E 58 03
    call   RUNC                                # 42DA: E8 5A EA
    .byte 0x32, 0xC0 # 42DD
    mov    ds:NLONLY,al                           # 42DF: A2 36 05
    call   L_4128                                # 42E2: E8 43 FE
    mov    al,ds:RUNFLG                           # 42E5: A0 EF 04
    .byte 0x0A, 0xC0 # 42E8
    je     L_42EF                                # 42EA: 74 03
    jmp    L_0EE8                                # 42EC: E9 F9 CB
L_42EF:
    jmp    READY                                # 42EF: E9 C4 C5
L_42F2:
    xchg   dx,bx                                 # 42F2: 87 DA
    mov    bx,WORD PTR ds:FRETOP                  # 42F4: 8B 1E 2F 03
    xchg   dx,bx                                 # 42F8: 87 DA
    .byte 0x3B, 0xDA # 42FA
    jb     L_4296                                # 42FC: 72 98
    call   L_2D1D                                # 42FE: E8 1C EA
    .byte 0x32, 0xC0 # 4301
    mov    ds:NLONLY,al                           # 4303: A2 36 05
    jmp    L_2CF4                                # 4306: E9 EB E9
L_4309:
    push   bx                                    # 4309: 53
    push   dx                                    # 430A: 52
    mov    bx,WORD PTR ds:PTRFIL                  # 430B: 8B 1E E9 04
    mov    dx,0x2e                               # 430F: BA 2E 00
    .byte 0x03, 0xDA # 4312
    mov    al,BYTE PTR [bx]                      # 4314: 8A 07
    pop    dx                                    # 4316: 5A
    pop    bx                                    # 4317: 5B
    ret                                          # 4318: C3
L_4319:
    jne    L_4339                                # 4319: 75 1E
    push   bx                                    # 431B: 53
    push   cx                                    # 431C: 51
    push   ax                                    # 431D: 50
    mov    dx,0x4326                             # 431E: BA 26 43
    push   dx                                    # 4321: 52
    push   cx                                    # 4322: 51
    .byte 0x0A, 0xC0 # 4323
    ret                                          # 4325: C3
    .byte 0x58, 0x59, 0xFE, 0xC8, 0x79, 0xF0, 0x5B # 4326
L_432D:
    ret                                          # 432D: C3
    .byte 0x59, 0x5B, 0x8A, 0x07, 0x3C, 0x2C, 0x75, 0xF7, 0xE8, 0xE4, 0xCB # 432E
L_4339:
    push   cx                                    # 4339: 51
    mov    al,BYTE PTR [bx]                      # 433A: 8A 07
    cmp    al,0x23                               # 433C: 3C 23
    jne    L_4343                                # 433E: 75 03
    call   CHRGTR                                # 4340: E8 DA CB
L_4343:
    call   GETBYT                                # 4343: E8 D6 DB
    pop    si                                    # 4346: 5E
    xchg   si,bx                                 # 4347: 87 DE
    push   si                                    # 4349: 56
    push   bx                                    # 434A: 53
    mov    dx,0x432e                             # 434B: BA 2E 43
    push   dx                                    # 434E: 52
    stc                                          # 434F: F9
    jmp    bx                                    # 4350: FF E3
CLOSE:
    mov    cx,0x4128                             # 4352: B9 28 41
    mov    al,ds:MAX_FILE_NUMBER                           # 4355: A0 DF 04
    jmp    L_4319                                # 4358: EB BF
L_435A:
    mov    al,ds:NLONLY                           # 435A: A0 36 05
    .byte 0x0A, 0xC0 # 435D
    js     L_432D                                # 435F: 78 CC
    mov    cx,0x4128                             # 4361: B9 28 41
    .byte 0x32, 0xC0 # 4364
    mov    al,ds:MAX_FILE_NUMBER                           # 4366: A0 DF 04
    jmp    L_4319                                # 4369: EB AE
L_436B:
    .byte 0x32, 0xC0, 0x8A, 0xE8 # 436B
L_436F:
    .byte 0x8A, 0xC5 # 436F
    call   GET_FILE_BLOCK                                # 4371: E8 31 FC
    mov    BYTE PTR [bx],0x0                     # 4374: C6 07 00
    mov    al,ds:MAX_FILE_NUMBER                           # 4377: A0 DF 04
    inc    ch                                    # 437A: FE C5
    .byte 0x2A, 0xC5 # 437C
    jae    L_436F                                # 437E: 73 EF
    .byte 0x32, 0xC0 # 4380
    mov    ds:NLONLY,al                           # 4382: A2 36 05
    call   L_2D1D                                # 4385: E8 95 E9
    mov    bx,WORD PTR ds:TXTTAB                   # 4388: 8B 1E 30 00
    dec    bx                                    # 438C: 4B
    mov    BYTE PTR [bx],0x0                     # 438D: C6 07 00
    jmp    L_076E                                # 4390: E9 DB C3
L_4393:
    pop    bx                                    # 4393: 5B
    pop    ax                                    # 4394: 58
    xchg   ah,al                                 # 4395: 86 C4
    sahf                                         # 4397: 9E
    push   bx                                    # 4398: 53
    push   dx                                    # 4399: 52
    push   cx                                    # 439A: 51
    lahf                                         # 439B: 9F
    xchg   ah,al                                 # 439C: 86 C4
    push   ax                                    # 439E: 50
    xchg   ah,al                                 # 439F: 86 C4
    mov    bx,WORD PTR ds:PTRFIL                  # 43A1: 8B 1E E9 04
    mov    al,0x6                                # 43A5: B0 06
    call   L_43AF                                # 43A7: E8 05 00
    int    0xe3                                  # 43AA: CD E3
    jmp    L_079A                                # 43AC: E9 EB C3
L_43AF:
    lahf                                         # 43AF: 9F
    xchg   ah,al                                 # 43B0: 86 C4
    push   ax                                    # 43B2: 50
    xchg   ah,al                                 # 43B3: 86 C4
    push   dx                                    # 43B5: 52
    xchg   dx,bx                                 # 43B6: 87 DA
    mov    bx,0x2e                               # 43B8: BB 2E 00
    .byte 0x03, 0xDA # 43BB
    mov    al,BYTE PTR [bx]                      # 43BD: 8A 07
    xchg   dx,bx                                 # 43BF: 87 DA
    pop    dx                                    # 43C1: 5A
    cmp    al,0x9                                # 43C2: 3C 09
    jae    L_43C9                                # 43C4: 73 03
    jmp    L_4493                                # 43C6: E9 CA 00
L_43C9:
    pop    ax                                    # 43C9: 58
    xchg   ah,al                                 # 43CA: 86 C4
    sahf                                         # 43CC: 9E
    pop    si                                    # 43CD: 5E
    xchg   si,bx                                 # 43CE: 87 DE
    push   si                                    # 43D0: 56
    pop    bx                                    # 43D1: 5B
    jmp    L_3EB9                                # 43D2: E9 E4 FA
L_43D5:
    push   cx                                    # 43D5: 51
    push   bx                                    # 43D6: 53
    push   dx                                    # 43D7: 52
    mov    bx,WORD PTR ds:PTRFIL                  # 43D8: 8B 1E E9 04
    mov    al,0x8                                # 43DC: B0 08
    call   L_43AF                                # 43DE: E8 CE FF
    int    0xe4                                  # 43E1: CD E4
    jmp    L_079A                                # 43E3: E9 B4 C3
    .byte 0x5A, 0x5B, 0x59, 0xC3 # 43E6
L_43EA:
    call   CHRGTR                                # 43EA: E8 30 CB
    call   SYNCHR                                # 43ED: E8 04 EA
    .byte '$'                                  # 43F0: 24 -- SYNCHR inline operand
    .byte 0xE8 # 43F1 -- decoded continuation: call   0x2df4
    add    dl,ch                                 # 43F2: 00 EA
    .byte '('                                  # 43F4: 28 -- SYNCHR inline operand
    .byte 0x53, 0x8B # 43F5 -- decoded continuation: push   bx ; mov    bx,WORD PTR ds:PTRFIL
    push   ds                                    # 43F7: 1E
    jmp    0x96ff                                # 43F8: E9 04 53
    .byte 0xBB, 0x00, 0x00, 0x89, 0x1E, 0xE9, 0x04, 0x5B, 0x5E, 0x87, 0xDE, 0x56 # 43FB
    .byte 0xE8, 0x12, 0xDB, 0x52, 0x8A, 0x07, 0x3C, 0x2C, 0x75, 0x0B, 0xE8, 0x09 # 4407
    .byte 0xCB, 0xE8, 0xCD, 0xFB, 0x5B, 0x32, 0xC0, 0x8A, 0x07, 0x9F, 0x50 # 4413..441D
    call   SYNCHR                                # 441E: E8 D3 E9
    .byte ')'                                    # 4421: SYNCHR inline operand
    .byte 0x58, 0x9E, 0x5E, 0x87, 0xDE, 0x56, 0x9F, 0x50, 0x8A # 4422 -- pop    ax ; sahf ; pop    si ; xchg   si,bx ; push   si ; lahf ; push   ax ; mov    al,bl
    .byte 0xC3, 0x0A, 0xC0, 0x75, 0x03, 0xE9, 0x26, 0xCC, 0x53, 0xE8, 0x07, 0xE2 # 442B
    .byte 0x87, 0xDA, 0x59, 0x58, 0x9E, 0x9F, 0x50, 0x74, 0x28, 0xE8, 0x16, 0xE8 # 4437
    .byte 0x3C, 0x03, 0x74, 0x13, 0x88, 0x07, 0x43, 0xFE, 0xC9, 0x75, 0xEC, 0x58 # 4443
    .byte 0x9E, 0x59, 0x5B, 0x89, 0x1E, 0xE9, 0x04, 0x51, 0xE9, 0x33, 0xE2, 0x58 # 444F
    .byte 0x9E, 0x8B, 0x1E, 0x2E, 0x00, 0x89, 0x1E, 0x47, 0x03, 0x5B, 0xE9, 0x06 # 445B
    .byte 0xC3, 0xE8, 0x6A, 0xFF, 0x73, 0x03, 0xE9, 0x30, 0xC3, 0xEB, 0xD5, 0xCD # 4467
    .byte 0xE5, 0xE8, 0x12, 0x00, 0x53, 0xB5, 0x01, 0xE8, 0x02, 0x00 # 4473
L_447D:
    pop    bx                                    # 447D: 5B
    ret                                          # 447E: C3
    .byte 0x32, 0xC0, 0x88, 0x07, 0x43, 0xFE, 0xCD, 0x75, 0xF9, 0xC3, 0x8B, 0x1E # 447F
    .byte 0xE9, 0x04, 0xBA, 0x33, 0x00, 0x03, 0xDA, 0xC3 # 448B
L_4493:
    pop    ax                                    # 4493: 58
    xchg   ah,al                                 # 4494: 86 C4
    sahf                                         # 4496: 9E
L_4497:
    ret                                          # 4497: C3
LOC:
    call   GET_FILE_BLOCK_FROM_FAC                                # 4498: E8 07 FB
    jne    L_44A0                                # 449B: 75 03
    jmp    L_079A                                # 449D: E9 FA C2
L_44A0:
    mov    al,0xa                                # 44A0: B0 0A
    jae    L_44A7                                # 44A2: 73 03
    jmp    L_3EB9                                # 44A4: E9 12 FA
L_44A7:
    int    0xe6                                  # 44A7: CD E6
    jmp    L_079A                                # 44A9: E9 EE C2
LOF:
    call   GET_FILE_BLOCK_FROM_FAC                                # 44AC: E8 F3 FA
    jne    L_44B4                                # 44AF: 75 03
    jmp    L_079A                                # 44B1: E9 E6 C2
L_44B4:
    mov    al,0xc                                # 44B4: B0 0C
    jae    L_44BB                                # 44B6: 73 03
    jmp    L_3EB9                                # 44B8: E9 FE F9
L_44BB:
    int    0xe7                                  # 44BB: CD E7
    jmp    L_079A                                # 44BD: E9 DA C2
EOF:
    call   GET_FILE_BLOCK_FROM_FAC                                # 44C0: E8 DF FA
    jne    L_44C8                                # 44C3: 75 03
    jmp    L_079A                                # 44C5: E9 D2 C2
L_44C8:
    mov    al,0xe                                # 44C8: B0 0E
    jae    L_44CF                                # 44CA: 73 03
    jmp    L_3EB9                                # 44CC: E9 EA F9
L_44CF:
    int    0xe8                                  # 44CF: CD E8
    jmp    L_079A                                # 44D1: E9 C6 C2
L_44D4:
    call   ISFLIO                                # 44D4: E8 FF EA
    jne    L_44DC                                # 44D7: 75 03
    jmp    L_0EFB                                # 44D9: E9 1F CA
L_44DC:
    .byte 0x32, 0xC0 # 44DC
    call   L_4128                                # 44DE: E8 47 FC
    mov    dl,0x42                               # 44E1: B2 42
    jmp    L_07D8                                # 44E3: E9 F2 C2
L_44E6:
    cmp    al,0x23                               # 44E6: 3C 23
    jne    L_4497                                # 44E8: 75 AD
    call   GTBYTC                                # 44EA: E8 2C DA
    call   SYNCHR                                # 44ED: E8 04 E9
    .byte ','                                  # 44F0: 2C -- SYNCHR inline operand
    .byte 0x8A # 44F1 -- decoded continuation: mov    al,dl
    ret    0xe853                                # 44F2: C2 53 E8
    .byte 0x00, 0xFB, 0x5B, 0x8A, 0x07, 0xC3 # 44F5
PRGFIN:
    mov    cx,0x2dec                             # 44FB: B9 EC 2D
    push   cx                                    # 44FE: 51
    .byte 0x32, 0xC0 # 44FF
    jmp    L_4128                                # 4501: E9 24 FC
L_4504:
    call   GETYPR                                # 4504: E8 1E D6
    mov    cx,0x169b                             # 4507: B9 9B 16
    mov    dx,0x2c20                             # 450A: BA 20 2C
    jne    L_452A                                # 450D: 75 1B
    .byte 0x8A, 0xD6 # 450F
    jmp    L_452A                                # 4511: EB 17
L_4513:
    mov    cx,0x1498                             # 4513: B9 98 14
    push   cx                                    # 4516: 51
    call   L_44E6                                # 4517: E8 CC FF
    call   PTRGET                                # 451A: E8 51 F2
    call   L_643B                                # 451D: E8 1B 1F
    push   dx                                    # 4520: 52
    mov    cx,0x118a                             # 4521: B9 8A 11
    .byte 0x32, 0xC0, 0x8A, 0xF0, 0x8A, 0xD0 # 4524
L_452A:
    push   ax                                    # 452A: 50
    push   cx                                    # 452B: 51
    push   bx                                    # 452C: 53
L_452D:
    call   L_43D5                                # 452D: E8 A5 FE
    jae    L_4535                                # 4530: 73 03
    jmp    L_07A0                                # 4532: E9 6B C2
L_4535:
    cmp    al,0x20                               # 4535: 3C 20
    jne    L_453F                                # 4537: 75 06
    inc    dh                                    # 4539: FE C6
    dec    dh                                    # 453B: FE CE
    jne    L_452D                                # 453D: 75 EE
L_453F:
    cmp    al,0x22                               # 453F: 3C 22
    jne    L_4556                                # 4541: 75 13
    .byte 0x8A, 0xE8, 0x8A, 0xC2 # 4543
    cmp    al,0x2c                               # 4547: 3C 2C
    .byte 0x8A, 0xC5 # 4549
    jne    L_4556                                # 454B: 75 09
    .byte 0x8A, 0xF5, 0x8A, 0xD5 # 454D
    call   L_43D5                                # 4551: E8 81 FE
    jb     L_45A9                                # 4554: 72 53
L_4556:
    mov    bx,0x1f7                              # 4556: BB F7 01
    mov    ch,0xff                               # 4559: B5 FF
L_455B:
    .byte 0x8A, 0xC8, 0x8A, 0xC6 # 455B
    cmp    al,0x22                               # 455F: 3C 22
    .byte 0x8A, 0xC1 # 4561
    je     L_4593                                # 4563: 74 2E
    cmp    al,0xd                                # 4565: 3C 0D
    push   bx                                    # 4567: 53
    je     L_45C3                                # 4568: 74 59
    pop    bx                                    # 456A: 5B
    cmp    al,0xa                                # 456B: 3C 0A
    jne    L_4593                                # 456D: 75 24
    .byte 0x8A, 0xC8, 0x8A, 0xC2 # 456F
    cmp    al,0x2c                               # 4573: 3C 2C
    .byte 0x8A, 0xC1 # 4575
    je     L_457C                                # 4577: 74 03
    call   L_4605                                # 4579: E8 89 00
L_457C:
    push   bx                                    # 457C: 53
    call   L_43D5                                # 457D: E8 55 FE
    pop    bx                                    # 4580: 5B
    jb     L_45A9                                # 4581: 72 26
    cmp    al,0xd                                # 4583: 3C 0D
    jne    L_4593                                # 4585: 75 0C
    .byte 0x8A, 0xC2 # 4587
    cmp    al,0x20                               # 4589: 3C 20
    je     L_45A2                                # 458B: 74 15
    cmp    al,0x2c                               # 458D: 3C 2C
    mov    al,0xd                                # 458F: B0 0D
    je     L_45A2                                # 4591: 74 0F
L_4593:
    .byte 0x0A, 0xC0 # 4593
    je     L_45A2                                # 4595: 74 0B
    .byte 0x3A, 0xC6 # 4597
    je     L_45A9                                # 4599: 74 0E
    .byte 0x3A, 0xC2 # 459B
    je     L_45A9                                # 459D: 74 0A
    call   L_4605                                # 459F: E8 63 00
L_45A2:
    push   bx                                    # 45A2: 53
    call   L_43D5                                # 45A3: E8 2F FE
    pop    bx                                    # 45A6: 5B
    jae    L_455B                                # 45A7: 73 B2
L_45A9:
    push   bx                                    # 45A9: 53
    cmp    al,0x22                               # 45AA: 3C 22
    je     L_45B2                                # 45AC: 74 04
    cmp    al,0x20                               # 45AE: 3C 20
    jne    L_45D7                                # 45B0: 75 25
L_45B2:
    call   L_43D5                                # 45B2: E8 20 FE
    jb     L_45D7                                # 45B5: 72 20
    cmp    al,0x20                               # 45B7: 3C 20
    je     L_45B2                                # 45B9: 74 F7
    cmp    al,0x2c                               # 45BB: 3C 2C
    je     L_45D7                                # 45BD: 74 18
    cmp    al,0xd                                # 45BF: 3C 0D
    jne    L_45C7                                # 45C1: 75 04
L_45C3:
    int    0xe1                                  # 45C3: CD E1
    je     L_45D7                                # 45C5: 74 10
L_45C7:
    mov    bx,WORD PTR ds:PTRFIL                  # 45C7: 8B 1E E9 04
    .byte 0x8A, 0xC8 # 45CB
    mov    al,0x12                               # 45CD: B0 12
    call   L_43AF                                # 45CF: E8 DD FD
    int    0xe2                                  # 45D2: CD E2
    jmp    L_079A                                # 45D4: E9 C3 C1
L_45D7:
    pop    bx                                    # 45D7: 5B
L_45D8:
    mov    BYTE PTR [bx],0x0                     # 45D8: C6 07 00
    mov    bx,0x1f6                              # 45DB: BB F6 01
    .byte 0x8A, 0xC2 # 45DE
    sub    al,0x20                               # 45E0: 2C 20
    je     L_45EB                                # 45E2: 74 07
    mov    ch,0x0                                # 45E4: B5 00
    call   L_264F                                # 45E6: E8 66 E0
    pop    bx                                    # 45E9: 5B
    ret                                          # 45EA: C3
L_45EB:
    call   GETYPR                                # 45EB: E8 37 D5
    lahf                                         # 45EE: 9F
    push   ax                                    # 45EF: 50
    .byte 0xE8, 0x2A # 45F0
L_45F2:
    .byte 0xC9 # 45F2
    pop    ax                                    # 45F3: 58
    sahf                                         # 45F4: 9E
    lahf                                         # 45F5: 9F
    push   ax                                    # 45F6: 50
    jae    L_45FC                                # 45F7: 73 03
    call   L_69C0                                # 45F9: E8 C4 23
L_45FC:
    pop    ax                                    # 45FC: 58
    sahf                                         # 45FD: 9E
    jb     L_4603                                # 45FE: 72 03
    call   L_69C7                                # 4600: E8 C4 23
L_4603:
    pop    bx                                    # 4603: 5B
L_4604:
    ret                                          # 4604: C3
L_4605:
    .byte 0x0A, 0xC0 # 4605
    je     L_4604                                # 4607: 74 FB
    mov    BYTE PTR [bx],al                      # 4609: 88 07
    inc    bx                                    # 460B: 43
    dec    ch                                    # 460C: FE CD
    jne    L_4604                                # 460E: 75 F4
    pop    cx                                    # 4610: 59
    jmp    L_45D8                                # 4611: EB C5
BSAVE:
    call   L_465C                                # 4613: E8 46 00
    mov    ds:BINARY_ADDR_PARAM_SWITCH,al                            # 4616: A2 60 00
    inc    al                                    # 4619: FE C0
    je     L_4620                                # 461B: 74 03
    jmp    SNERR                                 # 461D: E9 9E C1
L_4620:
    push   bx                                    # 4620: 53
    push   cx                                    # 4621: 51
    mov    dl,0x2                                # 4622: B2 02
    call   L_40ED                                # 4624: E8 C6 FA
    pop    bx                                    # 4627: 5B
    call   L_4266                                # 4628: E8 3B FC
    .byte 0x32, 0xC0 # 462B
    mov    ds:BINARY_ADDR_PARAM_SWITCH,al                            # 462D: A2 60 00
    jmp    L_424D                                # 4630: E9 1A FC
BLOAD:
    call   L_465C                                # 4633: E8 26 00
    .byte 0x0A, 0xC0 # 4636
    je     L_4641                                # 4638: 74 07
    inc    al                                    # 463A: FE C0
    jne    L_4641                                # 463C: 75 03
    jmp    SNERR                                 # 463E: E9 7D C1
L_4641:
    dec    al                                    # 4641: FE C8
    mov    ds:BINARY_ADDR_PARAM_SWITCH,al                            # 4643: A2 60 00
    push   bx                                    # 4646: 53
    push   cx                                    # 4647: 51
    .byte 0x32, 0xC0 # 4648
    mov    dl,0x1                                # 464A: B2 01
    call   L_40ED                                # 464C: E8 9E FA
    pop    bx                                    # 464F: 5B
    call   L_4281                                # 4650: E8 2E FC
    .byte 0x32, 0xC0 # 4653
    mov    ds:BINARY_ADDR_PARAM_SWITCH,al                            # 4655: A2 60 00
    pop    bx                                    # 4658: 5B
    jmp    L_4128                                # 4659: E9 CC FA
L_465C:
    call   L_3F13                                # 465C: E8 B4 F8
    push   dx                                    # 465F: 52
    dec    bx                                    # 4660: 4B
    call   CHRGTR                                # 4661: E8 B9 C8
    pop    dx                                    # 4664: 5A
    jne    L_466A                                # 4665: 75 03
    mov    al,0x1                                # 4667: B0 01
    ret                                          # 4669: C3
L_466A:
    push   dx                                    # 466A: 52
    call   SYNCHR                                # 466B: E8 86 E7
    .byte ','                                  # 466E: 2C -- SYNCHR inline operand
    .byte 0xE8 # 466F -- decoded continuation: call   0x469d
    sub    ax,WORD PTR [bx+si]                   # 4670: 2B 00
    push   dx                                    # 4672: 52
    dec    bx                                    # 4673: 4B
    call   CHRGTR                                # 4674: E8 A6 C8
    jne    L_467E                                # 4677: 75 05
    pop    cx                                    # 4679: 59
    pop    dx                                    # 467A: 5A
    .byte 0x32, 0xC0 # 467B
    ret                                          # 467D: C3
L_467E:
    call   SYNCHR                                # 467E: E8 73 E7
    .byte ','                                  # 4681: 2C -- SYNCHR inline operand
    .byte 0xE8 # 4682 -- decoded continuation: call   0x469d
    sbb    BYTE PTR [bx+si],al                   # 4683: 18 00
    pop    cx                                    # 4685: 59
    xchg   dx,bx                                 # 4686: 87 DA
    .byte 0x03, 0xD9 # 4688
    mov    WORD PTR ds:SAVE_END_ADDR,bx                  # 468A: 89 1E 04 07
    xchg   dx,bx                                 # 468E: 87 DA
    dec    bx                                    # 4690: 4B
    call   CHRGTR                                # 4691: E8 89 C8
    je     L_4699                                # 4694: 74 03
    jmp    SNERR                                 # 4696: E9 25 C1
L_4699:
    pop    dx                                    # 4699: 5A
    mov    al,0xff                               # 469A: B0 FF
    ret                                          # 469C: C3
    .byte 0xE8, 0x87, 0xD0, 0x53, 0xE8, 0x11, 0xDC, 0x5A, 0x87, 0xDA, 0xC3 # 469D
L_46A8:
    mov    cx,0xd0b                              # 46A8: B9 0B 0D
    mov    bx,WORD PTR ds:TXTTAB                   # 46AB: 8B 1E 30 00
    xchg   dx,bx                                 # 46AF: 87 DA
L_46B1:
    mov    bx,WORD PTR ds:VARTAB                  # 46B1: 8B 1E 58 03
    .byte 0x3B, 0xDA # 46B5
    jne    L_46BA                                # 46B7: 75 01
L_46B9:
    ret                                          # 46B9: C3
L_46BA:
    mov    bx,0x6217                             # 46BA: BB 17 62
    .byte 0x8A, 0xC3, 0x02, 0xC1, 0x8A, 0xD8, 0x8A, 0xC7 # 46BD
    adc    al,0x0                                # 46C5: 14 00
    .byte 0x8A, 0xF8, 0x8B, 0xF2 # 46C7
    lods   al,BYTE PTR ds:[si]                   # 46CB: AC
    .byte 0x2A, 0xC5 # 46CC
    xor    al,BYTE PTR cs:[bx]                   # 46CE: 2E 32 07
    push   ax                                    # 46D1: 50
    mov    bx,0x6176                             # 46D2: BB 76 61
    .byte 0x8A, 0xC3, 0x02, 0xC5, 0x8A, 0xD8, 0x8A, 0xC7 # 46D5
    adc    al,0x0                                # 46DD: 14 00
    .byte 0x8A, 0xF8 # 46DF
    pop    ax                                    # 46E1: 58
    xor    al,BYTE PTR cs:[bx]                   # 46E2: 2E 32 07
    .byte 0x02, 0xC1, 0x8B, 0xFA # 46E5
    stos   BYTE PTR es:[di],al                   # 46E9: AA
    inc    dx                                    # 46EA: 42
    dec    cl                                    # 46EB: FE C9
    jne    L_46F1                                # 46ED: 75 02
    mov    cl,0xb                                # 46EF: B1 0B
L_46F1:
    dec    ch                                    # 46F1: FE CD
    jne    L_46B1                                # 46F3: 75 BC
    mov    ch,0xd                                # 46F5: B5 0D
    jmp    L_46B1                                # 46F7: EB B8
L_46F9:
    mov    cx,0xd0b                              # 46F9: B9 0B 0D
    mov    bx,WORD PTR ds:TXTTAB                   # 46FC: 8B 1E 30 00
    xchg   dx,bx                                 # 4700: 87 DA
L_4702:
    mov    bx,WORD PTR ds:VARTAB                  # 4702: 8B 1E 58 03
    .byte 0x3B, 0xDA # 4706
    je     L_46B9                                # 4708: 74 AF
    mov    bx,0x6176                             # 470A: BB 76 61
    .byte 0x8A, 0xC3, 0x02, 0xC5, 0x8A, 0xD8, 0x8A, 0xC7 # 470D
    adc    al,0x0                                # 4715: 14 00
    .byte 0x8A, 0xF8, 0x8B, 0xF2 # 4717
    lods   al,BYTE PTR ds:[si]                   # 471B: AC
    .byte 0x2A, 0xC1 # 471C
    xor    al,BYTE PTR cs:[bx]                   # 471E: 2E 32 07
    push   ax                                    # 4721: 50
    mov    bx,0x6217                             # 4722: BB 17 62
    .byte 0x8A, 0xC3, 0x02, 0xC1, 0x8A, 0xD8, 0x8A, 0xC7 # 4725
    adc    al,0x0                                # 472D: 14 00
    .byte 0x8A, 0xF8 # 472F
    pop    ax                                    # 4731: 58
    xor    al,BYTE PTR cs:[bx]                   # 4732: 2E 32 07
    .byte 0x02, 0xC5, 0x8B, 0xFA # 4735
    stos   BYTE PTR es:[di],al                   # 4739: AA
    inc    dx                                    # 473A: 42
    dec    cl                                    # 473B: FE C9
    jne    L_4741                                # 473D: 75 02
    mov    cl,0xb                                # 473F: B1 0B
L_4741:
    dec    ch                                    # 4741: FE CD
    jne    L_4702                                # 4743: 75 BD
    mov    ch,0xd                                # 4745: B5 0D
    jmp    L_4702                                # 4747: EB B9
L_4749:
    push   bx                                    # 4749: 53
    mov    bx,WORD PTR ds:CURLIN                   # 474A: 8B 1E 2E 00
    .byte 0x8A, 0xC7, 0x22, 0xC3 # 474E
    pop    bx                                    # 4752: 5B
    inc    al                                    # 4753: FE C0
    je     PROCHK                                # 4755: 74 01
    ret                                          # 4757: C3
PROCHK:
    lahf                                         # 4758: 9F
    push   ax                                    # 4759: 50
    mov    al,ds:PROFLG                           # 475A: A0 64 04
    .byte 0x0A, 0xC0 # 475D
    je     L_4764                                # 475F: 74 03
    .byte 0xE9, 0xF5 # 4761
L_4763:
    .byte 0xC8 # 4763
L_4764:
    .byte 0x58, 0x9E, 0xC3 # 4764
L_4767:
    mov    al,BYTE PTR [bx]                      # 4767: 8A 07
    cmp    al,0x40                               # 4769: 3C 40
L_476B:
    jne    L_4770                                # 476B: 75 03
    call   CHRGTR                                # 476D: E8 AD C7
L_4770:
    mov    cx,0x0                                # 4770: B9 00 00
    .byte 0x8A, 0xF5, 0x8A, 0xD1 # 4773
    cmp    al,0xea                               # 4777: 3C EA
    je     L_479A                                # 4779: 74 1F
L_477B:
    mov    al,BYTE PTR [bx]                      # 477B: 8A 07
    cmp    al,0xcf                               # 477D: 3C CF
    pushf                                        # 477F: 9C
    jne    L_4785                                # 4780: 75 03
    call   CHRGTR                                # 4782: E8 98 C7
L_4785:
    call   SYNCHR                                # 4785: E8 6C E6
    .byte '('                                  # 4788: 28 -- SYNCHR inline operand
    .byte 0xE8 # 4789 -- decoded continuation: call   0x1f0a
    jle    L_4763                                # 478A: 7E D7
    push   dx                                    # 478C: 52
    call   SYNCHR                                # 478D: E8 64 E6
    .byte ','                                  # 4790: 2C -- SYNCHR inline operand
    .byte 0xE8 # 4791 -- decoded continuation: call   0x1f0a
    jbe    L_476B                                # 4792: 76 D7
    call   SYNCHR                                # 4794: E8 5D E6
    .byte ')'                                  # 4797: 29 -- SYNCHR inline operand
    .byte 0x59, 0x9D # 4798 -- decoded continuation: pop    cx ; popf
L_479A:
    push   bx                                    # 479A: 53
    mov    bx,WORD PTR ds:GRPACX                  # 479B: 8B 1E 3D 05
    je     L_47A4                                # 479F: 74 03
    mov    bx,0x0                                # 47A1: BB 00 00
L_47A4:
    lahf                                         # 47A4: 9F
    .byte 0x03, 0xD9 # 47A5
    rcr    si,1                                  # 47A7: D1 DE
    sahf                                         # 47A9: 9E
    rcl    si,1                                  # 47AA: D1 D6
    mov    WORD PTR ds:GRPACX,bx                  # 47AC: 89 1E 3D 05
    mov    WORD PTR ds:GXPOS,bx                  # 47B0: 89 1E 37 05
    .byte 0x8B, 0xCB # 47B4
    mov    bx,WORD PTR ds:GRPACY                  # 47B6: 8B 1E 3B 05
    je     L_47BF                                # 47BA: 74 03
    mov    bx,0x0                                # 47BC: BB 00 00
L_47BF:
    .byte 0x03, 0xDA # 47BF
    mov    WORD PTR ds:GRPACY,bx                  # 47C1: 89 1E 3B 05
    mov    WORD PTR ds:GYPOS,bx                  # 47C5: 89 1E 39 05
    xchg   dx,bx                                 # 47C9: 87 DA
    pop    bx                                    # 47CB: 5B
    ret                                          # 47CC: C3
PRESET:
    .byte 0x32, 0xC0 # 47CD
    jmp    L_47D3                                # 47CF: EB 02
PSET:
    mov    al,0x3                                # 47D1: B0 03
L_47D3:
    push   ax                                    # 47D3: 50
    call   L_477B                                # 47D4: E8 A4 FF
    pop    ax                                    # 47D7: 58
    call   L_4809                                # 47D8: E8 2E 00
    push   bx                                    # 47DB: 53
    call   SCALXY                                # 47DC: E8 28 03
    jae    L_47E7                                # 47DF: 73 06
    call   MAPXYC                                # 47E1: E8 7F 02
    call   SETC                                # 47E4: E8 55 02
L_47E7:
    pop    bx                                    # 47E7: 5B
    ret                                          # 47E8: C3
L_47E9:
    call   CHRGTR                                # 47E9: E8 31 C7
    call   L_477B                                # 47EC: E8 8C FF
    push   bx                                    # 47EF: 53
    call   SCALXY                                # 47F0: E8 14 03
    mov    bx,0xffff                             # 47F3: BB FF FF
    jae    L_4802                                # 47F6: 73 0A
    call   MAPXYC                                # 47F8: E8 68 02
    call   READC                                # 47FB: E8 1B 02
    .byte 0x8A, 0xD8 # 47FE
    mov    bh,0x0                                # 4800: B7 00
L_4802:
    call   MAKINT                                # 4802: E8 07 1D
    pop    bx                                    # 4805: 5B
    ret                                          # 4806: C3
L_4807:
    .byte 0xB0, 0x03 # 4807
L_4809:
    push   cx                                    # 4809: 51
    push   dx                                    # 480A: 52
    .byte 0x8A, 0xD0 # 480B
    dec    bx                                    # 480D: 4B
    call   CHRGTR                                # 480E: E8 0C C7
    je     L_481E                                # 4811: 74 0B
    call   SYNCHR                                # 4813: E8 DE E5
    .byte ','                                  # 4816: 2C -- SYNCHR inline operand
    .byte 0x3C # 4817 -- decoded continuation: cmp    al,0x2c
    sub    al,0x74                               # 4818: 2C 74
    .byte 0x03, 0xE8, 0xFE, 0xD6 # 481A
L_481E:
    .byte 0x8A, 0xC2 # 481E
    push   bx                                    # 4820: 53
    call   SETATR                                # 4821: E8 C1 02
    jae    L_4829                                # 4824: 73 03
    jmp    FCERR                                # 4826: E9 30 C8
L_4829:
    pop    bx                                    # 4829: 5B
    pop    dx                                    # 482A: 5A
    pop    cx                                    # 482B: 59
    jmp    CHRGT2                                # 482C: E9 EF C6
    .byte 0x8B, 0x1E, 0x37, 0x05, 0x8A, 0xC3, 0x2A, 0xC1, 0x8A, 0xD8, 0x8A, 0xC7 # 482F
    .byte 0x1A, 0xC5, 0x8A, 0xF8, 0x73, 0xC5, 0x32, 0xC0, 0x2A, 0xC3, 0x8A, 0xD8 # 483B
    .byte 0x1A, 0xC7, 0x2A, 0xC3, 0x8A, 0xF8, 0xF9, 0xC3, 0x8B, 0x1E, 0x39, 0x05 # 4847
    .byte 0x8A, 0xC3, 0x2A, 0xC2, 0x8A, 0xD8, 0x8A, 0xC7, 0x1A, 0xC6, 0x8A, 0xF8 # 4853
    .byte 0xEB, 0xDE, 0x53, 0x8B, 0x1E, 0x39, 0x05, 0x87, 0xDA, 0x89, 0x1E, 0x39 # 485F
    .byte 0x05, 0x5B, 0xC3, 0xE8, 0xF0, 0xFF, 0x53, 0x51, 0x8B, 0x1E, 0x37, 0x05 # 486B
    .byte 0x5E, 0x87, 0xDE, 0x56, 0x89, 0x1E, 0x37, 0x05, 0x59, 0x5B, 0xC3 # 4877
L_4882:
    call   L_4767                                # 4882: E8 E2 FE
    push   cx                                    # 4885: 51
    push   dx                                    # 4886: 52
    call   SYNCHR                                # 4887: E8 6A E5
    .byte TK_MINUS                               # 488A: SYNCHR inline operand
    call   L_477B                                # 488B: E8 ED FE
    call   L_4807                                # 488E: E8 76 FF
    pop    dx                                    # 4891: 5A
    pop    cx                                    # 4892: 59
    je     L_48E8                                # 4893: 74 53
    call   SYNCHR                                # 4895: E8 5C E5
    .byte ','                                    # 4898: SYNCHR inline operand
    call   SYNCHR                                # 4899: E8 58 E5
    .byte 'B'                                    # 489C: SYNCHR inline operand
    jne    L_48A2                                # 489D: 75 03
    .byte 0xE9, 0x60, 0x00                       # 489F: near JMP 4902; historical near form
L_48A2:
    call   SYNCHR                                # 48A2: E8 4F E5
    .byte 'F'                                    # 48A5: SYNCHR inline operand
    push   bx                                    # 48A6: 53
    .byte 0xE8, 0x5D, 0x02, 0xE8, 0xC1, 0xFF, 0xE8, 0x57, 0x02, 0xE8, 0x9C, 0xFF # 48A7
    .byte 0x73, 0x03, 0xE8, 0xA9, 0xFF, 0x43, 0x53, 0xE8, 0x72, 0xFF, 0x73, 0x03 # 48B3
    .byte 0xE8, 0xAF, 0xFF, 0x43, 0x53, 0xE8, 0x9C, 0x01, 0x5A, 0x59, 0x52, 0x51 # 48BF
    .byte 0xE8, 0xDB, 0x00, 0x50, 0x53, 0x87, 0xDA, 0xE8, 0x69, 0x02, 0x5B, 0x58 # 48CB
    .byte 0xE8, 0xD7, 0x00, 0xE8, 0xF8, 0x00, 0x59, 0x5A, 0x49, 0x8A, 0xC5, 0x0A # 48D7
    .byte 0xC1, 0x75, 0xE3, 0x5B, 0xC3 # 48E3..48E7
L_48E8:
    .byte 0x51, 0x52, 0x53, 0xE8, 0x45, 0x00, 0x8B # 48E8..48EE
    .byte 0x1E, 0x3D, 0x05, 0x89, 0x1E, 0x37, 0x05, 0x8B, 0x1E, 0x3B, 0x05, 0x89 # 48EF
    .byte 0x1E, 0x39, 0x05, 0x5B, 0x5A, 0x59, 0xC3, 0x53, 0x8B, 0x1E, 0x39, 0x05 # 48FB
    .byte 0x53, 0x52, 0x87, 0xDA, 0xE8, 0xDA, 0xFF, 0x5B, 0x89, 0x1E, 0x39, 0x05 # 4907
    .byte 0x87, 0xDA, 0xE8, 0xD0, 0xFF, 0x5B, 0x89, 0x1E, 0x39, 0x05, 0x8B, 0x1E # 4913
    .byte 0x37, 0x05, 0x51, 0x8B, 0xCB, 0xE8, 0xC1, 0xFF, 0x5B, 0x89, 0x1E, 0x37 # 491F
    .byte 0x05, 0x8B, 0xCB, 0xE8, 0xB7, 0xFF, 0x5B, 0xC3, 0xCD, 0xB8, 0xE8, 0xCF # 492B
    .byte 0x01, 0xE8, 0x33, 0xFF, 0xE8, 0xC9, 0x01, 0xE8, 0x0E, 0xFF, 0x73, 0x03 # 4937
    .byte 0xE8, 0x28, 0xFF, 0x52, 0x53, 0xE8, 0xE4, 0xFE, 0x87, 0xDA, 0xBB, 0xF1 # 4943
    .byte 0x49, 0x73, 0x03, 0xBB, 0x05, 0x4A, 0x5E, 0x87, 0xDE, 0x56, 0x3B, 0xDA # 494F
    .byte 0x73, 0x14, 0x89, 0x1E, 0xFD, 0x06, 0x5B, 0x89, 0x1E, 0xF7, 0x06, 0xBB # 495B
    .byte 0xD5, 0x49, 0x89, 0x1E, 0xF9, 0x06, 0x87, 0xDA, 0xEB, 0x16, 0x5E, 0x87 # 4967
    .byte 0xDE, 0x56, 0x89, 0x1E, 0xF9, 0x06, 0xBB, 0xD5, 0x49, 0x89, 0x1E, 0xF7 # 4973
    .byte 0x06, 0x87, 0xDA, 0x89, 0x1E, 0xFD, 0x06, 0x5B, 0x5A, 0x53, 0x89, 0x1E # 497F
    .byte 0xFB, 0x06, 0xE8, 0xD3, 0x00, 0x5A, 0x52, 0xE8, 0x05, 0x00, 0x59, 0x41 # 498B
    .byte 0xE9, 0x20, 0x02, 0x8A, 0xC6, 0x0A, 0xC0, 0xD0, 0xD8, 0x8A, 0xF0, 0x8A # 4997
    .byte 0xC2, 0xD0, 0xD8, 0x8A, 0xD0, 0xC3, 0x8B, 0x1E, 0xF3, 0x06, 0xA0, 0xF5 # 49A3
    .byte 0x06, 0xC3, 0x89, 0x1E, 0xF3, 0x06, 0xA2, 0xF5, 0x06, 0xC3, 0x8B, 0x1E # 49AF
    .byte 0xF3, 0x06, 0x81, 0xFB, 0x00, 0x20, 0x72, 0x09, 0x81, 0xEB, 0x00, 0x20 # 49BB
    .byte 0x89, 0x1E, 0xF3, 0x06, 0xC3, 0x81, 0xC3, 0x50, 0x20, 0x89, 0x1E, 0xF3 # 49C7
    .byte 0x06, 0xC3, 0x8B, 0x1E, 0xF3, 0x06, 0x81, 0xFB, 0x00, 0x20, 0x72, 0x09 # 49D3
    .byte 0x81, 0xEB, 0xB0, 0x1F, 0x89, 0x1E, 0xF3, 0x06, 0xC3, 0x81, 0xC3, 0x00 # 49DF
    .byte 0x20, 0x89, 0x1E, 0xF3, 0x06, 0xC3, 0x8A, 0xC1, 0x8A, 0x0E, 0x55, 0x00 # 49EB
    .byte 0xD2, 0x0E, 0xF5, 0x06, 0x8A, 0xC8, 0x72, 0x01, 0xC3, 0xFF, 0x06, 0xF3 # 49F7
    .byte 0x06, 0xC3, 0x8A, 0xC1, 0x8A, 0x0E, 0x55, 0x00, 0xD2, 0x06, 0xF5, 0x06 # 4A03
    .byte 0x8A, 0xC8, 0x72, 0x01, 0xC3, 0xFF, 0x0E, 0xF3, 0x06, 0xC3 # 4A0F
READC:
    mov    si,es                                 # 4A19: 8C C6
    mov    di,0xb800                             # 4A1B: BF 00 B8
    mov    es,di                                 # 4A1E: 8E C7
    mov    bx,WORD PTR ds:PIXEL_BYTE_ADDR                  # 4A20: 8B 1E F3 06
    mov    al,BYTE PTR es:[bx]                   # 4A24: 26 8A 07
    mov    dl,BYTE PTR ds:PIXEL_MASK                  # 4A27: 8A 16 F5 06
    .byte 0x22, 0xC2 # 4A2B
    mov    cl,BYTE PTR ds:BITS_PER_PIXEL                   # 4A2D: 8A 0E 55 00
L_4A31:
    shr    dl,cl                                 # 4A31: D2 EA
    jb     L_4A39                                # 4A33: 72 04
    shr    al,cl                                 # 4A35: D2 E8
    jmp    L_4A31                                # 4A37: EB F8
L_4A39:
    mov    es,si                                 # 4A39: 8E C6
    ret                                          # 4A3B: C3
SETC:
    mov    si,es                                 # 4A3C: 8C C6
    mov    di,0xb800                             # 4A3E: BF 00 B8
    mov    es,di                                 # 4A41: 8E C7
    mov    bx,WORD PTR ds:PIXEL_BYTE_ADDR                  # 4A43: 8B 1E F3 06
    .byte 0x8B, 0xE9 # 4A47
    mov    al,ds:PIXEL_MASK                           # 4A49: A0 F5 06
    not    al                                    # 4A4C: F6 D0
    and    al,BYTE PTR es:[bx]                   # 4A4E: 26 22 07
    mov    cl,BYTE PTR ds:ATRBYT                  # 4A51: 8A 0E F6 06
    and    cl,BYTE PTR ds:PIXEL_MASK                  # 4A55: 22 0E F5 06
    .byte 0x0A, 0xC1 # 4A59
    mov    BYTE PTR es:[bx],al                   # 4A5B: 26 88 07
    .byte 0x8B, 0xCD # 4A5E
    mov    es,si                                 # 4A60: 8E C6
    ret                                          # 4A62: C3
MAPXYC:
    .byte 0x8B, 0xE9 # 4A63
    shr    dx,1                                  # 4A65: D1 EA
    lahf                                         # 4A67: 9F
    .byte 0x8B, 0xDA # 4A68
    mov    cl,0x2                                # 4A6A: B1 02
    shl    dx,cl                                 # 4A6C: D3 E2
    .byte 0x03, 0xD3 # 4A6E
    mov    cl,0x4                                # 4A70: B1 04
    shl    dx,cl                                 # 4A72: D3 E2
    sahf                                         # 4A74: 9E
    jae    L_4A7B                                # 4A75: 73 04
    add    dx,0x2000                             # 4A77: 81 C2 00 20
L_4A7B:
    mov    WORD PTR ds:PIXEL_BYTE_ADDR,dx                  # 4A7B: 89 16 F3 06
    .byte 0x8B, 0xD5, 0x8A, 0xCA # 4A7F
    test   BYTE PTR ds:BITS_PER_PIXEL,0x1                  # 4A83: F6 06 55 00 01
    je     L_4A9E                                # 4A88: 74 14
    mov    al,0x7                                # 4A8A: B0 07
    .byte 0x22, 0xC8 # 4A8C
    mov    al,0x80                               # 4A8E: B0 80
    shr    al,cl                                 # 4A90: D2 E8
    mov    ds:PIXEL_MASK,al                           # 4A92: A2 F5 06
    mov    cl,0x3                                # 4A95: B1 03
    shr    dx,cl                                 # 4A97: D3 EA
    add    WORD PTR ds:PIXEL_BYTE_ADDR,dx                  # 4A99: 01 16 F3 06
    ret                                          # 4A9D: C3
L_4A9E:
    mov    al,0x3                                # 4A9E: B0 03
    .byte 0x22, 0xC8, 0x02, 0xC9 # 4AA0
    mov    al,0xc0                               # 4AA4: B0 C0
    shr    al,cl                                 # 4AA6: D2 E8
    mov    ds:PIXEL_MASK,al                           # 4AA8: A2 F5 06
    mov    cl,0x2                                # 4AAB: B1 02
    shr    dx,cl                                 # 4AAD: D3 EA
    add    WORD PTR ds:PIXEL_BYTE_ADDR,dx                  # 4AAF: 01 16 F3 06
    ret                                          # 4AB3: C3
# Machine-dependent graphics mode parameter initialization. C1.20 generalizes
# this block for PCjr-era video handling. GRPACX/GRPACY initialize the graphics
# accumulator at screen center; DS:0055 still needs its historical name proved.
IBM_GRAPHICS_MODE_INIT:
    mov    al,ds:BIOS_VIDEO_MODE                            # 4AB4: A0 48 00
    mov    WORD PTR ds:GRPACY,0x64                # 4AB7: C7 06 3B 05 64 00
    cmp    al,0x6                                # 4ABD: 3C 06
    je     L_4AD3                                # 4ABF: 74 12
    jae    L_4ADF                                # 4AC1: 73 1C
    cmp    al,0x4                                # 4AC3: 3C 04
    jb     L_4ADF                                # 4AC5: 72 18
    mov    BYTE PTR ds:BITS_PER_PIXEL,0x2                  # 4AC7: C6 06 55 00 02
    mov    WORD PTR ds:GRPACX,0xa0                # 4ACC: C7 06 3D 05 A0 00
    ret                                          # 4AD2: C3
L_4AD3:
    mov    BYTE PTR ds:BITS_PER_PIXEL,0x1                  # 4AD3: C6 06 55 00 01
    mov    WORD PTR ds:GRPACX,0x140               # 4AD8: C7 06 3D 05 40 01
    ret                                          # 4ADE: C3
L_4ADF:
    mov    BYTE PTR ds:BITS_PER_PIXEL,0x0                  # 4ADF: C6 06 55 00 00
    ret                                          # 4AE4: C3
SETATR:
    cmp    al,0x4                                # 4AE5: 3C 04
    jae    L_4AF8                                # 4AE7: 73 0F
    test   BYTE PTR ds:BITS_PER_PIXEL,0x1                  # 4AE9: F6 06 55 00 01
    je     L_4AFC                                # 4AEE: 74 0C
    and    al,0x1                                # 4AF0: 24 01
    neg    al                                    # 4AF2: F6 D8
    mov    ds:ATRBYT,al                           # 4AF4: A2 F6 06
    clc                                          # 4AF7: F8
L_4AF8:
    ret                                          # 4AF8: C3
L_4AF9:
    jmp    FCERR                                # 4AF9: E9 5D C5
L_4AFC:
    and    al,0x3                                # 4AFC: 24 03
    mov    cl,0x55                               # 4AFE: B1 55
    mul    cl                                    # 4B00: F6 E1
    mov    ds:ATRBYT,al                           # 4B02: A2 F6 06
    clc                                          # 4B05: F8
    ret                                          # 4B06: C3
SCALXY:
    mov    al,ds:BITS_PER_PIXEL                            # 4B07: A0 55 00
    .byte 0x0A, 0xC0 # 4B0A
    je     L_4AF9                                # 4B0C: 74 EB
    .byte 0x0A, 0xED # 4B0E
    js     L_4B39                                # 4B10: 78 27
    mov    bx,0x280                              # 4B12: BB 80 02
    test   BYTE PTR ds:SCALE_MASK,al             # 4B15: 84 06 01 00
    je     L_4B1E                                # 4B19: 74 03
    mov    bx,0x140                              # 4B1B: BB 40 01
L_4B1E:
    .byte 0x3B, 0xCB # 4B1E
    lahf                                         # 4B20: 9F
    jb     L_4B26                                # 4B21: 72 03
    dec    bx                                    # 4B23: 4B
    .byte 0x8B, 0xCB # 4B24
L_4B26:
    .byte 0x0A, 0xF6 # 4B26
    js     L_4B36                                # 4B28: 78 0C
    cmp    dx,0xc8                               # 4B2A: 81 FA C8 00
    jb     L_4B34                                # 4B2E: 72 04
    mov    dx,0xc7                               # 4B30: BA C7 00
    ret                                          # 4B33: C3
L_4B34:
    sahf                                         # 4B34: 9E
    ret                                          # 4B35: C3
L_4B36:
    .byte 0x33, 0xD2 # 4B36
    ret                                          # 4B38: C3
L_4B39:
    .byte 0x33, 0xC9 # 4B39
    lahf                                         # 4B3B: 9F
    jmp    L_4B26                                # 4B3C: EB E8
    .byte 0x8C, 0xC6, 0xBF, 0x00, 0xB8, 0x8E, 0xC7, 0x8B, 0xD3, 0x0B, 0xD2, 0x74 # 4B3E
    .byte 0x6C, 0x8B, 0x1E, 0xF3, 0x06, 0x26, 0x8A, 0x2F, 0xA0, 0xF5, 0x06, 0x8A # 4B4A
    .byte 0xE0, 0xF6, 0xD0, 0x8A, 0x0E, 0x55, 0x00, 0x8A, 0x1E, 0xF6, 0x06, 0x22 # 4B56
    .byte 0xE8, 0x8A, 0xFC, 0x22, 0xFB, 0x0A, 0xEF, 0x4A, 0x74, 0x40, 0xD2, 0xC8 # 4B62
    .byte 0xD2, 0xCC, 0x73, 0xEF, 0x8B, 0x1E, 0xF3, 0x06, 0x26, 0x88, 0x2F, 0xFF # 4B6E
    .byte 0x06, 0xF3, 0x06, 0x88, 0x26, 0xF5, 0x06, 0x8B, 0xCA, 0xD1, 0xE9, 0xD1 # 4B7A
    .byte 0xE9, 0xF6, 0x06, 0x55, 0x00, 0x01, 0x75, 0x06, 0x81, 0xE2, 0x03, 0x00 # 4B86
    .byte 0xEB, 0x06, 0x81, 0xE2, 0x07, 0x00, 0xD1, 0xE9, 0xE3, 0xAB, 0xFC, 0xA0 # 4B92
    .byte 0xF6, 0x06, 0x8B, 0x3E, 0xF3, 0x06, 0xF3, 0xAA, 0x89, 0x3E, 0xF3, 0x06 # 4B9E
    .byte 0xEB, 0x9B, 0x8B, 0x1E, 0xF3, 0x06, 0x26, 0x88, 0x2F, 0x88, 0x26, 0xF5 # 4BAA
    .byte 0x06, 0x8E, 0xC6, 0xC3, 0xE8, 0x7F, 0xFE, 0x03, 0x16, 0xFD, 0x06, 0x3B # 4BB6
    .byte 0x16, 0xFB, 0x06, 0x72, 0x09, 0x2B, 0x16, 0xFB, 0x06, 0x3E, 0xFF, 0x16 # 4BC2
    .byte 0xF9, 0x06, 0x3E, 0xFF, 0x16, 0xF7, 0x06, 0xE2, 0xE3, 0xC3 # 4BCE
L_4BD8:
    push   bx                                    # 4BD8: 53
    call   L_1B7F                                # 4BD9: E8 A3 CF
    pop    bx                                    # 4BDC: 5B
    ret                                          # 4BDD: C3
L_4BDE:
    push   bx                                    # 4BDE: 53
    call   CONIA                                # 4BDF: E8 27 19
    pop    bx                                    # 4BE2: 5B
    ret                                          # 4BE3: C3
OEM_ROM_CHECKSUM_BYTE_BLOCK2:
    .byte 0xF6                                  # 4BE4: OEM 8 KiB ROM checksum byte (bank sum = 00h)
L_4BE5:
    cmp    BYTE PTR ds:KEYSW,0x0                  # 4BE5: 80 3E 71 00 00
    je     L_4BEF                                # 4BEA: 74 03
    jmp    KEYDSP                                # 4BEC: E9 F9 04
L_4BEF:
    ret                                          # 4BEF: C3
L_4BF0:
    mov    al,ds:CRTWID                            # 4BF0: A0 29 00
    .byte 0x8A, 0xD0 # 4BF3
    call   L_1EF7                                # 4BF5: E8 FF D2
    jmp    KEYDSP                                # 4BF8: E9 ED 04
    .byte 0x00, 0x00, 0x00 # 4BFB
L_4BFE:
    mov    ah,0xf                                # 4BFE: B4 0F
    int    0x10                                  # 4C00: CD 10
    mov    ds:BIOS_VIDEO_MODE,al                            # 4C02: A2 48 00
    mov    ah,0x28                               # 4C05: B4 28
    cmp    al,0x2                                # 4C07: 3C 02
    jb     L_4C18                                # 4C09: 72 0D
    mov    ah,0x50                               # 4C0B: B4 50
    cmp    al,0x7                                # 4C0D: 3C 07
    jne    L_4C18                                # 4C0F: 75 07
    mov    cx,0xb0c                              # 4C11: B9 0C 0B
    mov    WORD PTR ds:CURSOR_SHAPE,cx                   # 4C14: 89 0E 68 00
L_4C18:
    mov    BYTE PTR ds:CRTWID,ah                   # 4C18: 88 26 29 00
    cli                                          # 4C1C: FA
    mov    bx,ds                                 # 4C1D: 8C DB
    mov    WORD PTR ds:SAVSEG,bx                  # 4C1F: 89 1E 50 03
    push   ds                                    # 4C23: 1E
    mov    dx,0x0                                # 4C24: BA 00 00
    mov    ds,dx                                 # 4C27: 8E DA
    mov    WORD PTR ds:BASIC_DSEG_SAVE_ABS,bx     # 4C29: 89 1E 10 05 -- DS=0
    mov    bx,0x4d34                             # 4C2D: BB 34 4D
    mov    WORD PTR ds:IVT_INT1B_OFF,bx            # 4C30: 89 1E 6C 00 -- DS=0
    mov    bx,0x5744                             # 4C34: BB 44 57
    mov    WORD PTR ds:IVT_INT1C_OFF,bx            # 4C37: 89 1E 70 00 -- DS=0
    mov    WORD PTR ds:KEY_EXPANSION_SEG_HI,cs                   # 4C3B: 8C 0E 6E 00
    mov    WORD PTR ds:IVT_INT1C_SEG,cs           # 4C3F: 8C 0E 72 00 -- DS=0
    pop    ds                                    # 4C43: 1F
    call   L_4C79                                # 4C44: E8 32 00
    mov    bx,0x218                              # 4C47: BB 18 02
    mov    cx,0x0                                # 4C4A: B9 00 00
    mov    es,cx                                 # 4C4D: 8E C1
    mov    cx,0x7a                               # 4C4F: B9 7A 00
L_4C52:
    .byte 0x26, 0x8C, 0x8F, 0x02, 0x00 # 4C52
    mov    WORD PTR es:[bx],0x4c94               # 4C57: 26 C7 07 94 4C
    add    bx,0x4                                # 4C5C: 83 C3 04
    loopne L_4C52                                # 4C5F: E0 F1
    mov    bx,ds                                 # 4C61: 8C DB
    mov    es,bx                                 # 4C63: 8E C3
    call   L_2DB0                                # 4C65: E8 48 E1
    sti                                          # 4C68: FB
    mov    ah,0x1                                # 4C69: B4 01
    int    0x17                                  # 4C6B: CD 17
    call   CLS                                   # 4C6D: E8 77 06
    mov    bx,0x4c9b                             # 4C70: BB 9B 4C
    call   STROUT                                # 4C73: E8 DF 2E
    jmp    L_7EDC                                # 4C76: E9 63 32
L_4C79:
    mov    si,0x4ced                             # 4C79: BE ED 4C
    mov    bx,0x653                              # 4C7C: BB 53 06
    mov    cx,0xa                                # 4C7F: B9 0A 00
L_4C82:
    push   bx                                    # 4C82: 53
L_4C83:
    cld                                          # 4C83: FC
    lods   al,BYTE PTR cs:[si]                   # 4C84: 2E AC
    mov    BYTE PTR [bx],al                      # 4C86: 88 07
    inc    bx                                    # 4C88: 43
    .byte 0x0A, 0xC0 # 4C89
    jne    L_4C83                                # 4C8B: 75 F6
    pop    bx                                    # 4C8D: 5B
    add    bx,0x10                               # 4C8E: 83 C3 10
    loopne L_4C82                                # 4C91: E0 EF
    ret                                          # 4C93: C3
    .byte 0xCF, 0x3E, 0xFF, 0x2E, 0x00, 0x07, 0xCB # 4C94
BASIC_TITLE_TEXT:
    .ascii "The IBM Personal Computer Basic"
    .byte 0xFF, 0x0D
BASIC_VERSION_TEXT:
    .ascii "Version C1.10 Copyright IBM Corp 1981"
    .byte 0xFF, 0x0D, 0x00
BASIC_BUILD_DATE_TEXT:
    .ascii "25-Apr-81"
    .byte 0x4C, 0x49, 0x53, 0x54, 0x20, 0x00, 0x52, 0x55, 0x4E, 0x0D, 0x00, 0x4C # 4CED
    .byte 0x4F, 0x41, 0x44, 0x22, 0x00, 0x53, 0x41, 0x56, 0x45, 0x22, 0x00, 0x43 # 4CF9
    .byte 0x4F, 0x4E, 0x54, 0x0D, 0x00, 0x2C, 0x22, 0x4C, 0x50, 0x54, 0x31, 0x3A # 4D05
    .byte 0x22, 0x0D, 0x00, 0x54, 0x52, 0x4F, 0x4E, 0x0D, 0x00, 0x54, 0x52, 0x4F # 4D11
    .byte 0x46, 0x46, 0x0D, 0x00, 0x4B, 0x45, 0x59, 0x20, 0x00, 0x53, 0x43, 0x52 # 4D1D
    .byte 0x45, 0x45, 0x4E, 0x20, 0x30, 0x2C, 0x30, 0x2C, 0x30, 0x0D, 0x00, 0x9C # 4D29
    .byte 0x50, 0x1E, 0x52, 0xBA, 0x00, 0x00, 0x8E, 0xDA, 0x8E, 0x1E, 0x10, 0x05 # 4D35
    .byte 0xE8, 0x3A, 0x0A, 0x88, 0x16, 0x6A, 0x00, 0xFE, 0xCA, 0x88, 0x16, 0x5E # 4D41
    .byte 0x00, 0x5A, 0x1F, 0x58, 0x9D, 0xCF # 4D4D
L_4D53:
    push   si                                    # 4D53: 56
    mov    al,ds:CTRL_BREAK_PENDING                            # 4D54: A0 5E 00
    .byte 0x0A, 0xC0 # 4D57
    jne    L_4D6C                                # 4D59: 75 11
    mov    al,ds:KEY_EXPANSION_STATE                            # 4D5B: A0 6A 00
    .byte 0x0A, 0xC0 # 4D5E
    jne    L_4D6C                                # 4D60: 75 0A
    mov    ah,0x1                                # 4D62: B4 01
    int    0x16                                  # 4D64: CD 16
    mov    al,0x0                                # 4D66: B0 00
    je     L_4D6C                                # 4D68: 74 02
    dec    al                                    # 4D6A: FE C8
L_4D6C:
    pop    si                                    # 4D6C: 5E
    ret                                          # 4D6D: C3
L_4D6E:
    mov    al,ds:CTRL_BREAK_PENDING                            # 4D6E: A0 5E 00
    .byte 0x0A, 0xC0 # 4D71
    je     L_4D7D                                # 4D73: 74 08
    .byte 0x32, 0xC0 # 4D75
    mov    ds:CTRL_BREAK_PENDING,al                            # 4D77: A2 5E 00
    mov    al,0x3                                # 4D7A: B0 03
    ret                                          # 4D7C: C3
L_4D7D:
    push   si                                    # 4D7D: 56
    push   di                                    # 4D7E: 57
    mov    al,ds:KEY_EXPANSION_STATE                            # 4D7F: A0 6A 00
    .byte 0x0A, 0xC0 # 4D82
    jne    L_4DFA                                # 4D84: 75 74
    mov    ah,0x0                                # 4D86: B4 00
    int    0x16                                  # 4D88: CD 16
    .byte 0x0A, 0xC0 # 4D8A
    je     L_4D91                                # 4D8C: 74 03
L_4D8E:
    pop    di                                    # 4D8E: 5F
    pop    si                                    # 4D8F: 5E
    ret                                          # 4D90: C3
L_4D91:
    push   bx                                    # 4D91: 53
    cmp    ah,0x3b                               # 4D92: 80 FC 3B
    jb     L_4D9C                                # 4D95: 72 05
    cmp    ah,0x45                               # 4D97: 80 FC 45
    jb     L_4DD8                                # 4D9A: 72 3C
L_4D9C:
    mov    bx,WORD PTR ds:CURLIN                   # 4D9C: 8B 1E 2E 00
    inc    bx                                    # 4DA0: 43
    .byte 0x0B, 0xDB # 4DA1
    jne    L_4DB8                                # 4DA3: 75 13
    mov    bx,0x4e34                             # 4DA5: BB 34 4E
    mov    cl,0x1a                               # 4DA8: B1 1A
L_4DAA:
    cmp    ah,BYTE PTR cs:[bx]                   # 4DAA: 2E 3A 27
    je     L_4DBB                                # 4DAD: 74 0C
    inc    bx                                    # 4DAF: 43
    inc    al                                    # 4DB0: FE C0
    dec    cl                                    # 4DB2: FE C9
    jne    L_4DAA                                # 4DB4: 75 F4
    .byte 0x32, 0xC0 # 4DB6
L_4DB8:
    pop    bx                                    # 4DB8: 5B
    jmp    L_4D8E                                # 4DB9: EB D3
L_4DBB:
    .byte 0x32, 0xE4 # 4DBB
    shl    al,1                                  # 4DBD: D0 E0
    .byte 0x8B, 0xD8 # 4DBF
    mov    bx,WORD PTR cs:[bx+0x103]             # 4DC1: 2E 8B 9F 03 01
    mov    WORD PTR ds:KEY_EXPANSION_PTR,bx                   # 4DC6: 89 1E 6B 00
    dec    BYTE PTR ds:KEY_EXPANSION_STATE                      # 4DCA: FE 0E 6A 00
    shr    al,1                                  # 4DCE: D0 E8
    add    al,0x41                               # 4DD0: 04 41
    mov    WORD PTR ds:KEY_EXPANSION_SEG,cs                   # 4DD2: 8C 0E 6D 00
    jmp    L_4DB8                                # 4DD6: EB E0
L_4DD8:
    push   ax                                    # 4DD8: 50
    xchg   ah,al                                 # 4DD9: 86 C4
    sub    al,0x3b                               # 4DDB: 2C 3B
    mov    bl,0x10                               # 4DDD: B3 10
    mul    bl                                    # 4DDF: F6 E3
    mov    bx,0x653                              # 4DE1: BB 53 06
    .byte 0x03, 0xD8 # 4DE4
    test   BYTE PTR [bx],0xff                    # 4DE6: F6 07 FF
    pop    ax                                    # 4DE9: 58
    je     L_4DB8                                # 4DEA: 74 CC
    mov    WORD PTR ds:KEY_EXPANSION_PTR,bx                   # 4DEC: 89 1E 6B 00
    mov    WORD PTR ds:KEY_EXPANSION_SEG,ds                   # 4DF0: 8C 1E 6D 00
    dec    BYTE PTR ds:KEY_EXPANSION_STATE                      # 4DF4: FE 0E 6A 00
    jmp    L_4E06                                # 4DF8: EB 0C
L_4DFA:
    push   bx                                    # 4DFA: 53
    dec    al                                    # 4DFB: FE C8
    jne    L_4E06                                # 4DFD: 75 07
    mov    ds:KEY_EXPANSION_STATE,al                            # 4DFF: A2 6A 00
    mov    al,0x20                               # 4E02: B0 20
    jmp    L_4DB8                                # 4E04: EB B2
L_4E06:
    push   ds                                    # 4E06: 1E
    lds    bx,DWORD PTR ds:KEY_EXPANSION_PTR                  # 4E07: C5 1E 6B 00
    mov    al,BYTE PTR [bx]                      # 4E0B: 8A 07
    pop    ds                                    # 4E0D: 1F
    inc    WORD PTR ds:KEY_EXPANSION_PTR                      # 4E0E: FF 06 6B 00
    .byte 0x0A, 0xC0 # 4E12
    je     L_4E18                                # 4E14: 74 02
    jns    L_4DB8                                # 4E16: 79 A0
L_4E18:
    .byte 0x32, 0xE4 # 4E18
    mov    bx,cs                                 # 4E1A: 8C CB
    mov    bl,BYTE PTR ds:KEY_EXPANSION_SEG_HI                   # 4E1C: 8A 1E 6E 00
    .byte 0x3A, 0xDF # 4E20
    jb     L_4E28                                # 4E22: 72 04
    inc    ah                                    # 4E24: FE C4
    and    al,0x7f                               # 4E26: 24 7F
L_4E28:
    mov    BYTE PTR ds:KEY_EXPANSION_STATE,ah                   # 4E28: 88 26 6A 00
    .byte 0x0A, 0xC0 # 4E2C
    jne    L_4DB8                                # 4E2E: 75 88
    pop    bx                                    # 4E30: 5B
    jmp    L_5FAB                                # 4E31: E9 77 11
    .byte 0x1E, 0x30, 0x2E, 0x20, 0x12, 0x21, 0x22, 0x23, 0x17, 0x24, 0x25, 0x26 # 4E34
    .byte 0x32, 0x31, 0x18, 0x19, 0x10, 0x13, 0x1F, 0x14, 0x16, 0x2F, 0x11, 0x2D # 4E40
    .byte 0x15, 0x2C # 4E4C
L_4E4E:
    push   bx                                    # 4E4E: 53
    push   cx                                    # 4E4F: 51
    push   si                                    # 4E50: 56
    mov    si,0x4e6c                             # 4E51: BE 6C 4E
    mov    cl,0xe                                # 4E54: B1 0E
L_4E56:
    cld                                          # 4E56: FC
    lods   al,BYTE PTR cs:[si]                   # 4E57: 2E AC
    .byte 0x3A, 0xE0 # 4E59
    je     L_4E66                                # 4E5B: 74 09
    inc    si                                    # 4E5D: 46
    dec    cl                                    # 4E5E: FE C9
    jne    L_4E56                                # 4E60: 75 F4
    .byte 0x32, 0xC0 # 4E62
    jmp    L_4E68                                # 4E64: EB 02
L_4E66:
    lods   al,BYTE PTR cs:[si]                   # 4E66: 2E AC
L_4E68:
    pop    si                                    # 4E68: 5E
    pop    cx                                    # 4E69: 59
    pop    bx                                    # 4E6A: 5B
    ret                                          # 4E6B: C3
    .byte 0x47, 0x0B, 0x48, 0x1E, 0x4B, 0x1D, 0x4D, 0x1C, 0x50, 0x1F, 0x1C, 0x0A # 4E6C
    .byte 0x74, 0x06, 0x73, 0x02, 0x76, 0x01, 0x52, 0x12, 0x53, 0x7F, 0x4F, 0x0E # 4E78
    .byte 0x75, 0x05, 0x77, 0x0C, 0x1F, 0x1E, 0x1D, 0x1C, 0x0D, 0x0C, 0x0B, 0x0A # 4E84
L_4E90:
    pushf                                        # 4E90: 9C
    push   bx                                    # 4E91: 53
    push   cx                                    # 4E92: 51
    push   dx                                    # 4E93: 52
    push   ax                                    # 4E94: 50
    cmp    al,0x7                                # 4E95: 3C 07
    je     L_4EE6                                # 4E97: 74 4D
    cmp    al,0xd                                # 4E99: 3C 0D
    jne    L_4EA7                                # 4E9B: 75 0A
    test   BYTE PTR ds:CNTOFL,0xff                 # 4E9D: F6 06 6F 00 FF
    je     L_4EA7                                # 4EA2: 74 03
    call   L_4F32                                # 4EA4: E8 8B 00
L_4EA7:
    call   L_50D6                                # 4EA7: E8 2C 02
    je     L_4EB0                                # 4EAA: 74 04
    cmp    al,0xff                               # 4EAC: 3C FF
    je     L_4EE9                                # 4EAE: 74 39
L_4EB0:
    cmp    al,0xc                                # 4EB0: 3C 0C
    je     L_4ED6                                # 4EB2: 74 22
    mov    bx,0x4e87                             # 4EB4: BB 87 4E
    mov    cx,0x8                                # 4EB7: B9 08 00
L_4EBA:
    inc    bx                                    # 4EBA: 43
    dec    cl                                    # 4EBB: FE C9
    js     L_4EDB                                # 4EBD: 78 1C
    cmp    al,BYTE PTR cs:[bx]                   # 4EBF: 2E 3A 07
    jne    L_4EBA                                # 4EC2: 75 F6
    shl    cl,1                                  # 4EC4: D0 E1
    .byte 0x8B, 0xD9 # 4EC6
    mov    cx,0x4ee9                             # 4EC8: B9 E9 4E
    push   cx                                    # 4ECB: 51
    push   WORD PTR cs:[bx+0x2fe1]               # 4ECC: 2E FF B7 E1 2F
    mov    bx,WORD PTR ds:CSRY                   # 4ED1: 8B 1E 56 00
    ret                                          # 4ED5: C3
L_4ED6:
    call   CLS                                   # 4ED6: E8 0E 04
    jmp    L_4EE9                                # 4ED9: EB 0E
L_4EDB:
    call   L_4F1C                                # 4EDB: E8 3E 00
    call   L_4EEF                                # 4EDE: E8 0E 00
    call   L_2FF1                                # 4EE1: E8 0D E1
    jmp    L_4EE9                                # 4EE4: EB 03
L_4EE6:
    call   BEEPS                                 # 4EE6: E8 24 09
L_4EE9:
    pop    ax                                    # 4EE9: 58
    pop    dx                                    # 4EEA: 5A
    pop    cx                                    # 4EEB: 59
    pop    bx                                    # 4EEC: 5B
    popf                                         # 4EED: 9D
    ret                                          # 4EEE: C3
L_4EEF:
    push   ax                                    # 4EEF: 50
    mov    bh,BYTE PTR ds:ACTIVE_PAGE                   # 4EF0: 8A 3E 49 00
    mov    bl,BYTE PTR ds:TEXT_WRITE_ATTRIBUTE                   # 4EF4: 8A 1E 4E 00
    mov    cx,0x1                                # 4EF8: B9 01 00
    mov    ah,0x9                                # 4EFB: B4 09
    int    0x10                                  # 4EFD: CD 10
    pop    ax                                    # 4EFF: 58
    ret                                          # 4F00: C3
L_4F01:
    push   bx                                    # 4F01: 53
    call   L_4F76                                # 4F02: E8 71 00
    call   L_4EEF                                # 4F05: E8 E7 FF
    pop    bx                                    # 4F08: 5B
    ret                                          # 4F09: C3
L_4F0A:
    push   bx                                    # 4F0A: 53
    call   L_4F76                                # 4F0B: E8 68 00
    mov    ah,0x8                                # 4F0E: B4 08
    int    0x10                                  # 4F10: CD 10
    pop    bx                                    # 4F12: 5B
    ret                                          # 4F13: C3
    .byte 0xE8, 0xF3, 0xFF, 0x8A, 0xE8, 0x8A, 0xCC, 0xC3 # 4F14
L_4F1C:
    mov    bx,WORD PTR ds:CSRY                   # 4F1C: 8B 1E 56 00
L_4F20:
    mov    WORD PTR ds:CSRY,bx                   # 4F20: 89 1E 56 00
    pushf                                        # 4F24: 9C
    push   bx                                    # 4F25: 53
    call   L_4F76                                # 4F26: E8 4D 00
    pop    bx                                    # 4F29: 5B
    popf                                         # 4F2A: 9D
    ret                                          # 4F2B: C3
PTRGPS:
    mov    al,ds:CSRX                            # 4F2C: A0 57 00
    dec    al                                    # 4F2F: FE C8
L_4F31:
    ret                                          # 4F31: C3
L_4F32:
    push   ax                                    # 4F32: 50
    mov    cl,BYTE PTR ds:CRTWID                   # 4F33: 8A 0E 29 00
    sub    cl,BYTE PTR ds:CSRX                   # 4F37: 2A 0E 57 00
    inc    cl                                    # 4F3B: FE C1
    mov    ch,0x0                                # 4F3D: B5 00
    mov    bh,BYTE PTR ds:ACTIVE_PAGE                   # 4F3F: 8A 3E 49 00
    mov    bl,BYTE PTR ds:SCREEN_FILL_ATTRIBUTE                   # 4F43: 8A 1E 4F 00
    mov    al,0x20                               # 4F47: B0 20
    mov    ah,0x9                                # 4F49: B4 09
    int    0x10                                  # 4F4B: CD 10
    mov    dx,WORD PTR ds:CSRY                   # 4F4D: 8B 16 56 00
    xchg   dl,dh                                 # 4F51: 86 F2
    dec    dh                                    # 4F53: FE CE
    dec    dl                                    # 4F55: FE CA
    mov    ah,0x2                                # 4F57: B4 02
    int    0x10                                  # 4F59: CD 10
    pop    ax                                    # 4F5B: 58
    ret                                          # 4F5C: C3
L_4F5D:
    push   bx                                    # 4F5D: 53
    call   L_4F76                                # 4F5E: E8 15 00
    mov    bh,BYTE PTR ds:ACTIVE_PAGE                   # 4F61: 8A 3E 49 00
    mov    bl,BYTE PTR ds:SCREEN_FILL_ATTRIBUTE                   # 4F65: 8A 1E 4F 00
    mov    cl,BYTE PTR ds:CRTWID                   # 4F69: 8A 0E 29 00
    mov    ch,0x0                                # 4F6D: B5 00
    mov    al,0x20                               # 4F6F: B0 20
    mov    ah,0x9                                # 4F71: B4 09
    int    0x10                                  # 4F73: CD 10
    pop    bx                                    # 4F75: 5B
L_4F76:
    push   ax                                    # 4F76: 50
    push   dx                                    # 4F77: 52
    .byte 0x8B, 0xD3 # 4F78
    xchg   dl,dh                                 # 4F7A: 86 F2
    dec    dh                                    # 4F7C: FE CE
    dec    dl                                    # 4F7E: FE CA
    mov    bh,BYTE PTR ds:ACTIVE_PAGE                   # 4F80: 8A 3E 49 00
    mov    ah,0x2                                # 4F84: B4 02
    int    0x10                                  # 4F86: CD 10
    pop    dx                                    # 4F88: 5A
    pop    ax                                    # 4F89: 58
    ret                                          # 4F8A: C3
L_4F8B:
    push   bx                                    # 4F8B: 53
    push   dx                                    # 4F8C: 52
    mov    cl,0x0                                # 4F8D: B1 00
    .byte 0x8A, 0xEF, 0x8A, 0xF3 # 4F8F
    call   L_4FB1                                # 4F93: E8 1B 00
    mov    ah,0x6                                # 4F96: B4 06
    int    0x10                                  # 4F98: CD 10
    jmp    L_4FAB                                # 4F9A: EB 0F
L_4F9C:
    push   bx                                    # 4F9C: 53
    push   dx                                    # 4F9D: 52
    mov    cl,0x0                                # 4F9E: B1 00
    .byte 0x8A, 0xEB, 0x8A, 0xF7 # 4FA0
    call   L_4FB1                                # 4FA4: E8 0A 00
    mov    ah,0x7                                # 4FA7: B4 07
    int    0x10                                  # 4FA9: CD 10
L_4FAB:
    call   L_4FCA                                # 4FAB: E8 1C 00
    pop    dx                                    # 4FAE: 5A
    pop    bx                                    # 4FAF: 5B
    ret                                          # 4FB0: C3
L_4FB1:
    call   L_4FC5                                # 4FB1: E8 11 00
    mov    dl,BYTE PTR ds:CRTWID                   # 4FB4: 8A 16 29 00
    dec    dl                                    # 4FB8: FE CA
    dec    dh                                    # 4FBA: FE CE
    dec    ch                                    # 4FBC: FE CD
    mov    al,0x1                                # 4FBE: B0 01
    mov    bh,BYTE PTR ds:SCREEN_FILL_ATTRIBUTE                   # 4FC0: 8A 3E 4F 00
    ret                                          # 4FC4: C3
L_4FC5:
    mov    al,ds:ACTIVE_PAGE                            # 4FC5: A0 49 00
    jmp    L_4FCD                                # 4FC8: EB 03
L_4FCA:
    mov    al,ds:VISUAL_PAGE                            # 4FCA: A0 4A 00
L_4FCD:
    call   L_50D6                                # 4FCD: E8 06 01
    jne    L_4FF2                                # 4FD0: 75 20
    mov    ah,BYTE PTR ds:BIOS_VIDEO_MODE                   # 4FD2: 8A 26 48 00
    cmp    ah,0x7                                # 4FD6: 80 FC 07
    je     L_4FF2                                # 4FD9: 74 17
    push   dx                                    # 4FDB: 52
    mov    dx,0x800                              # 4FDC: BA 00 08
    cmp    ah,0x2                                # 4FDF: 80 FC 02
    jb     L_4FE6                                # 4FE2: 72 02
    shl    dh,1                                  # 4FE4: D0 E6
L_4FE6:
    .byte 0x32, 0xE4 # 4FE6
    mul    dx                                    # 4FE8: F7 E2
    push   ds                                    # 4FEA: 1E
    mov    ds,dx                                 # 4FEB: 8E DA
    mov    ds:BDA_VIDEO_PAGE_START_ABS,ax          # 4FED: A3 4E 04 -- DS=0, BIOS data area
    pop    ds                                    # 4FF0: 1F
    pop    dx                                    # 4FF1: 5A
L_4FF2:
    ret                                          # 4FF2: C3
    .byte 0x9C, 0x53, 0x52, 0x50, 0xBA, 0x00, 0x00, 0xB4, 0x00, 0xCD, 0x17, 0x8A # 4FF3
    .byte 0xC4, 0x80, 0xE4, 0x28, 0x80, 0xFC, 0x28, 0x74, 0x0D, 0xF6, 0xC4, 0x08 # 4FFF
    .byte 0x75, 0x0C, 0xA8, 0x01, 0x74, 0x0D, 0xB2, 0x18, 0xEB, 0x06, 0xB2, 0x1B # 500B
    .byte 0xEB, 0x02, 0xB2, 0x19, 0xE9, 0xBA, 0xB7, 0x58, 0x50, 0x3C, 0x0D, 0xE9 # 5017
    .byte 0x5D, 0x0F, 0x58, 0x5A, 0x5B, 0x9D, 0xC3 # 5023
KEYS:
    cmp    al,0x93                               # 502A: 3C 93
    je     L_508E                                # 502C: 74 60
    cmp    al,0x95                               # 502E: 3C 95
    je     L_5078                                # 5030: 74 46
    cmp    al,0xdd                               # 5032: 3C DD
    je     L_507C                                # 5034: 74 46
    call   GETBYT                                # 5036: E8 E3 CE
    .byte 0x0A, 0xC0 # 5039
    je     L_5075                                # 503B: 74 38
    dec    al                                    # 503D: FE C8
    cmp    al,0xa                                # 503F: 3C 0A
    jae    L_5075                                # 5041: 73 32
    mov    dx,0x10                               # 5043: BA 10 00
    mul    dl                                    # 5046: F6 E2
    .byte 0x8A, 0xD0 # 5048
    add    dx,0x653                              # 504A: 81 C2 53 06
    push   dx                                    # 504E: 52
    call   SYNCHR                                # 504F: E8 A2 DD
    .byte ','                                  # 5052: 2C -- SYNCHR inline operand
    .byte 0xE8 # 5053 -- decoded continuation: call   0x1727
    rol    si,1                                  # 5054: D1 C6
    push   bx                                    # 5056: 53
    call   L_28A6                                # 5057: E8 4C D8
    mov    cl,BYTE PTR [bx]                      # 505A: 8A 0F
    cmp    cl,0xf                                # 505C: 80 F9 0F
    jb     L_5063                                # 505F: 72 02
    mov    cl,0xf                                # 5061: B1 0F
L_5063:
    inc    bx                                    # 5063: 43
    mov    si,WORD PTR [bx]                      # 5064: 8B 37
    pop    bx                                    # 5066: 5B
    pop    di                                    # 5067: 5F
    push   bx                                    # 5068: 53
    mov    ch,0x0                                # 5069: B5 00
    cld                                          # 506B: FC
    rep movs BYTE PTR es:[di],BYTE PTR ds:[si]   # 506C: F3 A4
    mov    BYTE PTR [di],ch                      # 506E: 88 2D
    call   L_4BE5                                # 5070: E8 72 FB
    pop    bx                                    # 5073: 5B
    ret                                          # 5074: C3
L_5075:
    jmp    FCERR                                # 5075: E9 E1 BF
L_5078:
    mov    al,0xff                               # 5078: B0 FF
    jmp    L_507E                                # 507A: EB 02
L_507C:
    mov    al,0x0                                # 507C: B0 00
L_507E:
    cmp    al,BYTE PTR ds:KEYSW                   # 507E: 3A 06 71 00
    mov    ds:KEYSW,al                            # 5082: A2 71 00
    je     L_508A                                # 5085: 74 03
    call   KEYDSP                                # 5087: E8 5E 00
L_508A:
    call   CHRGTR                                # 508A: E8 90 BE
    ret                                          # 508D: C3
L_508E:
    push   bx                                    # 508E: 53
    mov    si,0x653                              # 508F: BE 53 06
    mov    cx,0xa                                # 5092: B9 0A 00
L_5095:
    inc    ch                                    # 5095: FE C5
    push   si                                    # 5097: 56
    mov    al,0x46                               # 5098: B0 46
    call   OUTDO                                # 509A: E8 08 DB
    push   cx                                    # 509D: 51
    .byte 0x8A, 0xDD # 509E
    mov    bh,0x0                                # 50A0: B7 00
    call   LINPRT                                # 50A2: E8 AB 14
    mov    al,0x20                               # 50A5: B0 20
    call   OUTDO                                # 50A7: E8 FB DA
    pop    cx                                    # 50AA: 59
    pop    si                                    # 50AB: 5E
    push   si                                    # 50AC: 56
    push   cx                                    # 50AD: 51
L_50AE:
    cld                                          # 50AE: FC
    lods   al,BYTE PTR ds:[si]                   # 50AF: AC
    .byte 0x0A, 0xC0 # 50B0
    je     L_50B9                                # 50B2: 74 05
    call   L_50CA                                # 50B4: E8 13 00
    jmp    L_50AE                                # 50B7: EB F5
L_50B9:
    mov    al,0xd                                # 50B9: B0 0D
    call   OUTDO                                # 50BB: E8 E7 DA
    pop    cx                                    # 50BE: 59
    pop    si                                    # 50BF: 5E
    add    si,0x10                               # 50C0: 83 C6 10
    dec    cl                                    # 50C3: FE C9
    jne    L_5095                                # 50C5: 75 CE
    pop    bx                                    # 50C7: 5B
    jmp    L_508A                                # 50C8: EB C0
L_50CA:
    push   si                                    # 50CA: 56
    cmp    al,0xd                                # 50CB: 3C 0D
    jne    L_50D1                                # 50CD: 75 02
    mov    al,0x1b                               # 50CF: B0 1B
L_50D1:
    call   OUTDO                                # 50D1: E8 D1 DA
    pop    si                                    # 50D4: 5E
    ret                                          # 50D5: C3
L_50D6:
    push   ax                                    # 50D6: 50
    mov    al,ds:BIOS_VIDEO_MODE                            # 50D7: A0 48 00
    cmp    al,0x7                                # 50DA: 3C 07
    je     L_50E2                                # 50DC: 74 04
    cmp    al,0x4                                # 50DE: 3C 04
    jae    L_50E4                                # 50E0: 73 02
L_50E2:
    .byte 0x32, 0xC0 # 50E2
L_50E4:
    .byte 0x0A, 0xC0 # 50E4
    pop    ax                                    # 50E6: 58
    ret                                          # 50E7: C3
KEYDSP:
    push   bx                                    # 50E8: 53
    int    0xad                                  # 50E9: CD AD
    mov    dh,0x18                               # 50EB: B6 18
    mov    dl,0x0                                # 50ED: B2 00
    mov    bh,BYTE PTR ds:ACTIVE_PAGE                   # 50EF: 8A 3E 49 00
    mov    ah,0x2                                # 50F3: B4 02
    int    0x10                                  # 50F5: CD 10
    mov    al,ds:KEYSW                            # 50F7: A0 71 00
    .byte 0x0A, 0xC0 # 50FA
    jne    L_5111                                # 50FC: 75 13
    mov    bl,BYTE PTR ds:SCREEN_FILL_ATTRIBUTE                   # 50FE: 8A 1E 4F 00
    mov    cl,BYTE PTR ds:CRTWID                   # 5102: 8A 0E 29 00
    mov    ch,0x0                                # 5106: B5 00
    mov    ah,0x9                                # 5108: B4 09
    int    0x10                                  # 510A: CD 10
    call   L_4F1C                                # 510C: E8 0D FE
    pop    bx                                    # 510F: 5B
    ret                                          # 5110: C3
L_5111:
    mov    bl,0x7                                # 5111: B3 07
    call   L_50D6                                # 5113: E8 C0 FF
    jne    L_5121                                # 5116: 75 09
    mov    al,ds:TEXT_BACKGROUND_COLOR                            # 5118: A0 4C 00
    .byte 0x0A, 0xC0 # 511B
    jne    L_5121                                # 511D: 75 02
    mov    bl,0x70                               # 511F: B3 70
L_5121:
    mov    si,0x653                              # 5121: BE 53 06
    mov    ch,0x5                                # 5124: B5 05
    mov    al,ds:CRTWID                            # 5126: A0 29 00
    cmp    al,0x28                               # 5129: 3C 28
    mov    al,0x31                               # 512B: B0 31
    je     L_5131                                # 512D: 74 02
    mov    ch,0xa                                # 512F: B5 0A
L_5131:
    push   ax                                    # 5131: 50
    push   bx                                    # 5132: 53
    mov    bl,BYTE PTR ds:TEXT_WRITE_ATTRIBUTE                   # 5133: 8A 1E 4E 00
    call   L_5171                                # 5137: E8 37 00
    pop    bx                                    # 513A: 5B
    push   si                                    # 513B: 56
    mov    cl,0x6                                # 513C: B1 06
L_513E:
    push   cx                                    # 513E: 51
    cld                                          # 513F: FC
    lods   al,BYTE PTR ds:[si]                   # 5140: AC
    .byte 0x0A, 0xC0 # 5141
    pushf                                        # 5143: 9C
    push   si                                    # 5144: 56
    jne    L_5149                                # 5145: 75 02
    .byte 0x32, 0xC0 # 5147
L_5149:
    call   L_5171                                # 5149: E8 25 00
    pop    si                                    # 514C: 5E
    popf                                         # 514D: 9D
    jne    L_5151                                # 514E: 75 01
    dec    si                                    # 5150: 4E
L_5151:
    pop    cx                                    # 5151: 59
    dec    cl                                    # 5152: FE C9
    jne    L_513E                                # 5154: 75 E8
    call   L_516F                                # 5156: E8 16 00
    pop    si                                    # 5159: 5E
    add    si,0x10                               # 515A: 83 C6 10
    pop    ax                                    # 515D: 58
    inc    al                                    # 515E: FE C0
    cmp    al,0x3a                               # 5160: 3C 3A
    jb     L_5166                                # 5162: 72 02
    mov    al,0x30                               # 5164: B0 30
L_5166:
    dec    ch                                    # 5166: FE CD
    jne    L_5131                                # 5168: 75 C7
    call   L_4F1C                                # 516A: E8 AF FD
    pop    bx                                    # 516D: 5B
    ret                                          # 516E: C3
L_516F:
    .byte 0x32, 0xC0 # 516F
L_5171:
    push   bx                                    # 5171: 53
    .byte 0x0A, 0xC0 # 5172
    jne    L_517C                                # 5174: 75 06
    mov    al,0x20                               # 5176: B0 20
    mov    bl,BYTE PTR ds:SCREEN_FILL_ATTRIBUTE                   # 5178: 8A 1E 4F 00
L_517C:
    cmp    al,0xd                                # 517C: 3C 0D
    jne    L_5182                                # 517E: 75 02
    mov    al,0x1b                               # 5180: B0 1B
L_5182:
    push   cx                                    # 5182: 51
    mov    cx,0x1                                # 5183: B9 01 00
    mov    ah,0x9                                # 5186: B4 09
    int    0x10                                  # 5188: CD 10
    inc    dl                                    # 518A: FE C2
    mov    ah,0x2                                # 518C: B4 02
    int    0x10                                  # 518E: CD 10
    pop    cx                                    # 5190: 59
    pop    bx                                    # 5191: 5B
    ret                                          # 5192: C3
SCREEN:
    mov    cl,BYTE PTR ds:ACTIVE_PAGE                   # 5193: 8A 0E 49 00
    mov    ch,0x0                                # 5197: B5 00
    mov    ah,BYTE PTR ds:BIOS_VIDEO_MODE                   # 5199: 8A 26 48 00
    test   ah,0x1                                # 519D: F6 C4 01
    je     L_51A5                                # 51A0: 74 03
    or     ch,0x80                               # 51A2: 80 CD 80
L_51A5:
    cmp    ah,0x4                                # 51A5: 80 FC 04
    jb     L_51B3                                # 51A8: 72 09
    inc    ch                                    # 51AA: FE C5
    cmp    ah,0x6                                # 51AC: 80 FC 06
    jb     L_51B3                                # 51AF: 72 02
    inc    ch                                    # 51B1: FE C5
L_51B3:
    push   cx                                    # 51B3: 51
    cmp    al,0x2c                               # 51B4: 3C 2C
    je     L_51C4                                # 51B6: 74 0C
    call   GETBYT                                # 51B8: E8 61 CD
    pop    cx                                    # 51BB: 59
    .byte 0x8A, 0xE8 # 51BC
    push   cx                                    # 51BE: 51
    call   CHRGT2                                # 51BF: E8 5C BD
    je     L_5204                                # 51C2: 74 40
L_51C4:
    call   SYNCHR                                # 51C4: E8 2D DC
    .byte ','                                  # 51C7: 2C -- SYNCHR inline operand
    .byte 0x3C # 51C8 -- decoded continuation: cmp    al,0x2c
    sub    al,0x74                               # 51C9: 2C 74
    adc    ax,0x4de8                             # 51CB: 15 E8 4D
    int    0xa                                   # 51CE: CD 0A
    .byte 0xC0, 0x74, 0x02, 0xB0 # 51D0
    sbb    BYTE PTR [bx+di-0x80],0xe5            # 51D4: 80 59 80 E5
    add    cx,WORD PTR [bp+si]                   # 51D8: 03 0A
    call   L_3A2E                                # 51DA: E8 51 E8
    aas                                          # 51DD: 3F
    mov    bp,0x2374                             # 51DE: BD 74 23
    call   SYNCHR                                # 51E1: E8 10 DC
    .byte ','                                  # 51E4: 2C -- SYNCHR inline operand
    .byte 0x3C # 51E5 -- decoded continuation: cmp    al,0x2c
    sub    al,0x74                               # 51E6: 2C 74
    or     al,0xe8                               # 51E8: 0C E8
    xor    ch,cl                                 # 51EA: 30 CD
    pop    cx                                    # 51EC: 59
    .byte 0x8A, 0xC8 # 51ED
    push   cx                                    # 51EF: 51
    call   CHRGT2                                # 51F0: E8 2B BD
    je     L_5204                                # 51F3: 74 0F
    call   SYNCHR                                # 51F5: E8 FC DB
    .byte ','                                  # 51F8: 2C -- SYNCHR inline operand
    .byte 0xE8 # 51F9 -- decoded continuation: call   0x1f1c
    and    ch,cl                                 # 51FA: 20 CD
    .byte 0x8A, 0xF0 # 51FC
    pop    cx                                    # 51FE: 59
    jmp    L_5207                                # 51FF: EB 06
L_5201:
    jmp    FCERR                                # 5201: E9 55 BE
L_5204:
    pop    cx                                    # 5204: 59
    .byte 0x8A, 0xF1 # 5205
L_5207:
    mov    ah,BYTE PTR ds:CRTWID                   # 5207: 8A 26 29 00
    .byte 0x8A, 0xC5 # 520B
    and    al,0x7f                               # 520D: 24 7F
    .byte 0x0A, 0xC0 # 520F
    je     L_521D                                # 5211: 74 0A
    .byte 0x32, 0xD2, 0x0A, 0xD6, 0x0A, 0xD1 # 5213
    jne    L_5201                                # 5219: 75 E6
    jmp    L_5238                                # 521B: EB 1B
L_521D:
    cmp    ah,0x28                               # 521D: 80 FC 28
    je     L_522E                                # 5220: 74 0C
    cmp    dh,0x4                                # 5222: 80 FE 04
    jae    L_5201                                # 5225: 73 DA
    cmp    cl,0x4                                # 5227: 80 F9 04
    jb     L_5238                                # 522A: 72 0C
    jmp    L_5201                                # 522C: EB D3
L_522E:
    cmp    dh,0x8                                # 522E: 80 FE 08
    jae    L_5201                                # 5231: 73 CE
    cmp    cl,0x8                                # 5233: 80 F9 08
    jae    L_5201                                # 5236: 73 C9
L_5238:
    .byte 0x8A, 0xD1, 0x0A, 0xC0 # 5238
    je     L_525E                                # 523C: 74 20
    cmp    BYTE PTR ds:BIOS_VIDEO_MODE,0x7                  # 523E: 80 3E 48 00 07
    je     L_52A1                                # 5243: 74 5C
    mov    cl,0x6                                # 5245: B1 06
    cmp    al,0x2                                # 5247: 3C 02
    mov    ah,0x50                               # 5249: B4 50
    je     L_5277                                # 524B: 74 2A
    mov    ah,0x28                               # 524D: B4 28
    dec    cl                                    # 524F: FE C9
    dec    al                                    # 5251: FE C8
    jne    L_5201                                # 5253: 75 AC
    test   ch,0x80                               # 5255: F6 C5 80
    jne    L_5277                                # 5258: 75 1D
    dec    cl                                    # 525A: FE C9
    jmp    L_5277                                # 525C: EB 19
L_525E:
    mov    cl,0x2                                # 525E: B1 02
    cmp    ah,0x28                               # 5260: 80 FC 28
    je     L_526E                                # 5263: 74 09
    test   ch,0x80                               # 5265: F6 C5 80
    je     L_5277                                # 5268: 74 0D
    inc    cl                                    # 526A: FE C1
    jmp    L_5277                                # 526C: EB 09
L_526E:
    dec    cl                                    # 526E: FE C9
    test   ch,0x80                               # 5270: F6 C5 80
    jne    L_5277                                # 5273: 75 02
    dec    cl                                    # 5275: FE C9
L_5277:
    mov    BYTE PTR ds:CRTWID,ah                   # 5277: 88 26 29 00
    mov    ax,ds:BIOS_VIDEO_MODE                            # 527B: A1 48 00
    mov    BYTE PTR ds:BIOS_VIDEO_MODE,cl                   # 527E: 88 0E 48 00
    mov    WORD PTR ds:ACTIVE_PAGE,dx                   # 5282: 89 16 49 00
    .byte 0x3A, 0xC1 # 5286
    je     L_52A4                                # 5288: 74 1A
    mov    ax,0x7                                # 528A: B8 07 00
    mov    ds:TEXT_FOREGROUND_COLOR,ax                            # 528D: A3 4B 00
    xchg   ah,al                                 # 5290: 86 C4
    mov    ds:BORDER_PALETTE_VALUE,ax                            # 5292: A3 4D 00
    mov    BYTE PTR ds:SCREEN_FILL_ATTRIBUTE,ah                   # 5295: 88 26 4F 00
    call   L_50D6                                # 5299: E8 3A FE
    je     L_52A1                                # 529C: 74 03
    mov    ds:SCREEN_FILL_ATTRIBUTE,al                            # 529E: A2 4F 00
L_52A1:
    call   L_5312                                # 52A1: E8 6E 00
L_52A4:
    mov    al,ds:VISUAL_PAGE                            # 52A4: A0 4A 00
    mov    ah,0x5                                # 52A7: B4 05
    int    0x10                                  # 52A9: CD 10
    ret                                          # 52AB: C3
L_52AC:
    cmp    al,BYTE PTR ds:CRTWID                   # 52AC: 3A 06 29 00
    je     L_52E6                                # 52B0: 74 34
    mov    ah,BYTE PTR ds:BIOS_VIDEO_MODE                   # 52B2: 8A 26 48 00
    cmp    al,0x50                               # 52B6: 3C 50
    je     L_52C1                                # 52B8: 74 07
    cmp    al,0x28                               # 52BA: 3C 28
    je     L_52C1                                # 52BC: 74 03
    jmp    FCERR                                # 52BE: E9 98 BD
L_52C1:
    cmp    ah,0x7                                # 52C1: 80 FC 07
    jne    L_52CA                                # 52C4: 75 04
    mov    al,0x50                               # 52C6: B0 50
    jmp    L_52E6                                # 52C8: EB 1C
L_52CA:
    xor    ah,0x2                                # 52CA: 80 F4 02
    cmp    ah,0x7                                # 52CD: 80 FC 07
    jne    L_52D4                                # 52D0: 75 02
    dec    ah                                    # 52D2: FE CC
L_52D4:
    push   ax                                    # 52D4: 50
    mov    ds:CRTWID,al                            # 52D5: A2 29 00
    mov    BYTE PTR ds:BIOS_VIDEO_MODE,ah                   # 52D8: 88 26 48 00
    mov    WORD PTR ds:ACTIVE_PAGE,0x0                  # 52DC: C7 06 49 00 00 00
    call   L_5312                                # 52E2: E8 2D 00
    pop    ax                                    # 52E5: 58
L_52E6:
    ret                                          # 52E6: C3
# C1.20 replaces C1.10's hard-coded 39/79 right edge with CRTWID-1,
# independently confirming DS:0029 as CRTWID.
CLS:
    push   bx                                    # 52E7: 53
    call   L_4FC5                                # 52E8: E8 DA FC
    mov    dl,0x27                               # 52EB: B2 27
    cmp    BYTE PTR ds:CRTWID,0x28                 # 52ED: 80 3E 29 00 28
    je     L_52F6                                # 52F2: 74 02
    mov    dl,0x4f                               # 52F4: B2 4F
L_52F6:
    mov    dh,0x18                               # 52F6: B6 18
    mov    bh,BYTE PTR ds:SCREEN_FILL_ATTRIBUTE                   # 52F8: 8A 3E 4F 00
    mov    cx,0x0                                # 52FC: B9 00 00
    .byte 0x8A, 0xC1 # 52FF
    mov    ah,0x6                                # 5301: B4 06
    int    0x10                                  # 5303: CD 10
    mov    dx,0x0                                # 5305: BA 00 00
    mov    bh,BYTE PTR ds:ACTIVE_PAGE                   # 5308: 8A 3E 49 00
    mov    ah,0x2                                # 530C: B4 02
    int    0x10                                  # 530E: CD 10
    jmp    L_5321                                # 5310: EB 0F
L_5312:
    push   bx                                    # 5312: 53
    mov    cx,0x0                                # 5313: B9 00 00
    mov    WORD PTR ds:ACTIVE_PAGE,cx                   # 5316: 89 0E 49 00
    mov    al,ds:BIOS_VIDEO_MODE                            # 531A: A0 48 00
    mov    ah,0x0                                # 531D: B4 00
    int    0x10                                  # 531F: CD 10
L_5321:
    call   L_30E1                                # 5321: E8 BD DD
    call   L_4BF0                                # 5324: E8 C9 F8
    call   IBM_GRAPHICS_MODE_INIT                                # 5327: E8 8A F7
    call   L_4FCA                                # 532A: E8 9D FC
    pop    bx                                    # 532D: 5B
    ret                                          # 532E: C3
COLOR:
    call   L_50D6                                # 532F: E8 A4 FD
    je     L_538F                                # 5332: 74 5B
    mov    cl,0x0                                # 5334: B1 00
    mov    si,0x51                               # 5336: BE 51 00
    cmp    BYTE PTR ds:BIOS_VIDEO_MODE,0x6                  # 5339: 80 3E 48 00 06
    jne    L_5343                                # 533E: 75 03
    jmp    FCERR                                # 5340: E9 16 BD
L_5343:
    mov    ch,BYTE PTR [si]                      # 5343: 8A 2C
    push   si                                    # 5345: 56
    push   cx                                    # 5346: 51
    call   CHRGT2                                # 5347: E8 D4 BB
    je     L_538C                                # 534A: 74 40
    cmp    al,0x2c                               # 534C: 3C 2C
    je     L_5357                                # 534E: 74 07
    call   GETBYT                                # 5350: E8 C9 CB
    pop    cx                                    # 5353: 59
    .byte 0x8A, 0xE8 # 5354
    push   cx                                    # 5356: 51
L_5357:
    pop    cx                                    # 5357: 59
    push   cx                                    # 5358: 51
    push   bx                                    # 5359: 53
    .byte 0x8A, 0xF9, 0x8A, 0xDD # 535A
    cmp    bh,0x0                                # 535E: 80 FF 00
    jne    L_536B                                # 5361: 75 08
    cmp    bl,0x8                                # 5363: 80 FB 08
    jb     L_536B                                # 5366: 72 03
    or     bl,0x10                               # 5368: 80 CB 10
L_536B:
    mov    ah,0xb                                # 536B: B4 0B
    int    0x10                                  # 536D: CD 10
    pop    bx                                    # 536F: 5B
    call   CHRGT2                                # 5370: E8 AB BB
    je     L_5378                                # 5373: 74 03
    call   CHRGTR                                # 5375: E8 A5 BB
L_5378:
    pop    cx                                    # 5378: 59
    pop    si                                    # 5379: 5E
    mov    BYTE PTR [si],ch                      # 537A: 88 2C
    je     L_5386                                # 537C: 74 08
    inc    si                                    # 537E: 46
    inc    cl                                    # 537F: FE C1
    cmp    cl,0x4                                # 5381: 80 F9 04
    jb     L_5343                                # 5384: 72 BD
L_5386:
    mov    BYTE PTR ds:SCREEN_FILL_ATTRIBUTE,0x0                  # 5386: C6 06 4F 00 00
    ret                                          # 538B: C3
L_538C:
    pop    cx                                    # 538C: 59
    pop    si                                    # 538D: 5E
    ret                                          # 538E: C3
L_538F:
    push   WORD PTR ds:BORDER_PALETTE_VALUE                      # 538F: FF 36 4D 00
    push   WORD PTR ds:TEXT_FOREGROUND_COLOR                      # 5393: FF 36 4B 00
    cmp    al,0x2c                               # 5397: 3C 2C
    je     L_53AB                                # 5399: 74 10
    call   GETBYT                                # 539B: E8 7E CB
    cmp    al,0x20                               # 539E: 3C 20
    jae    L_53BA                                # 53A0: 73 18
    pop    cx                                    # 53A2: 59
    .byte 0x8A, 0xC8 # 53A3
    push   cx                                    # 53A5: 51
    call   CHRGT2                                # 53A6: E8 75 BB
    je     L_53D7                                # 53A9: 74 2C
L_53AB:
    call   SYNCHR                                # 53AB: E8 46 DA
    .byte ','                                  # 53AE: 2C -- SYNCHR inline operand
    cmp    al,0x2c                                # 53AF: 3C 2C
    je     L_53C6                                # 53B1: 74 13
    call   GETBYT                                # 53B3: E8 66 CB
    cmp    al,0x10                               # 53B6: 3C 10
    jb     L_53BD                                # 53B8: 72 03
L_53BA:
    jmp    FCERR                                # 53BA: E9 9C BC
L_53BD:
    pop    cx                                    # 53BD: 59
    .byte 0x8A, 0xE8 # 53BE
    push   cx                                    # 53C0: 51
    call   CHRGT2                                # 53C1: E8 5A BB
    je     L_53D7                                # 53C4: 74 11
L_53C6:
    call   SYNCHR                                # 53C6: E8 2B DA
    .byte ','                                  # 53C9: 2C -- SYNCHR inline operand
    call   GETBYT                                # 53CA: E8 4F CB
    .byte 0x3C, 0x10, 0x73, 0xE9, 0x59, 0x5A, 0x8A, 0xD0, 0x52, 0x51 # 53CD
L_53D7:
    pop    cx                                    # 53D7: 59
    pop    dx                                    # 53D8: 5A
    .byte 0x8A, 0xF1 # 53D9
    and    dh,0xf                                # 53DB: 80 E6 0F
    mov    WORD PTR ds:TEXT_FOREGROUND_COLOR,cx                   # 53DE: 89 0E 4B 00
    .byte 0x8A, 0xC5 # 53E2
    shl    al,1                                  # 53E4: D0 E0
    and    al,0x10                               # 53E6: 24 10
    .byte 0x0A, 0xC2 # 53E8
    and    ch,0x7                                # 53EA: 80 E5 07
    shl    ch,1                                  # 53ED: D0 E5
    shl    ch,1                                  # 53EF: D0 E5
    shl    ch,1                                  # 53F1: D0 E5
    shl    ch,1                                  # 53F3: D0 E5
    test   cl,0x10                               # 53F5: F6 C1 10
    je     L_53FD                                # 53F8: 74 03
    or     ch,0x80                               # 53FA: 80 CD 80
L_53FD:
    .byte 0x0A, 0xEE # 53FD
    push   bx                                    # 53FF: 53
    .byte 0x8A, 0xD8 # 5400
    mov    bh,0x0                                # 5402: B7 00
    and    al,0xf                                # 5404: 24 0F
    mov    ds:BORDER_PALETTE_VALUE,al                            # 5406: A2 4D 00
    mov    BYTE PTR ds:TEXT_WRITE_ATTRIBUTE,ch                   # 5409: 88 2E 4E 00
    mov    BYTE PTR ds:SCREEN_FILL_ATTRIBUTE,ch                   # 540D: 88 2E 4F 00
    mov    ah,0xb                                # 5411: B4 0B
    int    0x10                                  # 5413: CD 10
    pop    bx                                    # 5415: 5B
    ret                                          # 5416: C3
LOCATE:
    push   WORD PTR ds:CSRY                      # 5417: FF 36 56 00
    cmp    al,0x2c                               # 541B: 3C 2C
    je     L_543F                                # 541D: 74 20
    call   GETBYT                                # 541F: E8 FA CA
    .byte 0x0A, 0xC0 # 5422
    je     L_5481                                # 5424: 74 5B
    cmp    al,0x1a                               # 5426: 3C 1A
    jae    L_5481                                # 5428: 73 57
    mov    ah,BYTE PTR ds:KEYSW                   # 542A: 8A 26 71 00
    .byte 0x0A, 0xE4 # 542E
    je     L_5436                                # 5430: 74 04
    cmp    al,0x19                               # 5432: 3C 19
    jae    L_5481                                # 5434: 73 4B
L_5436:
    pop    dx                                    # 5436: 5A
    .byte 0x8A, 0xD0 # 5437
    push   dx                                    # 5439: 52
    call   CHRGT2                                # 543A: E8 E1 BA
    je     L_54BA                                # 543D: 74 7B
L_543F:
    call   SYNCHR                                # 543F: E8 B2 D9
    .byte ','                                  # 5442: 2C -- SYNCHR inline operand
    .byte 0x3C # 5443 -- decoded continuation: cmp    al,0x2c
    sub    al,0x74                               # 5444: 2C 74
    sbb    al,ch                                 # 5446: 18 E8
    ror    dl,cl                                 # 5448: D2 CA
    .byte 0x0A, 0xC0 # 544A
    je     L_5481                                # 544C: 74 33
    mov    ah,BYTE PTR ds:CRTWID                   # 544E: 8A 26 29 00
    .byte 0x3A, 0xE0 # 5452
    jb     L_5481                                # 5454: 72 2B
    pop    dx                                    # 5456: 5A
    .byte 0x8A, 0xF0 # 5457
    push   dx                                    # 5459: 52
    call   CHRGT2                                # 545A: E8 C1 BA
    je     L_54BA                                # 545D: 74 5B
    push   WORD PTR ds:CURSOR_SHAPE                      # 545F: FF 36 68 00
    call   SYNCHR                                # 5463: E8 8E D9
    .byte ','                                  # 5466: 2C -- SYNCHR inline operand
    .byte 0x3C # 5467 -- decoded continuation: cmp    al,0x2c
    sub    al,0x74                               # 5468: 2C 74
    sbb    ax,bp                                 # 546A: 19 E8
    scas   al,BYTE PTR es:[di]                   # 546C: AE
    retf   0xc00a                                # 546D: CA 0A C0
    .byte 0xB0, 0x00, 0x75, 0x02, 0xB0, 0x20, 0x59, 0x0A, 0xE8, 0x51, 0xE8, 0xA1 # 5470
    .byte 0xBA, 0x74, 0x2D, 0xEB, 0x03 # 547C
L_5481:
    jmp    FCERR                                # 5481: E9 D5 BB
    call   SYNCHR                                # 5484: E8 6D D9
    .byte ','                                    # 5487: SYNCHR inline operand
    call   GETBYT                                # 5488: E8 91 CA
    cmp    al,0x20                               # 548B: 3C 20
    jae    L_5481                                # 548D: 73 F2
    pop    cx                                    # 548F: 59
    and    ch,0x20                               # 5490: 80 E5 20
    .byte 0x0A, 0xE8                             # 5493: OR CH,AL; historical direction-bit encoding
    .byte 0x8A, 0xC8                             # 5495: MOV CL,AL; historical direction-bit encoding
    push   cx                                    # 5497: 51
    call   CHRGT2                                # 5498: E8 83 BA
    je     L_54AC                                # 549B: 74 0F
    call   SYNCHR                                # 549D: E8 54 D9
    .byte ','                                    # 54A0: SYNCHR inline operand
    call   GETBYT                                # 54A1: E8 78 CA
    cmp    al,0x20                               # 54A4: 3C 20
    jae    L_5481                                # 54A6: 73 D9
    .byte 0x59, 0x8A, 0xC8, 0x51                 # 54A8: POP CX; MOV CL,AL (historical encoding); PUSH CX
L_54AC:
    .byte 0x59, 0x51, 0x80, 0xE5, 0x0F, 0x89, 0x0E, 0x68 # 54AC
    .byte 0x00, 0x59, 0xB4, 0x01, 0xCD, 0x10 # 54B4
L_54BA:
    pop    dx                                    # 54BA: 5A
    mov    WORD PTR ds:CSRY,dx                   # 54BB: 89 16 56 00
    xchg   dl,dh                                 # 54BF: 86 F2
    dec    dh                                    # 54C1: FE CE
    dec    dl                                    # 54C3: FE CA
    push   bx                                    # 54C5: 53
    mov    bh,BYTE PTR ds:ACTIVE_PAGE                   # 54C6: 8A 3E 49 00
    mov    ah,0x2                                # 54CA: B4 02
    int    0x10                                  # 54CC: CD 10
    pop    bx                                    # 54CE: 5B
    ret                                          # 54CF: C3
L_54D0:
    push   ax                                    # 54D0: 50
    mov    al,0x0                                # 54D1: B0 00
    jmp    L_54D8                                # 54D3: EB 03
L_54D5:
    push   ax                                    # 54D5: 50
    mov    al,0x20                               # 54D6: B0 20
L_54D8:
    pushf                                        # 54D8: 9C
    push   cx                                    # 54D9: 51
    push   bx                                    # 54DA: 53
    push   ax                                    # 54DB: 50
    call   L_4F1C                                # 54DC: E8 3D FA
    pop    ax                                    # 54DF: 58
    pop    bx                                    # 54E0: 5B
    mov    cx,WORD PTR ds:CURSOR_SHAPE                   # 54E1: 8B 0E 68 00
    test   BYTE PTR ds:F_INST,0xff                 # 54E5: F6 06 72 00 FF
    je     L_54EE                                # 54EA: 74 02
    mov    ch,0x4                                # 54EC: B5 04
L_54EE:
    .byte 0x0A, 0xE8 # 54EE
    mov    ah,0x1                                # 54F0: B4 01
    int    0x10                                  # 54F2: CD 10
    pop    cx                                    # 54F4: 59
    popf                                         # 54F5: 9D
    pop    ax                                    # 54F6: 58
    ret                                          # 54F7: C3
    .byte 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF # 54F8
    .byte 0xFF, 0xFF, 0xFF, 0xFF # 5504
L_5508:
    push   ax                                    # 5508: 50
    pushf                                        # 5509: 9C
    call   L_50D6                                # 550A: E8 C9 FB
    je     L_555A                                # 550D: 74 4B
    push   bx                                    # 550F: 53
    push   cx                                    # 5510: 51
    push   dx                                    # 5511: 52
    mov    si,es                                 # 5512: 8C C6
    mov    di,0x0                                # 5514: BF 00 00
    mov    es,di                                 # 5517: 8E C7
    push   WORD PTR es:0x7c                      # 5519: 26 FF 36 7C 00
    push   WORD PTR es:0x7e                      # 551E: 26 FF 36 7E 00
    mov    WORD PTR es:0x7c,0x54f8               # 5523: 26 C7 06 7C 00 F8 54
    mov    WORD PTR es:0x7e,cs                   # 552A: 26 8C 0E 7E 00
    mov    es,si                                 # 552F: 8E C6
    mov    al,0x81                               # 5531: B0 81
    add    al,BYTE PTR ds:F_INST                   # 5533: 02 06 72 00
    mov    bl,0x83                               # 5537: B3 83
    mov    bh,BYTE PTR ds:ACTIVE_PAGE                   # 5539: 8A 3E 49 00
    mov    cx,0x1                                # 553D: B9 01 00
    mov    ah,0x9                                # 5540: B4 09
    int    0x10                                  # 5542: CD 10
    mov    si,es                                 # 5544: 8C C6
    mov    di,0x0                                # 5546: BF 00 00
    mov    es,di                                 # 5549: 8E C7
    pop    WORD PTR es:0x7e                      # 554B: 26 8F 06 7E 00
    pop    WORD PTR es:0x7c                      # 5550: 26 8F 06 7C 00
    mov    es,si                                 # 5555: 8E C6
    pop    dx                                    # 5557: 5A
    pop    cx                                    # 5558: 59
    pop    bx                                    # 5559: 5B
L_555A:
    popf                                         # 555A: 9D
    pop    ax                                    # 555B: 58
    ret                                          # 555C: C3
L_555D:
    call   CHRGTR                                # 555D: E8 BD B9
    mov    al,ds:CSRY                            # 5560: A0 56 00
    jmp    L_4BD8                                # 5563: E9 72 F6
L_5566:
    call   CHRGTR                                # 5566: E8 B4 B9
    call   L_55D1                                # 5569: E8 65 00
    .byte 0x0A, 0xEE # 556C
    jne    L_55C6                                # 556E: 75 56
    .byte 0x0A, 0xEA, 0x0A, 0xE9 # 5570
    je     L_55C6                                # 5574: 74 50
    mov    ah,BYTE PTR ds:CRTWID                   # 5576: 8A 26 29 00
    .byte 0x3A, 0xE2 # 557A
    jb     L_55C6                                # 557C: 72 48
    cmp    cl,0x1a                               # 557E: 80 F9 1A
    jae    L_55C6                                # 5581: 73 43
    mov    al,ds:KEYSW                            # 5583: A0 71 00
    .byte 0x0A, 0xC0 # 5586
    je     L_558F                                # 5588: 74 05
    cmp    cl,0x19                               # 558A: 80 F9 19
    jae    L_55C6                                # 558D: 73 37
L_558F:
    push   bx                                    # 558F: 53
    .byte 0x8A, 0xF1 # 5590
    dec    dh                                    # 5592: FE CE
    dec    dl                                    # 5594: FE CA
    mov    bh,BYTE PTR ds:ACTIVE_PAGE                   # 5596: 8A 3E 49 00
    mov    ah,0x2                                # 559A: B4 02
    int    0x10                                  # 559C: CD 10
    mov    ah,0x8                                # 559E: B4 08
    int    0x10                                  # 55A0: CD 10
    pop    bx                                    # 55A2: 5B
    push   ax                                    # 55A3: 50
    call   CHRGT2                                # 55A4: E8 77 B9
    cmp    al,0x2c                               # 55A7: 3C 2C
    je     L_55AF                                # 55A9: 74 04
    mov    al,0x0                                # 55AB: B0 00
    jmp    L_55B6                                # 55AD: EB 07
L_55AF:
    call   SYNCHR                                # 55AF: E8 42 D8
    .byte ','                                    # 55B2: SYNCHR inline operand
    call   GETBYT                                # 55B3: E8 66 C9
L_55B6:
    push   ax                                    # 55B6: 50
    call   SYNCHR                                # 55B7: E8 3A D8
    .byte ')'                                    # 55BA: SYNCHR inline operand
    pop    ax                                    # 55BB: 58
    .byte 0x0A, 0xC0                             # 55BC: OR AL,AL; historical direction-bit encoding
    pop    ax                                    # 55BE: 58
    je     L_55C3                                # 55BF: 74 02
    .byte 0x8A, 0xC4                             # 55C1: MOV AL,AH; historical direction-bit encoding
L_55C3:
    jmp    L_4BD8                                # 55C3: E9 12 F6
L_55C6:
    jmp    FCERR                                # 55C6: E9 90 BA
L_55C9:
    call   L_55D1                                # 55C9: E8 05 00
    call   SYNCHR                                # 55CC: E8 25 D8
    .byte ')'                                    # 55CF: SYNCHR inline operand
    ret                                          # 55D0: C3
L_55D1:
    call   SYNCHR                                # 55D1: E8 20 D8
    .byte '('                                    # 55D4: SYNCHR inline operand
    call   GETIN2                                # 55D5: E8 32 C9
    push   dx                                    # 55D8: 52
    call   SYNCHR                                # 55D9: E8 18 D8
    .byte ','                                    # 55DC: SYNCHR inline operand
    call   GETIN2                                # 55DD: E8 2A C9
    pop    cx                                    # 55E0: 59
    ret                                          # 55E1: C3
L_55E2:
    call   CHRGTR                                # 55E2: E8 38 B9
    cmp    al,0x95                               # 55E5: 3C 95
    je     L_55F1                                # 55E7: 74 08
    call   SYNCHR                                # 55E9: E8 08 D8
    .byte TOK_OFF                              # 55EC: DD -- SYNCHR inline operand
    .byte 0x32, 0xC0                            # 55ED: XOR AL,AL; historical direction-bit encoding
    jmp    L_55F6                                # 55EF: EB 05
L_55F1:
    call   CHRGTR                                # 55F1: E8 29 B9
    mov    al,0xff                               # 55F4: B0 FF
L_55F6:
    mov    ds:PEN_ENABLED,al                            # 55F6: A2 34 00
    ret                                          # 55F9: C3
PENF:
    mov    al,ds:PEN_ENABLED                            # 55FA: A0 34 00
    .byte 0x0A, 0xC0 # 55FD
    je     L_5631                                # 55FF: 74 30
    call   CONINT                                # 5601: E8 1B C9
    cmp    al,0xa                                # 5604: 3C 0A
    jae    L_5631                                # 5606: 73 29
    push   bx                                    # 5608: 53
    push   si                                    # 5609: 56
    mov    dx,0x561a                             # 560A: BA 1A 56
    push   dx                                    # 560D: 52
    .byte 0x32, 0xE4 # 560E
    shl    ax,1                                  # 5610: D1 E0
    .byte 0x8B, 0xF0 # 5612
    push   WORD PTR cs:[si+0x561d]               # 5614: 2E FF B4 1D 56
    ret                                          # 5619: C3
    .byte 0x5E, 0x5B, 0xC3, 0x34, 0x56, 0x3F, 0x56, 0x46, 0x56, 0x4C, 0x56, 0x6B # 561A
    .byte 0x56, 0x72, 0x56, 0x78, 0x56, 0x80, 0x56, 0x88, 0x56, 0x90, 0x56 # 5626
L_5631:
    jmp    FCERR                                # 5631: E9 25 BA
    .byte 0xBB, 0x35, 0x00, 0x8A, 0x07, 0xC6, 0x07, 0x00, 0xE9, 0x9F, 0xF5, 0x8B # 5634
    .byte 0x1E, 0x37, 0x00, 0xE9, 0xC6, 0x0E, 0xA0, 0x39, 0x00, 0xE9, 0x8C, 0xF5 # 5640
    .byte 0xB4, 0x04, 0xCD, 0x10, 0x50, 0x0A, 0xE4, 0x74, 0x0C, 0x89, 0x1E, 0x3A # 564C
    .byte 0x00, 0x88, 0x2E, 0x3C, 0x00, 0x89, 0x16, 0x3F, 0x00, 0x58, 0x8A, 0xC4 # 5658
    .byte 0xFE, 0xC8, 0xF6, 0xD0, 0xE9, 0x73, 0xF5, 0x8B, 0x1E, 0x3A, 0x00, 0xE9 # 5664
    .byte 0x9A, 0x0E, 0xA0, 0x3C, 0x00, 0xE9, 0x60, 0xF5, 0xA0, 0x3E, 0x00, 0xFE # 5670
    .byte 0xC0, 0xE9, 0x58, 0xF5, 0xA0, 0x3D, 0x00, 0xFE, 0xC0, 0xE9, 0x50, 0xF5 # 567C
    .byte 0xA0, 0x40, 0x00, 0xFE, 0xC0, 0xE9, 0x48, 0xF5, 0xA0, 0x3F, 0x00, 0xFE # 5688
    .byte 0xC0, 0xE9, 0x40, 0xF5 # 5694
STICKF:
    call   CONINT                                # 5698: E8 84 C8
    .byte 0x0A, 0xC0 # 569B
    je     L_56B1                                # 569D: 74 12
    cmp    al,0x4                                # 569F: 3C 04
    jae    L_56F7                                # 56A1: 73 54
    mov    ah,0x0                                # 56A3: B4 00
    push   bx                                    # 56A5: 53
    mov    bx,0x41                               # 56A6: BB 41 00
    .byte 0x03, 0xD8 # 56A9
    mov    al,BYTE PTR [bx]                      # 56AB: 8A 07
    pop    bx                                    # 56AD: 5B
    jmp    L_4BD8                                # 56AE: E9 27 F5
L_56B1:
    push   bx                                    # 56B1: 53
    mov    dx,0x201                              # 56B2: BA 01 02
    mov    cx,0x101                              # 56B5: B9 01 01
    mov    bx,0xf                                # 56B8: BB 0F 00
    cli                                          # 56BB: FA
    out    dx,al                                 # 56BC: EE
L_56BD:
    in     al,dx                                 # 56BD: EC
    and    al,0xf                                # 56BE: 24 0F
    .byte 0x3A, 0xC3 # 56C0
    loope  L_56BD                                # 56C2: E1 F9
    jcxz   L_56D1                                # 56C4: E3 0B
    .byte 0x32, 0xC3, 0x8A, 0xE1 # 56C6
    push   ax                                    # 56CA: 50
    inc    bh                                    # 56CB: FE C7
    .byte 0x32, 0xD8 # 56CD
    jmp    L_56BD                                # 56CF: EB EC
L_56D1:
    .byte 0x0A, 0xFF # 56D1
    je     L_56EF                                # 56D3: 74 1A
    .byte 0x8A, 0xD7 # 56D5
L_56D7:
    mov    bx,0x41                               # 56D7: BB 41 00
    mov    cx,0x4                                # 56DA: B9 04 00
    pop    ax                                    # 56DD: 58
    not    ah                                    # 56DE: F6 D4
    .byte 0x02, 0xE2 # 56E0
L_56E2:
    shr    al,1                                  # 56E2: D0 E8
    jae    L_56E8                                # 56E4: 73 02
    mov    BYTE PTR [bx],ah                      # 56E6: 88 27
L_56E8:
    inc    bx                                    # 56E8: 43
    loop   L_56E2                                # 56E9: E2 F7
    dec    dl                                    # 56EB: FE CA
    jne    L_56D7                                # 56ED: 75 E8
L_56EF:
    sti                                          # 56EF: FB
    pop    bx                                    # 56F0: 5B
    mov    al,ds:STICK_VALUES                            # 56F1: A0 41 00
    jmp    L_4BD8                                # 56F4: E9 E1 F4
L_56F7:
    jmp    FCERR                                # 56F7: E9 5F B9
L_56FA:
    call   CHRGTR                                # 56FA: E8 20 B8
    cmp    al,0x95                               # 56FD: 3C 95
    je     L_5709                                # 56FF: 74 08
    call   SYNCHR                                # 5701: E8 F0 D6
    .byte TOK_OFF                              # 5704: DD -- SYNCHR inline operand
    .byte 0x32, 0xC0                            # 5705: XOR AL,AL; historical direction-bit encoding
    jmp    L_570E                                # 5707: EB 05
L_5709:
    call   CHRGTR                                # 5709: E8 11 B8
    mov    al,0xff                               # 570C: B0 FF
L_570E:
    mov    ds:STRIG_ENABLED,al                            # 570E: A2 45 00
    ret                                          # 5711: C3
STRIGF:
    mov    al,ds:STRIG_ENABLED                            # 5712: A0 45 00
    .byte 0x0A, 0xC0 # 5715
    je     L_56F7                                # 5717: 74 DE
    call   CONINT                                # 5719: E8 03 C8
    cmp    al,0x4                                # 571C: 3C 04
    jae    L_56F7                                # 571E: 73 D7
    test   al,0x1                                # 5720: A8 01
    je     L_5732                                # 5722: 74 0E
    mov    ah,0x10                               # 5724: B4 10
    dec    al                                    # 5726: FE C8
    je     L_572C                                # 5728: 74 02
    mov    ah,0x40                               # 572A: B4 40
L_572C:
    call   L_57FF                                # 572C: E8 D0 00
    jmp    L_4BDE                                # 572F: E9 AC F4
L_5732:
    push   bx                                    # 5732: 53
    mov    bx,0x46                               # 5733: BB 46 00
    .byte 0x0A, 0xC0 # 5736
    je     L_573B                                # 5738: 74 01
    inc    bx                                    # 573A: 43
L_573B:
    mov    al,BYTE PTR [bx]                      # 573B: 8A 07
    mov    BYTE PTR [bx],0x0                     # 573D: C6 07 00
    pop    bx                                    # 5740: 5B
    jmp    L_4BDE                                # 5741: E9 9A F4
    .byte 0x9C, 0x50, 0x55, 0x56, 0x57, 0x1E, 0xBA, 0x00, 0x00, 0x8E, 0xDA, 0x8E # 5744
    .byte 0x1E, 0x10, 0x05, 0xA1, 0x66, 0x00, 0x0A, 0xC4, 0x74, 0x09, 0xFF, 0x0E # 5750
    .byte 0x66, 0x00, 0x75, 0x03, 0xE8, 0x27, 0x00, 0xA0, 0x34, 0x00, 0x0A, 0xC0 # 575C
    .byte 0x74, 0x03, 0xE8, 0x36, 0x00, 0xA0, 0x45, 0x00, 0x0A, 0xC0, 0x74, 0x03 # 5768
    .byte 0xE8, 0x69, 0x00, 0x1F, 0x5F, 0x5E, 0x5D, 0x58, 0x9D, 0xCF # 5774
L_577E:
    mov    BYTE PTR ds:SOUND_RETRIGGER_FLAG,0x0                  # 577E: C6 06 65 00 00
    mov    ax,ds:SOUND_TICK_COUNTDOWN                            # 5783: A1 66 00
    .byte 0x0B, 0xC0 # 5786
    je     L_57A2                                # 5788: 74 18
    push   dx                                    # 578A: 52
    cli                                          # 578B: FA
    test   BYTE PTR ds:SOUND_RETRIGGER_FLAG,0xff                 # 578C: F6 06 65 00 FF
    jne    L_579A                                # 5791: 75 07
    mov    dx,0x61                               # 5793: BA 61 00
    in     al,dx                                 # 5796: EC
    and    al,0xfc                               # 5797: 24 FC
    out    dx,al                                 # 5799: EE
L_579A:
    mov    WORD PTR ds:SOUND_TICK_COUNTDOWN,0x0                  # 579A: C7 06 66 00 00 00
    sti                                          # 57A0: FB
    pop    dx                                    # 57A1: 5A
L_57A2:
    ret                                          # 57A2: C3
    .byte 0x53, 0x51, 0x52, 0xB4, 0x04, 0xCD, 0x10, 0x50, 0x0A, 0xE4, 0x74, 0x0C # 57A3
    .byte 0x89, 0x1E, 0x3A, 0x00, 0x88, 0x2E, 0x3C, 0x00, 0x89, 0x16, 0x3F, 0x00 # 57AF
    .byte 0x58, 0xA0, 0x36, 0x00, 0x32, 0xC4, 0x74, 0x19, 0x0A, 0xE4, 0x88, 0x26 # 57BB
    .byte 0x36, 0x00, 0x74, 0x11, 0x89, 0x1E, 0x37, 0x00, 0x88, 0x2E, 0x39, 0x00 # 57C7
    .byte 0x89, 0x16, 0x3D, 0x00, 0xB0, 0xFF, 0xA2, 0x35, 0x00, 0x5A, 0x59, 0x5B # 57D3
    .byte 0xC3, 0x53, 0xBB, 0x46, 0x00, 0x80, 0x3F, 0x00, 0x75, 0x07, 0xB4, 0x10 # 57DF
    .byte 0xE8, 0x11, 0x00, 0x88, 0x07, 0x43, 0x80, 0x3F, 0x00, 0x75, 0x07, 0xB4 # 57EB
    .byte 0x40, 0xE8, 0x04, 0x00, 0x88, 0x07, 0x5B, 0xC3 # 57F7
L_57FF:
    push   dx                                    # 57FF: 52
    mov    dx,0x201                              # 5800: BA 01 02
L_5803:
    in     al,dx                                 # 5803: EC
    .byte 0x22, 0xC4 # 5804
    dec    al                                    # 5806: FE C8
    cbw                                          # 5808: 98
    .byte 0x8A, 0xC4 # 5809
    pop    dx                                    # 580B: 5A
    ret                                          # 580C: C3
BEEPS:
    call   L_5819                                # 580D: E8 09 00
    mov    ax,0x5d3                              # 5810: B8 D3 05
    mov    dx,0x4                                # 5813: BA 04 00
    push   dx                                    # 5816: 52
    jmp    L_5851                                # 5817: EB 38
L_5819:
    mov    dx,WORD PTR ds:SOUND_TICK_COUNTDOWN                   # 5819: 8B 16 66 00
    .byte 0x0A, 0xF2 # 581D
    je     L_5828                                # 581F: 74 07
    mov    BYTE PTR ds:SOUND_RETRIGGER_FLAG,0xff                 # 5821: C6 06 65 00 FF
    jmp    L_5819                                # 5826: EB F1
L_5828:
    ret                                          # 5828: C3
SOUNDS:
    call   GETIN2                                # 5829: E8 DE C6
    cmp    dx,0x25                               # 582C: 83 FA 25
    jb     L_5843                                # 582F: 72 12
    push   dx                                    # 5831: 52
    call   SYNCHR                                # 5832: E8 BF D5
    .byte ','                                  # 5835: 2C -- SYNCHR inline operand
    .byte 0xE8 # 5836 -- decoded continuation: call   0x22aa
    jno    L_5803                                # 5837: 71 CA
    pop    cx                                    # 5839: 59
    push   dx                                    # 583A: 52
    .byte 0x0B, 0xD2 # 583B
    jne    L_5846                                # 583D: 75 07
    pop    dx                                    # 583F: 5A
    jmp    L_577E                                # 5840: E9 3B FF
L_5843:
    jmp    FCERR                                # 5843: E9 13 B8
L_5846:
    call   L_5819                                # 5846: E8 D0 FF
    mov    dx,0x12                               # 5849: BA 12 00
    mov    ax,0x34dc                             # 584C: B8 DC 34
    div    cx                                    # 584F: F7 F1
L_5851:
    test   BYTE PTR ds:SOUND_RETRIGGER_FLAG,0xff                 # 5851: F6 06 65 00 FF
    jne    L_5860                                # 5856: 75 08
    push   ax                                    # 5858: 50
    mov    dx,0x43                               # 5859: BA 43 00
    mov    al,0xb6                               # 585C: B0 B6
    out    dx,al                                 # 585E: EE
    pop    ax                                    # 585F: 58
L_5860:
    mov    dx,0x42                               # 5860: BA 42 00
    out    dx,al                                 # 5863: EE
    .byte 0x8A, 0xC4 # 5864
    out    dx,al                                 # 5866: EE
    jne    L_5870                                # 5867: 75 07
    mov    dx,0x61                               # 5869: BA 61 00
    in     al,dx                                 # 586C: EC
    or     al,0x3                                # 586D: 0C 03
    out    dx,al                                 # 586F: EE
L_5870:
    pop    dx                                    # 5870: 5A
    mov    WORD PTR ds:SOUND_TICK_COUNTDOWN,dx                   # 5871: 89 16 66 00
    mov    BYTE PTR ds:SOUND_RETRIGGER_FLAG,0x0                  # 5875: C6 06 65 00 00
    ret                                          # 587A: C3
    .byte 0x0A, 0x5A, 0x4D, 0x41, 0x59, 0x10, 0x59, 0x10, 0x19, 0x5A, 0x59, 0x10 # 587B
    .byte 0x59, 0x10, 0x59, 0x10, 0x59, 0x10, 0x2D, 0x5A, 0x59, 0x10, 0x34, 0x5A # 5887
    .byte 0x4D, 0x41, 0x59, 0x10, 0x45, 0x5A, 0x59, 0x10, 0x59, 0x10, 0x59, 0x10 # 5893
    .byte 0x59, 0x10, 0x59, 0x10, 0x59, 0x10, 0x5D, 0x5A, 0x63, 0x5A, 0x4D, 0x41 # 589F
    .byte 0x59, 0x10, 0x7C, 0x5A, 0x59, 0x10, 0x59, 0x10, 0x59, 0x10, 0x59, 0x10 # 58AB
    .byte 0x59, 0x10, 0x59, 0x10, 0xAA, 0x5A, 0xB1, 0x5A, 0x6E, 0x5B, 0x59, 0x10 # 58B7
    .byte 0xAB, 0x5B, 0xF0, 0x5B, 0x59, 0x10, 0x59, 0x10, 0x6C, 0x5C, 0x59, 0x10 # 58C3
    .byte 0x76, 0x5C, 0x59, 0x10, 0x22, 0xC2, 0x75, 0x22, 0x9C, 0x50, 0x53, 0x89 # 58CF
    .byte 0x1E, 0xE9, 0x04, 0x88, 0x17, 0x83, 0xC3, 0x2D, 0xC6, 0x07, 0x00, 0x43 # 58DB
    .byte 0x43, 0x88, 0x2F, 0x43, 0xC6, 0x07, 0x00, 0x43, 0x88, 0x0F, 0x43, 0xC6 # 58E7
    .byte 0x07, 0x00, 0x5B, 0x58, 0x9D, 0xC3, 0xE9, 0x98, 0xAE, 0x58, 0x5B, 0xC3 # 58F3
    .byte 0x80, 0xFA, 0x80, 0x75, 0x02, 0xB2, 0x02, 0xC3, 0x58, 0x86, 0xC4, 0x9E # 58FF
    .byte 0x59, 0x5A, 0x5B, 0xC3, 0x5A, 0x5B, 0x59, 0xC3 # 590B
L_5913:
    add    bx,0x2e                               # 5913: 83 C3 2E
    mov    al,BYTE PTR [bx]                      # 5916: 8A 07
    not    al                                    # 5918: F6 D0
    ret                                          # 591A: C3
    .byte 0x8B, 0x1E, 0xE9, 0x04, 0x83, 0xC3, 0x2B, 0xC3 # 591B
L_5923:
    mov    bx,WORD PTR ds:PTRFIL                  # 5923: 8B 1E E9 04
    add    bx,0x32                               # 5927: 83 C3 32
    ret                                          # 592A: C3
L_592B:
    mov    bx,WORD PTR ds:PTRFIL                  # 592B: 8B 1E E9 04
    .byte 0x8A, 0x87, 0x2F, 0x00 # 592F
    ret                                          # 5933: C3
    .byte 0x56, 0x57, 0x51, 0xC6, 0x06, 0x3F, 0x05, 0xA5, 0xBE, 0xF0, 0x04, 0xBF # 5934
    .byte 0x40, 0x05, 0xB9, 0x08, 0x00, 0xFC, 0xA4, 0xE2, 0xFD, 0x59, 0x5F, 0x5E # 5940
    .byte 0xC3, 0x53, 0x51, 0xBB, 0x40, 0x05, 0xB1, 0x08, 0x80, 0x3F, 0x20, 0x75 # 594C
    .byte 0x0D, 0x43, 0xFE, 0xC9, 0x75, 0xF6, 0xBE, 0x5C, 0x05, 0xBF, 0x48, 0x05 # 5958
    .byte 0xEB, 0x10, 0xBE, 0x54, 0x05, 0xBF, 0x40, 0x05, 0xB1, 0x08, 0xFC, 0xA6 # 5964
    .byte 0x75, 0x27, 0xFE, 0xC9, 0x75, 0xF9, 0x8A, 0x05, 0x3A, 0x04, 0x74, 0x09 # 5970
    .byte 0x0A, 0xC0, 0x75, 0x19, 0xF6, 0x04, 0x01, 0x75, 0x14, 0x8A, 0x04, 0x8B # 597C
    .byte 0x1E, 0xE9, 0x04, 0x88, 0x87, 0x31, 0x00, 0xBB, 0xF4, 0x59, 0xE8, 0x0E # 5988
    .byte 0x00, 0x32, 0xC0, 0xEB, 0x07, 0xBB, 0xFE, 0x59, 0xE8, 0x04, 0x00, 0xF9 # 5994
    .byte 0x59, 0x5B, 0xC3, 0x53, 0x8B, 0x1E, 0x2E, 0x00, 0x43, 0x0B, 0xDB, 0x74 # 59A0
    .byte 0x02, 0x5B, 0xC3, 0xBB, 0x53, 0x05, 0x53, 0x43, 0xB1, 0x08, 0x8A, 0x07 # 59AC
    .byte 0xE8, 0xD5, 0xF4, 0x43, 0xFE, 0xC9, 0x75, 0xF6, 0xB0, 0x2E, 0xE8, 0xCB # 59B8
    .byte 0xF4, 0x5B, 0x83, 0xC3, 0x09, 0xB0, 0x44, 0xF6, 0x07, 0xE1, 0x74, 0x17 # 59C4
    .byte 0xB0, 0x50, 0xF6, 0x07, 0x20, 0x75, 0x10, 0xB0, 0x42, 0xF6, 0x07, 0x80 # 59D0
    .byte 0x75, 0x09, 0xB0, 0x41, 0xF6, 0x07, 0x40, 0x75, 0x02, 0xB0, 0x4D, 0x5B # 59DC
    .byte 0xE8, 0xA5, 0xF4, 0x2E, 0x8A, 0x07, 0x43, 0x0A, 0xC0, 0x75, 0xF5, 0xC3 # 59E8
    .byte 0x20, 0x46, 0x6F, 0x75, 0x6E, 0x64, 0x2E, 0xFF, 0x0D, 0x00, 0x20, 0x53 # 59F4
    .byte 0x6B, 0x69, 0x70, 0x70, 0x65, 0x64, 0x2E, 0xFF, 0x0D, 0x00, 0xB9, 0x00 # 5A00
    .byte 0x00, 0x88, 0x0E, 0x52, 0x05, 0xB0, 0xEA, 0xE8, 0xBD, 0xFE, 0xE9, 0xE3 # 5A0C
    .byte 0xFE, 0xBB, 0x52, 0x05, 0x8A, 0x07, 0xC6, 0x07, 0x00, 0x0A, 0xC0, 0x75 # 5A18
    .byte 0x05, 0xE8, 0x46, 0xF3, 0x0A, 0xC0, 0xE9, 0xE2, 0xFE, 0x88, 0x0E, 0x52 # 5A24
    .byte 0x05, 0xE9, 0xA3, 0xEB, 0xE8, 0xC8, 0xFE, 0x8A, 0x2E, 0x29, 0x00, 0xB1 # 5A30
    .byte 0x00, 0xB0, 0xED, 0xE8, 0x91, 0xFE, 0xE9, 0xB7, 0xFE, 0x58, 0x50, 0x86 # 5A3C
    .byte 0xC4, 0xE8, 0x44, 0xF4, 0x8A, 0x0E, 0x57, 0x00, 0xFE, 0xC9, 0x8B, 0x1E # 5A48
    .byte 0xE9, 0x04, 0x88, 0x8F, 0x32, 0x00, 0xE9, 0xAA, 0xFE, 0x58, 0x86, 0xC4 # 5A54
    .byte 0xE9, 0x49, 0xF8, 0x8A, 0x2E, 0x62, 0x00, 0xB1, 0x00, 0xE8, 0x93, 0xFE # 5A60
    .byte 0xB0, 0x6D, 0xE8, 0x62, 0xFE, 0xE8, 0xAF, 0xFE, 0xA0, 0x63, 0x00, 0x88 # 5A6C
    .byte 0x07, 0xE9, 0x80, 0xFE, 0x58, 0x50, 0x86, 0xC4, 0xE8, 0x03, 0x00, 0xE9 # 5A78
    .byte 0x81, 0xFE, 0xE8, 0x6A, 0xF5, 0xBB, 0x63, 0x00, 0x3C, 0x0D, 0x75, 0x03 # 5A84
    .byte 0xE9, 0xE4, 0x04, 0x3C, 0x20, 0x73, 0x01, 0xC3, 0xFE, 0x07, 0x53, 0xE8 # 5A90
    .byte 0x8D, 0xFE, 0x5B, 0xFE, 0xC0, 0x74, 0xF4, 0xFE, 0xC8, 0x38, 0x07, 0xE9 # 5A9C
    .byte 0xC5, 0x04, 0x58, 0x86, 0xC4, 0xA2, 0x62, 0x00, 0xC3, 0xA0, 0x61, 0x00 # 5AA8
    .byte 0x0A, 0xC0, 0x74, 0x03, 0xE9, 0xE8, 0xAC, 0x80, 0xE2, 0xFB, 0x75, 0x02 # 5AB4
    .byte 0xB2, 0x01, 0xA2, 0x51, 0x05, 0xFE, 0xC0, 0xA2, 0x50, 0x05, 0x8A, 0xCA # 5AC0
    .byte 0x80, 0xE1, 0x80, 0x80, 0xE9, 0x01, 0xF5, 0x1A, 0xC9, 0x80, 0xE1, 0x80 # 5ACC
    .byte 0xF6, 0xC2, 0x10, 0x74, 0x03, 0x80, 0xC9, 0x20, 0xA0, 0x60, 0x00, 0x0A # 5AD8
    .byte 0xC0, 0x74, 0x02, 0xB1, 0x01, 0x0A, 0xC9, 0x75, 0x09, 0xF6, 0x06, 0x5F # 5AE4
    .byte 0x00, 0xFF, 0x74, 0x02, 0xB1, 0x40, 0x88, 0x0E, 0x48, 0x05, 0xB5, 0xFF # 5AF0
    .byte 0xB0, 0x68, 0xE8, 0xD2, 0xFD, 0x8A, 0x27, 0xE8, 0x2E, 0xFE, 0xF6, 0xC4 # 5AFC
    .byte 0x01, 0x75, 0x0C, 0xF6, 0xC1, 0x81, 0x75, 0x03, 0xE8, 0x2F, 0x00, 0xB0 # 5B08
    .byte 0xFF, 0xEB, 0x1F, 0xE8, 0x33, 0x00, 0xE8, 0x30, 0xFE, 0x72, 0xF8, 0x8B # 5B14
    .byte 0x1E, 0xE9, 0x04, 0xF6, 0x87, 0x31, 0x00, 0x81, 0x75, 0x0A, 0xE8, 0x11 # 5B20
    .byte 0x01, 0x73, 0x05, 0xC6, 0x06, 0x50, 0x05, 0x00, 0xB0, 0x01, 0xA2, 0x61 # 5B2C
    .byte 0x00, 0xE8, 0xE7, 0xFD, 0xC6, 0x07, 0x01, 0xE9, 0xBA, 0xFD # 5B38
CASSETTE_WRITE_HEADER17:
    mov    bx,0x53f                              # 5B42: BB 3F 05
    mov    cx,0x11                               # 5B45: B9 11 00
    mov    ah,BIOS_CASS_WRITE_BLOCK              # 5B48: B4 03
    int    0x15                                  # 5B4A: CD 15
    ret                                          # 5B4C: C3
    .byte 0xBB, 0x53, 0x05, 0xB9, 0x11, 0x00, 0x53, 0xB4, 0x02, 0xCD, 0x15, 0x73 # 5B4D -- BIOS_CASS_READ_BLOCK, 17-byte header
    .byte 0x03, 0xE9, 0x02, 0x01, 0x5B, 0xA0, 0x5E, 0x00, 0x0A, 0xC0, 0x75, 0x06 # 5B59
    .byte 0x80, 0x3F, 0xA5, 0x75, 0xE6, 0xC3, 0xE9, 0x29, 0xAC, 0xA0, 0x61, 0x00 # 5B65
    .byte 0xFE, 0xC0, 0x74, 0x0B, 0x32, 0xC0, 0xA2, 0x61, 0x00, 0xA2, 0x60, 0x00 # 5B71
    .byte 0xE9, 0xCD, 0xE5, 0x8B, 0x1E, 0xE9, 0x04, 0xF6, 0x87, 0x31, 0x00, 0x81 # 5B7D
    .byte 0x75, 0xEA, 0xE8, 0x3B, 0x00, 0xE8, 0x1F, 0x01, 0xEB, 0xE2, 0x53, 0xBB # 5B89
    .byte 0x61, 0x00, 0x38, 0x27, 0x75, 0x0D, 0x8B, 0x1E, 0xE9, 0x04, 0xF6, 0x87 # 5B95
    .byte 0x31, 0x00, 0x81, 0x5B, 0x75, 0x01, 0xC3, 0xE9, 0xE9, 0xAB, 0xB4, 0xFF # 5BA1
    .byte 0xE8, 0xE3, 0xFF, 0x58, 0x50, 0x86, 0xC4, 0xE8, 0x03, 0x00, 0xE9, 0x4D # 5BAD
    .byte 0xFD, 0xE8, 0x26, 0x00, 0x88, 0x07, 0xFE, 0xC1, 0x74, 0x0B, 0xE8, 0x5D # 5BB9
    .byte 0xFD, 0x88, 0x0F, 0xC3, 0xE8, 0x57, 0xFD, 0x8A, 0x0F, 0xBB, 0x53, 0x05 # 5BC5
    .byte 0xB5, 0x00, 0xFE, 0xC9, 0x41, 0x88, 0x0F, 0xB4, 0x03, 0xCD, 0x15, 0xE8 # 5BD1
    .byte 0x44, 0xFD, 0xC6, 0x07, 0x01, 0xC3, 0xE8, 0x3D, 0xFD, 0x8A, 0x0F, 0xB5 # 5BDD
    .byte 0x00, 0xBB, 0x53, 0x05, 0x03, 0xD9, 0xC3, 0xB4, 0x01, 0xE8, 0x9E, 0xFF # 5BE9
    .byte 0xE8, 0x03, 0x00, 0xE9, 0x14, 0xFD, 0xA0, 0x50, 0x05, 0x2C, 0x01, 0x73 # 5BF5
    .byte 0x01, 0xC3, 0xBB, 0x51, 0x05, 0x8A, 0x07, 0xC6, 0x07, 0x00, 0x0A, 0xC0 # 5C01
    .byte 0x74, 0x01, 0xC3, 0xE8, 0x0A, 0x00, 0x73, 0x07, 0xC6, 0x06, 0x50, 0x05 # 5C0D
    .byte 0x00, 0x0A, 0xC0, 0xC3, 0xE8, 0xC3, 0xFF, 0x8A, 0x07, 0xFE, 0xC1, 0xE8 # 5C19
    .byte 0xFC, 0xFC, 0x88, 0x0F, 0xE8, 0xEF, 0xFC, 0x3A, 0x0F, 0x74, 0x03, 0x0A # 5C25
    .byte 0xC0, 0xC3, 0x80, 0x3F, 0x00, 0x75, 0xDD, 0x50, 0xE8, 0x02, 0x00, 0x58 # 5C31
    .byte 0xC3, 0xBB, 0x53, 0x05, 0xB9, 0x00, 0x01, 0xB4, 0x02, 0xCD, 0x15, 0x72 # 5C3D -- BIOS_CASS_READ_BLOCK, 256-byte block
    .byte 0x15, 0xA0, 0x53, 0x05, 0xE8, 0xCB, 0xFC, 0x88, 0x07, 0xE8, 0xCE, 0xFC # 5C49
    .byte 0xC6, 0x07, 0x01, 0xFE, 0xC8, 0xF9, 0x74, 0x01, 0xF8, 0xC3, 0x80, 0xFC # 5C55
    .byte 0x04, 0x75, 0x05, 0xB2, 0x18, 0xE9, 0x6F, 0xAB, 0xE9, 0x25, 0xAB, 0xA0 # 5C61
    .byte 0x50, 0x05, 0x2C, 0x01, 0x1A, 0xC0, 0xE9, 0x93, 0x08, 0x88, 0x0E, 0x51 # 5C6D
    .byte 0x05, 0xE9, 0x5A, 0xE9 # 5C79
L_5C7D:
    mov    BYTE PTR ds:BASIC_PROGRAM_FILE_FLAG,0x0                  # 5C7D: C6 06 5F 00 00
    push   bx                                    # 5C82: 53
    mov    WORD PTR ds:CASSETTE_XFER_OFF,bx                  # 5C83: 89 1E 4D 05
    mov    dx,WORD PTR ds:SAVSEG                  # 5C87: 8B 16 50 03
    mov    WORD PTR ds:CASSETTE_XFER_SEG,dx                  # 5C8B: 89 16 4B 05
    mov    cx,WORD PTR ds:SAVE_END_ADDR                  # 5C8F: 8B 0E 04 07
    .byte 0x2B, 0xCB # 5C93
    mov    WORD PTR ds:CASSETTE_XFER_COUNT,cx                  # 5C95: 89 0E 49 05
    push   cx                                    # 5C99: 51
    push   dx                                    # 5C9A: 52
    call   CASSETTE_WRITE_HEADER17                                # 5C9B: E8 A4 FE
    pop    dx                                    # 5C9E: 5A
    pop    cx                                    # 5C9F: 59
    pop    bx                                    # 5CA0: 5B
    mov    al,ds:BINARY_ADDR_PARAM_SWITCH                            # 5CA1: A0 60 00
    .byte 0x0A, 0xC0 # 5CA4
    push   es                                    # 5CA6: 06
    je     L_5CAB                                # 5CA7: 74 02
    mov    es,dx                                 # 5CA9: 8E C2
L_5CAB:
    mov    ah,BIOS_CASS_WRITE_BLOCK              # 5CAB: B4 03
    int    0x15                                  # 5CAD: CD 15
    pop    es                                    # 5CAF: 07
    call   L_5D3C                                # 5CB0: E8 89 00
    mov    dx,0x5                                # 5CB3: BA 05 00
    mov    cx,0x0                                # 5CB6: B9 00 00
L_5CB9:
    dec    cx                                    # 5CB9: 49
    jne    L_5CB9                                # 5CBA: 75 FD
    dec    dx                                    # 5CBC: 4A
    jne    L_5CB9                                # 5CBD: 75 FA
    call   L_5D38                                # 5CBF: E8 76 00
    ret                                          # 5CC2: C3
L_5CC3:
    mov    si,0x553                              # 5CC3: BE 53 05
    .byte 0x8B, 0x8C, 0x0A, 0x00 # 5CC6
    mov    al,ds:BINARY_ADDR_PARAM_SWITCH                            # 5CCA: A0 60 00
    .byte 0x0A, 0xC0 # 5CCD
    pushf                                        # 5CCF: 9C
    push   cx                                    # 5CD0: 51
    jne    L_5CE0                                # 5CD1: 75 0D
    push   ax                                    # 5CD3: 50
    push   bx                                    # 5CD4: 53
    push   cx                                    # 5CD5: 51
    push   si                                    # 5CD6: 56
    .byte 0x03, 0xD9 # 5CD7
    call   L_42F2                                # 5CD9: E8 16 E6
    pop    si                                    # 5CDC: 5E
    pop    cx                                    # 5CDD: 59
    pop    bx                                    # 5CDE: 5B
    pop    ax                                    # 5CDF: 58
L_5CE0:
    cmp    al,0x1                                # 5CE0: 3C 01
    jne    L_5CE8                                # 5CE2: 75 04
    .byte 0x8B, 0x9C, 0x0E, 0x00 # 5CE4
L_5CE8:
    push   es                                    # 5CE8: 06
    .byte 0x0A, 0xC0 # 5CE9
    je     L_5CFB                                # 5CEB: 74 0E
    .byte 0x8B, 0x94, 0x0C, 0x00 # 5CED
    dec    al                                    # 5CF1: FE C8
    je     L_5CF9                                # 5CF3: 74 04
    mov    dx,WORD PTR ds:SAVSEG                  # 5CF5: 8B 16 50 03
L_5CF9:
    mov    es,dx                                 # 5CF9: 8E C2
L_5CFB:
    mov    ah,BIOS_CASS_READ_BLOCK               # 5CFB: B4 02
    int    0x15                                  # 5CFD: CD 15
    pop    es                                    # 5CFF: 07
    jb     L_5D14                                # 5D00: 72 12
    pop    cx                                    # 5D02: 59
    popf                                         # 5D03: 9D
    jne    L_5D11                                # 5D04: 75 0B
    mov    bx,WORD PTR ds:TXTTAB                   # 5D06: 8B 1E 30 00
    .byte 0x03, 0xD9 # 5D0A
    inc    bx                                    # 5D0C: 43
    mov    WORD PTR ds:VARTAB,bx                  # 5D0D: 89 1E 58 03
L_5D11:
    jmp    L_4294                                # 5D11: E9 80 E5
L_5D14:
    push   ax                                    # 5D14: 50
    call   L_2D1D                                # 5D15: E8 05 D0
    pop    ax                                    # 5D18: 58
    cmp    ah,BIOS_CASS_ST_NO_LEADER             # 5D19: 80 FC 04
    jne    L_5D23                                # 5D1C: 75 05
    mov    dl,0x18                               # 5D1E: B2 18
    jmp    L_07D8                                # 5D20: E9 B5 AA
L_5D23:
    jmp    L_0791                                # 5D23: E9 6B AA
MOTOR:
    dec    bx                                    # 5D26: 4B
    call   CHRGTR                                # 5D27: E8 F3 B1
    jne    L_5D31                                # 5D2A: 75 05
    mov    al,ds:CASSETTE_MOTOR_CMD                            # 5D2C: A0 64 00
    jmp    L_5D34                                # 5D2F: EB 03
L_5D31:
    call   GETBYT                                # 5D31: E8 E8 C1
L_5D34:
    .byte 0x0A, 0xC0 # 5D34
    jne    L_5D3C                                # 5D36: 75 04
L_5D38:
    mov    al,0x1                                # 5D38: B0 01
    jmp    L_5D3E                                # 5D3A: EB 02
L_5D3C:
    mov    al,0x0                                # 5D3C: B0 00
L_5D3E:
    mov    ds:CASSETTE_MOTOR_CMD,al                            # 5D3E: A2 64 00
    .byte 0x8A, 0xE0 # 5D41
    int    0x15                                  # 5D43: CD 15
    ret                                          # 5D45: C3
L_5D46:
    int    0xdb                                  # 5D46: CD DB
AEXPS:
    stc                                          # 5D48: F9
    jmp    SES00                                # 5D49: EB 01
SEXPS:
    clc                                          # 5D4B: F8
SES00:
    .byte 0x8B, 0xF3 # 5D4C
    pushf                                        # 5D4E: 9C
    mov    cx,WORD PTR ds:FACSGN                  # 5D4F: 8B 0E A5 04
    .byte 0x8A, 0xC3, 0x32, 0xC1 # 5D53
    mov    ds:FAC_AUX,al                           # 5D57: A2 A7 04
    .byte 0x8A, 0xC7, 0x32, 0xE4, 0x8A, 0xDD, 0x32, 0xFF # 5D5A
    popf                                         # 5D62: 9D
    jae    L_5D6C                                # 5D63: 73 07
    .byte 0x03, 0xC3 # 5D65
    sub    ax,0x101                              # 5D67: 2D 01 01
    jmp    L_5D6E                                # 5D6A: EB 02
L_5D6C:
    .byte 0x2B, 0xC3 # 5D6C
L_5D6E:
    .byte 0x0A, 0xE4 # 5D6E
    js     L_5D7F                                # 5D70: 78 0D
    cmp    ax,0x80                               # 5D72: 3D 80 00
    jb     L_5D8C                                # 5D75: 72 15
    .byte 0x8B, 0xDE # 5D77
    add    sp,0x2                                # 5D79: 83 C4 02
    jmp    L_74DC                                # 5D7C: E9 5D 17
L_5D7F:
    add    ax,0x80                               # 5D7F: 05 80 00
    jns    L_5D8F                                # 5D82: 79 0B
    .byte 0x8B, 0xDE # 5D84
    add    sp,0x2                                # 5D86: 83 C4 02
    jmp    ZERO                                # 5D89: E9 DF 1D
L_5D8C:
    add    ax,0x80                               # 5D8C: 05 80 00
L_5D8F:
    mov    ds:FACEXP,al                           # 5D8F: A2 A6 04
    mov    bx,FACM1                              # 5D92: BB A5 04
    or     BYTE PTR [bx],0x80                    # 5D95: 80 0F 80
    .byte 0x8B, 0xDE, 0x32, 0xFF # 5D98
    or     bl,0x80                               # 5D9C: 80 CB 80
    ret                                          # 5D9F: C3
CALLS:
    mov    BYTE PTR ds:SUBFLG,0x80                # 5DA0: C6 06 39 03 80
    call   PTRGET                                # 5DA5: E8 C6 D9
    push   bx                                    # 5DA8: 53
    .byte 0x8B, 0xDA # 5DA9
    call   L_6498                                # 5DAB: E8 EA 06
    call   L_22B5                                # 5DAE: E8 04 C5
    mov    WORD PTR ds:TEMPA,bx                  # 5DB1: 89 1E 5E 04
    mov    cl,0x20                               # 5DB5: B1 20
    call   GETSTK                                # 5DB7: E8 1B CF
    pop    bx                                    # 5DBA: 5B
    call   CHRGT2                                # 5DBB: E8 60 B1
    je     L_5DD7                                # 5DBE: 74 17
    call   SYNCHR                                # 5DC0: E8 31 D0
    .byte '('                                  # 5DC3: 28 -- SYNCHR inline operand
L_5DC4:
    .byte 0xE8, 0xA7, 0xD9, 0x52, 0x8A, 0x07 # 5DC4
    cmp    al,0x2c                               # 5DCA: 3C 2C
    jne    L_5DD3                                # 5DCC: 75 05
    call   CHRGTR                                # 5DCE: E8 4C B1
    jmp    L_5DC4                                # 5DD1: EB F1
L_5DD3:
    call   SYNCHR                                # 5DD3: E8 1E D0
    .byte ')'                                  # 5DD6: 29 -- SYNCHR inline operand
L_5DD7:
    .byte 0x89, 0x1E, 0x3B, 0x03, 0x0E, 0xB8, 0xE9, 0x5D # 5DD7
    push   ax                                    # 5DDF: 50
    push   WORD PTR ds:SAVSEG                     # 5DE0: FF 36 50 03
    push   WORD PTR ds:TEMPA                     # 5DE4: FF 36 5E 04
    retf                                         # 5DE8: CB
    .byte 0x8B, 0x1E, 0x3B, 0x03, 0xC3, 0x53, 0xE8, 0x0E, 0x05, 0x3C, 0x6C, 0x74 # 5DE9
    .byte 0x0A, 0x3C, 0x4C, 0x74, 0x06, 0x3C, 0x71, 0x74, 0x02, 0x3C, 0x51, 0x5B # 5DF5
    .byte 0xC3, 0x26, 0x26, 0x26, 0x26, 0x26, 0x26, 0x26, 0x26, 0x26, 0x26, 0x26 # 5E01
    .byte 0x26, 0x26, 0x26, 0x26, 0x26, 0x26, 0x26, 0x26, 0x26, 0x26, 0x26, 0x26 # 5E0D
    .byte 0x26, 0x26, 0x25, 0x25, 0x25, 0x24, 0x24, 0x24, 0x23, 0x23, 0x23, 0x22 # 5E19
    .byte 0x22, 0x22, 0x22, 0x21, 0x21, 0x21, 0x20, 0x20, 0x20, 0x1F, 0x1F, 0x1F # 5E25
    .byte 0x1F, 0x1E, 0x1E, 0x1E, 0x1D, 0x1D, 0x1D, 0x1D, 0x1C, 0x1C, 0x1C, 0x1B # 5E31
    .byte 0x1B, 0x1B, 0x1A, 0x1A, 0x1A, 0x19, 0x19, 0x19, 0x19, 0x18, 0x18, 0x18 # 5E3D
    .byte 0x17, 0x17, 0x17, 0x17, 0x16, 0x16, 0x16, 0x16, 0x15, 0x15, 0x15, 0x14 # 5E49
    .byte 0x14, 0x14, 0x13, 0x13, 0x13, 0x13, 0x12, 0x12, 0x12, 0x11, 0x11, 0x11 # 5E55
    .byte 0x10, 0x10, 0x10, 0x10, 0x0F, 0x0F, 0x0F, 0x0E, 0x0E, 0x0E, 0x0D, 0x0D # 5E61
    .byte 0x0D, 0x0D, 0x0C, 0x0C, 0x0C, 0x0B, 0x0B, 0x0B, 0x0A, 0x0A, 0x0A, 0x0A # 5E6D
    .byte 0x09, 0x09, 0x09, 0x08, 0x08, 0x08, 0x07, 0x07, 0x07, 0x06, 0x06, 0x06 # 5E79
    .byte 0x06, 0x05, 0x05, 0x05, 0x04, 0x04, 0x04, 0x03, 0x03, 0x03, 0x03, 0x02 # 5E85
    .byte 0x02, 0x02, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF # 5E91
    .byte 0xFE, 0xFE, 0xFE, 0xFD, 0xFD, 0xFD, 0xFD, 0xFC, 0xFC, 0xFC, 0xFB, 0xFB # 5E9D
    .byte 0xFB, 0xFA, 0xFA, 0xFA, 0xFA, 0xF9, 0xF9, 0xF9, 0xF8, 0xF8, 0xF8, 0xF7 # 5EA9
    .byte 0xF7, 0xF7, 0xF7, 0xF6, 0xF6, 0xF6, 0xF5, 0xF5, 0xF5, 0xF4, 0xF4, 0xF4 # 5EB5
    .byte 0xF4, 0xF3, 0xF3, 0xF3, 0xF2, 0xF2, 0xF2, 0xF1, 0xF1, 0xF1, 0xF1, 0xF0 # 5EC1
    .byte 0xF0, 0xF0, 0xEF, 0xEF, 0xEF, 0xEE, 0xEE, 0xEE, 0xEE, 0xED, 0xED, 0xED # 5ECD
    .byte 0xEC, 0xEC, 0xEC, 0xEB, 0xEB, 0xEB, 0xEB, 0xEA, 0xEA, 0xEA, 0xE9, 0xE9 # 5ED9
    .byte 0xE9, 0xE8, 0xE8, 0xE8, 0xE7, 0xE7, 0xE7, 0xE7, 0xE6, 0xE6, 0xE6, 0xE5 # 5EE5
    .byte 0xE5, 0xE5, 0xE4, 0xE4, 0xE4, 0xE4, 0xE3, 0xE3, 0xE3, 0xE2, 0xE2, 0xE2 # 5EF1
    .byte 0xE1, 0xE1, 0xE1, 0xE1, 0xE0 # 5EFD
L_5F02:
    .byte 0x0B, 0xF6 # 5F02
    jns    L_5F08                                # 5F04: 79 02
    neg    dx                                    # 5F06: F7 DA
L_5F08:
    .byte 0x2B, 0xD7 # 5F08
    jo     L_5F49                                # 5F0A: 70 3D
    je     L_5F48                                # 5F0C: 74 3A
L_5F0E:
    push   bx                                    # 5F0E: 53
    call   GETYP                                # 5F0F: E8 90 1C
    pushf                                        # 5F12: 9C
    jae    L_5F18                                # 5F13: 73 03
    call   FRCDBL                                # 5F15: E8 6A 0C
L_5F18:
    .byte 0x0B, 0xD2 # 5F18
    js     L_5F2B                                # 5F1A: 78 0F
    cmp    dx,0x27                               # 5F1C: 83 FA 27
    jb     L_5F3E                                # 5F1F: 72 1D
    popf                                         # 5F21: 9D
    jae    L_5F27                                # 5F22: 73 03
    call   CSD                                # 5F24: E8 3D 0C
L_5F27:
    pop    bx                                    # 5F27: 5B
    jmp    L_74DC                                # 5F28: E9 B1 15
L_5F2B:
    cmp    dx,0xffda                             # 5F2B: 83 FA DA
    jge    L_5F3E                                # 5F2E: 7D 0E
    add    dx,0x26                               # 5F30: 83 C2 26
    cmp    dx,0xffda                             # 5F33: 83 FA DA
    jl     L_5F49                                # 5F36: 7C 11
    call   MDP10                                # 5F38: E8 13 00
    mov    dx,0xffda                             # 5F3B: BA DA FF
L_5F3E:
    call   MDP10                                # 5F3E: E8 0D 00
L_5F41:
    popf                                         # 5F41: 9D
    jae    L_5F47                                # 5F42: 73 03
    call   CSD                                # 5F44: E8 1D 0C
L_5F47:
    pop    bx                                    # 5F47: 5B
L_5F48:
    ret                                          # 5F48: C3
L_5F49:
    call   ZERO                                # 5F49: E8 1F 1C
    jmp    L_5F41                                # 5F4C: EB F3
MDP10:
    .byte 0x0B, 0xD2 # 5F4E
    pushf                                        # 5F50: 9C
    jns    L_5F55                                # 5F51: 79 02
    neg    dx                                    # 5F53: F7 DA
L_5F55:
    mov    cx,0x3                                # 5F55: B9 03 00
    shl    dx,cl                                 # 5F58: D3 E2
    add    dx,OFFSET FLAT:MATH_DP00                             # 5F5A: 81 C2 32 60
    xchg   dx,bx                                 # 5F5E: 87 DA
    call   MOVAC                                # 5F60: E8 25 1D
    popf                                         # 5F63: 9D
    js     L_5F69                                # 5F64: 78 03
    jmp    FMULD                                # 5F66: E9 EC 0C
L_5F69:
    call   XCGAF                                # 5F69: E8 EC 1C
    jmp    L_6843                                # 5F6C: E9 D4 08
    .byte 0x72, 0x09, 0xB0, 0x0D, 0x90, 0xE9, 0x0F, 0xFB, 0xC6, 0x07, 0x00, 0x8A # 5F6F
    .byte 0x07, 0xE8, 0xA4, 0xF9, 0x88, 0x07, 0xC3, 0x75, 0x06, 0xB0, 0x0A, 0x90 # 5F7B
    .byte 0xE8, 0x69, 0xF0, 0x58, 0x5A, 0x5B, 0x9D, 0xC3 # 5F87
L_5F8F:
    cmp    BYTE PTR ds:KEY_EXPANSION_STATE,0x0                  # 5F8F: 80 3E 6A 00 00
    je     L_5FA8                                # 5F94: 74 12
    push   ds                                    # 5F96: 1E
    push   bx                                    # 5F97: 53
    lds    bx,DWORD PTR ds:KEY_EXPANSION_PTR                  # 5F98: C5 1E 6B 00
    cmp    BYTE PTR [bx],0x0                     # 5F9C: 80 3F 00
    pop    bx                                    # 5F9F: 5B
    pop    ds                                    # 5FA0: 1F
    jne    L_5FA8                                # 5FA1: 75 05
    mov    BYTE PTR ds:KEY_EXPANSION_STATE,0x0                  # 5FA3: C6 06 6A 00 00
L_5FA8:
    jmp    CHRGTR                                # 5FA8: E9 72 AF
L_5FAB:
    pop    di                                    # 5FAB: 5F
    pop    si                                    # 5FAC: 5E
    jmp    L_4D6E                                # 5FAD: E9 BE ED
L_5FB0:
    jne    L_5FC2                                # 5FB0: 75 10
    pop    bx                                    # 5FB2: 5B
    mov    BYTE PTR ds:FAC_AUX,dh                  # 5FB3: 88 36 A7 04
    mov    bx,0x1000                             # 5FB7: BB 00 10
    mov    BYTE PTR ds:VALTYP,0x4                 # 5FBA: C6 06 FB 02 04
    jmp    L_74EA                                # 5FBF: E9 28 15
L_5FC2:
    mov    WORD PTR ds:FACSGN,0x0                 # 5FC2: C7 06 A5 04 00 00
    ret                                          # 5FC8: C3
C110_UNREFERENCED_STUB_PREFIX:
    .byte 0x10                                  # 5FC9: unreferenced residue; exact historical role not yet proven
C110_DUPLICATE_ZERO_DIVISOR_STUB:
    # 5FCA-5FE0 duplicates the live 5FB2-5FC8 zero-divisor/conversion tail;
    # no C1.10 control-flow reference enters this copy. C1.20 safely reclaims it.
    .byte 0x5B, 0x88, 0x36, 0xA7, 0x04, 0xBB, 0x00, 0x10, 0xC6, 0x06, 0xFB
    .byte 0x02, 0x04, 0xE9, 0x10, 0x15, 0xC7, 0x06, 0xA5, 0x04, 0x00, 0x00, 0xC3
C110_PRE_NEG_POW10_RESIDUE:
    .byte 0x5C                                  # 5FE1: unresolved byte immediately before legacy negative-powers table
# 5FE2-6029: legacy MBF double constants 10^-10..10^-2. The current C1.10
# MDP10 path scales negative exponents by dividing by positive powers, so these
# entries have no static references and are retained dead numeric data. C1.20
# reclaims most of this dead span for its PCjr compatibility/math fixes.
MATH_LEGACY_UNUSED_DPM10:
    .byte 0xD6, 0xED, 0xBD, 0xCE, 0xFE, 0xE6, 0x5B, 0x5F # 5FE2: MBF double 10^-10
MATH_LEGACY_UNUSED_DPM09:
    .byte 0xA6, 0xB4, 0x36, 0x41, 0x5F, 0x70, 0x09, 0x63 # 5FEA: MBF double 10^-9
MATH_LEGACY_UNUSED_DPM08:
    .byte 0xCF, 0x61, 0x84, 0x11, 0x77, 0xCC, 0x2B, 0x66 # 5FF2: MBF double 10^-8
MATH_LEGACY_UNUSED_DPM07:
    .byte 0x43, 0x7A, 0xE5, 0xD5, 0x94, 0xBF, 0x56, 0x69 # 5FFA: MBF double 10^-7
MATH_LEGACY_UNUSED_DPM06:
    .byte 0x6A, 0x6C, 0xAF, 0x05, 0xBD, 0x37, 0x06, 0x6D # 6002: MBF double 10^-6
MATH_LEGACY_UNUSED_DPM05:
    .byte 0x85, 0x47, 0x1B, 0x47, 0xAC, 0xC5, 0x27, 0x70 # 600A: MBF double 10^-5
MATH_LEGACY_UNUSED_DPM04:
    .byte 0x66, 0x19, 0xE2, 0x58, 0x17, 0xB7, 0x51, 0x73 # 6012: MBF double 10^-4
MATH_LEGACY_UNUSED_DPM03:
    .byte 0xE0, 0x4F, 0x8D, 0x97, 0x6E, 0x12, 0x03, 0x77 # 601A: MBF double 10^-3
MATH_LEGACY_UNUSED_DPM02:
    .byte 0xD8, 0xA3, 0x70, 0x3D, 0x0A, 0xD7, 0x23, 0x7A # 6022: MBF double 10^-2
MATH_DPM01:
    .byte 0xCD, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0x4C, 0x7D # 602A: MBF double 10^-1
MATH_DP00:
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x81 # 6032: MBF double 10^0
MATH_DP01:
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x84 # 603A: MBF double 10^1
MATH_DP02:
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x48, 0x87 # 6042: MBF double 10^2
MATH_DP03:
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7A, 0x8A # 604A: MBF double 10^3
MATH_DP04:
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x1C, 0x8E # 6052: MBF double 10^4
MATH_DP05:
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x50, 0x43, 0x91 # 605A: MBF double 10^5
MATH_DP06:
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x24, 0x74, 0x94 # 6062: MBF double 10^6
MATH_DP07:
    .byte 0x00, 0x00, 0x00, 0x00, 0x80, 0x96, 0x18, 0x98 # 606A: MBF double 10^7
MATH_DP08:
    .byte 0x00, 0x00, 0x00, 0x00, 0x20, 0xBC, 0x3E, 0x9B # 6072: MBF double 10^8
MATH_DP09:
    .byte 0x00, 0x00, 0x00, 0x00, 0x28, 0x6B, 0x6E, 0x9E # 607A: MBF double 10^9
MATH_DP10:
    .byte 0x00, 0x00, 0x00, 0x00, 0xF9, 0x02, 0x15, 0xA2 # 6082: MBF double 10^10
MATH_DP11:
    .byte 0x00, 0x00, 0x00, 0x40, 0xB7, 0x43, 0x3A, 0xA5 # 608A: MBF double 10^11
MATH_DP12:
    .byte 0x00, 0x00, 0x00, 0x10, 0xA5, 0xD4, 0x68, 0xA8 # 6092: MBF double 10^12
MATH_DP13:
    .byte 0x00, 0x00, 0x00, 0x2A, 0xE7, 0x84, 0x11, 0xAC # 609A: MBF double 10^13
MATH_DP14:
    .byte 0x00, 0x00, 0x80, 0xF4, 0x20, 0xE6, 0x35, 0xAF # 60A2: MBF double 10^14
MATH_DP15:
    .byte 0x00, 0x00, 0xA0, 0x31, 0xA9, 0x5F, 0x63, 0xB2 # 60AA: MBF double 10^15
MATH_DP16:
    .byte 0x00, 0x00, 0x04, 0xBF, 0xC9, 0x1B, 0x0E, 0xB6 # 60B2: MBF double 10^16
MATH_DP17:
    .byte 0x00, 0x00, 0xC5, 0x2E, 0xBC, 0xA2, 0x31, 0xB9 # 60BA: MBF double 10^17
MATH_DP18:
    .byte 0x00, 0x40, 0x76, 0x3A, 0x6B, 0x0B, 0x5E, 0xBC # 60C2: MBF double 10^18
MATH_DP19:
    .byte 0x00, 0xE8, 0x89, 0x04, 0x23, 0xC7, 0x0A, 0xC0 # 60CA: MBF double 10^19
MATH_DP20:
    .byte 0x00, 0x62, 0xAC, 0xC5, 0xEB, 0x78, 0x2D, 0xC3 # 60D2: MBF double 10^20
MATH_DP21:
    .byte 0x80, 0x7A, 0x17, 0xB7, 0x26, 0xD7, 0x58, 0xC6 # 60DA: MBF double 10^21
MATH_DP22:
    .byte 0x90, 0xAC, 0x6E, 0x32, 0x78, 0x86, 0x07, 0xCA # 60E2: MBF double 10^22
MATH_DP23:
    .byte 0xB5, 0x57, 0x0A, 0x3F, 0x16, 0x68, 0x29, 0xCD # 60EA: MBF double 10^23
MATH_DP24:
    .byte 0xA2, 0xED, 0xCC, 0xCE, 0x1B, 0xC2, 0x53, 0xD0 # 60F2: MBF double 10^24
MATH_DP25:
    .byte 0x85, 0x14, 0x40, 0x61, 0x51, 0x59, 0x04, 0xD4 # 60FA: MBF double 10^25
MATH_DP26:
    .byte 0xA6, 0x19, 0x90, 0xB9, 0xA5, 0x6F, 0x25, 0xD7 # 6102: MBF double 10^26
MATH_DP27:
    .byte 0x10, 0x20, 0xF4, 0x27, 0x8F, 0xCB, 0x4E, 0xDA # 610A: MBF double 10^27
MATH_DP28:
    .byte 0x0A, 0x94, 0xF8, 0x78, 0x39, 0x3F, 0x01, 0xDE # 6112: MBF double 10^28
MATH_DP29:
    .byte 0x0C, 0xB9, 0x36, 0xD7, 0x07, 0x8F, 0x21, 0xE1 # 611A: MBF double 10^29
MATH_DP30:
    .byte 0x4F, 0x67, 0x04, 0xCD, 0xC9, 0xF2, 0x49, 0xE4 # 6122: MBF double 10^30
MATH_DP31:
    .byte 0x23, 0x81, 0x45, 0x40, 0x7C, 0x6F, 0x7C, 0xE7 # 612A: MBF double 10^31
MATH_DP32:
    .byte 0xB6, 0x70, 0x2B, 0xA8, 0xAD, 0xC5, 0x1D, 0xEB # 6132: MBF double 10^32
MATH_DP33:
    .byte 0xE4, 0x4C, 0x36, 0x12, 0x19, 0x37, 0x45, 0xEE # 613A: MBF double 10^33
MATH_DP34:
    .byte 0x1C, 0xE0, 0xC3, 0x56, 0xDF, 0x84, 0x76, 0xF1 # 6142: MBF double 10^34
MATH_DP35:
    .byte 0x12, 0x6C, 0x3A, 0x96, 0x0B, 0x13, 0x1A, 0xF5 # 614A: MBF double 10^35
MATH_DP36:
    .byte 0x16, 0x07, 0xC9, 0x7B, 0xCE, 0x97, 0x40, 0xF8 # 6152: MBF double 10^36
MATH_DP37:
    .byte 0xDC, 0x48, 0xBB, 0x1A, 0xC2, 0xBD, 0x70, 0xFB # 615A: MBF double 10^37
MATH_DP38:
    .byte 0x89, 0x0D, 0xB5, 0x50, 0x99, 0x76, 0x16, 0xFF # 6162: MBF double 10^38
MATH_DHALF:
    .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80 # 616A: MBF double 0.5 ($DHALF)
    .byte 0xF1, 0x04, 0x35, 0x80, 0x04, 0x9A, 0xF7 # 6172: following math constant/table data; classification continues
    .byte 0x19, 0x83, 0x24, 0x63, 0x43, 0x83, 0x75, 0xCD, 0x8D, 0x84, 0xA9, 0x7F # 6179
    .byte 0x83, 0x82, 0x04, 0x00, 0x00, 0x00, 0x81, 0xE2, 0xB0, 0x4D, 0x83, 0x0A # 6185
    .byte 0x72, 0x11, 0x83, 0xF4, 0x04, 0x35, 0x7F, 0x18, 0x72, 0x31, 0x80, 0x2E # 6191
    .byte 0x65, 0x45, 0x25, 0x23, 0x21, 0x44, 0x64, 0x2C, 0x30, 0x00, 0x80, 0xC6 # 619D
    .byte 0xA4, 0x7E, 0x8D, 0x03, 0x00, 0x40, 0x7A, 0x10, 0xF3, 0x5A, 0x00, 0x00 # 61A9
    .byte 0xA0, 0x72, 0x4E, 0x18, 0x09, 0x00, 0x00, 0x10, 0xA5, 0xD4, 0xE8, 0x00 # 61B5
    .byte 0x00, 0x00, 0xE8, 0x76, 0x48, 0x17, 0x00, 0x00, 0x00, 0xE4, 0x0B, 0x54 # 61C1
    .byte 0x02, 0x00, 0x00, 0x00, 0xCA, 0x9A, 0x3B, 0x00, 0x00, 0x00, 0x00, 0xE1 # 61CD
    .byte 0xF5, 0x05, 0x00, 0x00, 0x00, 0x80, 0x96, 0x98, 0x00, 0x00, 0x00, 0x00 # 61D9
    .byte 0x40, 0x42, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x40, 0x42, 0x0F, 0xA0, 0x86 # 61E5
    .byte 0x01, 0x10, 0x27, 0x00, 0x10, 0x27, 0xE8, 0x03, 0x64, 0x00, 0x0A, 0x00 # 61F1
    .byte 0x01, 0x00                              # 61FD: preceding table/data tail
MATH_S32KM:
    .byte 0x00, 0x00, 0x80, 0x90                  # 61FF: MBF single -32768 ($S32KM)
    .byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF      # 6203: following table/data continues
    .byte 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x3B, 0xAA # 6209
    .byte 0x38, 0x81, 0x07, 0x7C, 0x88, 0x59, 0x74, 0xE0, 0x97, 0x26, 0x77, 0xC4 # 6215
    .byte 0x1D, 0x1E, 0x7A, 0x5E, 0x50, 0x63, 0x7C, 0x1A, 0xFE, 0x75, 0x7E, 0x18 # 6221
    .byte 0x72, 0x31, 0x80, 0x00, 0x00, 0x00, 0x81, 0x05, 0xFB, 0xD7, 0x1E, 0x86 # 622D
    .byte 0x65, 0x26, 0x99, 0x87, 0x58, 0x34, 0x23, 0x87, 0xE1, 0x5D, 0xA5, 0x86 # 6239
    .byte 0xDB, 0x0F, 0x49, 0x83, 0x02, 0xD7, 0xB3, 0x5D, 0x81, 0x00, 0x00, 0x80 # 6245
    .byte 0x81, 0x04, 0x62, 0x35, 0x83, 0x7E, 0x50, 0x24, 0x4C, 0x7E, 0x79, 0xA9 # 6251
    .byte 0xAA, 0x7F, 0x00, 0x00, 0x00, 0x81, 0x0B, 0x44, 0x4E, 0x6E, 0x83, 0xF9 # 625D
    .byte 0x22, 0x7E, 0xFD, 0x43, 0x03, 0xC3, 0x9E, 0x26, 0x01, 0x00, 0x00, 0x30 # 6269
    .byte 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x41, 0x42, 0x43 # 6275
    .byte 0x44, 0x45, 0x46 # 6281
EXP:
    mov    dx,0xaa3b                             # 6284: BA 3B AA
    mov    bx,0x8138                             # 6287: BB 38 81
    call   FMULS                                # 628A: E8 72 0A
    mov    al,ds:FACEXP                           # 628D: A0 A6 04
    cmp    al,0x88                               # 6290: 3C 88
    jae    L_62D0                                # 6292: 73 3C
    cmp    al,0x68                               # 6294: 3C 68
    jb     L_62E3                                # 6296: 72 4B
    push   WORD PTR ds:FACLO                     # 6298: FF 36 A3 04
    push   WORD PTR ds:FACSGN                     # 629C: FF 36 A5 04
    call   L_7303                                # 62A0: E8 60 10
    .byte 0x8A, 0xE2 # 62A3
    add    ah,0x81                               # 62A5: 80 C4 81
    je     L_62CD                                # 62A8: 74 23
    push   ax                                    # 62AA: 50
    test   BYTE PTR ds:FAC_AUX,0x80                # 62AB: F6 06 A7 04 80
    call   L_72F6                                # 62B0: E8 43 10
    .byte 0x32, 0xE4 # 62B3
    call   L_749E                                # 62B5: E8 E6 11
    pop    ax                                    # 62B8: 58
    pop    bx                                    # 62B9: 5B
    pop    dx                                    # 62BA: 5A
    push   ax                                    # 62BB: 50
    call   L_6767                                # 62BC: E8 A8 04
    mov    bx,0x6217                             # 62BF: BB 17 62
    call   L_7552                                # 62C2: E8 8D 12
    pop    bx                                    # 62C5: 5B
    .byte 0x33, 0xD2, 0x8A, 0xDA # 62C6
    jmp    FMULS                                # 62CA: E9 32 0A
L_62CD:
    add    sp,0x4                                # 62CD: 83 C4 04
L_62D0:
    and    BYTE PTR ds:FACSGN,0x80                # 62D0: 80 26 A5 04 80
    je     L_62DA                                # 62D5: 74 03
    jmp    ZERO                                # 62D7: E9 91 18
L_62DA:
    .byte 0x32, 0xE4 # 62DA
    mov    BYTE PTR ds:FAC_AUX,ah                  # 62DC: 88 26 A7 04
    jmp    L_74DC                                # 62E0: E9 F9 11
L_62E3:
    mov    di,0x4a3                              # 62E3: BF A3 04
    nop                                          # 62E6: 90
    .byte 0x33, 0xC0 # 62E7
    cld                                          # 62E9: FC
    stos   WORD PTR es:[di],ax                   # 62EA: AB
    mov    WORD PTR [di],0x8100                  # 62EB: C7 05 00 81
    ret                                          # 62EF: C3
MATH_TYPECHECK:
    call   GETYP                                # 62F0: E8 AF 18
    jne    L_62F8                                # 62F3: 75 03
    jmp    L_07D6                                # 62F5: E9 DE A4
L_62F8:
    ret                                          # 62F8: C3
    .byte 0xFC, 0xAB, 0xC7, 0x05, 0x00, 0x81, 0xC3 # 62F9
L_6300:
    jmp    CHRGTR                                # 6300: E9 1A AC
    .byte 0xCD, 0xB9, 0x80, 0x36, 0xA5, 0x04, 0x80, 0x80, 0x36, 0xB1, 0x04, 0x80 # 6303
    .byte 0xE9, 0x8A, 0x03 # 630F
L_6312:
    int    0xba                                  # 6312: CD BA
    xchg   cx,bx                                 # 6314: 87 D9
    jmp    L_6773                                # 6316: E9 5A 04
    .byte 0xCD, 0xBB, 0x87, 0xD9, 0xE9, 0x47, 0x04, 0xCD, 0xBC, 0xE8, 0x33, 0x19 # 6319
    .byte 0xE9, 0x1B, 0x05, 0x87, 0xD9, 0xE9, 0xB1, 0x05, 0xCD, 0xBD, 0x89, 0x1E # 6325
    .byte 0xA3, 0x04, 0xE9, 0x6B, 0x08, 0xCD, 0xBE, 0x52, 0x98, 0x8B, 0xD0, 0xE8 # 6331
    .byte 0xEE, 0x08, 0x5A, 0xC3, 0xCD, 0xBF, 0x87, 0xD9, 0xE9, 0xB7, 0x09, 0xCD # 633D
    .byte 0xC0, 0x87, 0xD9, 0xE9, 0xED, 0x0D, 0x81, 0xFB, 0x00, 0x80, 0x75, 0x13 # 6349
    .byte 0xCD, 0xC1, 0xE8, 0xD3, 0x08, 0x33, 0xD2, 0xBB, 0x80, 0x90, 0xE8, 0x05 # 6355
    .byte 0x04, 0xE8, 0x4B, 0x1A, 0xE9, 0x45, 0x08, 0xF7, 0xDB, 0x53, 0x03, 0xDA # 6361
    .byte 0x70, 0x04, 0x58, 0xE9, 0x99, 0x01, 0xCD, 0xC2, 0xE8, 0xB5, 0x08, 0x5A # 636D
    .byte 0xFF, 0x36, 0xA3, 0x04, 0xFF, 0x36, 0xA5, 0x04, 0xE8, 0xA9, 0x08, 0x5B # 6379
    .byte 0x5A, 0xE9, 0xEA, 0x03, 0x8B, 0xC3, 0x52, 0xF7, 0xEA, 0x5A, 0x72, 0x05 # 6385
    .byte 0x8B, 0xD8, 0xE9, 0x76, 0x01, 0xCD, 0xC3, 0x53, 0xE8, 0x91, 0x08, 0x5A # 6391
    .byte 0xFF, 0x36, 0xA3, 0x04, 0xFF, 0x36, 0xA5, 0x04, 0xE8, 0x85, 0x08, 0x5B # 639D
    .byte 0x5A, 0xE9, 0x52, 0x09, 0x0B, 0xDB, 0x75, 0x0C, 0x88, 0x36, 0xA7, 0x04 # 63A9
    .byte 0xC6, 0x06, 0xFB, 0x02, 0x04, 0xE9, 0x2D, 0x11, 0x89, 0x1E, 0xA3, 0x04 # 63B5
    .byte 0xB8, 0x00, 0x00, 0xA3, 0xA5, 0x04, 0x92, 0x0B, 0xC0, 0x79, 0x03, 0xBA # 63C1
    .byte 0xFF, 0xFF, 0x0B, 0xDB, 0x79, 0x06, 0xC7, 0x06, 0xA5, 0x04, 0xFF, 0xFF # 63CD
    .byte 0xF7, 0x3E, 0xA3, 0x04, 0x8B, 0xD8, 0xE9, 0x2A, 0x01, 0x87, 0xD9, 0xE8 # 63D9
    .byte 0xD7, 0x18, 0x87, 0xD9, 0xC3, 0x53, 0xE8, 0x45, 0x1A, 0x5B, 0x83, 0xC3 # 63E5
    .byte 0x04, 0xC3 # 63F1
L_63F3:
    mov    dx,WORD PTR ds:FACLO                  # 63F3: 8B 16 A3 04
    mov    cx,WORD PTR ds:FACSGN                  # 63F7: 8B 0E A5 04
    ret                                          # 63FB: C3
L_63FC:
    pushf                                        # 63FC: 9C
    push   bx                                    # 63FD: 53
    call   MOVMF                                # 63FE: E8 19 1A
    pop    bx                                    # 6401: 5B
    add    bx,0x4                                # 6402: 83 C3 04
    popf                                         # 6405: 9D
    ret                                          # 6406: C3
L_6407:
    call   L_22B5                                # 6407: E8 AB BE
    mov    WORD PTR ds:FACLO,bx                  # 640A: 89 1E A3 04
    jmp    L_6E78                                # 640E: E9 67 0A
L_6411:
    call   L_22B5                                # 6411: E8 A1 BE
    mov    WORD PTR ds:FACLO,bx                  # 6414: 89 1E A3 04
    jmp    L_6E80                                # 6418: E9 65 0A
L_641B:
    int    0xc4                                  # 641B: CD C4
    mov    dx,WORD PTR [bx]                      # 641D: 8B 17
    .byte 0x8B, 0x9F, 0x02, 0x00 # 641F
    jmp    L_6773                                # 6423: E9 4D 03
L_6426:
    pop    si                                    # 6426: 5E
    push   WORD PTR ds:FACLO                     # 6427: FF 36 A3 04
    push   WORD PTR ds:FACSGN                     # 642B: FF 36 A5 04
    jmp    si                                    # 642F: FF E6
L_6431:
    int    0xc5                                  # 6431: CD C5
    xchg   cx,bx                                 # 6433: 87 D9
    call   FCOMP                                # 6435: E8 A0 18
    xchg   cx,bx                                 # 6438: 87 D9
    ret                                          # 643A: C3
L_643B:
    call   GETYP                                # 643B: E8 64 17
    je     L_6443                                # 643E: 74 03
    jmp    L_07D6                                # 6440: E9 93 A3
L_6443:
    ret                                          # 6443: C3
L_6444:
    xchg   dx,bx                                 # 6444: 87 DA
    call   VALSNG                                # 6446: E8 CD 00
    .byte 0x32, 0xC0 # 6449
    mov    ch,0x98                               # 644B: B5 98
    int    0xc6                                  # 644D: CD C6
    mov    bx,0x4a6                              # 644F: BB A6 04
    .byte 0x8A, 0xC8 # 6452
    mov    BYTE PTR [bx],ch                      # 6454: 88 2F
    mov    ch,0x0                                # 6456: B5 00
    inc    bx                                    # 6458: 43
    mov    BYTE PTR [bx],ch                      # 6459: 88 2F
    rcl    al,1                                  # 645B: D0 D0
    int    0xc7                                  # 645D: CD C7
    jae    L_6464                                # 645F: 73 03
    call   L_6584                                # 6461: E8 20 01
L_6464:
    .byte 0x8A, 0xE5, 0x8A, 0xD9 # 6464
    jmp    L_749E                                # 6468: E9 33 10
L_646B:
    call   L_6300                                # 646B: E8 92 FE
L_646E:
    push   bx                                    # 646E: 53
    .byte 0x33, 0xDB # 646F
    mov    WORD PTR ds:FACLO,bx                  # 6471: 89 1E A3 04
    mov    bh,0x81                               # 6475: B7 81
    mov    WORD PTR ds:FACSGN,bx                  # 6477: 89 1E A5 04
    mov    BYTE PTR ds:VALTYP,0x4                 # 647B: C6 06 FB 02 04
    call   RND                              # 6480: E8 04 14
    pop    bx                                    # 6483: 5B
    mov    BYTE PTR ds:VALTYP,0x4                 # 6484: C6 06 FB 02 04
    ret                                          # 6489: C3
L_648A:
    .byte 0x8B, 0xC1 # 648A
    mul    dx                                    # 648C: F7 E2
    xchg   dx,ax                                 # 648E: 92
    jae    L_6494                                # 648F: 73 03
    jmp    L_39B9                                # 6491: E9 25 D5
L_6494:
    ret                                          # 6494: C3
    .byte 0xBB, 0xAB, 0x04 # 6495
L_6498:
    mov    dx,0x64b7                             # 6498: BA B7 64
    .byte 0xE9, 0x06, 0x00, 0xBB, 0xAB, 0x04 # 649B
L_64A1:
    mov    dx,0x64b9                             # 64A1: BA B9 64
L_64A4:
    push   dx                                    # 64A4: 52
    mov    dx,0x4a3                              # 64A5: BA A3 04
    call   GETYP                                # 64A8: E8 F7 16
    jb     L_64B0                                # 64AB: 72 03
    mov    dx,DFACL                              # 64AD: BA 9F 04
L_64B0:
    ret                                          # 64B0: C3
L_64B1:
    .byte 0x8A, 0xCD, 0x32, 0xED # 64B1
    jmp    L_64BF                                # 64B5: EB 08
    .byte 0x87, 0xDA # 64B7
L_64B9:
    mov    al,ds:VALTYP                           # 64B9: A0 FB 02
    cbw                                          # 64BC: 98
    .byte 0x8B, 0xC8 # 64BD
L_64BF:
    cld                                          # 64BF: FC
    .byte 0x8B, 0xF2, 0x8B, 0xFB # 64C0
    rep movs BYTE PTR es:[di],BYTE PTR ds:[si]   # 64C4: F3 A4
    .byte 0x8B, 0xD6, 0x8B, 0xDF # 64C6
    ret                                          # 64CA: C3
BLTU:
    call   L_2D04                                # 64CB: E8 36 C8
L_64CE:
    .byte 0x8B, 0xF1, 0x8B, 0xFB # 64CE
    std                                          # 64D2: FD
    .byte 0x2B, 0xCA # 64D3
    inc    cx                                    # 64D5: 41
    rep movs BYTE PTR es:[di],BYTE PTR ds:[si]   # 64D6: F3 A4
    .byte 0x8B, 0xDA, 0x8B, 0xCF # 64D8
    inc    cx                                    # 64DC: 41
    cld                                          # 64DD: FC
    ret                                          # 64DE: C3
L_64DF:
    pushf                                        # 64DF: 9C
    dec    cx                                    # 64E0: 49
    popf                                         # 64E1: 9D
    ret                                          # 64E2: C3
L_64E3:
    call   GETYP                                # 64E3: E8 BC 16
    jne    L_64EB                                # 64E6: 75 03
    jmp    L_07D6                                # 64E8: E9 EB A2
L_64EB:
    int    0xc8                                  # 64EB: CD C8
    js     L_64F2                                # 64ED: 78 03
    jmp    SIGN                                # 64EF: E9 83 16
L_64F2:
    mov    ax,ds:FACLO                           # 64F2: A1 A3 04
    .byte 0x0B, 0xC0 # 64F5
    je     L_64FF                                # 64F7: 74 06
L_64F9:
    mov    al,0x1                                # 64F9: B0 01
    jns    L_64FF                                # 64FB: 79 02
    mov    al,0xff                               # 64FD: B0 FF
L_64FF:
    ret                                          # 64FF: C3
L_6500:
    .byte 0x33, 0xC0, 0x0B, 0xDB # 6500
    jne    L_64F9                                # 6504: 75 F3
    ret                                          # 6506: C3
POPHRT:
    pop    bx                                    # 6507: 5B
    ret                                          # 6508: C3
CONIA:
    cbw                                          # 6509: 98
    .byte 0x8B, 0xD8 # 650A
MAKINT:
    mov    BYTE PTR ds:VALTYP,0x2                 # 650C: C6 06 FB 02 02
    mov    WORD PTR ds:FACLO,bx                  # 6511: 89 1E A3 04
    ret                                          # 6515: C3
VALSNG:
    mov    BYTE PTR ds:VALTYP,0x4                 # 6516: C6 06 FB 02 04
    ret                                          # 651B: C3
SGN:
    call   L_64E3                                # 651C: E8 C4 FF
    .byte 0xE9, 0xE7, 0xFF, 0xCD, 0xC9, 0x5B, 0x5A, 0xE9, 0xB5, 0x03, 0xE8, 0x25 # 651F
    .byte 0x06, 0x5B, 0x5A, 0xE9, 0x0B, 0x0C # 652B
L_6531:
    mov    cx,0x4                                # 6531: B9 04 00
    .byte 0xE9, 0x88, 0xFF # 6534
L_6537:
    pushf                                        # 6537: 9C
    mov    dl,BYTE PTR [bx]                      # 6538: 8A 17
    inc    bx                                    # 653A: 43
    popf                                         # 653B: 9D
L_653C:
    pushf                                        # 653C: 9C
    mov    dh,BYTE PTR [bx]                      # 653D: 8A 37
    inc    bx                                    # 653F: 43
    mov    cx,WORD PTR [bx]                      # 6540: 8B 0F
    inc    bx                                    # 6542: 43
    popf                                         # 6543: 9D
L_6544:
    pushf                                        # 6544: 9C
    inc    bx                                    # 6545: 43
    popf                                         # 6546: 9D
    ret                                          # 6547: C3
L_6548:
    push   bx                                    # 6548: 53
    mov    bx,0x728                              # 6549: BB 28 07
    call   STROUT                                # 654C: E8 06 16
    pop    bx                                    # 654F: 5B
LINPRT:
    mov    cx,0x26b6                             # 6550: B9 B6 26
    push   cx                                    # 6553: 51
    call   MAKINT                                # 6554: E8 B5 FF
    .byte 0x32, 0xC0 # 6557
    int    0xca                                  # 6559: CD CA
    mov    ds:TEMP3,al                           # 655B: A2 31 03
    mov    bx,0x4b4                              # 655E: BB B4 04
    mov    BYTE PTR [bx],0x20                    # 6561: C6 07 20
    or     al,BYTE PTR [bx]                      # 6564: 0A 07
    inc    bx                                    # 6566: 43
    mov    BYTE PTR [bx],0x30                    # 6567: C6 07 30
    jmp    L_70D7                                # 656A: E9 6A 0B
    .byte 0xCD, 0xCB, 0xA0, 0xA5, 0x04, 0xEB, 0x09, 0xCD, 0xCC, 0xE8, 0xE5, 0x17 # 656D
    .byte 0x74, 0x08, 0xF6, 0xD0, 0xD0, 0xE0, 0x1A, 0xC0, 0x74, 0x3D, 0xC3 # 6579
L_6584:
    int    0xcd                                  # 6584: CD CD
    xor    BYTE PTR ds:FAC_AUX,0x80                # 6586: 80 36 A7 04 80
    .byte 0x33, 0xDB # 658B
    neg    ch                                    # 658D: F6 DD
    .byte 0x8B, 0xC3, 0x1B, 0xC2, 0x8B, 0xD0, 0x8A, 0xC3, 0x1A, 0xC1, 0x8A, 0xC8 # 658F
L_659B:
    ret                                          # 659B: C3
FIXER:
    call   GETYP                                # 659C: E8 03 16
    js     L_659B                                # 659F: 78 FA
    int    0xce                                  # 65A1: CD CE
    call   SIGN                                # 65A3: E8 CF 15
    js     L_65AB                                # 65A6: 78 03
    jmp    VINT                             # 65A8: E9 D5 18
L_65AB:
    call   NEG                                # 65AB: E8 02 18
    call   VINT                             # 65AE: E8 CF 18
    jmp    NEG                                # 65B1: E9 FC 17
ICOMP:
    .byte 0x8B, 0xC3 # 65B4
ICMPA:
    .byte 0x2B, 0xC2 # 65B6
    je     IC40                                # 65B8: 74 0E
    jo     IC20                                # 65BA: 70 07
    js     IC30                                # 65BC: 78 07
IC10:
    .byte 0x32, 0xC0 # 65BE
INRART:
    inc    al                                    # 65C0: FE C0
    ret                                          # 65C2: C3
IC20:
    js     IC10                                # 65C3: 78 F9
IC30:
    stc                                          # 65C5: F9
    .byte 0x1A, 0xC0 # 65C6
IC40:
    ret                                          # 65C8: C3
IMOD:
    .byte 0x3B, 0xDA # 65C9
    jne    IMD10                                # 65CB: 75 05
IMD05:
    .byte 0x33, 0xDB, 0xE9, 0x26, 0x00 # 65CD
IMD10:
    .byte 0x8B, 0xC2 # 65D2
    mov    WORD PTR ds:FACLO,bx                  # 65D4: 89 1E A3 04
    .byte 0x0B, 0xDB # 65D8
    call   L_5FB0                                # 65DA: E8 D3 F9
    nop                                          # 65DD: 90
    nop                                          # 65DE: 90
    nop                                          # 65DF: 90
    jns    L_65E8                                # 65E0: 79 06
    mov    WORD PTR ds:FACSGN,0xffff              # 65E2: C7 06 A5 04 FF FF
L_65E8:
    .byte 0x0B, 0xC0 # 65E8
    mov    dx,0x0                                # 65EA: BA 00 00
    jns    L_65F2                                # 65ED: 79 03
    mov    dx,0xffff                             # 65EF: BA FF FF
L_65F2:
    idiv   WORD PTR ds:FACLO                     # 65F2: F7 3E A3 04
    .byte 0x8B, 0xDA # 65F6
IMD40:
    mov    WORD PTR ds:FACLO,bx                  # 65F8: 89 1E A3 04
    ret                                          # 65FC: C3
LOPTOP:
    lods   ax,WORD PTR ds:[si]                   # 65FD: AD
    .byte 0x3A, 0xE1 # 65FE
    je     ISIT                                # 6600: 74 11
NOTIT1:
    inc    si                                    # 6602: 46
    add    al,BYTE PTR [si]                      # 6603: 02 04
    inc    al                                    # 6605: FE C0
NOTIT0:
    cbw                                          # 6607: 98
    .byte 0x03, 0xF0 # 6608
NOTIT2:
    .byte 0x3B, 0xF5 # 660A
    jne    LOPTOP                                # 660C: 75 EF
    .byte 0x8B, 0xD6 # 660E
    jmp    L_384C                                # 6610: E9 39 D2
ISIT:
    cmp    al,BYTE PTR ds:VALTYP                  # 6613: 3A 06 FB 02
    jne    NOTIT1                                # 6617: 75 E9
    cmp    ch,BYTE PTR [si]                      # 6619: 3A 2C
    jne    NOTIT1                                # 661B: 75 E5
    inc    si                                    # 661D: 46
    .byte 0x8A, 0xD0 # 661E
    lods   al,BYTE PTR ds:[si]                   # 6620: AC
    cmp    al,BYTE PTR ds:NAMCNT                   # 6621: 3A 06 8E 00
    je     LENMAT                                # 6625: 74 04
    .byte 0x02, 0xC2 # 6627
    jmp    NOTIT0                                # 6629: EB DC
LENMAT:
    .byte 0x0A, 0xC0 # 662B
    je     FNDITV                                # 662D: 74 10
    cbw                                          # 662F: 98
    xchg   cx,ax                                 # 6630: 91
    mov    di,0x8f                               # 6631: BF 8F 00
    repz cmps BYTE PTR ds:[si],BYTE PTR es:[di]  # 6634: F3 A6
    xchg   cx,ax                                 # 6636: 91
    je     FNDITV                                # 6637: 74 06
    .byte 0x03, 0xF0, 0x8A, 0xC2 # 6639
    jmp    NOTIT0                                # 663D: EB C8
FNDITV:
    .byte 0x8B, 0xD6 # 663F
    pop    bx                                    # 6641: 5B
    ret                                          # 6642: C3
LOPFND:
    .byte 0x8B, 0xF3 # 6643
    mov    bp,WORD PTR ds:ARYTA2                  # 6645: 8B 2E 4B 04
    cld                                          # 6649: FC
    jmp    NOTIT2                                # 664A: EB BE
LOPFD1:
    .byte 0x8B, 0xF3 # 664C
    mov    bp,WORD PTR ds:STREND                  # 664E: 8B 2E 5C 03
    cld                                          # 6652: FC
    .byte 0xE9, 0x0D, 0x00 # 6653
LOPFD0:
    lods   ax,WORD PTR ds:[si]                   # 6656: AD
    .byte 0x3A, 0xE1 # 6657
    je     ISARY                                # 6659: 74 11
NMARY1:
    inc    si                                    # 665B: 46
NMARY2:
    lods   al,BYTE PTR ds:[si]                   # 665C: AC
NMARY3:
    cbw                                          # 665D: 98
    .byte 0x03, 0xF0 # 665E
NMARY4:
    lods   ax,WORD PTR ds:[si]                   # 6660: AD
    .byte 0x03, 0xF0 # 6661
LOPFDI:
    .byte 0x3B, 0xEE # 6663
    jne    LOPFD0                                # 6665: 75 EF
    .byte 0x8B, 0xDE # 6667
    jmp    L_39BF                                # 6669: E9 53 D3
ISARY:
    cmp    al,BYTE PTR ds:VALTYP                  # 666C: 3A 06 FB 02
    jne    NMARY1                                # 6670: 75 E9
    cmp    ch,BYTE PTR [si]                      # 6672: 3A 2C
    jne    NMARY1                                # 6674: 75 E5
    inc    si                                    # 6676: 46
    lods   al,BYTE PTR ds:[si]                   # 6677: AC
    cmp    al,BYTE PTR ds:NAMCNT                   # 6678: 3A 06 8E 00
    jne    NMARY3                                # 667C: 75 DF
    .byte 0x0A, 0xC0 # 667E
    je     CNOMAT                                # 6680: 74 0E
    cbw                                          # 6682: 98
    xchg   cx,ax                                 # 6683: 91
    mov    di,0x8f                               # 6684: BF 8F 00
    repz cmps BYTE PTR ds:[si],BYTE PTR es:[di]  # 6687: F3 A6
    xchg   cx,ax                                 # 6689: 91
    je     CNOMAT                                # 668A: 74 04
    .byte 0x03, 0xF0 # 668C
    jmp    NMARY4                                # 668E: EB D0
CNOMAT:
    lods   ax,WORD PTR ds:[si]                   # 6690: AD
    .byte 0x8B, 0xD0, 0x8B, 0xDE # 6691
    jmp    L_399D                                # 6695: E9 05 D3
L_6698:
    call   MOVFA                                # 6698: E8 18 16
L_669B:
    ret                                          # 669B: C3
L_669C:
    mov    ax,ds:FACSGN                           # 669C: A1 A5 04
    .byte 0x0A, 0xE4 # 669F
    je     L_6698                                # 66A1: 74 F5
    xor    BYTE PTR ds:FACSGN,0x80                # 66A3: 80 36 A5 04 80
    int    0xd7                                  # 66A8: CD D7
L_66AA:
    mov    al,0x0                                # 66AA: B0 00
    mov    ds:DFACL-1,al                           # 66AC: A2 9E 04
    mov    ds:ARGLO-1,al                           # 66AF: A2 AA 04
    mov    al,ds:ARGEXP                           # 66B2: A0 B2 04
    .byte 0x0A, 0xC0 # 66B5
    je     L_669B                                # 66B7: 74 E2
    mov    ax,ds:FACSGN                           # 66B9: A1 A5 04
    .byte 0x0A, 0xE4 # 66BC
    je     L_6698                                # 66BE: 74 D8
    mov    bx,WORD PTR ds:ARG_M1                  # 66C0: 8B 1E B1 04
    or     BYTE PTR ds:FACSGN,0x80                # 66C4: 80 0E A5 04 80
    or     BYTE PTR ds:ARG_M1,0x80                # 66C9: 80 0E B1 04 80
    .byte 0x8A, 0xCC, 0x2A, 0xCF # 66CE
    mov    ds:FAC_AUX,al                           # 66D2: A2 A7 04
    je     L_66F9                                # 66D5: 74 22
    jae    L_66EB                                # 66D7: 73 12
    xchg   bl,al                                 # 66D9: 86 C3
    neg    cl                                    # 66DB: F6 D9
    mov    ds:FAC_AUX,al                           # 66DD: A2 A7 04
    mov    BYTE PTR ds:FACEXP,bh                  # 66E0: 88 3E A6 04
    push   ax                                    # 66E4: 50
    push   cx                                    # 66E5: 51
    call   XCGAF                                # 66E6: E8 6F 15
    pop    cx                                    # 66E9: 59
    pop    ax                                    # 66EA: 58
L_66EB:
    cmp    cl,0x39                               # 66EB: 80 F9 39
    jae    L_674F                                # 66EE: 73 5F
    push   bx                                    # 66F0: 53
    clc                                          # 66F1: F8
    call   L_7C16                                # 66F2: E8 21 15
    mov    al,ds:FAC_AUX                           # 66F5: A0 A7 04
    pop    bx                                    # 66F8: 5B
L_66F9:
    .byte 0x32, 0xC3 # 66F9
    mov    bx,DFACL-1                              # 66FB: BB 9E 04
    mov    si,ARGLO-1                              # 66FE: BE AA 04
    mov    cx,0x4                                # 6701: B9 04 00
    clc                                          # 6704: F8
    cld                                          # 6705: FC
    js     L_6726                                # 6706: 78 1E
L_6708:
    lods   ax,WORD PTR ds:[si]                   # 6708: AD
    adc    WORD PTR [bx],ax                      # 6709: 11 07
    inc    bx                                    # 670B: 43
    inc    bx                                    # 670C: 43
    loop   L_6708                                # 670D: E2 F9
    jae    L_6723                                # 670F: 73 12
L_6711:
    mov    bx,0x4a6                              # 6711: BB A6 04
    inc    BYTE PTR [bx]                         # 6714: FE 07
    je     L_674C                                # 6716: 74 34
    dec    bx                                    # 6718: 4B
    dec    bx                                    # 6719: 4B
    mov    cx,0x4                                # 671A: B9 04 00
L_671D:
    rcr    WORD PTR [bx],1                       # 671D: D1 1F
    dec    bx                                    # 671F: 4B
    dec    bx                                    # 6720: 4B
    loop   L_671D                                # 6721: E2 FA
L_6723:
    jmp    L_790F                                # 6723: E9 E9 11
L_6726:
    lods   ax,WORD PTR ds:[si]                   # 6726: AD
    sbb    WORD PTR [bx],ax                      # 6727: 19 07
    inc    bx                                    # 6729: 43
    inc    bx                                    # 672A: 43
    loop   L_6726                                # 672B: E2 F9
    jae    L_6749                                # 672D: 73 1A
    .byte 0xF6, 0x97, 0x01, 0x00 # 672F
    mov    cx,0x4                                # 6733: B9 04 00
L_6736:
    dec    bx                                    # 6736: 4B
    dec    bx                                    # 6737: 4B
    not    WORD PTR [bx]                         # 6738: F7 17
    loop   L_6736                                # 673A: E2 FA
    mov    cx,0x4                                # 673C: B9 04 00
L_673F:
    inc    WORD PTR [bx]                         # 673F: FF 07
    jne    L_6749                                # 6741: 75 06
    inc    bx                                    # 6743: 43
    inc    bx                                    # 6744: 43
    loop   L_673F                                # 6745: E2 F8
    je     L_6711                                # 6747: 74 C8
L_6749:
    jmp    L_7440                                # 6749: E9 F4 0C
L_674C:
    jmp    L_74DC                                # 674C: E9 8D 0D
L_674F:
    mov    al,ds:FAC_AUX                           # 674F: A0 A7 04
    and    al,0x80                               # 6752: 24 80
    and    BYTE PTR ds:FACSGN,0x7f                # 6754: 80 26 A5 04 7F
    or     BYTE PTR ds:FACSGN,al                  # 6759: 08 06 A5 04
    ret                                          # 675D: C3
L_675E:
    mov    WORD PTR ds:FACSGN,bx                  # 675E: 89 1E A5 04
    mov    WORD PTR ds:FACLO,dx                  # 6762: 89 16 A3 04
L_6766:
    ret                                          # 6766: C3
L_6767:
    mov    ax,ds:FACSGN                           # 6767: A1 A5 04
    .byte 0x0A, 0xE4 # 676A
    je     L_675E                                # 676C: 74 F0
    xor    BYTE PTR ds:FACSGN,0x80                # 676E: 80 36 A5 04 80
L_6773:
    .byte 0x0A, 0xFF # 6773
    je     L_6766                                # 6775: 74 EF
    mov    ax,ds:FACSGN                           # 6777: A1 A5 04
    .byte 0x0A, 0xE4 # 677A
    je     L_675E                                # 677C: 74 E0
    .byte 0x33, 0xC9 # 677E
    mov    si,WORD PTR ds:FACLO                  # 6780: 8B 36 A3 04
    mov    ds:FAC_AUX,al                           # 6784: A2 A7 04
    .byte 0x8A, 0xCC, 0x2A, 0xCF # 6787
    jae    L_679A                                # 678B: 73 0D
    neg    cl                                    # 678D: F6 D9
    xchg   bh,bl                                 # 678F: 86 DF
    mov    WORD PTR ds:FACEXP,bx                  # 6791: 89 1E A6 04
    xchg   bh,bl                                 # 6795: 86 DF
    xchg   bx,ax                                 # 6797: 93
    xchg   si,dx                                 # 6798: 87 D6
L_679A:
    .byte 0x8A, 0xE0, 0x32, 0xE3 # 679A
    pushf                                        # 679E: 9C
    mov    ah,0x80                               # 679F: B4 80
    .byte 0x0A, 0xC4, 0x0A, 0xDC, 0x32, 0xE4, 0x8A, 0xFC # 67A1
L_67A9:
    .byte 0x0B, 0xC9 # 67A9
    je     L_67F3                                # 67AB: 74 46
    cmp    cx,0x19                               # 67AD: 83 F9 19
    jb     L_67C4                                # 67B0: 72 12
    popf                                         # 67B2: 9D
    mov    WORD PTR ds:FACLO,si                  # 67B3: 89 36 A3 04
    mov    ah,BYTE PTR ds:FAC_AUX                  # 67B7: 8A 26 A7 04
    and    ax,0x807f                             # 67BB: 25 7F 80
    .byte 0x0A, 0xC4 # 67BE
    mov    ds:FACSGN,al                           # 67C0: A2 A5 04
    ret                                          # 67C3: C3
L_67C4:
    cmp    cl,0x8                                # 67C4: 80 F9 08
    jb     L_67E5                                # 67C7: 72 1C
    jmp    L_6AD1                                # 67C9: E9 05 03
    .byte 0x90 # 67CC
L_67CD:
    .byte 0x8A, 0xF3, 0x32, 0xDB # 67CD
    sub    cl,0x8                                # 67D1: 80 E9 08
    test   ah,0x1f                               # 67D4: F6 C4 1F
    je     L_67A9                                # 67D7: 74 D0
    or     ah,0x20                               # 67D9: 80 CC 20
    jmp    L_67A9                                # 67DC: EB CB
L_67DE:
    or     ah,0x20                               # 67DE: 80 CC 20
    loop   L_67E6                                # 67E1: E2 03
    jmp    L_67F3                                # 67E3: EB 0E
L_67E5:
    clc                                          # 67E5: F8
L_67E6:
    rcr    bl,1                                  # 67E6: D0 DB
    rcr    dx,1                                  # 67E8: D1 DA
    rcr    ah,1                                  # 67EA: D0 DC
    test   ah,0x10                               # 67EC: F6 C4 10
    jne    L_67DE                                # 67EF: 75 ED
    loop   L_67E6                                # 67F1: E2 F3
L_67F3:
    popf                                         # 67F3: 9D
    jns    L_681B                                # 67F4: 79 25
    .byte 0x2A, 0xCC, 0x8A, 0xE1, 0x1B, 0xF2, 0x8B, 0xD6, 0x1A, 0xC3, 0x8A, 0xD8 # 67F6
    jae    L_6833                                # 6802: 73 2F
    not    BYTE PTR ds:FAC_AUX                     # 6804: F6 16 A7 04
    not    ah                                    # 6808: F6 D4
    not    dx                                    # 680A: F7 D2
    not    bl                                    # 680C: F6 D3
    inc    ah                                    # 680E: FE C4
    jne    L_6833                                # 6810: 75 21
    inc    dx                                    # 6812: 42
    jne    L_6833                                # 6813: 75 1E
    inc    bl                                    # 6815: FE C3
    jne    L_6833                                # 6817: 75 1A
    jmp    L_6821                                # 6819: EB 06
L_681B:
    .byte 0x03, 0xD6, 0x12, 0xD8 # 681B
    jae    L_682D                                # 681F: 73 0C
L_6821:
    inc    BYTE PTR ds:FACEXP                     # 6821: FE 06 A6 04
    je     L_6830                                # 6825: 74 09
    rcr    bl,1                                  # 6827: D0 DB
    rcr    dx,1                                  # 6829: D1 DA
    rcr    ah,1                                  # 682B: D0 DC
L_682D:
    jmp    L_7954                                # 682D: E9 24 11
L_6830:
    jmp    L_74DC                                # 6830: E9 A9 0C
L_6833:
    jmp    L_749E                                # 6833: E9 68 0C
L_6836:
    call   DZERO                                # 6836: E8 25 13
    ret                                          # 6839: C3
L_683A:
    mov    al,ds:ARG_M1                           # 683A: A0 B1 04
    mov    ds:FAC_AUX,al                           # 683D: A2 A7 04
    jmp    L_74EA                                # 6840: E9 A7 0C
L_6843:
    test   BYTE PTR ds:FACEXP,0xff                # 6843: F6 06 A6 04 FF
    je     L_683A                                # 6848: 74 F0
    test   BYTE PTR ds:ARGEXP,0xff                # 684A: F6 06 B2 04 FF
    je     L_6836                                # 684F: 74 E5
    mov    bx,WORD PTR ds:ARG_M1                  # 6851: 8B 1E B1 04
    call   SEXPS                                # 6855: E8 F3 F4
    mov    WORD PTR ds:ARG_M1,bx                  # 6858: 89 1E B1 04
    mov    bx,0x4a4                              # 685C: BB A4 04
    clc                                          # 685F: F8
    call   L_7C04                                # 6860: E8 A1 13
    mov    bx,0x4b0                              # 6863: BB B0 04
    clc                                          # 6866: F8
    call   L_7C04                                # 6867: E8 9A 13
    push   WORD PTR ds:FACEXP                     # 686A: FF 36 A6 04
    call   SETDB                                # 686E: E8 5E 15
    pop    WORD PTR ds:FACEXP                     # 6871: 8F 06 A6 04
    mov    cx,0x40                               # 6875: B9 40 00
    push   cx                                    # 6878: 51
    jmp    L_6883                                # 6879: EB 08
L_687B:
    push   cx                                    # 687B: 51
    clc                                          # 687C: F8
    mov    bx,ARGLO-1                              # 687D: BB AA 04
    call   L_7BFA                                # 6880: E8 77 13
L_6883:
    .byte 0x8B, 0xFC # 6883
    sub    sp,0x8                                # 6885: 83 EC 08
    sub    di,0x2                                # 6888: 83 EF 02
    mov    si,0x4b0                              # 688B: BE B0 04
    mov    cx,0x4                                # 688E: B9 04 00
    std                                          # 6891: FD
    rep movs WORD PTR es:[di],WORD PTR ds:[si]   # 6892: F3 A5
    mov    si,DBUFF                              # 6894: BE 78 04
    mov    cx,0x4                                # 6897: B9 04 00
    mov    bx,ARGLO-1                              # 689A: BB AA 04
    clc                                          # 689D: F8
    cld                                          # 689E: FC
L_689F:
    lods   ax,WORD PTR ds:[si]                   # 689F: AD
    sbb    WORD PTR [bx],ax                      # 68A0: 19 07
    inc    bx                                    # 68A2: 43
    inc    bx                                    # 68A3: 43
    loop   L_689F                                # 68A4: E2 F9
    jae    L_68B8                                # 68A6: 73 10
    mov    cx,0x4                                # 68A8: B9 04 00
    .byte 0x8B, 0xF4 # 68AB
    mov    di,ARGLO-1                              # 68AD: BF AA 04
    cld                                          # 68B0: FC
    rep movs WORD PTR es:[di],WORD PTR ds:[si]   # 68B1: F3 A5
    .byte 0x8B, 0xE6 # 68B3
    clc                                          # 68B5: F8
    jmp    L_68BC                                # 68B6: EB 04
L_68B8:
    add    sp,0x8                                # 68B8: 83 C4 08
    stc                                          # 68BB: F9
L_68BC:
    mov    bx,DFACL-1                              # 68BC: BB 9E 04
    call   L_7BFA                                # 68BF: E8 38 13
    pop    cx                                    # 68C2: 59
    loop   L_687B                                # 68C3: E2 B6
    test   BYTE PTR ds:FACSGN,0x80                # 68C5: F6 06 A5 04 80
    je     L_68D5                                # 68CA: 74 09
    inc    WORD PTR ds:FACEXP                     # 68CC: FF 06 A6 04
    jne    L_68DB                                # 68D0: 75 09
    jmp    L_74DC                                # 68D2: E9 07 0C
L_68D5:
    mov    bx,DFACL-1                              # 68D5: BB 9E 04
    call   L_7BFA                                # 68D8: E8 1F 13
L_68DB:
    jmp    L_790F                                # 68DB: E9 31 10
L_68DE:
    call   SIGN                                # 68DE: E8 94 12
    jne    L_68EA                                # 68E1: 75 07
    mov    BYTE PTR ds:FAC_AUX,bl                  # 68E3: 88 1E A7 04
    jmp    L_74EA                                # 68E7: E9 00 0C
L_68EA:
    .byte 0x0A, 0xFF # 68EA
    jne    L_68F1                                # 68EC: 75 03
    jmp    ZERO                                # 68EE: E9 7A 12
L_68F1:
    call   SEXPS                                # 68F1: E8 57 F4
    .byte 0x8B, 0xFA, 0x33, 0xD2, 0x8A, 0xFE, 0x8B, 0xF3, 0x8A, 0xDF # 68F4
    mov    cx,0x20                               # 68FE: B9 20 00
    push   bp                                    # 6901: 55
    mov    bp,WORD PTR ds:FACLO                  # 6902: 8B 2E A3 04
    mov    al,ds:FACSGN                           # 6906: A0 A5 04
    .byte 0x8A, 0xE7 # 6909
    jmp    L_6912                                # 690B: EB 05
L_690D:
    clc                                          # 690D: F8
    rcl    di,1                                  # 690E: D1 D7
    rcl    si,1                                  # 6910: D1 D6
L_6912:
    push   si                                    # 6912: 56
    push   di                                    # 6913: 57
    .byte 0x2B, 0xFD, 0x1B, 0xF0 # 6914
    jae    L_691E                                # 6918: 73 04
    pop    di                                    # 691A: 5F
    pop    si                                    # 691B: 5E
    jmp    L_6922                                # 691C: EB 04
L_691E:
    add    sp,0x4                                # 691E: 83 C4 04
    clc                                          # 6921: F8
L_6922:
    cmc                                          # 6922: F5
    rcl    dx,1                                  # 6923: D1 D2
    rcl    bx,1                                  # 6925: D1 D3
    loop   L_690D                                # 6927: E2 E4
    .byte 0x0B, 0xDB # 6929
    jns    L_6937                                # 692B: 79 0A
    inc    BYTE PTR ds:FACEXP                     # 692D: FE 06 A6 04
    jne    L_693B                                # 6931: 75 08
    pop    bp                                    # 6933: 5D
    jmp    L_74DC                                # 6934: E9 A5 0B
L_6937:
    rcl    dx,1                                  # 6937: D1 D2
    rcl    bx,1                                  # 6939: D1 D3
L_693B:
    .byte 0x8A, 0xE2, 0x8A, 0xD6, 0x8A, 0xF3, 0x8A, 0xDF # 693B
    pop    bp                                    # 6943: 5D
    jmp    L_7954                                # 6944: E9 0D 10
L_6947:
    .byte 0x13, 0xF9 # 6947
    push   bx                                    # 6949: 53
    push   di                                    # 694A: 57
    push   cx                                    # 694B: 51
    sub    al,0x30                               # 694C: 2C 30
    push   ax                                    # 694E: 50
    call   GETYP                                # 694F: E8 50 12
    pop    ax                                    # 6952: 58
    cbw                                          # 6953: 98
    jns    L_6974                                # 6954: 79 1E
    mov    bx,WORD PTR ds:FACLO                  # 6956: 8B 1E A3 04
    cmp    bx,0xccd                              # 695A: 81 FB CD 0C
    jae    L_6979                                # 695E: 73 19
    .byte 0x8B, 0xCB # 6960
    shl    bx,1                                  # 6962: D1 E3
    shl    bx,1                                  # 6964: D1 E3
    .byte 0x03, 0xD9 # 6966
    shl    bx,1                                  # 6968: D1 E3
    .byte 0x03, 0xD8 # 696A
    js     L_6979                                # 696C: 78 0B
    mov    WORD PTR ds:FACLO,bx                  # 696E: 89 1E A3 04
    jmp    L_69BC                                # 6972: EB 48
L_6974:
    push   ax                                    # 6974: 50
    jb     L_697F                                # 6975: 72 08
    jmp    L_69AC                                # 6977: EB 33
L_6979:
    push   ax                                    # 6979: 50
    call   CSI                                # 697A: E8 24 02
    jmp    L_6993                                # 697D: EB 14
L_697F:
    mov    WORD PTR ds:DBUFF+4,0x2400              # 697F: C7 06 7C 04 00 24
    mov    WORD PTR ds:DBUFF+6,0x9474              # 6985: C7 06 7E 04 74 94
    mov    bx,DBUFF+6                              # 698B: BB 7E 04
    call   COMPM                                # 698E: E8 83 13
    jns    L_69A9                                # 6991: 79 16
L_6993:
    call   MUL10                                # 6993: E8 3C 12
    pop    dx                                    # 6996: 5A
    push   WORD PTR ds:FACLO                     # 6997: FF 36 A3 04
    push   WORD PTR ds:FACSGN                     # 699B: FF 36 A5 04
    call   FLT                                # 699F: E8 8B 02
    pop    bx                                    # 69A2: 5B
    pop    dx                                    # 69A3: 5A
    call   L_6773                                # 69A4: E8 CC FD
    jmp    L_69BC                                # 69A7: EB 13
L_69A9:
    call   L_6B93                                # 69A9: E8 E7 01
L_69AC:
    call   MUL10                                # 69AC: E8 23 12
    call   MOVAF                                # 69AF: E8 EE 12
    pop    dx                                    # 69B2: 5A
    call   FLT                                # 69B3: E8 77 02
    call   L_6B93                                # 69B6: E8 DA 01
    call   L_66AA                                # 69B9: E8 EE FC
L_69BC:
    pop    cx                                    # 69BC: 59
    pop    di                                    # 69BD: 5F
    pop    bx                                    # 69BE: 5B
    ret                                          # 69BF: C3
L_69C0:
    int    0xd9                                  # 69C0: CD D9
    .byte 0x32, 0xC0, 0xE9, 0x09, 0x00 # 69C2
L_69C7:
    int    0xda                                  # 69C7: CD DA
    mov    al,0x1                                # 69C9: B0 01
    mov    BYTE PTR ds:VALTYP,0x8                 # 69CB: C6 06 FB 02 08
L_69D0:
    mov    BYTE PTR ds:FLGOVC,0x1                 # 69D0: C6 06 A8 04 01
    mov    si,0x25b4                             # 69D5: BE B4 25
    push   si                                    # 69D8: 56
    .byte 0x33, 0xFF, 0x8B, 0xCF, 0x8B, 0xF7 # 69D9
    not    cx                                    # 69DF: F7 D1
    push   ax                                    # 69E1: 50
    call   ZERO                                # 69E2: E8 86 11
    pop    ax                                    # 69E5: 58
    .byte 0x0A, 0xC0 # 69E6
    jne    L_69EF                                # 69E8: 75 05
    mov    BYTE PTR ds:VALTYP,0x2                 # 69EA: C6 06 FB 02 02
L_69EF:
    mov    al,BYTE PTR [bx]                      # 69EF: 8A 07
    cmp    al,0x26                               # 69F1: 3C 26
    jne    L_69F8                                # 69F3: 75 03
    jmp    L_19FF                                # 69F5: E9 07 B0
L_69F8:
    cmp    al,0x2d                               # 69F8: 3C 2D
    pushf                                        # 69FA: 9C
    je     L_6A02                                # 69FB: 74 05
    cmp    al,0x2b                               # 69FD: 3C 2B
    je     L_6A02                                # 69FF: 74 01
    dec    bx                                    # 6A01: 4B
L_6A02:
    call   L_6300                                # 6A02: E8 FB F8
    jae    L_6A0D                                # 6A05: 73 06
    call   L_6947                                # 6A07: E8 3D FF
    .byte 0xE9, 0xF5, 0xFF # 6A0A
L_6A0D:
    mov    bp,0x61a3                             # 6A0D: BD A3 61
    .byte 0x33, 0xD2, 0x8B, 0xF2 # 6A10
L_6A14:
    .byte 0x2E, 0x3A, 0x86, 0x00, 0x00 # 6A14
    je     L_6A25                                # 6A19: 74 0A
    cmp    bp,0x619c                             # 6A1B: 81 FD 9C 61
    je     L_6A45                                # 6A1F: 74 24
    dec    bp                                    # 6A21: 4D
    .byte 0xE9, 0xEF, 0xFF # 6A22
L_6A25:
    sub    bp,0x619c                             # 6A25: 81 ED 9C 61
    shl    bp,1                                  # 6A29: D1 E5
    jmp    WORD PTR cs:[bp+0x6a30]               # 6A2B: 2E FF A6 30 6A
    .byte 0x4B, 0x6A, 0x5F, 0x6A, 0x5F, 0x6A, 0x67, 0x6A, 0x6D, 0x6A, 0x73, 0x6A # 6A30
    .byte 0x40, 0x6A, 0x40, 0x6A, 0x32, 0xC0, 0xE8, 0x9C, 0x00 # 6A3C
L_6A45:
    call   L_6A89                                # 6A45: E8 41 00
    .byte 0xE9, 0x2D, 0x00, 0x41, 0x75, 0xF7, 0xE8, 0x51, 0x11, 0x79, 0xAF, 0x51 # 6A48
    .byte 0x53, 0x57, 0xE8, 0x48, 0x01, 0x5F, 0x5B, 0x59, 0xE9, 0xA3, 0xFF, 0xE8 # 6A54
    .byte 0x8C, 0xF3, 0x74, 0xE1, 0xE9, 0xDB, 0xFF, 0x43, 0xEB, 0xDB, 0xE9, 0x0B # 6A60
    .byte 0x00, 0xE8, 0xBC, 0x00, 0xE9, 0x05, 0x00, 0x32, 0xC0, 0xE8, 0xB6, 0x00 # 6A6C
L_6A78:
    popf                                         # 6A78: 9D
    jne    L_6A88                                # 6A79: 75 0D
    call   VNEG                                # 6A7B: E8 2D 13
    call   GETYP                                # 6A7E: E8 21 11
    jp     L_6A88                                # 6A81: 7A 05
    push   bx                                    # 6A83: 53
    call   CONI2                                # 6A84: E8 ED 12
    pop    bx                                    # 6A87: 5B
L_6A88:
    ret                                          # 6A88: C3
L_6A89:
    jmp    L_5F02                                # 6A89: E9 76 F4
L_6A8C:
    mov    BYTE PTR ds:NXTFLG,0xff                # 6A8C: C6 06 55 04 FF
    call   CHRGTR                                # 6A91: E8 89 A4
    .byte 0x8B, 0xD4 # 6A94
    jmp    L_737C                                # 6A96: E9 E3 08
ZCMPCK:
    .byte 0x0A, 0xFF # 6A99
    jne    NZCOMP                                # 6A9B: 75 05
    call   SIS05                                # 6A9D: E8 E8 10
    stc                                          # 6AA0: F9
    ret                                          # 6AA1: C3
NZCOMP:
    mov    al,ds:FACEXP                           # 6AA2: A0 A6 04
    .byte 0x0A, 0xC0 # 6AA5
    jne    ZCMPRT                                # 6AA7: 75 08
    .byte 0x8A, 0xC3 # 6AA9
    not    al                                    # 6AAB: F6 D0
    call   SIGNAL                                # 6AAD: E8 E4 10
    stc                                          # 6AB0: F9
ZCMPRT:
    ret                                          # 6AB1: C3
L_6AB2:
    call   ZCMPCK                                # 6AB2: E8 E4 FF
    pop    bp                                    # 6AB5: 5D
    jb     ZEREXP                                # 6AB6: 72 14
    jmp    L_6ACA                                # 6AB8: EB 10
L_6ABA:
    push   bx                                    # 6ABA: 53
    mov    bx,WORD PTR [bx]                      # 6ABB: 8B 1F
    call   ZCMPCK                                # 6ABD: E8 D9 FF
    pop    bx                                    # 6AC0: 5B
    pop    bp                                    # 6AC1: 5D
    jb     ZEREXP                                # 6AC2: 72 08
    push   bx                                    # 6AC4: 53
    push   di                                    # 6AC5: 57
    mov    di,FACM1                              # 6AC6: BF A5 04
    nop                                          # 6AC9: 90
L_6ACA:
    push   bp                                    # 6ACA: 55
    ret                                          # 6ACB: C3
ZEREXP:
    inc    al                                    # 6ACC: FE C0
    sub    al,0x1                                # 6ACE: 2C 01
    ret                                          # 6AD0: C3
L_6AD1:
    test   ah,0xff                               # 6AD1: F6 C4 FF
    .byte 0x8A, 0xE2 # 6AD4
    je     L_6ADB                                # 6AD6: 74 03
    or     ah,0x20                               # 6AD8: 80 CC 20
L_6ADB:
    .byte 0x8A, 0xD6 # 6ADB
    jmp    L_67CD                                # 6ADD: E9 ED FC
    .byte 0x10, 0x9F, 0x80, 0x3E, 0xFB, 0x02, 0x08, 0x75, 0x04, 0x9E, 0xE9, 0x08 # 6AE0
    .byte 0x00, 0x9E, 0x53, 0x57, 0xE8, 0x5C, 0x00, 0x5F, 0x5B, 0x33, 0xF6, 0x8B # 6AEC
    .byte 0xD6, 0xE8, 0x04, 0xF8, 0x72, 0x13, 0x3C, 0x2D, 0x75, 0x04, 0xF7, 0xD6 # 6AF8
    .byte 0xEB, 0x05, 0x3C, 0x2B, 0x74, 0x01, 0xC3, 0xE8, 0xF2, 0xF7, 0x72, 0x01 # 6B04
    .byte 0xC3, 0x81, 0xFA, 0xCC, 0x0C, 0x72, 0x05, 0xBA, 0xFF, 0x7F, 0xEB, 0xEF # 6B10
    .byte 0x50, 0xB8, 0x0A, 0x00, 0xF7, 0xE2, 0x5A, 0x80, 0xEA, 0x30, 0x32, 0xF6 # 6B1C
    .byte 0x03, 0xD0, 0xEB, 0xDF, 0x0C, 0x01, 0x53, 0x57, 0x75, 0x07, 0xE8, 0x1C # 6B28
    .byte 0x00, 0xEB, 0x05, 0x90, 0x90, 0xE8, 0x46, 0x00, 0x5F, 0x5B, 0x33, 0xF6 # 6B34
    .byte 0x8B, 0xD6, 0xE8, 0xBD, 0xF3, 0x43, 0xC3, 0xE8, 0x58, 0x10, 0x78, 0xF9 # 6B40
    .byte 0xE9, 0x6F, 0x9C, 0x74, 0x31 # 6B4C
FRCSNG:
    call   GETYP                                # 6B51: E8 4E 10
    jnp    L_6BAC                                # 6B54: 7B 56
    jne    L_6B5B                                # 6B56: 75 03
    jmp    L_07D6                                # 6B58: E9 7B 9C
L_6B5B:
    int    0xcf                                  # 6B5B: CD CF
    jns    CSD                                # 6B5D: 79 05
    call   CSI                                # 6B5F: E8 3F 00
    jmp    L_6BAC                                # 6B62: EB 48
CSD:
    mov    al,0x4                                # 6B64: B0 04
    mov    ds:VALTYP,al                           # 6B66: A2 FB 02
    mov    bl,BYTE PTR ds:FACSGN                  # 6B69: 8A 1E A5 04
    mov    BYTE PTR ds:FAC_AUX,bl                  # 6B6D: 88 1E A7 04
    mov    dx,WORD PTR ds:FACLO                  # 6B71: 8B 16 A3 04
    mov    ah,BYTE PTR ds:DFACL+3                  # 6B75: 8A 26 A2 04
    or     ah,0x40                               # 6B79: 80 CC 40
    or     bl,0x80                               # 6B7C: 80 CB 80
    jmp    L_7957                                # 6B7F: E9 D5 0D
FRCDBL:
    call   GETYP                                # 6B82: E8 1D 10
    jae    L_6BAC                                # 6B85: 73 25
    jne    L_6B8C                                # 6B87: 75 03
    jmp    L_07D6                                # 6B89: E9 4A 9C
L_6B8C:
    int    0xd0                                  # 6B8C: CD D0
    jns    L_6B93                                # 6B8E: 79 03
    call   CSI                                # 6B90: E8 0E 00
L_6B93:
    mov    al,0x8                                # 6B93: B0 08
    mov    ds:VALTYP,al                           # 6B95: A2 FB 02
    .byte 0x33, 0xC0 # 6B98
    mov    ds:DFACL,ax                           # 6B9A: A3 9F 04
    mov    ds:DFACL+2,ax                           # 6B9D: A3 A1 04
    ret                                          # 6BA0: C3
CSI:
    push   dx                                    # 6BA1: 52
    push   si                                    # 6BA2: 56
    mov    dx,WORD PTR ds:FACLO                  # 6BA3: 8B 16 A3 04
    call   FLT                                # 6BA7: E8 83 00
    pop    si                                    # 6BAA: 5E
    pop    dx                                    # 6BAB: 5A
L_6BAC:
    ret                                          # 6BAC: C3
FRCINT:
    call   GETYP                                # 6BAD: E8 F2 0F
    jns    L_6BB7                                # 6BB0: 79 05
    mov    bx,WORD PTR ds:FACLO                  # 6BB2: 8B 1E A3 04
    ret                                          # 6BB6: C3
L_6BB7:
    int    0xd1                                  # 6BB7: CD D1
    jne    L_6BBE                                # 6BB9: 75 03
    jmp    L_07D6                                # 6BBB: E9 18 9C
L_6BBE:
    mov    al,ds:FACEXP                           # 6BBE: A0 A6 04
    cmp    al,0x90                               # 6BC1: 3C 90
    jb     L_6BF6                                # 6BC3: 72 31
    je     L_6BCA                                # 6BC5: 74 03
    jmp    L_07D0                                # 6BC7: E9 06 9C
L_6BCA:
    mov    al,ds:FACSGN                           # 6BCA: A0 A5 04
    .byte 0x0A, 0xC0 # 6BCD
    js     L_6BD4                                # 6BCF: 78 03
    jmp    L_07D0                                # 6BD1: E9 FC 9B
L_6BD4:
    mov    dx,0x0                                # 6BD4: BA 00 00
    mov    bx,0x8000                             # 6BD7: BB 00 80
    call   L_6767                                # 6BDA: E8 8A FB
    call   L_72AB                                # 6BDD: E8 CB 06
    call   NEG                                # 6BE0: E8 CD 11
    mov    dx,0x0                                # 6BE3: BA 00 00
    mov    bx,0x9080                             # 6BE6: BB 80 90
    call   FCOMP                                # 6BE9: E8 EC 10
    je     L_6BF1                                # 6BEC: 74 03
    jmp    L_07D0                                # 6BEE: E9 DF 9B
L_6BF1:
    mov    bx,0x8000                             # 6BF1: BB 00 80
    jmp    L_6C23                                # 6BF4: EB 2D
L_6BF6:
    mov    al,ds:FACSGN                           # 6BF6: A0 A5 04
    .byte 0x0A, 0xC0 # 6BF9
    pushf                                        # 6BFB: 9C
    jns    L_6C03                                # 6BFC: 79 05
    and    al,0x7f                               # 6BFE: 24 7F
    mov    ds:FACSGN,al                           # 6C00: A2 A5 04
L_6C03:
    mov    dx,0x0                                # 6C03: BA 00 00
    mov    bx,0x8000                             # 6C06: BB 00 80
    call   L_6773                                # 6C09: E8 67 FB
    mov    al,ds:FACEXP                           # 6C0C: A0 A6 04
    cmp    al,0x90                               # 6C0F: 3C 90
    jne    L_6C19                                # 6C11: 75 06
    popf                                         # 6C13: 9D
    js     L_6BF1                                # 6C14: 78 DB
    jmp    L_07D0                                # 6C16: E9 B7 9B
L_6C19:
    call   L_7303                                # 6C19: E8 E7 06
    .byte 0x8B, 0xDA # 6C1C
    popf                                         # 6C1E: 9D
    jns    L_6C23                                # 6C1F: 79 02
    neg    bx                                    # 6C21: F7 DB
L_6C23:
    mov    WORD PTR ds:FACLO,bx                  # 6C23: 89 1E A3 04
    mov    BYTE PTR ds:VALTYP,0x2                 # 6C27: C6 06 FB 02 02
    ret                                          # 6C2C: C3
FLT:
    .byte 0x33, 0xDB, 0x32, 0xE4 # 6C2D
    mov    si,FAC_AUX                              # 6C31: BE A7 04
    .byte 0xC6, 0x84, 0xFF, 0xFF, 0x90 # 6C34
    mov    BYTE PTR [si],0x0                     # 6C39: C6 04 00
    .byte 0x0B, 0xD2 # 6C3C
    jns    L_6C45                                # 6C3E: 79 05
    neg    dx                                    # 6C40: F7 DA
    mov    BYTE PTR [si],0x80                    # 6C42: C6 04 80
L_6C45:
    .byte 0x8A, 0xDE, 0x8A, 0xF2, 0x8A, 0xD7 # 6C45
    mov    BYTE PTR ds:VALTYP,0x4                 # 6C4B: C6 06 FB 02 04
    jmp    L_749E                                # 6C50: E9 4B 08
    .byte 0xCD, 0xD6 # 6C53
DMULT:
FMULD:
    mov    al,ds:FACEXP                           # 6C55: A0 A6 04
    .byte 0x0A, 0xC0 # 6C58
    je     FMD10                                # 6C5A: 74 0A
    mov    al,ds:ARGEXP                           # 6C5C: A0 B2 04
    .byte 0x0A, 0xC0 # 6C5F
    jne    FMD20                                # 6C61: 75 04
    jmp    DZERO                                # 6C63: E9 F8 0E
FMD10:
    ret                                          # 6C66: C3
FMD20:
    mov    bx,WORD PTR ds:ARG_M1                  # 6C67: 8B 1E B1 04
    call   AEXPS                                # 6C6B: E8 DA F0
    push   WORD PTR ds:FACEXP                     # 6C6E: FF 36 A6 04
    mov    WORD PTR ds:ARG_M1,bx                  # 6C72: 89 1E B1 04
    call   SETDB                                # 6C76: E8 56 11
    .byte 0x8B, 0xF0 # 6C79
    mov    ds:FACEXP,ax                           # 6C7B: A3 A6 04
    mov    bx,DBUFF                              # 6C7E: BB 78 04
    mov    ds:ARGEXP,ax                           # 6C81: A3 B2 04
    mov    bp,ARGLO                              # 6C84: BD AB 04
L_6C87:
    mov    ax,WORD PTR [bx+si]                   # 6C87: 8B 00
    .byte 0x0B, 0xC0 # 6C89
    je     L_6CB9                                # 6C8B: 74 2C
    mov    di,0x0                                # 6C8D: BF 00 00
    .byte 0x8B, 0xCF # 6C90
L_6C92:
    mov    ax,WORD PTR [bx+si]                   # 6C92: 8B 00
    mul    WORD PTR [bp+di]                      # 6C94: F7 23
    push   bx                                    # 6C96: 53
    .byte 0x8B, 0xDE, 0x03, 0xDF # 6C97
    add    bx,DFACL-8                              # 6C9B: 81 C3 97 04
    add    ax,WORD PTR [bx]                      # 6C9F: 03 07
    jae    L_6CA4                                # 6CA1: 73 01
    inc    dx                                    # 6CA3: 42
L_6CA4:
    .byte 0x03, 0xC1 # 6CA4
    jae    L_6CA9                                # 6CA6: 73 01
    inc    dx                                    # 6CA8: 42
L_6CA9:
    mov    WORD PTR [bx],ax                      # 6CA9: 89 07
    .byte 0x8B, 0xCA # 6CAB
    pop    bx                                    # 6CAD: 5B
    cmp    di,0x6                                # 6CAE: 83 FF 06
    je     L_6CB7                                # 6CB1: 74 04
    inc    di                                    # 6CB3: 47
    inc    di                                    # 6CB4: 47
    jmp    L_6C92                                # 6CB5: EB DB
L_6CB7:
    .byte 0x8B, 0xC1 # 6CB7
L_6CB9:
    push   bx                                    # 6CB9: 53
    mov    bx,DFACL                              # 6CBA: BB 9F 04
    mov    WORD PTR [bx+si],ax                   # 6CBD: 89 00
    pop    bx                                    # 6CBF: 5B
    cmp    si,0x6                                # 6CC0: 83 FE 06
    je     L_6CC9                                # 6CC3: 74 04
    inc    si                                    # 6CC5: 46
    inc    si                                    # 6CC6: 46
    jmp    L_6C87                                # 6CC7: EB BE
L_6CC9:
    mov    si,0x49d                              # 6CC9: BE 9D 04
    std                                          # 6CCC: FD
    mov    cx,0x7                                # 6CCD: B9 07 00
L_6CD0:
    lods   al,BYTE PTR ds:[si]                   # 6CD0: AC
    .byte 0x0A, 0xC0 # 6CD1
    loope  L_6CD0                                # 6CD3: E1 FB
    je     L_6CDC                                # 6CD5: 74 05
    or     BYTE PTR ds:DFACL-1,0x20                # 6CD7: 80 0E 9E 04 20
L_6CDC:
    mov    al,ds:FACSGN                           # 6CDC: A0 A5 04
    .byte 0x0A, 0xC0 # 6CDF
    pop    WORD PTR ds:FACEXP                     # 6CE1: 8F 06 A6 04
    js     L_6CF6                                # 6CE5: 78 0F
    mov    bx,DFACL-1                              # 6CE7: BB 9E 04
    mov    cx,0x4                                # 6CEA: B9 04 00
L_6CED:
    rcl    WORD PTR [bx],1                       # 6CED: D1 17
    inc    bx                                    # 6CEF: 43
    inc    bx                                    # 6CF0: 43
    loop   L_6CED                                # 6CF1: E2 FA
L_6CF3:
    jmp    L_790F                                # 6CF3: E9 19 0C
L_6CF6:
    inc    BYTE PTR ds:FACEXP                     # 6CF6: FE 06 A6 04
    jne    L_6CF3                                # 6CFA: 75 F7
    jmp    L_74DC                                # 6CFC: E9 DD 07
FMULT:
FMULS:
    call   SIGN                                # 6CFF: E8 73 0E
    je     L_6D08                                # 6D02: 74 04
    .byte 0x0A, 0xFF # 6D04
    jne    L_6D0B                                # 6D06: 75 03
L_6D08:
    jmp    ZERO                                # 6D08: E9 60 0E
L_6D0B:
    call   AEXPS                                # 6D0B: E8 3A F0
    mov    cx,WORD PTR ds:FACSGN                  # 6D0E: 8B 0E A5 04
    .byte 0x32, 0xED # 6D12
    mov    ax,ds:FACLO                           # 6D14: A1 A3 04
    .byte 0x8A, 0xFD # 6D17
    push   bx                                    # 6D19: 53
    push   cx                                    # 6D1A: 51
    push   dx                                    # 6D1B: 52
    push   cx                                    # 6D1C: 51
    push   ax                                    # 6D1D: 50
    mul    dx                                    # 6D1E: F7 E2
    .byte 0x8B, 0xCA # 6D20
    pop    ax                                    # 6D22: 58
    mul    bx                                    # 6D23: F7 E3
    .byte 0x03, 0xC8 # 6D25
    jae    L_6D2A                                # 6D27: 73 01
    inc    dx                                    # 6D29: 42
L_6D2A:
    .byte 0x8B, 0xDA # 6D2A
    pop    dx                                    # 6D2C: 5A
    pop    ax                                    # 6D2D: 58
    mul    dx                                    # 6D2E: F7 E2
    .byte 0x03, 0xC8 # 6D30
    jae    L_6D35                                # 6D32: 73 01
    inc    dx                                    # 6D34: 42
L_6D35:
    .byte 0x03, 0xDA # 6D35
    pop    dx                                    # 6D37: 5A
    pop    ax                                    # 6D38: 58
    mul    dl                                    # 6D39: F6 E2
    .byte 0x03, 0xD8 # 6D3B
    jae    L_6D4C                                # 6D3D: 73 0D
    rcr    bx,1                                  # 6D3F: D1 DB
    rcr    cx,1                                  # 6D41: D1 D9
    inc    BYTE PTR ds:FACEXP                     # 6D43: FE 06 A6 04
    jne    L_6D4C                                # 6D47: 75 03
    jmp    L_74DC                                # 6D49: E9 90 07
L_6D4C:
    .byte 0x0A, 0xFF # 6D4C
    jns    L_6D59                                # 6D4E: 79 09
    inc    BYTE PTR ds:FACEXP                     # 6D50: FE 06 A6 04
    jne    L_6D5D                                # 6D54: 75 07
    jmp    L_74DC                                # 6D56: E9 83 07
L_6D59:
    rcl    cx,1                                  # 6D59: D1 D1
    rcl    bx,1                                  # 6D5B: D1 D3
L_6D5D:
    .byte 0x8A, 0xD5, 0x8A, 0xF3, 0x8A, 0xDF, 0x8A, 0xE1 # 6D5D
    jmp    L_7954                                # 6D65: E9 EC 0B
    .byte 0xC3 # 6D68
L_6D69:
    push   bx                                    # 6D69: 53
    mov    al,0x8                                # 6D6A: B0 08
    jb     L_6D70                                # 6D6C: 72 02
    mov    al,0x11                               # 6D6E: B0 11
L_6D70:
    .byte 0x8A, 0xE8, 0x8A, 0xC8 # 6D70
    push   cx                                    # 6D74: 51
    pushf                                        # 6D75: 9C
    call   L_6FC1                                # 6D76: E8 48 02
    .byte 0x0A, 0xC0 # 6D79
    je     L_6D7F                                # 6D7B: 74 02
    jns    L_6D8B                                # 6D7D: 79 0C
L_6D7F:
    popf                                         # 6D7F: 9D
    pop    cx                                    # 6D80: 59
    push   ax                                    # 6D81: 50
    jnp    L_6D8F                                # 6D82: 7B 0B
    add    al,0x10                               # 6D84: 04 10
    pop    ax                                    # 6D86: 58
    jns    L_6DA3                                # 6D87: 79 1A
    jmp    L_6D94                                # 6D89: EB 09
L_6D8B:
    popf                                         # 6D8B: 9D
    pop    cx                                    # 6D8C: 59
    jmp    L_6DB5                                # 6D8D: EB 26
L_6D8F:
    add    al,0x7                                # 6D8F: 04 07
    pop    ax                                    # 6D91: 58
    jns    L_6DA3                                # 6D92: 79 0F
L_6D94:
    push   ax                                    # 6D94: 50
    call   L_798E                                # 6D95: E8 F6 0B
    pop    ax                                    # 6D98: 58
    .byte 0x8A, 0xE0, 0x02, 0xE1 # 6D99
    jle    L_6DB5                                # 6D9D: 7E 16
    .byte 0x02, 0xE8 # 6D9F
    jmp    L_6DAF                                # 6DA1: EB 0C
L_6DA3:
    .byte 0x02, 0xC5 # 6DA3
    inc    ch                                    # 6DA5: FE C5
    .byte 0x3A, 0xE8 # 6DA7
    mov    ch,0x3                                # 6DA9: B5 03
    jb     L_6DB9                                # 6DAB: 72 0C
    .byte 0x8A, 0xE8 # 6DAD
L_6DAF:
    inc    ch                                    # 6DAF: FE C5
    mov    al,0x2                                # 6DB1: B0 02
    jmp    L_6DB9                                # 6DB3: EB 04
L_6DB5:
    .byte 0x02, 0xC5 # 6DB5
    mov    ch,0x3                                # 6DB7: B5 03
L_6DB9:
    dec    al                                    # 6DB9: FE C8
    dec    al                                    # 6DBB: FE C8
    pop    bx                                    # 6DBD: 5B
    push   ax                                    # 6DBE: 50
    pushf                                        # 6DBF: 9C
    .byte 0x32, 0xC9 # 6DC0
    call   L_6E12                                # 6DC2: E8 4D 00
    mov    BYTE PTR [bx],0x30                    # 6DC5: C6 07 30
    jne    L_6DCB                                # 6DC8: 75 01
    inc    bx                                    # 6DCA: 43
L_6DCB:
    call   L_6EB6                                # 6DCB: E8 E8 00
L_6DCE:
    dec    bx                                    # 6DCE: 4B
    cmp    BYTE PTR [bx],0x30                    # 6DCF: 80 3F 30
    je     L_6DCE                                # 6DD2: 74 FA
    cmp    BYTE PTR [bx],0x2e                    # 6DD4: 80 3F 2E
    je     L_6DDA                                # 6DD7: 74 01
    inc    bx                                    # 6DD9: 43
L_6DDA:
    popf                                         # 6DDA: 9D
    pop    ax                                    # 6DDB: 58
    je     L_6E09                                # 6DDC: 74 2B
L_6DDE:
    pushf                                        # 6DDE: 9C
    push   ax                                    # 6DDF: 50
    call   GETYP                                # 6DE0: E8 BF 0D
    mov    ah,0x45                               # 6DE3: B4 45
    jnp    L_6DE9                                # 6DE5: 7B 02
    mov    ah,0x44                               # 6DE7: B4 44
L_6DE9:
    mov    BYTE PTR [bx],ah                      # 6DE9: 88 27
    inc    bx                                    # 6DEB: 43
    pop    ax                                    # 6DEC: 58
    popf                                         # 6DED: 9D
    mov    BYTE PTR [bx],0x2b                    # 6DEE: C6 07 2B
    jns    L_6DF8                                # 6DF1: 79 05
    mov    BYTE PTR [bx],0x2d                    # 6DF3: C6 07 2D
    neg    al                                    # 6DF6: F6 D8
L_6DF8:
    mov    ah,0x2f                               # 6DF8: B4 2F
L_6DFA:
    inc    ah                                    # 6DFA: FE C4
    sub    al,0xa                                # 6DFC: 2C 0A
    jae    L_6DFA                                # 6DFE: 73 FA
    add    al,0x3a                               # 6E00: 04 3A
    inc    bx                                    # 6E02: 43
    xchg   ah,al                                 # 6E03: 86 C4
    mov    WORD PTR [bx],ax                      # 6E05: 89 07
    inc    bx                                    # 6E07: 43
    inc    bx                                    # 6E08: 43
L_6E09:
    mov    BYTE PTR [bx],0x0                     # 6E09: C6 07 00
    xchg   cx,bx                                 # 6E0C: 87 D9
    mov    bx,0x4b4                              # 6E0E: BB B4 04
    ret                                          # 6E11: C3
L_6E12:
    dec    ch                                    # 6E12: FE CD
    jns    L_6E2C                                # 6E14: 79 16
    mov    WORD PTR ds:TEMP2,bx                  # 6E16: 89 1E 52 03
    mov    BYTE PTR [bx],0x2e                    # 6E1A: C6 07 2E
L_6E1D:
    inc    bx                                    # 6E1D: 43
    mov    BYTE PTR [bx],0x30                    # 6E1E: C6 07 30
    inc    ch                                    # 6E21: FE C5
    jne    L_6E1D                                # 6E23: 75 F8
    inc    bx                                    # 6E25: 43
    .byte 0x33, 0xC9 # 6E26
    jmp    L_6E44                                # 6E28: EB 1A
L_6E2A:
    dec    ch                                    # 6E2A: FE CD
L_6E2C:
    jne    L_6E3A                                # 6E2C: 75 0C
    mov    BYTE PTR [bx],0x2e                    # 6E2E: C6 07 2E
    mov    WORD PTR ds:TEMP2,bx                  # 6E31: 89 1E 52 03
    inc    bx                                    # 6E35: 43
    .byte 0x33, 0xC9 # 6E36
    jmp    L_6E44                                # 6E38: EB 0A
L_6E3A:
    dec    cl                                    # 6E3A: FE C9
    jne    L_6E44                                # 6E3C: 75 06
    mov    BYTE PTR [bx],0x2c                    # 6E3E: C6 07 2C
    inc    bx                                    # 6E41: 43
    mov    cl,0x3                                # 6E42: B1 03
L_6E44:
    mov    WORD PTR ds:FMTCX,cx                  # 6E44: 89 0E 81 04
    ret                                          # 6E48: C3
L_6E49:
    mov    ah,0x5                                # 6E49: B4 05
    mov    bp,0x61f5                             # 6E4B: BD F5 61
L_6E4E:
    call   L_6E2A                                # 6E4E: E8 D9 FF
    .byte 0x2E, 0x8B, 0x96, 0x00, 0x00 # 6E51
    inc    bp                                    # 6E56: 45
    inc    bp                                    # 6E57: 45
    mov    si,WORD PTR ds:FACLO                  # 6E58: 8B 36 A3 04
    mov    al,0x2f                               # 6E5C: B0 2F
L_6E5E:
    inc    al                                    # 6E5E: FE C0
    .byte 0x2B, 0xF2 # 6E60
    jae    L_6E5E                                # 6E62: 73 FA
    .byte 0x03, 0xF2 # 6E64
    mov    BYTE PTR [bx],al                      # 6E66: 88 07
    inc    bx                                    # 6E68: 43
    mov    WORD PTR ds:FACLO,si                  # 6E69: 89 36 A3 04
    dec    ah                                    # 6E6D: FE CC
    jne    L_6E4E                                # 6E6F: 75 DD
    call   L_6E2A                                # 6E71: E8 B6 FF
    mov    BYTE PTR [bx],0x0                     # 6E74: C6 07 00
    ret                                          # 6E77: C3
L_6E78:
    mov    cx,0x301                              # 6E78: B9 01 03
    mov    si,0x6                                # 6E7B: BE 06 00
    jmp    L_6E86                                # 6E7E: EB 06
L_6E80:
    mov    cx,0x404                              # 6E80: B9 04 04
    mov    si,0x4                                # 6E83: BE 04 00
L_6E86:
    mov    di,0x4b3                              # 6E86: BF B3 04
    cld                                          # 6E89: FC
    mov    bx,0x6274                             # 6E8A: BB 74 62
    mov    dx,WORD PTR ds:FACLO                  # 6E8D: 8B 16 A3 04
    push   si                                    # 6E91: 56
L_6E92:
    .byte 0x8A, 0xC6, 0x32, 0xE4 # 6E92
    shl    ax,cl                                 # 6E96: D3 E0
    xchg   al,ah                                 # 6E98: 86 E0
    xlat   BYTE PTR cs:[bx]                      # 6E9A: 2E D7
    stos   BYTE PTR es:[di],al                   # 6E9C: AA
    shl    dx,cl                                 # 6E9D: D3 E2
    .byte 0x8A, 0xCD # 6E9F
    dec    si                                    # 6EA1: 4E
    jne    L_6E92                                # 6EA2: 75 EE
    mov    BYTE PTR [di],0x0                     # 6EA4: C6 05 00
    mov    bx,0x4b3                              # 6EA7: BB B3 04
    pop    cx                                    # 6EAA: 59
    dec    cl                                    # 6EAB: FE C9
L_6EAD:
    cmp    BYTE PTR [bx],0x30                    # 6EAD: 80 3F 30
    jne    L_6EB5                                # 6EB0: 75 03
    inc    bx                                    # 6EB2: 43
    loop   L_6EAD                                # 6EB3: E2 F8
L_6EB5:
    ret                                          # 6EB5: C3
L_6EB6:
    call   GETYP                                # 6EB6: E8 E9 0C
    jnp    L_6F32                                # 6EB9: 7B 77
    push   cx                                    # 6EBB: 51
    push   bx                                    # 6EBC: 53
    mov    si,DFACL                              # 6EBD: BE 9F 04
    mov    di,ARGLO                              # 6EC0: BF AB 04
    mov    cx,0x4                                # 6EC3: B9 04 00
    cld                                          # 6EC6: FC
    rep movs WORD PTR es:[di],WORD PTR ds:[si]   # 6EC7: F3 A5
    call   L_7241                                # 6EC9: E8 75 03
    push   bx                                    # 6ECC: 53
    mov    bx,ARG_M1                              # 6ECD: BB B1 04
    call   VCOMP                                # 6ED0: E8 FD 0D
    pop    bx                                    # 6ED3: 5B
    mov    si,ARGLO                              # 6ED4: BE AB 04
    mov    di,DFACL                              # 6ED7: BF 9F 04
    mov    cx,0x4                                # 6EDA: B9 04 00
    cld                                          # 6EDD: FC
    rep movs WORD PTR es:[di],WORD PTR ds:[si]   # 6EDE: F3 A5
    je     L_6EE5                                # 6EE0: 74 03
    call   DADDH                                # 6EE2: E8 CE 0C
L_6EE5:
    mov    cl,BYTE PTR ds:FACEXP                  # 6EE5: 8A 0E A6 04
    sub    cl,0xb8                               # 6EE9: 80 E9 B8
    neg    cl                                    # 6EEC: F6 D9
    clc                                          # 6EEE: F8
    call   L_724C                                # 6EEF: E8 5A 03
    pop    bx                                    # 6EF2: 5B
    pop    cx                                    # 6EF3: 59
    mov    si,0x61a6                             # 6EF4: BE A6 61
    mov    al,0x9                                # 6EF7: B0 09
L_6EF9:
    call   L_6E2A                                # 6EF9: E8 2E FF
    push   ax                                    # 6EFC: 50
    mov    al,0x2f                               # 6EFD: B0 2F
    push   ax                                    # 6EFF: 50
L_6F00:
    pop    ax                                    # 6F00: 58
    inc    al                                    # 6F01: FE C0
    push   ax                                    # 6F03: 50
    call   L_6F9B                                # 6F04: E8 94 00
    jae    L_6F00                                # 6F07: 73 F7
    call   L_6FAF                                # 6F09: E8 A3 00
    pop    ax                                    # 6F0C: 58
    jmp    L_6F1A                                # 6F0D: EB 0B
    .byte 0x75, 0x09, 0xC6, 0x07, 0x31, 0x43, 0xC6, 0x07, 0x30, 0xEB, 0x02 # 6F0F
L_6F1A:
    mov    BYTE PTR [bx],al                      # 6F1A: 88 07
    inc    bx                                    # 6F1C: 43
    pop    ax                                    # 6F1D: 58
    dec    al                                    # 6F1E: FE C8
    jne    L_6EF9                                # 6F20: 75 D7
    push   cx                                    # 6F22: 51
    mov    si,DFACL                              # 6F23: BE 9F 04
    mov    di,0x4a3                              # 6F26: BF A3 04
    mov    cx,0x2                                # 6F29: B9 02 00
    cld                                          # 6F2C: FC
    rep movs WORD PTR es:[di],WORD PTR ds:[si]   # 6F2D: F3 A5
    pop    cx                                    # 6F2F: 59
    jmp    L_6F5B                                # 6F30: EB 29
L_6F32:
    push   bx                                    # 6F32: 53
    push   cx                                    # 6F33: 51
    call   PUSHF                                # 6F34: E8 18 0F
    call   L_72AB                                # 6F37: E8 71 03
    pop    dx                                    # 6F3A: 5A
    pop    bx                                    # 6F3B: 5B
    call   FCOMP                                # 6F3C: E8 99 0D
    je     L_6F4C                                # 6F3F: 74 0B
    mov    WORD PTR ds:FACSGN,bx                  # 6F41: 89 1E A5 04
    mov    WORD PTR ds:FACLO,dx                  # 6F45: 89 16 A3 04
    call   FADDH                                # 6F49: E8 73 0C
L_6F4C:
    mov    al,0x1                                # 6F4C: B0 01
    call   L_7303                                # 6F4E: E8 B2 03
    mov    WORD PTR ds:FACSGN,bx                  # 6F51: 89 1E A5 04
    mov    WORD PTR ds:FACLO,dx                  # 6F55: 89 16 A3 04
    pop    cx                                    # 6F59: 59
    pop    bx                                    # 6F5A: 5B
L_6F5B:
    mov    al,0x3                                # 6F5B: B0 03
    mov    dx,0x61ec                             # 6F5D: BA EC 61
L_6F60:
    call   L_6E2A                                # 6F60: E8 C7 FE
    push   ax                                    # 6F63: 50
    push   bx                                    # 6F64: 53
    push   dx                                    # 6F65: 52
    call   MOVRF                                # 6F66: E8 5E 0D
    pop    bp                                    # 6F69: 5D
    mov    al,0x2f                               # 6F6A: B0 2F
    push   ax                                    # 6F6C: 50
L_6F6D:
    pop    ax                                    # 6F6D: 58
    inc    al                                    # 6F6E: FE C0
    push   ax                                    # 6F70: 50
    call   L_7D8B                                # 6F71: E8 17 0E
    jae    L_6F6D                                # 6F74: 73 F7
    .byte 0x2E, 0x03, 0x96, 0x00, 0x00, 0x2E, 0x12, 0x9E, 0x02, 0x00 # 6F76
    inc    bp                                    # 6F80: 45
    inc    bp                                    # 6F81: 45
    inc    bp                                    # 6F82: 45
    call   MOVFR                                # 6F83: E8 38 0D
    pop    ax                                    # 6F86: 58
    xchg   bp,dx                                 # 6F87: 87 D5
    pop    bx                                    # 6F89: 5B
    mov    BYTE PTR [bx],al                      # 6F8A: 88 07
    inc    bx                                    # 6F8C: 43
    pop    ax                                    # 6F8D: 58
    dec    al                                    # 6F8E: FE C8
    jne    L_6F60                                # 6F90: 75 CE
    inc    dx                                    # 6F92: 42
    inc    dx                                    # 6F93: 42
    .byte 0x8B, 0xEA # 6F94
    mov    ah,0x4                                # 6F96: B4 04
    jmp    L_6E4E                                # 6F98: E9 B3 FE
L_6F9B:
    push   cx                                    # 6F9B: 51
    push   si                                    # 6F9C: 56
    mov    cx,0x7                                # 6F9D: B9 07 00
    mov    di,DFACL                              # 6FA0: BF 9F 04
    clc                                          # 6FA3: F8
    cld                                          # 6FA4: FC
L_6FA5:
    lods   al,BYTE PTR cs:[si]                   # 6FA5: 2E AC
    sbb    BYTE PTR [di],al                      # 6FA7: 18 05
    inc    di                                    # 6FA9: 47
    loop   L_6FA5                                # 6FAA: E2 F9
    pop    si                                    # 6FAC: 5E
    pop    cx                                    # 6FAD: 59
    ret                                          # 6FAE: C3
L_6FAF:
    push   cx                                    # 6FAF: 51
    mov    cx,0x7                                # 6FB0: B9 07 00
    mov    di,DFACL                              # 6FB3: BF 9F 04
    clc                                          # 6FB6: F8
    cld                                          # 6FB7: FC
L_6FB8:
    lods   al,BYTE PTR cs:[si]                   # 6FB8: 2E AC
    adc    BYTE PTR [di],al                      # 6FBA: 10 05
    inc    di                                    # 6FBC: 47
    loop   L_6FB8                                # 6FBD: E2 F9
    pop    cx                                    # 6FBF: 59
    ret                                          # 6FC0: C3
L_6FC1:
    push   bx                                    # 6FC1: 53
    push   cx                                    # 6FC2: 51
    .byte 0x33, 0xFF # 6FC3
    push   di                                    # 6FC5: 57
L_6FC6:
    mov    bx,0x5e02                             # 6FC6: BB 02 5E
    mov    al,ds:FACEXP                           # 6FC9: A0 A6 04
    xlat   BYTE PTR cs:[bx]                      # 6FCC: 2E D7
    .byte 0x0A, 0xC0 # 6FCE
    je     L_6FDE                                # 6FD0: 74 0C
    pop    di                                    # 6FD2: 5F
    cbw                                          # 6FD3: 98
    .byte 0x2B, 0xF8 # 6FD4
    push   di                                    # 6FD6: 57
    .byte 0x8B, 0xD0 # 6FD7
    call   L_5F0E                                # 6FD9: E8 32 EF
    jmp    L_6FC6                                # 6FDC: EB E8
L_6FDE:
    mov    bx,0x6066                             # 6FDE: BB 66 60
    call   MOVBS                                # 6FE1: E8 88 0C
    call   COMPM                                # 6FE4: E8 2D 0D
    jae    L_6FEF                                # 6FE7: 73 06
    call   MUL10                                # 6FE9: E8 E6 0B
    pop    di                                    # 6FEC: 5F
    dec    di                                    # 6FED: 4F
    push   di                                    # 6FEE: 57
L_6FEF:
    call   GETYP                                # 6FEF: E8 B0 0B
    jb     L_7013                                # 6FF2: 72 1F
    mov    bx,0x607a                             # 6FF4: BB 7A 60
    call   MOVAC                                # 6FF7: E8 8E 0C
    call   FMULD                                # 6FFA: E8 58 FC
    pop    ax                                    # 6FFD: 58
    sub    al,0x9                                # 6FFE: 2C 09
    push   ax                                    # 7000: 50
    mov    bx,0x7ff6                             # 7001: BB F6 7F
    call   MOVBF                                # 7004: E8 6D 0C
    call   DCMPM                                # 7007: E8 57 0D
    jbe    L_7013                                # 700A: 76 07
    call   DIV10                                # 700C: E8 B9 0B
    pop    ax                                    # 700F: 58
    inc    al                                    # 7010: FE C0
    push   ax                                    # 7012: 50
L_7013:
    pop    ax                                    # 7013: 58
    pop    cx                                    # 7014: 59
    pop    bx                                    # 7015: 5B
    .byte 0x0A, 0xC0 # 7016
    ret                                          # 7018: C3
    .byte 0x58, 0x59, 0x5B, 0x0A, 0xC0, 0xC3 # 7019
L_701F:
    mov    bx,0x4b4                              # 701F: BB B4 04
    mov    ch,BYTE PTR [bx]                      # 7022: 8A 2F
    mov    cl,0x20                               # 7024: B1 20
    mov    ah,BYTE PTR ds:FMTAX                  # 7026: 8A 26 83 04
    test   ah,0x20                               # 702A: F6 C4 20
    je     L_703C                                # 702D: 74 0D
    .byte 0x3A, 0xE9 # 702F
    mov    cl,0x2a                               # 7031: B1 2A
    jne    L_703C                                # 7033: 75 07
    test   ah,0x4                                # 7035: F6 C4 04
    jne    L_703C                                # 7038: 75 02
    .byte 0x8A, 0xE9 # 703A
L_703C:
    mov    BYTE PTR [bx],cl                      # 703C: 88 0F
    call   L_6300                                # 703E: E8 BF F2
    je     L_7075                                # 7041: 74 32
    mov    bp,0x61a5                             # 7043: BD A5 61
L_7046:
    .byte 0x2E, 0x3A, 0x86, 0x00, 0x00 # 7046
    je     L_7056                                # 704B: 74 09
    cmp    bp,0x619c                             # 704D: 81 FD 9C 61
    je     L_7079                                # 7051: 74 26
    dec    bp                                    # 7053: 4D
    jmp    L_7046                                # 7054: EB F0
L_7056:
    sub    bp,0x619c                             # 7056: 81 ED 9C 61
    shl    bp,1                                  # 705A: D1 E5
    jmp    WORD PTR cs:[bp+0x7061]               # 705C: 2E FF A6 61 70
    .byte 0x75, 0x70, 0x75, 0x70, 0x79, 0x70, 0x79, 0x70, 0x79, 0x70, 0x79, 0x70 # 7061
    .byte 0x75, 0x70, 0x79, 0x70, 0x3C, 0x70, 0x3C, 0x70 # 706D
L_7075:
    dec    bx                                    # 7075: 4B
    mov    BYTE PTR [bx],0x30                    # 7076: C6 07 30
L_7079:
    mov    ah,BYTE PTR ds:FMTAX                  # 7079: 8A 26 83 04
    test   ah,0x10                               # 707D: F6 C4 10
    je     L_7086                                # 7080: 74 04
    dec    bx                                    # 7082: 4B
    mov    BYTE PTR [bx],0x24                    # 7083: C6 07 24
L_7086:
    test   ah,0x4                                # 7086: F6 C4 04
    jne    L_7090                                # 7089: 75 05
    dec    bx                                    # 708B: 4B
    mov    BYTE PTR [bx],ch                      # 708C: 88 2F
    .byte 0x32, 0xED # 708E
L_7090:
    ret                                          # 7090: C3
L_7091:
    .byte 0x0A, 0xC0 # 7091
    jmp    L_709B                                # 7093: EB 06
L_7095:
    mov    BYTE PTR [bx],0x30                    # 7095: C6 07 30
    inc    bx                                    # 7098: 43
    dec    al                                    # 7099: FE C8
L_709B:
    jne    L_7095                                # 709B: 75 F8
    ret                                          # 709D: C3
L_709E:
    call   L_6E2A                                # 709E: E8 89 FD
L_70A1:
    mov    BYTE PTR [bx],0x30                    # 70A1: C6 07 30
    inc    bx                                    # 70A4: 43
    dec    al                                    # 70A5: FE C8
    jne    L_709E                                # 70A7: 75 F5
    ret                                          # 70A9: C3
L_70AA:
    mov    bx,0x4b4                              # 70AA: BB B4 04
    mov    BYTE PTR [bx],0x20                    # 70AD: C6 07 20
    push   bx                                    # 70B0: 53
    call   SIGN                                # 70B1: E8 C1 0A
    pop    bx                                    # 70B4: 5B
    pushf                                        # 70B5: 9C
    jns    L_70C2                                # 70B6: 79 0A
    mov    BYTE PTR [bx],0x2d                    # 70B8: C6 07 2D
    push   bx                                    # 70BB: 53
    call   VNEG                                # 70BC: E8 EC 0C
    pop    bx                                    # 70BF: 5B
    or     al,0x1                                # 70C0: 0C 01
L_70C2:
    inc    bx                                    # 70C2: 43
    mov    BYTE PTR [bx],0x30                    # 70C3: C6 07 30
    popf                                         # 70C6: 9D
    ret                                          # 70C7: C3
L_70C8:
    int    0xd8                                  # 70C8: CD D8
L_70CA:
    call   L_70AA                                # 70CA: E8 DD FF
    jne    L_70D7                                # 70CD: 75 08
    inc    bx                                    # 70CF: 43
    mov    BYTE PTR [bx],0x0                     # 70D0: C6 07 00
    mov    bx,0x4b4                              # 70D3: BB B4 04
    ret                                          # 70D6: C3
L_70D7:
    call   GETYP                                # 70D7: E8 C8 0A
    jns    L_70EE                                # 70DA: 79 12
    mov    cx,0x700                              # 70DC: B9 00 07
    .byte 0x33, 0xC0 # 70DF
    mov    ds:FMTAX,ax                           # 70E1: A3 83 04
    mov    WORD PTR ds:FMTCX,cx                  # 70E4: 89 0E 81 04
    call   L_6E49                                # 70E8: E8 5E FD
    jmp    L_701F                                # 70EB: E9 31 FF
L_70EE:
    jmp    L_6D69                                # 70EE: E9 78 FC
SQR:
    call   SIGN                                # 70F1: E8 81 0A
    jns    L_70F9                                # 70F4: 79 03
    jmp    FCERR                                # 70F6: E9 60 9F
L_70F9:
    jne    L_70FC                                # 70F9: 75 01
    ret                                          # 70FB: C3
L_70FC:
    mov    al,ds:FACEXP                           # 70FC: A0 A6 04
    shr    al,1                                  # 70FF: D0 E8
    push   ax                                    # 7101: 50
    mov    BYTE PTR ds:FACEXP,0x40                # 7102: C6 06 A6 04 40
    rcl    BYTE PTR ds:FACEXP,1                   # 7107: D0 16 A6 04
    mov    bx,ARGLO                              # 710B: BB AB 04
    call   MOVMF                                # 710E: E8 09 0D
    mov    cx,0x4                                # 7111: B9 04 00
L_7114:
    push   cx                                    # 7114: 51
    call   PUSHF                                # 7115: E8 37 0D
    mov    dx,WORD PTR ds:ARGLO                  # 7118: 8B 16 AB 04
    mov    bx,WORD PTR ds:ARGLO+2                  # 711C: 8B 1E AD 04
    call   L_68DE                                # 7120: E8 BB F7
    pop    dx                                    # 7123: 5A
    pop    bx                                    # 7124: 5B
    call   L_6773                                # 7125: E8 4B F6
    dec    BYTE PTR ds:FACEXP                     # 7128: FE 0E A6 04
    pop    cx                                    # 712C: 59
    je     L_7139                                # 712D: 74 0A
    loop   L_7114                                # 712F: E2 E3
    pop    ax                                    # 7131: 58
    add    al,0xc0                               # 7132: 04 C0
    add    BYTE PTR ds:FACEXP,al                  # 7134: 00 06 A6 04
    ret                                          # 7138: C3
L_7139:
    jmp    ZERO                                # 7139: E9 2F 0A
    .byte 0xBF, 0xBE, 0x25, 0x57, 0xBF, 0xA8, 0x04, 0xC6, 0x05, 0x01, 0xE8, 0x2C # 713C
    .byte 0x0A, 0x75, 0x03, 0xE9, 0x36, 0xF1, 0x79, 0x07, 0x0A, 0xFF, 0x75, 0x0A # 7148
    .byte 0xE9, 0x93, 0x03, 0x0A, 0xFF, 0x75, 0x03, 0xE9, 0x0D, 0x0A, 0x0A, 0xDB # 7154
    .byte 0x79, 0x26, 0x80, 0x3E, 0xA6, 0x04, 0x99, 0x72, 0x03, 0xE9, 0xED, 0x9E # 7160
    .byte 0x52, 0x53, 0xFF, 0x36, 0xA3, 0x04, 0xFF, 0x36, 0xA5, 0x04, 0xE8, 0x32 # 716C
    .byte 0x01, 0x5B, 0x5A, 0xE8, 0x5A, 0x0B, 0xE8, 0x3D, 0x0B, 0x5B, 0x5A, 0x74 # 7178
    .byte 0x03, 0xE9, 0xD1, 0x9E, 0xA0, 0xA5, 0x04, 0x0A, 0xC0, 0x79, 0x09, 0xBF # 7184
    .byte 0xC4, 0x71, 0x57, 0x24, 0x7F, 0xA2, 0xA5, 0x04, 0x53, 0x52, 0x80, 0xCB # 7190
    .byte 0x7F, 0x9C, 0xFF, 0x36, 0xA5, 0x04, 0xFF, 0x36, 0xA3, 0x04, 0xE8, 0x02 # 719C
    .byte 0x01, 0x5A, 0x5B, 0xE8, 0x2A, 0x0B, 0x75, 0x1C, 0x52, 0x53, 0x33, 0xD2 # 71A8
    .byte 0xBB, 0x00, 0x90, 0xE8, 0x1E, 0x0B, 0x5B, 0x5A, 0x79, 0x0E, 0x9D, 0x5A # 71B4
    .byte 0x5B, 0xEB, 0x3C, 0x90, 0x33, 0xD2, 0xBB, 0x00, 0x81, 0xE9, 0x12, 0xF7 # 71C0
    .byte 0x9D, 0x79, 0x0E, 0x53, 0x52, 0xE8, 0x2F, 0x01, 0x8A, 0xC2, 0xE8, 0xC5 # 71CC
    .byte 0x02, 0x5A, 0x5B, 0xD0, 0xD8, 0x8F, 0x06, 0xA3, 0x04, 0x8F, 0x06, 0xA5 # 71D8
    .byte 0x04, 0x9F, 0x80, 0x26, 0xA5, 0x04, 0x7F, 0x9E, 0x73, 0x04, 0xBF, 0xB0 # 71E4
    .byte 0x7D, 0x57, 0x53, 0x52, 0xE8, 0x15, 0x01, 0x5A, 0x5B, 0xE8, 0x03, 0xFB # 71F0
    .byte 0xE9, 0x85, 0xF0, 0x53, 0x52, 0xE8, 0xFF, 0x00, 0x89, 0x16, 0xB2, 0x04 # 71FC
    .byte 0xC7, 0x06, 0xA3, 0x04, 0x00, 0x00, 0xC7, 0x06, 0xA5, 0x04, 0x00, 0x81 # 7208
    .byte 0xD1, 0x2E, 0xB2, 0x04, 0x73, 0x07, 0x5A, 0x5B, 0x53, 0x52, 0xE8, 0xDE # 7214
    .byte 0xFA, 0xF7, 0x06, 0xB2, 0x04, 0xFF, 0xFF, 0x74, 0x15, 0x5A, 0x5B, 0xE8 # 7220
    .byte 0x21, 0x0C, 0xE8, 0x8D, 0x0A, 0xE8, 0xCB, 0xFA, 0x5A, 0x5B, 0xE8, 0x16 # 722C
    .byte 0x0C, 0xE8, 0x82, 0x0A, 0xEB, 0xD6, 0x5A, 0x5B, 0xC3 # 7238
L_7241:
    mov    cl,BYTE PTR ds:FACEXP                  # 7241: 8A 0E A6 04
    sub    cl,0xb8                               # 7245: 80 E9 B8
    jae    L_7283                                # 7248: 73 39
    neg    cl                                    # 724A: F6 D9
L_724C:
    pushf                                        # 724C: 9C
    mov    bx,0x4a4                              # 724D: BB A4 04
    .byte 0x8A, 0x87, 0x01, 0x00, 0x88, 0x87, 0x03, 0x00, 0x0A, 0xC0 # 7250
    pushf                                        # 725A: 9C
    or     al,0x80                               # 725B: 0C 80
    .byte 0x88, 0x87, 0x01, 0x00, 0xC6, 0x87, 0x02, 0x00, 0xB8 # 725D
    popf                                         # 7266: 9D
    pushf                                        # 7267: 9C
    jns    L_726D                                # 7268: 79 03
    call   L_728F                                # 726A: E8 22 00
L_726D:
    .byte 0x32, 0xED # 726D
    call   L_7284                                # 726F: E8 12 00
    popf                                         # 7272: 9D
    jns    L_7278                                # 7273: 79 03
    call   L_729E                                # 7275: E8 26 00
L_7278:
    mov    BYTE PTR ds:DFACL-1,0x0                 # 7278: C6 06 9E 04 00
    popf                                         # 727D: 9D
    jae    L_7283                                # 727E: 73 03
    jmp    L_7440                                # 7280: E9 BD 01
L_7283:
    ret                                          # 7283: C3
L_7284:
    push   cx                                    # 7284: 51
    push   bx                                    # 7285: 53
    clc                                          # 7286: F8
    call   L_7C04                                # 7287: E8 7A 09
    pop    bx                                    # 728A: 5B
    pop    cx                                    # 728B: 59
    loop   L_7284                                # 728C: E2 F6
    ret                                          # 728E: C3
L_728F:
    push   bx                                    # 728F: 53
    mov    bx,DFACL                              # 7290: BB 9F 04
L_7293:
    sub    WORD PTR [bx],0x1                     # 7293: 83 2F 01
    jae    L_729C                                # 7296: 73 04
    inc    bx                                    # 7298: 43
    inc    bx                                    # 7299: 43
    jmp    L_7293                                # 729A: EB F7
L_729C:
    pop    bx                                    # 729C: 5B
    ret                                          # 729D: C3
L_729E:
    push   bx                                    # 729E: 53
    mov    bx,DFACL                              # 729F: BB 9F 04
L_72A2:
    inc    BYTE PTR [bx]                         # 72A2: FE 07
    jne    L_72A9                                # 72A4: 75 03
    inc    bx                                    # 72A6: 43
    jmp    L_72A2                                # 72A7: EB F9
L_72A9:
    pop    bx                                    # 72A9: 5B
    ret                                          # 72AA: C3
L_72AB:
    mov    cl,BYTE PTR ds:FACEXP                  # 72AB: 8A 0E A6 04
    sub    cl,0x98                               # 72AF: 80 E9 98
    jae    L_72F5                                # 72B2: 73 41
    neg    cl                                    # 72B4: F6 D9
L_72B6:
    pushf                                        # 72B6: 9C
    mov    dx,WORD PTR ds:FACLO                  # 72B7: 8B 16 A3 04
    mov    bx,WORD PTR ds:FACSGN                  # 72BB: 8B 1E A5 04
    .byte 0x0A, 0xDB # 72BF
    pushf                                        # 72C1: 9C
    mov    BYTE PTR ds:FAC_AUX,bl                  # 72C2: 88 1E A7 04
    mov    BYTE PTR ds:FACEXP,0x98                # 72C6: C6 06 A6 04 98
    or     bl,0x80                               # 72CB: 80 CB 80
    popf                                         # 72CE: 9D
    pushf                                        # 72CF: 9C
    jns    L_72D8                                # 72D0: 79 06
    sub    dx,0x1                                # 72D2: 83 EA 01
    sbb    bl,0x0                                # 72D5: 80 DB 00
L_72D8:
    .byte 0x32, 0xED, 0x0A, 0xC9 # 72D8
    je     L_72E4                                # 72DC: 74 06
L_72DE:
    shr    bl,1                                  # 72DE: D0 EB
    rcr    dx,1                                  # 72E0: D1 DA
    loop   L_72DE                                # 72E2: E2 FA
L_72E4:
    popf                                         # 72E4: 9D
    lahf                                         # 72E5: 9F
    jns    L_72ED                                # 72E6: 79 05
    inc    dx                                    # 72E8: 42
    jne    L_72ED                                # 72E9: 75 02
    inc    bl                                    # 72EB: FE C3
L_72ED:
    popf                                         # 72ED: 9D
    jae    L_72F5                                # 72EE: 73 05
    .byte 0x32, 0xE4 # 72F0
    jmp    L_749E                                # 72F2: E9 A9 01
L_72F5:
    sahf                                         # 72F5: 9E
L_72F6:
    jns    L_7302                                # 72F6: 79 0A
    not    dx                                    # 72F8: F7 D2
    not    bl                                    # 72FA: F6 D3
    add    dx,0x1                                # 72FC: 83 C2 01
    adc    bl,0x0                                # 72FF: 80 D3 00
L_7302:
    ret                                          # 7302: C3
L_7303:
    mov    cl,0x98                               # 7303: B1 98
    sub    cl,BYTE PTR ds:FACEXP                  # 7305: 2A 0E A6 04
    clc                                          # 7309: F8
    jmp    L_72B6                                # 730A: EB AA
LOG:
    call   SIGN                                # 730C: E8 66 08
    jle    L_7362                                # 730F: 7E 51
    mov    dx,0x0                                # 7311: BA 00 00
    mov    bx,0x8100                             # 7314: BB 00 81
    call   FCOMP                                # 7317: E8 BE 09
    jne    L_7325                                # 731A: 75 09
    mov    WORD PTR ds:FACLO,dx                  # 731C: 89 16 A3 04
    mov    WORD PTR ds:FACSGN,dx                  # 7320: 89 16 A5 04
    ret                                          # 7324: C3
L_7325:
    mov    al,ds:FACEXP                           # 7325: A0 A6 04
    sub    al,0x80                               # 7328: 2C 80
    cbw                                          # 732A: 98
    push   ax                                    # 732B: 50
    mov    BYTE PTR ds:FACEXP,0x80                # 732C: C6 06 A6 04 80
    call   PUSHF                                # 7331: E8 1B 0B
    mov    bx,0x6176                             # 7334: BB 76 61
    call   L_7552                                # 7337: E8 18 02
    pop    dx                                    # 733A: 5A
    pop    bx                                    # 733B: 5B
    call   PUSHF                                # 733C: E8 10 0B
    call   MOVFR                                # 733F: E8 7C 09
    mov    bx,0x6187                             # 7342: BB 87 61
    call   L_7552                                # 7345: E8 0A 02
    pop    dx                                    # 7348: 5A
    pop    bx                                    # 7349: 5B
    call   L_68DE                                # 734A: E8 91 F5
    pop    dx                                    # 734D: 5A
    call   PUSHF                                # 734E: E8 FE 0A
    call   FLT                                # 7351: E8 D9 F8
    pop    dx                                    # 7354: 5A
    pop    bx                                    # 7355: 5B
    call   L_6773                                # 7356: E8 1A F4
    mov    bx,0x8031                             # 7359: BB 31 80
    mov    dx,0x7218                             # 735C: BA 18 72
    jmp    FMULS                                # 735F: E9 9D F9
L_7362:
    jmp    FCERR                                # 7362: E9 F4 9C
L_7365:
    jmp    L_07C4                                # 7365: E9 5C 94
NEXT:
    lahf                                         # 7368: 9F
    xchg   al,ah                                 # 7369: 86 E0
    push   ax                                    # 736B: 50
    mov    al,0x1                                # 736C: B0 01
    jmp    L_7372                                # 736E: EB 02
L_7370:
    .byte 0x32, 0xC0 # 7370
L_7372:
    mov    ds:NXTFLG,al                           # 7372: A2 55 04
    pop    ax                                    # 7375: 58
    xchg   ah,al                                 # 7376: 86 C4
    sahf                                         # 7378: 9E
    mov    dx,0x0                                # 7379: BA 00 00
L_737C:
    mov    WORD PTR ds:NXTTXT,bx                  # 737C: 89 1E 53 04
    je     L_7385                                # 7380: 74 03
    call   PTRGET                                # 7382: E8 E9 C3
L_7385:
    mov    WORD PTR ds:TEMP,bx                  # 7385: 89 1E 3B 03
    call   CODE_BODY_START                       # 7389: E8 AC 93
    jne    L_7365                                # 738C: 75 D7
    .byte 0x8B, 0xE3 # 738E
    mov    si,WORD PTR ds:NXTTXT                  # 7390: 8B 36 53 04
    cmp    WORD PTR [bx],si                      # 7394: 39 37
    jne    L_7365                                # 7396: 75 CD
    push   dx                                    # 7398: 52
    .byte 0x8A, 0xA7, 0x02, 0x00 # 7399
    push   ax                                    # 739D: 50
    push   dx                                    # 739E: 52
    add    bx,0x4                                # 739F: 83 C3 04
    .byte 0xF6, 0x87, 0xFF, 0xFF, 0x80 # 73A2
    js     L_73EA                                # 73A7: 78 41
    mov    cx,0x2                                # 73A9: B9 02 00
    cld                                          # 73AC: FC
    .byte 0x8B, 0xF3 # 73AD
    mov    di,0x4a3                              # 73AF: BF A3 04
    rep movs WORD PTR es:[di],WORD PTR ds:[si]   # 73B2: F3 A5
    pop    bx                                    # 73B4: 5B
    push   si                                    # 73B5: 56
    push   bx                                    # 73B6: 53
    test   BYTE PTR ds:NXTFLG,0xff                # 73B7: F6 06 55 04 FF
    jne    L_73CD                                # 73BC: 75 0F
    mov    si,0x456                              # 73BE: BE 56 04
    sub    di,0x4                                # 73C1: 83 EF 04
    mov    cx,0x2                                # 73C4: B9 02 00
    rep movs WORD PTR es:[di],WORD PTR ds:[si]   # 73C7: F3 A5
    .byte 0x32, 0xC0 # 73C9
    je     L_73D0                                # 73CB: 74 03
L_73CD:
    call   L_641B                                # 73CD: E8 4B F0
L_73D0:
    pop    di                                    # 73D0: 5F
    mov    si,0x4a3                              # 73D1: BE A3 04
    mov    cx,0x2                                # 73D4: B9 02 00
    cld                                          # 73D7: FC
    rep movs WORD PTR es:[di],WORD PTR ds:[si]   # 73D8: F3 A5
    pop    si                                    # 73DA: 5E
    mov    dx,WORD PTR [si]                      # 73DB: 8B 14
    .byte 0x8B, 0x8C, 0x02, 0x00 # 73DD
    add    si,0x4                                # 73E1: 83 C6 04
    push   si                                    # 73E4: 56
    call   L_6431                                # 73E5: E8 49 F0
    jmp    L_7411                                # 73E8: EB 27
L_73EA:
    add    bx,0x4                                # 73EA: 83 C3 04
    mov    cx,WORD PTR [bx]                      # 73ED: 8B 0F
    inc    bx                                    # 73EF: 43
    inc    bx                                    # 73F0: 43
    pop    si                                    # 73F1: 5E
    mov    dx,WORD PTR [si]                      # 73F2: 8B 14
    test   BYTE PTR ds:NXTFLG,0xff                # 73F4: F6 06 55 04 FF
    jne    L_7401                                # 73F9: 75 06
    mov    dx,WORD PTR ds:FVALSV                  # 73FB: 8B 16 56 04
    jmp    L_7405                                # 73FF: EB 04
L_7401:
    .byte 0x03, 0xD1 # 7401
    jo     L_743A                                # 7403: 70 35
L_7405:
    mov    WORD PTR [si],dx                      # 7405: 89 14
    push   dx                                    # 7407: 52
    mov    dx,WORD PTR [bx]                      # 7408: 8B 17
    inc    bx                                    # 740A: 43
    inc    bx                                    # 740B: 43
    pop    ax                                    # 740C: 58
    push   bx                                    # 740D: 53
    call   ICMPA                                # 740E: E8 A5 F1
L_7411:
    pop    bx                                    # 7411: 5B
    pop    cx                                    # 7412: 59
    .byte 0x2A, 0xC5 # 7413
    call   L_6537                                # 7415: E8 1F F1
    je     L_7425                                # 7418: 74 0B
    mov    WORD PTR ds:CURLIN,dx                   # 741A: 89 16 2E 00
    .byte 0x8B, 0xD1 # 741E
    xchg   bx,dx                                 # 7420: 87 D3
    jmp    L_0EA1                                # 7422: E9 7C 9A
L_7425:
    .byte 0x8B, 0xE3 # 7425
    mov    WORD PTR ds:SAVSTK,bx                  # 7427: 89 1E 45 03
    mov    bx,WORD PTR ds:TEMP                  # 742B: 8B 1E 3B 03
    cmp    BYTE PTR [bx],0x2c                    # 742F: 80 3F 2C
    jne    L_743D                                # 7432: 75 09
    call   L_6A8C                                # 7434: E8 55 F6
    call   L_737C                                # 7437: E8 42 FF
L_743A:
    jmp    L_07D0                                # 743A: E9 93 93
L_743D:
    jmp    L_0EE8                                # 743D: E9 A8 9A
L_7440:
    push   cx                                    # 7440: 51
    push   bx                                    # 7441: 53
    push   si                                    # 7442: 56
    push   di                                    # 7443: 57
    push   dx                                    # 7444: 52
    mov    dl,0x39                               # 7445: B2 39
    mov    bx,DFACL-1                              # 7447: BB 9E 04
L_744A:
    mov    di,FACM1                              # 744A: BF A5 04
    mov    si,0x4a6                              # 744D: BE A6 04
    jmp    L_746B                                # 7450: EB 19
L_7452:
    push   bx                                    # 7452: 53
    mov    cx,0x4                                # 7453: B9 04 00
    clc                                          # 7456: F8
L_7457:
    rcl    WORD PTR [bx],1                       # 7457: D1 17
    inc    bx                                    # 7459: 43
    inc    bx                                    # 745A: 43
    loop   L_7457                                # 745B: E2 FA
    pop    bx                                    # 745D: 5B
    test   BYTE PTR [bx],0x40                    # 745E: F6 07 40
    jne    L_748C                                # 7461: 75 29
L_7463:
    dec    BYTE PTR [si]                         # 7463: FE 0C
    je     L_7491                                # 7465: 74 2A
    dec    dl                                    # 7467: FE CA
    je     L_7491                                # 7469: 74 26
L_746B:
    test   BYTE PTR [di],0xff                    # 746B: F6 05 FF
    js     L_7491                                # 746E: 78 21
    jne    L_7452                                # 7470: 75 E0
    sub    BYTE PTR [si],0x8                     # 7472: 80 2C 08
    jbe    L_7491                                # 7475: 76 1A
    sub    dl,0x8                                # 7477: 80 EA 08
    jbe    L_7491                                # 747A: 76 15
    mov    si,0x4a4                              # 747C: BE A4 04
    mov    cx,0x7                                # 747F: B9 07 00
    std                                          # 7482: FD
    rep movs BYTE PTR es:[di],BYTE PTR ds:[si]   # 7483: F3 A4
    and    BYTE PTR ds:DFACL-1,0x20                # 7485: 80 26 9E 04 20
    jmp    L_744A                                # 748A: EB BE
L_748C:
    or     BYTE PTR [bx],0x20                    # 748C: 80 0F 20
    jmp    L_7463                                # 748F: EB D2
L_7491:
    pop    dx                                    # 7491: 5A
    pop    di                                    # 7492: 5F
    pop    si                                    # 7493: 5E
    pop    bx                                    # 7494: 5B
    pop    cx                                    # 7495: 59
    jbe    L_749B                                # 7496: 76 03
    jmp    L_790F                                # 7498: E9 74 04
L_749B:
    jmp    DZERO                                # 749B: E9 C0 06
L_749E:
    mov    bh,BYTE PTR ds:FACEXP                  # 749E: 8A 3E A6 04
    mov    cx,0x4                                # 74A2: B9 04 00
L_74A5:
    .byte 0x0A, 0xDB # 74A5
    js     L_74CA                                # 74A7: 78 21
    jne    L_74BC                                # 74A9: 75 11
    sub    bh,0x8                                # 74AB: 80 EF 08
    jb     L_74C7                                # 74AE: 72 17
    .byte 0x8A, 0xDE, 0x8A, 0xF2, 0x8A, 0xD4, 0x32, 0xE4 # 74B0
    loop   L_74A5                                # 74B8: E2 EB
    je     L_74C7                                # 74BA: 74 0B
L_74BC:
    clc                                          # 74BC: F8
    rcl    ah,1                                  # 74BD: D0 D4
    rcl    dx,1                                  # 74BF: D1 D2
    rcl    bl,1                                  # 74C1: D0 D3
    dec    bh                                    # 74C3: FE CF
    jne    L_74A5                                # 74C5: 75 DE
L_74C7:
    jmp    ZERO                                # 74C7: E9 A1 06
L_74CA:
    mov    BYTE PTR ds:FACEXP,bh                  # 74CA: 88 3E A6 04
    jmp    L_7954                                # 74CE: E9 83 04
    .byte 0xCC, 0x20, 0xEB, 0xF4, 0x88, 0x3E, 0xA6, 0x04, 0xE9, 0x78, 0x04 # 74D1
L_74DC:
    push   bx                                    # 74DC: 53
    call   L_74E2                                # 74DD: E8 02 00
    pop    bx                                    # 74E0: 5B
    ret                                          # 74E1: C3
L_74E2:
    call   L_7512                                # 74E2: E8 2D 00
    mov    bx,0x40a                              # 74E5: BB 0A 04
    jmp    L_74F6                                # 74E8: EB 0C
L_74EA:
    push   bx                                    # 74EA: 53
    call   L_74F0                                # 74EB: E8 02 00
    pop    bx                                    # 74EE: 5B
    ret                                          # 74EF: C3
L_74F0:
    call   L_7512                                # 74F0: E8 1F 00
    mov    bx,0x463                              # 74F3: BB 63 04
L_74F6:
    cmp    BYTE PTR ds:FLGOVC,0x1                 # 74F6: 80 3E A8 04 01
    js     L_7504                                # 74FB: 78 07
    jne    L_7511                                # 74FD: 75 12
    mov    BYTE PTR ds:FLGOVC,0x2                 # 74FF: C6 06 A8 04 02
L_7504:
    call   L_2488                                # 7504: E8 81 AF
    mov    al,0xd                                # 7507: B0 0D
    call   L_2495                                # 7509: E8 89 AF
    mov    al,0xa                                # 750C: B0 0A
    call   L_2495                                # 750E: E8 84 AF
L_7511:
    ret                                          # 7511: C3
L_7512:
    cld                                          # 7512: FC
    .byte 0x0A, 0xFF # 7513
    mov    si,0x6203                             # 7515: BE 03 62
    je     L_7524                                # 7518: 74 0A
    test   BYTE PTR ds:FAC_AUX,0x80                # 751A: F6 06 A7 04 80
    jns    L_7524                                # 751F: 79 03
    mov    si,0x620b                             # 7521: BE 0B 62
L_7524:
    call   GETYP                                # 7524: E8 7B 06
    jb     L_7531                                # 7527: 72 08
    mov    di,DFACL                              # 7529: BF 9F 04
    mov    cx,0x4                                # 752C: B9 04 00
    jmp    L_753A                                # 752F: EB 09
L_7531:
    add    si,0x4                                # 7531: 83 C6 04
    mov    di,0x4a3                              # 7534: BF A3 04
    mov    cx,0x2                                # 7537: B9 02 00
L_753A:
    movs   WORD PTR es:[di],WORD PTR cs:[si]     # 753A: 2E A5
    loop   L_753A                                # 753C: E2 FC
    ret                                          # 753E: C3
L_753F:
    call   PUSHF                                # 753F: E8 0D 09
    push   bx                                    # 7542: 53
    call   MOVRF                                # 7543: E8 81 07
    call   FMULS                                # 7546: E8 B6 F7
    pop    bx                                    # 7549: 5B
    call   L_7552                                # 754A: E8 05 00
    pop    dx                                    # 754D: 5A
    pop    bx                                    # 754E: 5B
    jmp    FMULS                                # 754F: E9 AD F7
L_7552:
    mov    al,BYTE PTR cs:[bx]                   # 7552: 2E 8A 07
    cbw                                          # 7555: 98
    call   PUSHF                                # 7556: E8 F6 08
    push   ax                                    # 7559: 50
    inc    bx                                    # 755A: 43
    mov    ax,WORD PTR cs:[bx]                   # 755B: 2E 8B 07
    mov    ds:FACLO,ax                           # 755E: A3 A3 04
    add    bx,0x2                                # 7561: 83 C3 02
    mov    ax,WORD PTR cs:[bx]                   # 7564: 2E 8B 07
    mov    ds:FACSGN,ax                           # 7567: A3 A5 04
    add    bx,0x2                                # 756A: 83 C3 02
L_756D:
    pop    ax                                    # 756D: 58
    pop    dx                                    # 756E: 5A
    pop    cx                                    # 756F: 59
    dec    ax                                    # 7570: 48
    je     L_758F                                # 7571: 74 1C
    push   cx                                    # 7573: 51
    push   dx                                    # 7574: 52
    push   ax                                    # 7575: 50
    push   bx                                    # 7576: 53
    xchg   cx,bx                                 # 7577: 87 D9
    call   FMULS                                # 7579: E8 83 F7
    pop    bx                                    # 757C: 5B
    push   bx                                    # 757D: 53
    mov    dx,WORD PTR cs:[bx]                   # 757E: 2E 8B 17
    .byte 0x2E, 0x8B, 0x9F, 0x02, 0x00 # 7581
    call   L_6773                                # 7586: E8 EA F1
    pop    bx                                    # 7589: 5B
    add    bx,0x4                                # 758A: 83 C3 04
    jmp    L_756D                                # 758D: EB DE
L_758F:
    ret                                          # 758F: C3
L_7590:
    push   bx                                    # 7590: 53
    shr    al,1                                  # 7591: D0 E8
    jae    L_7598                                # 7593: 73 03
    jmp    L_76A1                                # 7595: E9 09 01
L_7598:
    mov    bx,0x60b2                             # 7598: BB B2 60
    call   MOVBF                                # 759B: E8 D6 06
    call   VCOMP                                # 759E: E8 2F 07
    jb     L_75AC                                # 75A1: 72 09
    pop    bx                                    # 75A3: 5B
    call   L_70CA                                # 75A4: E8 23 FB
    dec    bx                                    # 75A7: 4B
    mov    BYTE PTR [bx],0x25                    # 75A8: C6 07 25
    ret                                          # 75AB: C3
L_75AC:
    call   GETYP                                # 75AC: E8 F3 05
    mov    ch,0x10                               # 75AF: B5 10
    jae    L_75B5                                # 75B1: 73 02
    mov    ch,0x7                                # 75B3: B5 07
L_75B5:
    call   SIGN                                # 75B5: E8 BD 05
    je     L_75BD                                # 75B8: 74 03
    call   L_6FC1                                # 75BA: E8 04 FA
L_75BD:
    pop    bx                                    # 75BD: 5B
    js     L_75FF                                # 75BE: 78 3F
    .byte 0x8A, 0xD0, 0x02, 0xC5 # 75C0
    sub    al,BYTE PTR ds:FMTCX+1                  # 75C4: 2A 06 82 04
    jns    L_75CF                                # 75C8: 79 05
    neg    al                                    # 75CA: F6 D8
    call   L_7091                                # 75CC: E8 C2 FA
L_75CF:
    .byte 0x32, 0xC9 # 75CF
    call   L_7685                                # 75D1: E8 B1 00
    push   WORD PTR ds:FMTCX                     # 75D4: FF 36 81 04
    push   dx                                    # 75D8: 52
    call   L_6EB6                                # 75D9: E8 DA F8
    pop    dx                                    # 75DC: 5A
    pop    WORD PTR ds:FMTCX                     # 75DD: 8F 06 81 04
    push   WORD PTR ds:FMTCX                     # 75E1: FF 36 81 04
    .byte 0x32, 0xC0, 0x0A, 0xC2 # 75E5
    je     L_75F1                                # 75E9: 74 06
    call   L_70A1                                # 75EB: E8 B3 FA
    call   L_6E2A                                # 75EE: E8 39 F8
L_75F1:
    pop    WORD PTR ds:FMTCX                     # 75F1: 8F 06 81 04
    push   WORD PTR ds:FMTCX                     # 75F5: FF 36 81 04
    mov    al,ds:FMTCX                           # 75F9: A0 81 04
    jmp    L_7871                                # 75FC: E9 72 02
L_75FF:
    .byte 0x8A, 0xD0 # 75FF
    mov    al,ds:FMTCX                           # 7601: A0 81 04
    .byte 0x0A, 0xC0 # 7604
    je     L_760A                                # 7606: 74 02
    dec    al                                    # 7608: FE C8
L_760A:
    .byte 0x8A, 0xF0, 0x02, 0xC2, 0x8A, 0xC8 # 760A
    js     L_7616                                # 7610: 78 04
    .byte 0x32, 0xC0, 0x8A, 0xC8 # 7612
L_7616:
    jns    L_7629                                # 7616: 79 11
L_7618:
    push   ax                                    # 7618: 50
    push   cx                                    # 7619: 51
    push   dx                                    # 761A: 52
    push   bx                                    # 761B: 53
    call   DIV10                                # 761C: E8 A9 05
    pop    bx                                    # 761F: 5B
    pop    dx                                    # 7620: 5A
    pop    cx                                    # 7621: 59
    pop    ax                                    # 7622: 58
    inc    al                                    # 7623: FE C0
    js     L_7618                                # 7625: 78 F1
    .byte 0x8A, 0xE1 # 7627
L_7629:
    .byte 0x8A, 0xC2, 0x2A, 0xC1, 0x02, 0xC5 # 7629
    jns    L_7648                                # 762F: 79 17
    mov    al,ds:FMTCX+1                           # 7631: A0 82 04
    call   L_7091                                # 7634: E8 5A FA
    mov    BYTE PTR [bx],0x2e                    # 7637: C6 07 2E
    mov    WORD PTR ds:TEMP2,bx                  # 763A: 89 1E 52 03
    inc    bx                                    # 763E: 43
    .byte 0x32, 0xC9, 0x8A, 0xC6, 0x2A, 0xC5 # 763F
    jmp    L_7FE9                                # 7645: E9 A1 09
L_7648:
    mov    al,ds:FMTCX+1                           # 7648: A0 82 04
    push   dx                                    # 764B: 52
    push   WORD PTR ds:FMTCX                     # 764C: FF 36 81 04
    .byte 0x2A, 0xC5, 0x2A, 0xC2, 0x02, 0xC1 # 7650
    js     L_765B                                # 7656: 78 03
    call   L_7091                                # 7658: E8 36 FA
L_765B:
    call   L_7685                                # 765B: E8 27 00
L_765E:
    push   WORD PTR ds:FMTCX                     # 765E: FF 36 81 04
    call   L_6EB6                                # 7662: E8 51 F8
    mov    al,ds:FMTCX+1                           # 7665: A0 82 04
    pop    WORD PTR ds:FMTCX                     # 7668: 8F 06 81 04
    .byte 0x0A, 0xC0 # 766C
    pop    ax                                    # 766E: 58
    pop    dx                                    # 766F: 5A
    jne    L_7679                                # 7670: 75 07
    mov    bx,WORD PTR ds:TEMP2                  # 7672: 8B 1E 52 03
    jmp    L_77E0                                # 7676: E9 67 01
L_7679:
    .byte 0x02, 0xC2 # 7679
    dec    al                                    # 767B: FE C8
    js     L_7682                                # 767D: 78 03
    call   L_7091                                # 767F: E8 0F FA
L_7682:
    jmp    L_77E0                                # 7682: E9 5B 01
L_7685:
    .byte 0x8A, 0xC5, 0x02, 0xC2, 0x2A, 0xC1 # 7685
    inc    al                                    # 768B: FE C0
    .byte 0x8A, 0xE8 # 768D
L_768F:
    sub    al,0x3                                # 768F: 2C 03
    jg     L_768F                                # 7691: 7F FC
    add    al,0x3                                # 7693: 04 03
    .byte 0x8A, 0xC8 # 7695
    mov    al,ds:FMTAX                           # 7697: A0 83 04
    and    al,0x40                               # 769A: 24 40
    jne    L_76A0                                # 769C: 75 02
    .byte 0x8A, 0xC8 # 769E
L_76A0:
    ret                                          # 76A0: C3
L_76A1:
    call   GETYP                                # 76A1: E8 FE 04
    mov    ah,0x7                                # 76A4: B4 07
    jb     L_76AA                                # 76A6: 72 02
    mov    ah,0x10                               # 76A8: B4 10
L_76AA:
    call   SIGN                                # 76AA: E8 C8 04
    pop    bx                                    # 76AD: 5B
    stc                                          # 76AE: F9
    je     L_76BA                                # 76AF: 74 09
    push   bx                                    # 76B1: 53
    push   ax                                    # 76B2: 50
    call   L_6FC1                                # 76B3: E8 0B F9
    pop    dx                                    # 76B6: 5A
    pop    bx                                    # 76B7: 5B
    .byte 0x8A, 0xE6 # 76B8
L_76BA:
    pushf                                        # 76BA: 9C
    push   ax                                    # 76BB: 50
    mov    dx,WORD PTR ds:FMTCX                  # 76BC: 8B 16 81 04
    .byte 0x0A, 0xF6 # 76C0
    pushf                                        # 76C2: 9C
    .byte 0x0A, 0xD2 # 76C3
    je     L_76C9                                # 76C5: 74 02
    dec    dl                                    # 76C7: FE CA
L_76C9:
    .byte 0x02, 0xF2 # 76C9
    popf                                         # 76CB: 9D
    je     L_76D7                                # 76CC: 74 09
    test   BYTE PTR ds:FMTAX,0x4                 # 76CE: F6 06 83 04 04
    jne    L_76D7                                # 76D3: 75 02
    dec    dh                                    # 76D5: FE CE
L_76D7:
    .byte 0x2A, 0xF4, 0x8A, 0xE6 # 76D7
    push   ax                                    # 76DB: 50
    js     L_76E1                                # 76DC: 78 03
    .byte 0xE9, 0x4E, 0x00 # 76DE
L_76E1:
    push   bx                                    # 76E1: 53
    push   ax                                    # 76E2: 50
L_76E3:
    push   ax                                    # 76E3: 50
    call   DIV10                                # 76E4: E8 E1 04
    pop    ax                                    # 76E7: 58
    inc    ah                                    # 76E8: FE C4
    jne    L_76E3                                # 76EA: 75 F7
    call   VADDH                                # 76EC: E8 BF 04
    call   VINT                             # 76EF: E8 8E 07
    pop    ax                                    # 76F2: 58
    push   ax                                    # 76F3: 50
    mov    cx,0x3                                # 76F4: B9 03 00
    shl    ah,cl                                 # 76F7: D2 E4
    call   GETYP                                # 76F9: E8 A6 04
    jb     L_770E                                # 76FC: 72 10
    .byte 0x8A, 0xC4 # 76FE
    cbw                                          # 7700: 98
    mov    bx,0x60b2                             # 7701: BB B2 60
    .byte 0x03, 0xD8 # 7704
    call   MOVBF                                # 7706: E8 6B 05
    call   DCMPM                                # 7709: E8 55 06
    jmp    L_771C                                # 770C: EB 0E
L_770E:
    mov    bx,0x606e                             # 770E: BB 6E 60
    .byte 0x8A, 0xC4 # 7711
    cbw                                          # 7713: 98
    .byte 0x03, 0xD8 # 7714
    call   MOVBS                                # 7716: E8 53 05
    call   COMPM                                # 7719: E8 F8 05
L_771C:
    pop    ax                                    # 771C: 58
    pop    bx                                    # 771D: 5B
    js     L_7731                                # 771E: 78 11
    pop    ax                                    # 7720: 58
    pop    cx                                    # 7721: 59
    inc    cl                                    # 7722: FE C1
    push   cx                                    # 7724: 51
    push   ax                                    # 7725: 50
    push   bx                                    # 7726: 53
    push   ax                                    # 7727: 50
    call   DIV10                                # 7728: E8 9D 04
    pop    ax                                    # 772B: 58
    pop    bx                                    # 772C: 5B
    jmp    L_7731                                # 772D: EB 02
L_772F:
    .byte 0x32, 0xE4 # 772F
L_7731:
    neg    ah                                    # 7731: F6 DC
    mov    al,ds:FMTCX+1                           # 7733: A0 82 04
    .byte 0x02, 0xE0 # 7736
    inc    ah                                    # 7738: FE C4
    .byte 0x0A, 0xC0 # 773A
    je     L_7747                                # 773C: 74 09
    test   BYTE PTR ds:FMTAX,0x4                 # 773E: F6 06 83 04 04
    jne    L_7747                                # 7743: 75 02
    dec    ah                                    # 7745: FE CC
L_7747:
    .byte 0x8A, 0xEC, 0x32, 0xC9 # 7747
    pop    ax                                    # 774B: 58
    push   WORD PTR ds:FMTCX                     # 774C: FF 36 81 04
    push   ax                                    # 7750: 50
    mov    BYTE PTR ds:FMTCX+1,ch                  # 7751: 88 2E 82 04
    call   L_6EB6                                # 7755: E8 5E F7
    pop    ax                                    # 7758: 58
    .byte 0x0A, 0xE4 # 7759
    jle    L_7762                                # 775B: 7E 05
    .byte 0x8A, 0xC4 # 775D
    call   L_70A1                                # 775F: E8 3F F9
L_7762:
    pop    ax                                    # 7762: 58
    mov    ds:FMTCX,ax                           # 7763: A3 81 04
    .byte 0x0A, 0xC0 # 7766
    jne    L_7776                                # 7768: 75 0C
    dec    bx                                    # 776A: 4B
    mov    al,BYTE PTR [bx]                      # 776B: 8A 07
    cmp    al,0x2e                               # 776D: 3C 2E
    je     L_7772                                # 776F: 74 01
    inc    bx                                    # 7771: 43
L_7772:
    mov    WORD PTR ds:TEMP2,bx                  # 7772: 89 1E 52 03
L_7776:
    pop    ax                                    # 7776: 58
    popf                                         # 7777: 9D
    jb     L_778F                                # 7778: 72 15
    .byte 0x02, 0xC4 # 777A
    mov    ah,BYTE PTR ds:FMTCX+1                  # 777C: 8A 26 82 04
    .byte 0x2A, 0xC4, 0x0A, 0xE4 # 7780
    je     L_778F                                # 7784: 74 09
    test   BYTE PTR ds:FMTAX,0x4                 # 7786: F6 06 83 04 04
    jne    L_778F                                # 778B: 75 02
    inc    al                                    # 778D: FE C0
L_778F:
    .byte 0x0A, 0xC0 # 778F
    call   L_6DDE                                # 7791: E8 4A F6
    .byte 0x8B, 0xD9, 0xE9, 0x47, 0x00 # 7794
L_7799:
    .byte 0x8A, 0xE0 # 7799
    test   ah,0x40                               # 779B: F6 C4 40
    mov    ah,0x3                                # 779E: B4 03
    jne    L_77A4                                # 77A0: 75 02
    .byte 0x32, 0xE4 # 77A2
L_77A4:
    mov    ds:FMTAX,ax                           # 77A4: A3 83 04
    mov    WORD PTR ds:FMTCX,cx                  # 77A7: 89 0E 81 04
    .byte 0x8A, 0xE0 # 77AB
    mov    bx,0x4b4                              # 77AD: BB B4 04
    mov    BYTE PTR [bx],0x20                    # 77B0: C6 07 20
    test   ah,0x8                                # 77B3: F6 C4 08
    je     L_77BB                                # 77B6: 74 03
    mov    BYTE PTR [bx],0x2b                    # 77B8: C6 07 2B
L_77BB:
    push   bx                                    # 77BB: 53
    call   SIGN                                # 77BC: E8 B6 03
    pop    bx                                    # 77BF: 5B
    jns    L_77CA                                # 77C0: 79 08
    mov    BYTE PTR [bx],0x2d                    # 77C2: C6 07 2D
    push   bx                                    # 77C5: 53
    call   VNEG                                # 77C6: E8 E2 05
    pop    bx                                    # 77C9: 5B
L_77CA:
    inc    bx                                    # 77CA: 43
    mov    BYTE PTR [bx],0x30                    # 77CB: C6 07 30
    call   GETYP                                # 77CE: E8 D1 03
    mov    ax,ds:FMTAX                           # 77D1: A1 83 04
    mov    cx,WORD PTR ds:FMTCX                  # 77D4: 8B 0E 81 04
    js     L_77DD                                # 77D8: 78 03
    jmp    L_7590                                # 77DA: E9 B3 FD
L_77DD:
    .byte 0xE9, 0x68, 0x00 # 77DD
L_77E0:
    push   bx                                    # 77E0: 53
    call   L_701F                                # 77E1: E8 3B F8
    pop    bx                                    # 77E4: 5B
    je     L_77EA                                # 77E5: 74 03
    mov    BYTE PTR [bx],ch                      # 77E7: 88 2F
    inc    bx                                    # 77E9: 43
L_77EA:
    mov    BYTE PTR [bx],0x0                     # 77EA: C6 07 00
    mov    bx,0x4b3                              # 77ED: BB B3 04
L_77F0:
    inc    bx                                    # 77F0: 43
L_77F1:
    mov    di,WORD PTR ds:TEMP2                  # 77F1: 8B 3E 52 03
    mov    dx,WORD PTR ds:FMTCX                  # 77F5: 8B 16 81 04
    mov    al,ds:FMTCX+1                           # 77F9: A0 82 04
    .byte 0x32, 0xE4, 0x2B, 0xFB, 0x2B, 0xF8 # 77FC
    je     L_7847                                # 7802: 74 43
    mov    al,BYTE PTR [bx]                      # 7804: 8A 07
    cmp    al,0x20                               # 7806: 3C 20
    je     L_77F0                                # 7808: 74 E6
    cmp    al,0x2a                               # 780A: 3C 2A
    je     L_77F0                                # 780C: 74 E2
    mov    ah,0x1                                # 780E: B4 01
    dec    bx                                    # 7810: 4B
    push   bx                                    # 7811: 53
L_7812:
    push   ax                                    # 7812: 50
    call   L_6300                                # 7813: E8 EA EA
    .byte 0x32, 0xE4 # 7816
    cmp    al,0x2d                               # 7818: 3C 2D
    je     L_7812                                # 781A: 74 F6
    cmp    al,0x2b                               # 781C: 3C 2B
    je     L_7812                                # 781E: 74 F2
    cmp    al,0x24                               # 7820: 3C 24
    je     L_7812                                # 7822: 74 EE
    cmp    al,0x30                               # 7824: 3C 30
    jne    L_783E                                # 7826: 75 16
    inc    bx                                    # 7828: 43
    call   L_6300                                # 7829: E8 D4 EA
    jae    L_783E                                # 782C: 73 10
    dec    bx                                    # 782E: 4B
    jmp    L_7834                                # 782F: EB 03
L_7831:
    dec    bx                                    # 7831: 4B
    mov    BYTE PTR [bx],al                      # 7832: 88 07
L_7834:
    pop    ax                                    # 7834: 58
    .byte 0x0A, 0xE4 # 7835
    je     L_7831                                # 7837: 74 F8
    add    sp,0x2                                # 7839: 83 C4 02
    jmp    L_77F1                                # 783C: EB B3
L_783E:
    pop    ax                                    # 783E: 58
    .byte 0x0A, 0xE4 # 783F
    je     L_783E                                # 7841: 74 FB
    pop    bx                                    # 7843: 5B
    mov    BYTE PTR [bx],0x25                    # 7844: C6 07 25
L_7847:
    ret                                          # 7847: C3
L_7848:
    mov    ax,ds:FMTAX                           # 7848: A1 83 04
    .byte 0x8A, 0xCC # 784B
    mov    ch,0x6                                # 784D: B5 06
    shr    al,1                                  # 784F: D0 E8
    mov    dx,WORD PTR ds:FMTCX                  # 7851: 8B 16 81 04
    jae    L_7862                                # 7855: 73 0B
    push   bx                                    # 7857: 53
    push   dx                                    # 7858: 52
    call   CSI                                # 7859: E8 45 F3
    .byte 0x32, 0xC0 # 785C
    pop    dx                                    # 785E: 5A
    jmp    L_76A1                                # 785F: E9 3F FE
L_7862:
    .byte 0x8A, 0xC6 # 7862
    sub    al,0x5                                # 7864: 2C 05
    js     L_786B                                # 7866: 78 03
    call   L_7091                                # 7868: E8 26 F8
L_786B:
    push   dx                                    # 786B: 52
    call   L_6E49                                # 786C: E8 DA F5
    pop    ax                                    # 786F: 58
    push   ax                                    # 7870: 50
L_7871:
    .byte 0x0A, 0xC0 # 7871
    jne    L_7876                                # 7873: 75 01
    dec    bx                                    # 7875: 4B
L_7876:
    dec    al                                    # 7876: FE C8
    js     L_7880                                # 7878: 78 06
    call   L_7091                                # 787A: E8 14 F8
    mov    BYTE PTR [bx],0x0                     # 787D: C6 07 00
L_7880:
    pop    WORD PTR ds:FMTCX                     # 7880: 8F 06 81 04
    jmp    L_77E0                                # 7884: E9 59 FF
RND:
    call   SIGN                                # 7887: E8 EB 02
    je     L_78F9                                # 788A: 74 6D
    jns    L_789A                                # 788C: 79 0C
    mov    ax,ds:FACLO                           # 788E: A1 A3 04
    mov    ds:RNDX,ax                             # 7891: A3 0B 00
    mov    al,ds:FACSGN                           # 7894: A0 A5 04
    mov    ds:RNDX+2,al                             # 7897: A2 0D 00
L_789A:
    mov    ax,ds:RNDX                             # 789A: A1 0B 00
    mul    WORD PTR cs:0x626b                    # 789D: 2E F7 26 6B 62
    .byte 0x8B, 0xF8, 0x8A, 0xCA # 78A2
    mov    al,cs:0x626d                          # 78A6: 2E A0 6D 62
    mul    BYTE PTR ds:RNDX                       # 78AA: F6 26 0B 00
    .byte 0x02, 0xC8 # 78AE
    mov    al,cs:0xd                             # 78B0: 2E A0 0D 00
    mul    BYTE PTR cs:0x626b                    # 78B4: 2E F6 26 6B 62
    .byte 0x02, 0xC8, 0x32, 0xC0 # 78B9
    mov    dx,WORD PTR cs:0x626e                 # 78BD: 2E 8B 16 6E 62
    .byte 0x03, 0xD7 # 78C2
    mov    bl,BYTE PTR cs:0x6270                 # 78C4: 2E 8A 1E 70 62
    .byte 0x12, 0xD9 # 78C9
    mov    ds:FAC_AUX,al                           # 78CB: A2 A7 04
    mov    al,0x80                               # 78CE: B0 80
    mov    ds:FACEXP,al                           # 78D0: A2 A6 04
    mov    WORD PTR ds:RNDX,dx                    # 78D3: 89 16 0B 00
    mov    BYTE PTR ds:RNDX+2,bl                    # 78D7: 88 1E 0D 00
    mov    al,0x4                                # 78DB: B0 04
    mov    ds:VALTYP,al                           # 78DD: A2 FB 02
    jmp    L_749E                                # 78E0: E9 BB FB
    .byte 0x00, 0x00, 0x00, 0xBB, 0xB3, 0x04, 0xB9, 0x20, 0x00, 0x03, 0x07, 0x43 # 78E3
    .byte 0x43, 0xE2, 0xFA, 0x24, 0xFE, 0xA3, 0x0B, 0x00, 0xEB, 0xA1 # 78EF
L_78F9:
    mov    dx,WORD PTR ds:RNDX                    # 78F9: 8B 16 0B 00
    mov    bl,BYTE PTR ds:RNDX+2                    # 78FD: 8A 1E 0D 00
    .byte 0x33, 0xC0 # 7901
    mov    al,0x80                               # 7903: B0 80
    mov    ds:FACEXP,al                           # 7905: A2 A6 04
    mov    BYTE PTR ds:FAC_AUX,ah                  # 7908: 88 26 A7 04
    jmp    L_749E                                # 790C: E9 8F FB
L_790F:
    push   bx                                    # 790F: 53
    push   cx                                    # 7910: 51
    mov    bx,DFACL-1                              # 7911: BB 9E 04
    add    WORD PTR [bx],0x80                    # 7914: 81 07 80 00
    mov    cx,0x3                                # 7918: B9 03 00
    jae    L_792B                                # 791B: 73 0E
L_791D:
    inc    bx                                    # 791D: 43
    inc    bx                                    # 791E: 43
    inc    WORD PTR [bx]                         # 791F: FF 07
    jne    L_792B                                # 7921: 75 08
    loop   L_791D                                # 7923: E2 F8
    inc    BYTE PTR ds:FACEXP                     # 7925: FE 06 A6 04
    rcr    WORD PTR [bx],1                       # 7929: D1 1F
L_792B:
    pop    cx                                    # 792B: 59
    je     L_794E                                # 792C: 74 20
    test   BYTE PTR ds:DFACL-1,0xff                # 792E: F6 06 9E 04 FF
    jne    L_793A                                # 7933: 75 05
    and    BYTE PTR ds:DFACL,0xfe                # 7935: 80 26 9F 04 FE
L_793A:
    mov    bx,FACM1                              # 793A: BB A5 04
    mov    al,BYTE PTR [bx]                      # 793D: 8A 07
    .byte 0x8A, 0xA7, 0x02, 0x00 # 793F
    and    al,0x7f                               # 7943: 24 7F
    and    ah,0x80                               # 7945: 80 E4 80
    .byte 0x0A, 0xE0 # 7948
    mov    BYTE PTR [bx],ah                      # 794A: 88 27
    pop    bx                                    # 794C: 5B
    ret                                          # 794D: C3
L_794E:
    nop                                          # 794E: 90
    nop                                          # 794F: 90
    nop                                          # 7950: 90
    jmp    L_74DC                                # 7951: E9 88 FB
L_7954:
    and    ah,0xe0                               # 7954: 80 E4 E0
L_7957:
    add    ah,0x80                               # 7957: 80 C4 80
    jae    L_7978                                # 795A: 73 1C
    pushf                                        # 795C: 9C
    inc    dx                                    # 795D: 42
    jne    L_7972                                # 795E: 75 12
    popf                                         # 7960: 9D
    inc    bl                                    # 7961: FE C3
    jne    L_7978                                # 7963: 75 13
    stc                                          # 7965: F9
    rcr    bl,1                                  # 7966: D0 DB
    inc    BYTE PTR ds:FACEXP                     # 7968: FE 06 A6 04
    jne    L_7978                                # 796C: 75 0A
    nop                                          # 796E: 90
    jmp    L_74DC                                # 796F: E9 6A FB
L_7972:
    popf                                         # 7972: 9D
    jne    L_7978                                # 7973: 75 03
    and    dl,0xfe                               # 7975: 80 E2 FE
L_7978:
    push   si                                    # 7978: 56
    mov    si,0x4a3                              # 7979: BE A3 04
    mov    WORD PTR [si],dx                      # 797C: 89 14
    inc    si                                    # 797E: 46
    inc    si                                    # 797F: 46
    mov    bh,BYTE PTR ds:FAC_AUX                  # 7980: 8A 3E A7 04
    and    bx,0x807f                             # 7984: 81 E3 7F 80
    .byte 0x0A, 0xDF # 7988
    mov    BYTE PTR [si],bl                      # 798A: 88 1C
    pop    si                                    # 798C: 5E
    ret                                          # 798D: C3
L_798E:
    .byte 0x8B, 0xF1 # 798E
    call   VPSHF                                # 7990: E8 B4 04
    .byte 0x8B, 0xCE # 7993
    push   cx                                    # 7995: 51
    call   GETYP                                # 7996: E8 09 02
    jb     L_79A4                                # 7999: 72 09
    cmp    BYTE PTR ds:FACEXP,0xb8                # 799B: 80 3E A6 04 B8
    jns    L_79B1                                # 79A0: 79 0F
    jmp    L_79AB                                # 79A2: EB 07
L_79A4:
    cmp    BYTE PTR ds:FACEXP,0x98                # 79A4: 80 3E A6 04 98
    jns    L_79B1                                # 79A9: 79 06
L_79AB:
    call   VADDH                                # 79AB: E8 00 02
    call   VINT                             # 79AE: E8 CF 04
L_79B1:
    mov    bx,0x486                              # 79B1: BB 86 04
    call   VMVMF                                # 79B4: E8 51 04
    pop    cx                                    # 79B7: 59
L_79B8:
    push   cx                                    # 79B8: 51
    mov    di,0x48e                              # 79B9: BF 8E 04
    mov    bx,0x486                              # 79BC: BB 86 04
    call   VMOVM                                # 79BF: E8 35 04
    mov    bx,0x486                              # 79C2: BB 86 04
    call   VMVFM                                # 79C5: E8 5D 04
    call   DIV10                                # 79C8: E8 FD 01
    call   VINT                             # 79CB: E8 B2 04
    mov    bx,0x486                              # 79CE: BB 86 04
    call   VMVMF                                # 79D1: E8 34 04
    call   MUL10                                # 79D4: E8 FB 01
    mov    bx,0x494                              # 79D7: BB 94 04
    call   GETYP                                # 79DA: E8 C5 01
    jae    L_79E2                                # 79DD: 73 03
    sub    bx,0x4                                # 79DF: 83 EB 04
L_79E2:
    call   VCMPM                                # 79E2: E8 57 04
    pop    cx                                    # 79E5: 59
    jne    L_79EC                                # 79E6: 75 04
    inc    cl                                    # 79E8: FE C1
    jmp    L_79B8                                # 79EA: EB CC
L_79EC:
    .byte 0x8B, 0xE9 # 79EC
    call   VPOPF                                # 79EE: E8 75 04
    .byte 0x8B, 0xCD # 79F1
    ret                                          # 79F3: C3
COS:
    and    BYTE PTR ds:FACSGN,0x7f                # 79F4: 80 26 A5 04 7F
    call   L_7A82                                # 79F9: E8 86 00
    call   L_7AA4                                # 79FC: E8 A5 00
    mov    BYTE PTR ds:ARGEXP,0x7f                # 79FF: C6 06 B2 04 7F
    call   L_66AA                                # 7A04: E8 A3 EC
    call   L_7A8E                                # 7A07: E8 84 00
    jmp    L_7A27                                # 7A0A: EB 1B
    .byte 0x65, 0xED # 7A0C
SIN:
    mov    ax,ds:FACSGN                           # 7A0E: A1 A5 04
    cmp    ah,0x77                               # 7A11: 80 FC 77
    jae    L_7A17                                # 7A14: 73 01
    ret                                          # 7A16: C3
L_7A17:
    .byte 0x0A, 0xC0 # 7A17
    jns    L_7A24                                # 7A19: 79 09
    and    al,0x7f                               # 7A1B: 24 7F
    mov    ds:FACSGN,al                           # 7A1D: A2 A5 04
    mov    ax,0x7db0                             # 7A20: B8 B0 7D
    push   ax                                    # 7A23: 50
L_7A24:
    call   L_7A82                                # 7A24: E8 5B 00
L_7A27:
    mov    al,ds:FACEXP                           # 7A27: A0 A6 04
    .byte 0x0A, 0xC0 # 7A2A
    je     L_7A33                                # 7A2C: 74 05
    add    BYTE PTR ds:FACEXP,0x2                 # 7A2E: 80 06 A6 04 02
L_7A33:
    call   L_7A97                                # 7A33: E8 61 00
    mov    ax,ds:ARG_M1                           # 7A36: A1 B1 04
    cmp    ah,0x82                               # 7A39: 80 FC 82
    pushf                                        # 7A3C: 9C
    test   ah,0x1                                # 7A3D: F6 C4 01
    jne    L_7A44                                # 7A40: 75 02
    test   al,0x40                               # 7A42: A8 40
L_7A44:
    pushf                                        # 7A44: 9C
    call   L_7A91                                # 7A45: E8 49 00
    popf                                         # 7A48: 9D
    je     L_7A54                                # 7A49: 74 09
    mov    bx,0x6032                             # 7A4B: BB 32 60
    call   MOVAC                                # 7A4E: E8 37 02
    call   L_669C                                # 7A51: E8 48 EC
L_7A54:
    sub    BYTE PTR ds:FACEXP,0x2                 # 7A54: 80 2E A6 04 02
    jae    L_7A5E                                # 7A59: 73 03
    call   DZERO                                # 7A5B: E8 00 01
L_7A5E:
    call   CSD                                # 7A5E: E8 03 F1
    mov    al,ds:FACEXP                           # 7A61: A0 A6 04
    cmp    al,0x74                               # 7A64: 3C 74
    jae    L_7A73                                # 7A66: 73 0B
    mov    dx,0xfdb                              # 7A68: BA DB 0F
    mov    bx,0x8349                             # 7A6B: BB 49 83
    call   FMULS                                # 7A6E: E8 8E F2
    jmp    L_7A79                                # 7A71: EB 06
L_7A73:
    mov    bx,0x6234                             # 7A73: BB 34 62
    call   L_753F                                # 7A76: E8 C6 FA
L_7A79:
    popf                                         # 7A79: 9D
    jne    L_7A81                                # 7A7A: 75 05
    xor    BYTE PTR ds:FACSGN,0x80                # 7A7C: 80 36 A5 04 80
L_7A81:
    ret                                          # 7A81: C3
L_7A82:
    mov    bx,0x6263                             # 7A82: BB 63 62
    call   MOVAC                                # 7A85: E8 00 02
    call   L_6B93                                # 7A88: E8 08 F1
    call   FMULD                                # 7A8B: E8 C7 F1
L_7A8E:
    call   L_7A97                                # 7A8E: E8 06 00
L_7A91:
    call   L_669C                                # 7A91: E8 08 EC
    jmp    NEG                                # 7A94: E9 19 03
L_7A97:
    call   VPSHF                                # 7A97: E8 AD 03
    call   L_7241                                # 7A9A: E8 A4 F7
    call   MOVAF                                # 7A9D: E8 00 02
    call   VPOPF                                # 7AA0: E8 C3 03
    ret                                          # 7AA3: C3
L_7AA4:
    mov    bx,0x6032                             # 7AA4: BB 32 60
    jmp    MOVAC                                # 7AA7: E9 DE 01
    .byte 0xB8, 0xF0, 0xC3 # 7AAA
TAN:
    push   WORD PTR ds:FACSGN                     # 7AAD: FF 36 A5 04
    push   WORD PTR ds:FACLO                     # 7AB1: FF 36 A3 04
    call   SIN                              # 7AB5: E8 56 FF
    pop    dx                                    # 7AB8: 5A
    pop    bx                                    # 7AB9: 5B
    push   WORD PTR ds:FACLO                     # 7ABA: FF 36 A3 04
    push   WORD PTR ds:FACSGN                     # 7ABE: FF 36 A5 04
    call   MOVFR                                # 7AC2: E8 F9 01
    call   COS                           # 7AC5: E8 2C FF
    pop    bx                                    # 7AC8: 5B
    pop    dx                                    # 7AC9: 5A
    jmp    L_68DE                                # 7ACA: E9 11 EE
ATN:
    mov    ax,ds:FACSGN                           # 7ACD: A1 A5 04
    .byte 0x0A, 0xC0 # 7AD0
    jns    L_7ADD                                # 7AD2: 79 09
    mov    di,0x7db0                             # 7AD4: BF B0 7D
    push   di                                    # 7AD7: 57
    and    al,0x7f                               # 7AD8: 24 7F
    mov    ds:FACSGN,al                           # 7ADA: A2 A5 04
L_7ADD:
    cmp    ah,0x81                               # 7ADD: 80 FC 81
    jb     L_7AEE                                # 7AE0: 72 0C
    mov    di,0x7b39                             # 7AE2: BF 39 7B
    push   di                                    # 7AE5: 57
    .byte 0x33, 0xD2 # 7AE6
    mov    bx,0x8100                             # 7AE8: BB 00 81
    call   L_68DE                                # 7AEB: E8 F0 ED
L_7AEE:
    mov    dx,0x30a2                             # 7AEE: BA A2 30
    mov    bx,0x7f09                             # 7AF1: BB 09 7F
    call   FCOMP                                # 7AF4: E8 E1 01
    js     L_7B33                                # 7AF7: 78 3A
    mov    di,0x7b42                             # 7AF9: BF 42 7B
    push   di                                    # 7AFC: 57
    push   WORD PTR ds:FACLO                     # 7AFD: FF 36 A3 04
    push   WORD PTR ds:FACSGN                     # 7B01: FF 36 A5 04
    mov    dx,0xb3d7                             # 7B05: BA D7 B3
    mov    bx,0x815d                             # 7B08: BB 5D 81
    call   L_6773                                # 7B0B: E8 65 EC
    pop    bx                                    # 7B0E: 5B
    pop    dx                                    # 7B0F: 5A
    push   WORD PTR ds:FACLO                     # 7B10: FF 36 A3 04
    push   WORD PTR ds:FACSGN                     # 7B14: FF 36 A5 04
    call   MOVFR                                # 7B18: E8 A3 01
    mov    bx,0x6249                             # 7B1B: BB 49 62
    call   L_7552                                # 7B1E: E8 31 FA
    pop    bx                                    # 7B21: 5B
    pop    dx                                    # 7B22: 5A
    push   WORD PTR ds:FACLO                     # 7B23: FF 36 A3 04
    push   WORD PTR ds:FACSGN                     # 7B27: FF 36 A5 04
    call   MOVFR                                # 7B2B: E8 90 01
    pop    bx                                    # 7B2E: 5B
    pop    dx                                    # 7B2F: 5A
    call   L_68DE                                # 7B30: E8 AB ED
L_7B33:
    mov    bx,0x6252                             # 7B33: BB 52 62
    jmp    L_753F                                # 7B36: E9 06 FA
    .byte 0xBA, 0xDB, 0x0F, 0xBB, 0x49, 0x81, 0xE9, 0x25, 0xEC, 0xBA, 0x92, 0x0A # 7B39
    .byte 0xBB, 0x06, 0x80, 0xE9, 0x28, 0xEC # 7B45
L_7B4B:
    call   OUTDO                                # 7B4B: E8 57 B0
    cmp    al,0xd                                # 7B4E: 3C 0D
    jne    STROUT                                # 7B50: 75 03
    call   L_2C78                                # 7B52: E8 23 B1
STROUT:
    mov    al,BYTE PTR cs:[bx]                   # 7B55: 2E 8A 07
    inc    bx                                    # 7B58: 43
    .byte 0x0A, 0xC0 # 7B59
    jne    L_7B4B                                # 7B5B: 75 EE
    ret                                          # 7B5D: C3
DZERO:
    mov    di,DFACL                              # 7B5E: BF 9F 04
    mov    cx,0x4                                # 7B61: B9 04 00
    mov    ax,0x0                                # 7B64: B8 00 00
    cld                                          # 7B67: FC
    rep stos WORD PTR es:[di],ax                 # 7B68: F3 AB
    ret                                          # 7B6A: C3
ZERO:
    mov    ax,0x0                                # 7B6B: B8 00 00
    mov    ds:FACLO,ax                           # 7B6E: A3 A3 04
    mov    ds:FACSGN,ax                           # 7B71: A3 A5 04
    ret                                          # 7B74: C3
SIGN:
SIGNS:
    call   MATH_TYPECHECK                         # 7B75: E8 78 E7
    jns    SIS05                                # 7B78: 79 0E
    mov    ax,ds:FACLO                            # 7B7A: A1 A3 04
    .byte 0x0B, 0xC0 # 7B7D
    je     SIS10                                # 7B7F: 74 20
    mov    al,0x1                                # 7B81: B0 01
    jns    SIS10                                # 7B83: 79 1C
    neg    al                                    # 7B85: F6 D8
    ret                                          # 7B87: C3
SIS05:
    int    0xd4                                  # 7B88: CD D4
    mov    al,ds:FACEXP                          # 7B8A: A0 A6 04
    .byte 0x0A, 0xC0 # 7B8D
    je     SIS10                                # 7B8F: 74 10
    mov    al,ds:FACSGN                          # 7B91: A0 A5 04
SIGNAL:
    .byte 0x0A, 0xC0 # 7B94
    je     SIGN_NONZERO                                # 7B96: 74 07
    mov    al,0x1                                # 7B98: B0 01
    jns    SIS10                                # 7B9A: 79 05
    neg    al                                    # 7B9C: F6 D8
    ret                                          # 7B9E: C3
SIGN_NONZERO:
    or     al,0x1                                # 7B9F: 0C 01
SIS10:
    ret                                          # 7BA1: C3
GETYP:
    # Historical Microsoft source name: $GETYP.
    mov    al,ds:VALTYP                           # 7BA2: A0 FB 02
    cmp    al,0x8                                # 7BA5: 3C 08
    dec    al                                    # 7BA7: FE C8
    dec    al                                    # 7BA9: FE C8
    dec    al                                    # 7BAB: FE C8
    ret                                          # 7BAD: C3
VADDH:
    call   GETYP                                # 7BAE: E8 F1 FF
    jb     FADDH                                # 7BB1: 72 0C
DADDH:
    push   bx                                    # 7BB3: 53
    mov    bx,OFFSET FLAT:MATH_DHALF                             # 7BB4: BB 6A 61
    call   MOVAC                                # 7BB7: E8 CE 00
    call   L_66AA                                # 7BBA: E8 ED EA
    pop    bx                                    # 7BBD: 5B
    ret                                          # 7BBE: C3
FADDH:
    .byte 0x33, 0xD2 # 7BBF
    mov    bx,0x8000                             # 7BC1: BB 00 80
    call   L_6773                                # 7BC4: E8 AC EB
    ret                                          # 7BC7: C3
DIV10:
    call   GETYP                                # 7BC8: E8 D7 FF
    mov    bx,OFFSET FLAT:MATH_DPM01                             # 7BCB: BB 2A 60
    jb     ML10                                # 7BCE: 72 11
    jmp    ML05                                # 7BD0: EB 08
MUL10:
    call   GETYP                                # 7BD2: E8 CD FF
    mov    bx,OFFSET FLAT:MATH_DP01                             # 7BD5: BB 3A 60
    jb     ML10                                # 7BD8: 72 07
ML05:
    call   MOVAC                                # 7BDA: E8 AB 00
    call   FMULD                                # 7BDD: E8 75 F0
    ret                                          # 7BE0: C3
ML10:
MLSP:
    push   WORD PTR ds:FACSGN                     # 7BE1: FF 36 A5 04
    push   WORD PTR ds:FACLO                     # 7BE5: FF 36 A3 04
    mov    BYTE PTR ds:VALTYP,0x8                 # 7BE9: C6 06 FB 02 08
    call   MOVFC                                # 7BEE: E8 9C 00
    call   CSD                                # 7BF1: E8 70 EF
    pop    dx                                    # 7BF4: 5A
    pop    bx                                    # 7BF5: 5B
    call   FMULS                                # 7BF6: E8 06 F1
    ret                                          # 7BF9: C3
L_7BFA:
    mov    cx,0x4                                # 7BFA: B9 04 00
L_7BFD:
    rcl    WORD PTR [bx],1                       # 7BFD: D1 17
    inc    bx                                    # 7BFF: 43
    inc    bx                                    # 7C00: 43
    loop   L_7BFD                                # 7C01: E2 FA
    ret                                          # 7C03: C3
L_7C04:
    mov    cx,0x4                                # 7C04: B9 04 00
L_7C07:
    rcr    WORD PTR [bx],1                       # 7C07: D1 1F
    dec    bx                                    # 7C09: 4B
    dec    bx                                    # 7C0A: 4B
    loop   L_7C07                                # 7C0B: E2 FA
    ret                                          # 7C0D: C3
L_7C0E:
    .byte 0x80, 0x8F, 0x02, 0x00, 0x20 # 7C0E
    loop   L_7C16                                # 7C13: E2 01
    ret                                          # 7C15: C3
L_7C16:
    mov    bx,0x4b0                              # 7C16: BB B0 04
    cmp    cl,0x8                                # 7C19: 80 F9 08
    jb     L_7C44                                # 7C1C: 72 26
    push   cx                                    # 7C1E: 51
    mov    cx,0x7                                # 7C1F: B9 07 00
    mov    bx,ARGLO-1                              # 7C22: BB AA 04
    mov    ah,BYTE PTR [bx]                      # 7C25: 8A 27
L_7C27:
    .byte 0x8A, 0x87, 0x01, 0x00 # 7C27
    mov    BYTE PTR [bx],al                      # 7C2B: 88 07
    inc    bx                                    # 7C2D: 43
    loop   L_7C27                                # 7C2E: E2 F7
    .byte 0x32, 0xC0 # 7C30
    mov    BYTE PTR [bx],al                      # 7C32: 88 07
    pop    cx                                    # 7C34: 59
    sub    cl,0x8                                # 7C35: 80 E9 08
    and    ah,0x20                               # 7C38: 80 E4 20
    je     L_7C16                                # 7C3B: 74 D9
    or     BYTE PTR ds:ARGLO-1,ah                  # 7C3D: 08 26 AA 04
    .byte 0xE9, 0xD2, 0xFF # 7C41
L_7C44:
    .byte 0x0A, 0xC9 # 7C44
    je     L_7C57                                # 7C46: 74 0F
    push   cx                                    # 7C48: 51
    clc                                          # 7C49: F8
    call   L_7C04                                # 7C4A: E8 B7 FF
    pop    cx                                    # 7C4D: 59
    .byte 0xF6, 0x87, 0x02, 0x00, 0x10 # 7C4E
    jne    L_7C0E                                # 7C53: 75 B9
    loop   L_7C16                                # 7C55: E2 BF
L_7C57:
    ret                                          # 7C57: C3
XCGAF:
    mov    si,DFACL                              # 7C58: BE 9F 04
    mov    di,ARGLO                              # 7C5B: BF AB 04
    cld                                          # 7C5E: FC
    mov    cx,0x4                                # 7C5F: B9 04 00
XCG10:
    mov    ax,WORD PTR [di]                      # 7C62: 8B 05
    movs   WORD PTR es:[di],WORD PTR ds:[si]     # 7C64: A5
    .byte 0x89, 0x84, 0xFE, 0xFF # 7C65
    loop   XCG10                                # 7C69: E2 F7
    ret                                          # 7C6B: C3
MOVBS:
    mov    di,DBUFF+4                              # 7C6C: BF 7C 04
    mov    cx,0x2                                # 7C6F: B9 02 00
    jmp    MBF10                                # 7C72: EB 06
MOVBF:
    mov    di,DBUFF                              # 7C74: BF 78 04
MBF05:
    mov    cx,0x4                                # 7C77: B9 04 00
MBF10:
    cld                                          # 7C7A: FC
MBF20:
    mov    ax,WORD PTR cs:[bx]                   # 7C7B: 2E 8B 07
    stos   WORD PTR es:[di],ax                   # 7C7E: AB
    inc    bx                                    # 7C7F: 43
    inc    bx                                    # 7C80: 43
    loop   MBF20                                # 7C81: E2 F8
    .byte 0x8B, 0xDF # 7C83
    dec    bx                                    # 7C85: 4B
    dec    bx                                    # 7C86: 4B
    ret                                          # 7C87: C3
MOVAC:
    mov    di,ARGLO                              # 7C88: BF AB 04
    jmp    MBF05                                # 7C8B: EB EA
MOVFC:
    mov    di,DFACL                              # 7C8D: BF 9F 04
    jmp    MBF05                                # 7C90: EB E5
MOVAM:
    .byte 0xBF, 0xAB, 0x04, 0xB9, 0x04, 0x00 # 7C92
MOVEM:
    xchg   si,bx                                 # 7C98: 87 DE
    cld                                          # 7C9A: FC
    rep movs WORD PTR es:[di],WORD PTR ds:[si]   # 7C9B: F3 A5
    xchg   si,bx                                 # 7C9D: 87 DE
    ret                                          # 7C9F: C3
MOVAF:
    push   cx                                    # 7CA0: 51
    push   bx                                    # 7CA1: 53
    push   di                                    # 7CA2: 57
    mov    bx,DFACL                              # 7CA3: BB 9F 04
    mov    di,ARGLO                              # 7CA6: BF AB 04
MAF05:
    mov    cx,0x4                                # 7CA9: B9 04 00
    call   MOVEM                                # 7CAC: E8 E9 FF
    pop    di                                    # 7CAF: 5F
    pop    bx                                    # 7CB0: 5B
    pop    cx                                    # 7CB1: 59
    ret                                          # 7CB2: C3
MOVFA:
    push   cx                                    # 7CB3: 51
    push   bx                                    # 7CB4: 53
    push   di                                    # 7CB5: 57
    mov    bx,ARGLO                              # 7CB6: BB AB 04
    mov    di,DFACL                              # 7CB9: BF 9F 04
    jmp    MAF05                                # 7CBC: EB EB
MOVFR:
    mov    WORD PTR ds:FACLO,dx                  # 7CBE: 89 16 A3 04
    mov    WORD PTR ds:FACSGN,bx                  # 7CC2: 89 1E A5 04
    ret                                          # 7CC6: C3
MOVRF:
    mov    dx,WORD PTR ds:FACLO                  # 7CC7: 8B 16 A3 04
    mov    bx,WORD PTR ds:FACSGN                  # 7CCB: 8B 1E A5 04
    ret                                          # 7CCF: C3
VCOMP:
    call   GETYP                                # 7CD0: E8 CF FE
    jb     COMPM                                # 7CD3: 72 3F
    jmp    DCMPM                                # 7CD5: E9 89 00
FCOMP:
    # Single-precision FAC vs BX:DX comparison.
    call   L_6AB2                                # 7CD8: E8 D7 ED
    push   bx                                    # 7CDB: 53
    push   di                                    # 7CDC: 57
    .byte 0x8A, 0xC3 # 7CDD
    xor    al,BYTE PTR ds:FACSGN                  # 7CDF: 32 06 A5 04
    js     CPM05                                # 7CE3: 78 3C
    .byte 0x0A, 0xDB # 7CE5
    js     UFC10                                # 7CE7: 78 10
    mov    ax,ds:FACSGN                           # 7CE9: A1 A5 04
    .byte 0x2B, 0xC3 # 7CEC
    jb     CPM10                                # 7CEE: 72 3F
    jne    CPM06                                # 7CF0: 75 37
    mov    ax,ds:FACLO                           # 7CF2: A1 A3 04
    .byte 0x2B, 0xC2 # 7CF5
    jmp    TSTFLG                                # 7CF7: EB 10
UFC10:
    .byte 0x8B, 0xC3 # 7CF9
    sub    ax,WORD PTR ds:FACSGN                  # 7CFB: 2B 06 A5 04
    jb     CPM10                                # 7CFF: 72 2E
    jne    CPM06                                # 7D01: 75 26
    .byte 0x8B, 0xC2 # 7D03
    sub    ax,WORD PTR ds:FACLO                  # 7D05: 2B 06 A3 04
TSTFLG:
    jb     CPM10                                # 7D09: 72 24
    jne    CPM06                                # 7D0B: 75 1C
    .byte 0x32, 0xC0 # 7D0D
    jmp    CPM80                                # 7D0F: EB 4A
    .byte 0xC0, 0xEB, 0x47 # 7D11
COMPM:
    call   L_6ABA                                # 7D14: E8 A3 ED
    nop                                          # 7D17: 90
    nop                                          # 7D18: 90
    mov    ax,WORD PTR [bx]                      # 7D19: 8B 07
    xor    al,BYTE PTR ds:FACSGN                  # 7D1B: 32 06 A5 04
    jns    CPM20                                # 7D1F: 79 13
CPM05:
    mov    ah,BYTE PTR ds:FACSGN                  # 7D21: 8A 26 A5 04
    .byte 0x0A, 0xE4 # 7D25
    js     CPM10                                # 7D27: 78 06
CPM06:
    mov    al,0x1                                # 7D29: B0 01
    .byte 0x0A, 0xC0 # 7D2B
    jmp    CPM80                                # 7D2D: EB 2C
CPM10:
    mov    al,0xff                               # 7D2F: B0 FF
    stc                                          # 7D31: F9
    jmp    CPM80                                # 7D32: EB 27
CPM20:
    push   cx                                    # 7D34: 51
    mov    cx,0x2                                # 7D35: B9 02 00
CPM22:
    xchg   si,bx                                 # 7D38: 87 DE
    mov    al,ds:FACSGN                           # 7D3A: A0 A5 04
    .byte 0x0A, 0xC0 # 7D3D
    jns    CPM25                                # 7D3F: 79 02
    xchg   di,si                                 # 7D41: 87 F7
CPM25:
    std                                          # 7D43: FD
CPM30:
    cmps   WORD PTR ds:[si],WORD PTR es:[di]     # 7D44: A7
    jne    CPM50                                # 7D45: 75 06
    loop   CPM30                                # 7D47: E2 FB
    mov    al,0x0                                # 7D49: B0 00
    jmp    CPM70                                # 7D4B: EB 0D
CPM50:
    jae    CPM60                                # 7D4D: 73 06
    mov    al,0x1                                # 7D4F: B0 01
    .byte 0x0A, 0xC0 # 7D51
    jmp    CPM70                                # 7D53: EB 05
CPM60:
    mov    al,0xff                               # 7D55: B0 FF
    .byte 0x0A, 0xC0 # 7D57
    stc                                          # 7D59: F9
CPM70:
    pop    cx                                    # 7D5A: 59
CPM80:
    pop    di                                    # 7D5B: 5F
    pop    bx                                    # 7D5C: 5B
    ret                                          # 7D5D: C3
DCMPA:
    .byte 0xBB, 0xB1, 0x04 # 7D5E
DCMPM:
    call   L_6ABA                                # 7D61: E8 56 ED
    nop                                          # 7D64: 90
    nop                                          # 7D65: 90
    mov    al,BYTE PTR [di]                      # 7D66: 8A 05
    xor    al,BYTE PTR [bx]                      # 7D68: 32 07
    jns    DC10                                # 7D6A: 79 02
    jmp    CPM05                                # 7D6C: EB B3
DC10:
    push   cx                                    # 7D6E: 51
    mov    cx,0x4                                # 7D6F: B9 04 00
    jmp    CPM22                                # 7D72: EB C4
CONI2:
    mov    bx,OFFSET FLAT:MATH_S32KM                             # 7D74: BB FF 61
    call   MOVBS                                # 7D77: E8 F2 FE
    call   COMPM                                # 7D7A: E8 97 FF
    jne    CON10                                # 7D7D: 75 0B
    mov    BYTE PTR ds:VALTYP,0x2                 # 7D7F: C6 06 FB 02 02
    mov    WORD PTR ds:FACLO,0x8000              # 7D84: C7 06 A3 04 00 80
CON10:
    ret                                          # 7D8A: C3
L_7D8B:
    .byte 0x2E, 0x2B, 0x96, 0x00, 0x00, 0x2E, 0x1A, 0x9E, 0x02, 0x00 # 7D8B
    ret                                          # 7D95: C3
ABSFN:
VABS:
    call   GETYP                                # 7D96: E8 09 FE
    js     L_7DA3                                # 7D99: 78 08
    mov    al,ds:FACSGN                           # 7D9B: A0 A5 04
    .byte 0x0A, 0xC0 # 7D9E
    js     NEG                                # 7DA0: 78 0E
    ret                                          # 7DA2: C3
L_7DA3:
    mov    ax,ds:FACLO                           # 7DA3: A1 A3 04
    .byte 0x0B, 0xC0 # 7DA6
    js     VN15                                # 7DA8: 78 11
    ret                                          # 7DAA: C3
VNEG:
    call   GETYP                                # 7DAB: E8 F4 FD
    js     INEG                                # 7DAE: 78 08
NEG:
    int    0xd2                                  # 7DB0: CD D2
    xor    BYTE PTR ds:FACSGN,0x80                # 7DB2: 80 36 A5 04 80
    ret                                          # 7DB7: C3
INEG:
    mov    ax,ds:FACLO                           # 7DB8: A1 A3 04
VN15:
    cmp    ax,0x8000                             # 7DBB: 3D 00 80
    jne    VN20                                # 7DBE: 75 0A
    int    0xd3                                  # 7DC0: CD D3
    push   bx                                    # 7DC2: 53
    call   CSI                                # 7DC3: E8 DB ED
    pop    bx                                    # 7DC6: 5B
    .byte 0xE9, 0xE6, 0xFF # 7DC7
VN20:
    neg    WORD PTR ds:FACLO                     # 7DCA: F7 1E A3 04
    ret                                          # 7DCE: C3
SETDB:
    mov    bx,DBUFF+1                              # 7DCF: BB 79 04
    call   VMVMF                                # 7DD2: E8 33 00
    mov    di,DFACL-8                              # 7DD5: BF 97 04
    mov    cx,0x8                                # 7DD8: B9 08 00
    mov    ax,0x0                                # 7DDB: B8 00 00
    cld                                          # 7DDE: FC
    rep stos WORD PTR es:[di],ax                 # 7DDF: F3 AB
    mov    ds:DBUFF,al                           # 7DE1: A2 78 04
    mov    ds:ARGLO-1,al                           # 7DE4: A2 AA 04
    ret                                          # 7DE7: C3
    .byte 0xE8, 0xB7, 0xFD, 0x72, 0x03, 0xE9, 0xA2, 0xFE, 0x8B, 0x17, 0x8B, 0x9F # 7DE8
    .byte 0x02, 0x00, 0xC3 # 7DF4
VMOVM:
    mov    cx,0x4                                # 7DF7: B9 04 00
    call   GETYP                                # 7DFA: E8 A5 FD
    jb     VMM10                                # 7DFD: 72 03
    jmp    MOVEM                                # 7DFF: E9 96 FE
VMM10:
    mov    cx,0x2                                # 7E02: B9 02 00
    jmp    MOVEM                                # 7E05: E9 90 FE
VMVMF:
    mov    cx,0x4                                # 7E08: B9 04 00
    xchg   bx,di                                 # 7E0B: 87 FB
    mov    bx,DFACL                              # 7E0D: BB 9F 04
    call   GETYP                                # 7E10: E8 8F FD
    jb     VMVM1                                # 7E13: 72 03
    jmp    MOVEM                                # 7E15: E9 80 FE
VMVM1:
    xchg   di,bx                                 # 7E18: 87 DF
MOVMF:
    mov    cx,0x2                                # 7E1A: B9 02 00
    mov    di,0x4a3                              # 7E1D: BF A3 04
    xchg   bx,di                                 # 7E20: 87 FB
    jmp    MOVEM                                # 7E22: E9 73 FE
VMVFM:
    mov    cx,0x4                                # 7E25: B9 04 00
    mov    di,DFACL                              # 7E28: BF 9F 04
    call   GETYP                                # 7E2B: E8 74 FD
    jb     MOVFM                                # 7E2E: 72 03
    jmp    MOVEM                                # 7E30: E9 65 FE
MOVFM:
    mov    cx,0x2                                # 7E33: B9 02 00
    mov    di,0x4a3                              # 7E36: BF A3 04
    jmp    MOVEM                                # 7E39: E9 5C FE
VCMPM:
    call   GETYP                                # 7E3C: E8 63 FD
    jb     VCMP10                                # 7E3F: 72 03
    jmp    DCMPM                                # 7E41: E9 1D FF
VCMP10:
    jmp    COMPM                                # 7E44: E9 CD FE
VPSHF:
    call   GETYP                                # 7E47: E8 58 FD
    mov    cx,0x4                                # 7E4A: B9 04 00
    jae    VPS10                                # 7E4D: 73 03
PUSHF:
    mov    cx,0x2                                # 7E4F: B9 02 00
VPS10:
    pop    bp                                    # 7E52: 5D
    mov    di,FACM1                              # 7E53: BF A5 04
L_7E56:
    push   WORD PTR [di]                         # 7E56: FF 35
    dec    di                                    # 7E58: 4F
    dec    di                                    # 7E59: 4F
    loop   L_7E56                                # 7E5A: E2 FA
    push   bp                                    # 7E5C: 55
    ret                                          # 7E5D: C3
POPA:
    .byte 0xBF, 0xAB, 0x04, 0xB9, 0x04, 0x00, 0xEB, 0x11 # 7E5E
VPOPF:
    call   GETYP                                # 7E66: E8 39 FD
    mov    di,DFACL                              # 7E69: BF 9F 04
    mov    cx,0x4                                # 7E6C: B9 04 00
    jae    VPO17                                # 7E6F: 73 06
    mov    di,0x4a3                              # 7E71: BF A3 04
    mov    cx,0x2                                # 7E74: B9 02 00
VPO17:
    pop    ax                                    # 7E77: 58
VPO20:
    pop    WORD PTR [di]                         # 7E78: 8F 05
    inc    di                                    # 7E7A: 47
    inc    di                                    # 7E7B: 47
    loop   VPO20                                # 7E7C: E2 FA
    push   ax                                    # 7E7E: 50
    ret                                          # 7E7F: C3
VINT:
    call   GETYP                                # 7E80: E8 1F FD
    jns    L_7E86                                # 7E83: 79 01
    ret                                          # 7E85: C3
L_7E86:
    int    0xd5                                  # 7E86: CD D5
    jb     L_7E8D                                # 7E88: 72 03
    jmp    L_7241                                # 7E8A: E9 B4 F3
L_7E8D:
    jmp    L_72AB                                # 7E8D: E9 1B F4
    .byte 0x00, 0x00 # 7E90
COLD_START:
    cli                                          # 7E92: FA
    mov    dx,0x60                               # 7E93: BA 60 00
    mov    ds,dx                                 # 7E96: 8E DA
    mov    es,dx                                 # 7E98: 8E C2
    mov    ss,dx                                 # 7E9A: 8E D2
    .byte 0x32, 0xC0 # 7E9C
    mov    ds:PROFLG,al                           # 7E9E: A2 64 04
    mov    ch,0x91                               # 7EA1: B5 91
    mov    bx,0x0                                # 7EA3: BB 00 00
    mov    dx,0x69a                              # 7EA6: BA 9A 06
L_7EA9:
    .byte 0x8B, 0xF2 # 7EA9
    lods   al,BYTE PTR cs:[si]                   # 7EAB: 2E AC
    mov    BYTE PTR [bx],al                      # 7EAD: 88 07
    inc    bx                                    # 7EAF: 43
    inc    dx                                    # 7EB0: 42
    dec    ch                                    # 7EB1: FE CD
    jne    L_7EA9                                # 7EB3: 75 F4
    mov    sp,0x70e                              # 7EB5: BC 0E 07
    int    0x12                                  # 7EB8: CD 12
    cli                                          # 7EBA: FA
    mov    bx,0x40                               # 7EBB: BB 40 00
    mul    bx                                    # 7EBE: F7 E3
    mov    bx,ds                                 # 7EC0: 8C DB
    .byte 0x2B, 0xC3 # 7EC2
    mov    bx,0x0                                # 7EC4: BB 00 00
    test   ah,0xf0                               # 7EC7: F6 C4 F0
    jne    L_7ED2                                # 7ECA: 75 06
    mov    cl,0x4                                # 7ECC: B1 04
    shl    ax,cl                                 # 7ECE: D3 E0
    .byte 0x8B, 0xD8 # 7ED0
L_7ED2:
    dec    bx                                    # 7ED2: 4B
    mov    WORD PTR ds:TOPMEM,bx                   # 7ED3: 89 1E 2C 00
    .byte 0x8B, 0xE3 # 7ED7
    jmp    L_4BFE                                # 7ED9: E9 22 CD
L_7EDC:
    mov    al,0x2c                               # 7EDC: B0 2C
    mov    ds:BUFMIN,al                          # 7EDE: A2 F6 01 -- sentinel comma before BUF
    mov    bx,0xb7                               # 7EE1: BB B7 00
    mov    BYTE PTR [bx],0x3a                    # 7EE4: C6 07 3A
    .byte 0x32, 0xC0 # 7EE7
    mov    ds:TTYPOS,al                           # 7EE9: A2 F9 02
    mov    ds:DSEGZ,al                             # 7EEC: A2 06 00
    mov    ds:CHNFLG,al                           # 7EEF: A2 6B 04
    mov    ds:MRGFLG,al                           # 7EF2: A2 65 04
    mov    ds:ERRFLG,al                            # 7EF5: A2 28 00
    mov    bx,TEMPST                              # 7EF8: BB 0E 03
    mov    WORD PTR ds:TEMPPT,bx                  # 7EFB: 89 1E 0C 03
    mov    bx,0x37a                              # 7EFF: BB 7A 03
    mov    WORD PTR ds:PRMPRV,bx                  # 7F02: 89 1E E2 03
    mov    bx,WORD PTR ds:TOPMEM                   # 7F06: 8B 1E 2C 00
    dec    bx                                    # 7F0A: 4B
    mov    WORD PTR ds:MEMSIZ,bx                  # 7F0B: 89 1E 0A 03
    dec    bx                                    # 7F0F: 4B
    push   bx                                    # 7F10: 53
    mov    bx,0x70e                              # 7F11: BB 0E 07
    mov    al,0x4                                # 7F14: B0 04
    mov    ds:MAX_FILE_NUMBER,al                           # 7F16: A2 DF 04
    push   bx                                    # 7F19: 53
    mov    WORD PTR ds:FILE_PTR_TABLE,bx                  # 7F1A: 89 1E E0 04
    mov    al,ds:MAX_FILE_NUMBER                           # 7F1E: A0 DF 04
    inc    al                                    # 7F21: FE C0
    .byte 0x02, 0xC0, 0x8A, 0xD0 # 7F23
    mov    dh,0x0                                # 7F27: B6 00
    .byte 0x03, 0xDA # 7F29
    pop    dx                                    # 7F2B: 5A
    xchg   dx,bx                                 # 7F2C: 87 DA
    mov    bx,WORD PTR ds:FILE_PTR_TABLE                  # 7F2E: 8B 1E E0 04
    mov    BYTE PTR [bx],dl                      # 7F32: 88 17
    inc    bx                                    # 7F34: 43
    mov    BYTE PTR [bx],dh                      # 7F35: 88 37
    inc    bx                                    # 7F37: 43
    mov    al,ds:MAX_FILE_NUMBER                           # 7F38: A0 DF 04
    mov    cx,0x34                               # 7F3B: B9 34 00
    .byte 0x0A, 0xC0 # 7F3E
    je     L_7F50                                # 7F40: 74 0E
L_7F42:
    xchg   dx,bx                                 # 7F42: 87 DA
    .byte 0x03, 0xD9 # 7F44
    xchg   dx,bx                                 # 7F46: 87 DA
    mov    WORD PTR [bx],dx                      # 7F48: 89 17
    inc    bx                                    # 7F4A: 43
    inc    bx                                    # 7F4B: 43
    dec    al                                    # 7F4C: FE C8
    jne    L_7F42                                # 7F4E: 75 F2
L_7F50:
    xchg   dx,bx                                 # 7F50: 87 DA
    .byte 0x03, 0xD9 # 7F52
    inc    bx                                    # 7F54: 43
    push   bx                                    # 7F55: 53
    dec    al                                    # 7F56: FE C8
    mov    ds:NLONLY,al                           # 7F58: A2 36 05
    mov    bx,WORD PTR ds:FILE_PTR_TABLE                  # 7F5B: 8B 1E E0 04
    mov    dx,WORD PTR [bx]                      # 7F5F: 8B 17
    mov    bx,0x33                               # 7F61: BB 33 00
    .byte 0x03, 0xDA # 7F64
    mov    WORD PTR ds:FILE0_BLOCK_END,bx                  # 7F66: 89 1E E4 04
    pop    bx                                    # 7F6A: 5B
    inc    bx                                    # 7F6B: 43
    mov    WORD PTR ds:TXTTAB,bx                   # 7F6C: 89 1E 30 00
    mov    WORD PTR ds:SAVSTK,bx                  # 7F70: 89 1E 45 03
    pop    dx                                    # 7F74: 5A
    .byte 0x8A, 0xC2 # 7F75
    and    al,0xfe                               # 7F77: 24 FE
    .byte 0x8A, 0xD0, 0x8A, 0xC2, 0x2A, 0xC3, 0x8A, 0xD8, 0x8A, 0xC6, 0x1A, 0xC7 # 7F79
    .byte 0x8A, 0xF8 # 7F85
    jae    L_7F8C                                # 7F87: 73 03
    jmp    L_2CF4                                # 7F89: E9 68 AD
L_7F8C:
    mov    cl,0x3                                # 7F8C: B1 03
    shr    bx,cl                                 # 7F8E: D3 EB
    .byte 0x8A, 0xC7 # 7F90
    cmp    al,0x2                                # 7F92: 3C 02
    jb     L_7F99                                # 7F94: 72 03
    mov    bx,0x200                              # 7F96: BB 00 02
L_7F99:
    .byte 0x8A, 0xC2, 0x2A, 0xC3, 0x8A, 0xD8, 0x8A, 0xC6, 0x1A, 0xC7, 0x8A, 0xF8 # 7F99
    jae    L_7FAA                                # 7FA5: 73 03
    jmp    L_2CF4                                # 7FA7: E9 4A AD
L_7FAA:
    mov    WORD PTR ds:MEMSIZ,bx                  # 7FAA: 89 1E 0A 03
    xchg   dx,bx                                 # 7FAE: 87 DA
    mov    WORD PTR ds:TOPMEM,bx                   # 7FB0: 89 1E 2C 00
    mov    WORD PTR ds:FRETOP,bx                  # 7FB4: 89 1E 2F 03
    .byte 0x8B, 0xE3 # 7FB8
    mov    WORD PTR ds:SAVSTK,bx                  # 7FBA: 89 1E 45 03
    mov    bx,WORD PTR ds:TXTTAB                   # 7FBE: 8B 1E 30 00
    xchg   dx,bx                                 # 7FC2: 87 DA
    call   L_2D04                                # 7FC4: E8 3D AD
    .byte 0x2B, 0xDA # 7FC7
    dec    bx                                    # 7FC9: 4B
    dec    bx                                    # 7FCA: 4B
    push   bx                                    # 7FCB: 53
    pop    bx                                    # 7FCC: 5B
    call   LINPRT                                # 7FCD: E8 80 E5
    mov    bx,0x7fdc                             # 7FD0: BB DC 7F
    call   STROUT                                # 7FD3: E8 7F FB
    call   CRDO                                # 7FD6: E8 98 AC
    jmp    L_436B                                # 7FD9: E9 8F C3
BYTES_FREE_TEXT:
    .asciz " Bytes free"
OEM_ROM_CHECKSUM_BYTE_BLOCK3:
    .byte 0x14                                  # 7FE8: OEM 8 KiB ROM checksum byte (bank sum = 00h)
L_7FE9:
    call   L_7091                                # 7FE9: E8 A5 F0
    .byte 0x33, 0xC9 # 7FEC
    push   dx                                    # 7FEE: 52
    push   WORD PTR ds:FMTCX                     # 7FEF: FF 36 81 04
    jmp    L_765E                                # 7FF3: E9 68 F6
    .byte 0xFD, 0xFF, 0x03, 0xBF, 0xC9, 0x1B, 0x0E, 0xB6, 0x00, 0x00 # 7FF6
