# Recovery Method

The central rule is simple:

> No semantic cleanup is accepted on the exact branch unless the rebuilt ROM still compares byte-for-byte with the reference image.

The working source uses GNU GAS Intel syntax with `.code16` because it provides a repeatable modern executable oracle. Some instructions/data remain emitted with `.byte` when:

- the historical assembler encoding differs from GNU GAS's canonical encoding;
- bytes participate in overlapping instruction/data entry points;
- a region has not yet been classified with enough confidence.

A typical recovery step is:

1. identify one raw address, raw byte region, or anonymous routine;
2. prove its behavior from control flow and data usage;
3. compare against nearby IBM/Microsoft source lineage when useful;
4. promote the semantic representation conservatively;
5. assemble/link/objcopy;
6. byte-compare and hash the result;
7. reject the change if any byte differs unexpectedly.

Historical naming and binary exactness are deliberately separated. A useful semantic name is preferred over leaving an unexplained magic number when behavior is known, while comments make clear when the original identifier is not known.
