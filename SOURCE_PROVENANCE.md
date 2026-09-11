# Source Provenance / Witnesses

## Golden ROMs

C1.10:
- file: basic110(1).rom
- MD5 eb28f0e8d3f641f2b58a3677b3b998cc
- SHA256 3033d1a54c99d7e2aa1fc7c8c2e51a56ae1b61bf4e70e8aa580f43c43e37a63e

C1.20:
- file: ibm-basic-1.20.rom
- MD5 14d67552a24cbdc04dada9d8312143ea
- SHA256 01125823844d9877564d3365fbe212effaa3204004832293335c222672798f02

## Public source witnesses used during archaeology

IBM PC BIOS source reconstruction:
- https://github.com/gawlas/IBM-PC-BIOS
- preferred C1.10-generation witness: `IBM PC/PCBIOSV3.ASM`
- important labels: `CRT_MODE`, `CRT_MODE_SET`, video mode table `M7`, cassette BIOS implementation, POST/INT18 handoff.

Microsoft GW-BASIC surviving source:
- https://github.com/microsoft/GW-BASIC
- important modules used: GWDATA.ASM, GWMAIN.ASM, GENGRP.ASM, GIO86.ASM, GIOCAS.ASM, SCNDRV.ASM, SCNEDT.ASM, GWSTS.ASM, BIPRTU.ASM, BIPTRG.ASM, BISTRS.ASM, NEXT86.ASM, MATH1.ASM, MATH2.ASM, GWRAM.ASM, IBMRES.ASM.
- lineage evidence only; this is later than ROM C1.10.

Reverse-engineered later Microsoft BASIC OEM module:
- https://github.com/jeffpar/basicdos
- path: software/pcx86/bdsrc/msb/OEM.ASM
- useful descendant behavior: later SCALXY uses an explicit stored 320/640 graphics width rather than the old compact `TEST` selector.

PCjs C1.00 reference:
- https://github.com/jeffpar/pcjs
- path: machines/pcx86/ibm/5150/rom/basic/BASIC100.json5
- useful for pre-C1.10 differential checks, including the cassette/file code around the old 005F state.

## Local historical assembler archaeology

Included archives contain IBM Macro Assembler 1.00, its manual, Microsoft Macro Assembler 1.00, later MASM 1.27 beta, and Intel ASM86 3.1. Do not claim historical assembly success from static inspection alone.
