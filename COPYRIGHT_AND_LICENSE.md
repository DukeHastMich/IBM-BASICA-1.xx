# Copyright and License Status

This repository is an independent historical reconstruction and annotation of
IBM/Microsoft Cassette BASIC C1.10.

## Project-authored material

Original material created for this recovery project is available under the MIT
License in `LICENSE-MIT`, except where a file or section states otherwise. This
covers the project's build and verification scripts, original recovery
methodology and documentation, analysis, annotations, and project-created data
to the extent those materials are copyrightable and do not reproduce
third-party content.

Copyright (c) 2026 Eric Cromwell and contributors.

## Historical program content

The historical IBM/Microsoft program content reconstructed by this project is
not relicensed by the recovery project. The project does not grant rights it
does not own.

`src/basic110_C1.10_recovered_phase16_exact.asm` is therefore excluded from the
MIT grant as a complete work. It reconstructs the instruction stream, data,
tables, strings, constants, and layout of historical IBM/Microsoft software.
Project-authored comments, semantic labels, and annotations within that file
are MIT-licensed only to the extent they are separately copyrightable and
separable from the historical program content.

The same exclusion applies to any byte-exact ROM image built from the recovered
source. Producing a ROM image from the source does not convert the historical
program content into MIT-licensed material.

## ROM distribution

Reference ROM images are not tracked in the Git repository. The repository's
`.gitignore` excludes generated `.rom` and `.bin` files. The verification tool
accepts a user-supplied reference ROM without adding that ROM to the project.

## Trademarks and attribution

IBM, Microsoft, and product names associated with the historical software are
used for identification and historical documentation. This repository does not
claim ownership of third-party trademarks.

See `LICENSE` for the repository's license map and `LICENSE-MIT` for the MIT
terms that apply to project-authored material.
