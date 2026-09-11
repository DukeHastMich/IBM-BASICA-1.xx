# Provenance and Evidence Rules

The recovered ROM is the primary executable oracle. Semantic names and comments are promoted only when supported by one or more of:

- direct behavior visible in IBM Cassette BASIC C1.10;
- nearby C1.00/C1.20 differential evidence;
- contemporary IBM PC BIOS behavior and BIOS Data Area definitions;
- surviving Microsoft BASIC-family source code with demonstrable control-flow/data-layout correspondence;
- external historical documentation where the relationship is specific enough to verify.

Later Microsoft GW-BASIC source is treated as **lineage evidence**, not automatic proof that C1.10 used the same identifier or source organization.

Important external witnesses used during recovery include:

- IBM PC BIOS source, especially the 5150 v3 / 10-27-1982 generation;
- Microsoft GW-BASIC surviving 1982/83 source family;
- reverse-engineered OEM.ASM associated with the released GW-BASIC source;
- IBM Cassette BASIC C1.00/C1.20 ROMs and differential comparison;
- IBM/Microsoft period assembler material used to study likely historical encoding and syntax.

Semantic names that are not historical proofs are explicitly described as semantic recovery names in source comments.
