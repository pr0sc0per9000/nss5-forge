' Fn_0058DACC -- the ZIPENGINE MODULE'S INITIALISER
' VA 0x0058DACC   295 bytes
'
' STATUS: BLOCKED, NOT A NEAR MISS. There is no candidate body below and there cannot be
' one: this function is EMITTED BY bcc, not written by anyone. It is not reachable by
' harness.try_function (which compiles a user `Function` into a probe) or by
' harness.try_method (no Type, no reflection record), so the oracle has nothing to say
' about it and no marker will ever be earned here. Filed in recovered_unverified/ for the
' same reason as ModuleBody_RealProgram.bmx: it is module-level material the per-function
' oracle structurally cannot reach, and the alternative is leaving the reading outside the
' tree. Do NOT move it to src/recovered*/.
'
' WHAT IT ACTUALLY IS -- and it is not game code
' ==============================================
' The lane brief called this "the LAST module-level Function of the game's own module".
' It is not. It is the module initialiser of the third-party ZIPENGINE module, i.e. the
' `___bb_<mod>_<mod>` function bcc generates for every BlitzMax module. Four independent
' pieces of evidence, none of them a guess:
'
'  1. SHAPE. It opens with the module-init idempotence guard --
'        cmp dword [0x00C94808], 0 / je init / mov eax,0 / mov esp,ebp / pop ebp / ret
'        init: mov dword [0x00C94808], 1
'     -- the same shape as every other init in the image (0x005B929C blitz, 0x0059C78C
'     retro, ...). Note the EARLY return is emitted inline with no `jmp`, while the final
'     one at 0x0058DBE8 is `mov eax,0 / jmp +0`: two different return emissions in one
'     body, which is the generated template, not user source.
'  2. ITS CALLER. `extracted/call_sites.tsv` gives it exactly one caller, at 0x004BA1DF
'     inside the game's own module body (0x004BA034) -- body offset 427, inside the
'     +362..+432 module-initialiser chain that docs/archive/specs/22-module-body.md
'     already identified as the main module's 15 direct Imports. It is one of those 15.
'  3. WHAT IT REGISTERS. Thirteen `push <classtable>; call 0x004A8F90`
'     (_bbObjectRegisterType, per extracted/runtime_helpers.tsv), and per
'     extracted/class_tables.tsv every one of the thirteen is a ZipEngine Type:
'       0x00C94988 ZipFile          0x00C94B28 ZipWriter      0x00C94C5C ZipReader
'       0x00C94D44 ZipRamStream     0x00C94FB4 TZipFileList   0x00C95108 tm
'       0x00C951CC tm_zip           0x00C952D4 zip_fileinfo   0x00C953D0 SZIPFileDataDescriptor
'       0x00C956CC SZIPCentralFileHeader                      0x00C95844 SZipFileEntry
'       0x00C9590C TZipEngineStreamFactory                    0x00C95AE0 TZipEStream
'     That is the whole Type list of src/recovered_thirdparty/zipengine/.
'  4. WHERE IT SITS. It ends at 0x0058DBF2; 0x0058DBF3 is ZipFile.New, the first row of
'     src/recovered_thirdparty/MANIFEST.tsv. The manifest records zipengine's code extent
'     as starting at 0x0058DBF3 -- that lower bound is one function too high. The module's
'     own initialiser is these 295 bytes immediately below it.
'
'  This also NAMES a row the archive left open: spec 22's module-init table lists
'  "0x0058DACC | 21 calls | blitz, system, retro, map | large" with no module attached.
'  The class-table argument list settles it: 0x0058DACC is ZipEngine's initialiser.
'
' THE SIX DEPENDENCY INITS IT CALLS (in emission order, = ZipEngine's own Import list)
'   0x005B929C  ___bb_blitz_blitz    (named, extracted/brl_functions_inferred.tsv)
'   0x0059C75C  unnamed; calls blitz only, so a leaf module
'   0x0059CA88  unnamed; calls 13 inits including blitz and 0x0059F150 ramstream -- a
'               stream-layer module (brl.stream is the obvious fit; NOT confirmed)
'   0x005B4A18  ___bb_system_system  (named)
'   0x0059C78C  ___bb_retro_retro    (named)
'   0x00598AEC  ___bb_map_map        (named)
'
' THE MODULE'S OWN TOP-LEVEL STATEMENTS -- the only part that came from source at all
' ===================================================================================
' After the guard, the six init calls and the thirteen registrations, exactly two
' statements remain, at 0x0058DBB2..0x0058DBE7:
'
'   0x0058DBB2   push 0x00C9590C ; call _bbObjectNew ; add esp,4
'                -> `New TZipEngineStreamFactory`, RESULT DISCARDED (the very next
'                   instruction reloads eax from 0x00C95B8C; nothing stores it). This is
'                   the standard BlitzMax stream-factory self-registration: a
'                   TStreamFactory subclass links itself into the factory chain from its
'                   own New(), so constructing one and throwing the handle away is the
'                   whole point. It is why `ReadFile("zip::...")` works at all.
'
'   0x0058DBBF   mov eax,[0x00C95B8C] / and eax,1 / cmp eax,0 / jne done
'                push 0x00C9B7E4 ; call _bbObjectNew ; add esp,4
'                inc [eax+4] ; mov [0x00C95B90], eax ; or dword [0x00C95B8C], 1
'                -> `Global <name>:TMap = New TMap`, with bcc's per-Global lazy-init
'                   guard bit (bit 0 of the flag word at 0x00C95B8C).
'
' CORRECTION TO extracted/globals_final.tsv (direct evidence, worth carrying)
'   Row 0x00C95B90 reads `TZipEngineStreamFactory ... CONFLICT: TZipEngineStreamFactory=1;
'   TMap=1`. The conflict resolves to TMap. Only the TMap `bbObjectNew` result is ever
'   stored to 0x00C95B90; the TZipEngineStreamFactory one is discarded four instructions
'   earlier and never reaches a store. The row's declared type is wrong.
'   Row 0x00C94808 (`g_misc_int66:Int`) is this module's init guard, and row 0x00C95B8C
'   (`g_misc_int69:Int`) is its Global-init flag word -- neither is a game variable.
'
' WHAT WOULD BE NEEDED TO CLOSE IT
'   A probe that compiles a whole MODULE (guard + Import list + Type declarations + the
'   two top-level statements) and matches the generated init, rather than a probe that
'   compiles one Function. scripts/try_main_body.py is the nearest existing machinery and
'   it builds the game's own module body, not an imported module's. Until that exists this
'   body cannot be byte-checked, and no header anywhere should claim it has been.
