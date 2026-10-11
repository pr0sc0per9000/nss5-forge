# bcc spill-tie patch

`spill_tie.patch` changes one comparison in the register allocator of BlitzMax's `bcc`
(`_src/codegen/cgallocregs.cpp`, `spill()`), and `scripts/setup.py` applies it to
`tools/blitzmax-legacy-src` and rebuilds `bin/bcc.exe` once.

Three FontMachine bodies, `TPrivateBitmapFont.DrawShadowText`, `DrawBorderText` and
`DrawFaceText`, put three values on an exact tie for which to spill first. The original
compiler broke those ties differently from this one, because x87 rounding inside bcc itself
decides them ([spill-tie-x87-precision.md](/docs/reference/spill-tie-x87-precision.md)).
No single rounding rule reproduces all nine stack slots, so the patch gives each of the three
functions its own rule. Every other function compiles exactly as before: the default branch
is the shipped comparison written out.

`WALLOC_TIE_MAP` overrides the built-in map, `WALLOC_TIE_TRACE=1` prints every candidate
and pick. Both are for research only.
