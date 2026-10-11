# src/recovered_thirdparty - bodies that belong to a THIRD-PARTY MODULE

None of this is the game's own code. These are three BlitzMax community modules NSS5 links
that our BlitzMax install does not ship. Their `code`-section extents are measured and
listed in the table below.

| dir | module | code extent | fns | bytes |
|---|---|---|---|---|
| `zipengine/` | **ZipEngine** (Irrlicht-derived zip reader + minizip writer) | 0x0058DBF3 - 0x0058FEE0 | 77 | 8,966 |
| `fontmachine/` | **Font Machine 1.5.1** (`.fmf` bitmap-font renderer) | 0x0058FF89 - 0x0059356A | 102 | 13,887 |
| `volumes/` | **BaH.Volumes 1.06** (MIT, see `volumes/LICENSE`) | 0x00597F30 - 0x00598AEA | 35 | 3,003 |

## Why they are not in `src/recovered/`

`src/recovered/` feeds `assemble.py`, which builds the **game's main module**.
The main module declares exactly 135 Types in a recorded order, and the module body's
Type-registration sequence - and therefore the class tables in `data` - follows from it.
A Type declared by a module the game *imports* must not be declared again in the main file.
These Types are third-party module Types, so their bodies live here, keyed by module.

## Rules

1. A file lands here only if `harness.try_method` returned **MATCH** under
   `NSS5_NO_LEARN=1`. The header states the byte count and it must be correct.
2. One file per member, `<Type>.<Member>.bmx`, same header/wrapper convention as
   `src/recovered/` (so `scripts/reverify.py:body_of` reads it unchanged).
3. `MANIFEST.tsv` is generated: every function in the two code blocks, with its Type,
   member, size and verification status. `status=MISPLACED` marks a verified body that is
   still sitting in `src/recovered/` and needs migrating (28 of them at time of writing).
4. The `z_*` Types inside the fontmachine block (`z_blide_bg…`, GUIDs e3390d53 and 84d6b1ac)
   are BLIde-generated classes that FontMachine's own inits register. The game's own set is
   GUID 1a09b2da at 0x004BBF31. Until they have bodies they are listed in
   `src/unrecovered/fontmachine.bmx`.
5. `<mod>/unit/<stem>.bmx` is one of the module's compile units: its Imports, its Types in
   declaration order and its top-level statements. `assemble.py` emits it as
   `src/assembled/<stem>.bmx`, and `python scripts/compare_module_body.py --unit
   src/assembled/<stem>.bmx --va <init VA> --in-build` checks the init the build compiled. Its VA line is
   that init's.
