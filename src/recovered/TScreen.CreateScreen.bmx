' GLOBAL RENAMED (2026-08-15): g_currentscreen -> g_curscreen. Same slot, 0x00C61700,
' stated in this file's own header and in TScreen.SetActive's. SetActive WRITES the
' active screen as g_curscreen and this file READ it as g_currentscreen, so in the
' assembled program they were two Globals and the reader always saw Null -- the boot
' died in SetActiveGadget on `g_currentscreen.gadgetlist` while setting up the very
' first screen. 8 files already spell 0x00C61700 g_curscreen; only these 2 did not.
' Byte-neutral (Global names never appear in the compiled bytes; the oracle masks the
' address) -- confirmed with scripts/reverify.py.
' CAUTION for anyone extending this: g_curscreen is ALSO used for a DIFFERENT slot,
' 0x00C6764C, in TScreen_MatchPaused.ButtonSkipTime and others. The name->address map
' is many-to-many, so never sweep-rename it globally; see scripts/unify_globals.py.
' TScreen.CreateScreen
' VA 0x005103c3   381 bytes   class-table slot 0x38   sig ($,:TImage,()i,()i):TScreen
' byte-identical vs NSS5.exe (381/381, original length from Ghidra's inventory, mode=reloc)
' Re-verified 2026-08-22 under NSS5_NO_LEARN=1 on worker trees 380 and 380b, after the
' runtime-helper table rows for 0x004A7410/0x004A74E0 were corrected. See below.
' RUNTIME HELPER TABLE WAS WRONG HERE. CORRECTED 2026-08-22; THIS BODY NOW MATCHES.
' extracted/runtime_helpers.tsv (LEARNED, gitignored) used to carry these two rows:
'     0x004A7410  _brl_retro_Lower   205 witnesses
'     0x004A74E0  _brl_retro_Upper    14 witnesses
' Both were wrong, and not merely swapped: neither address is a brl.retro wrapper at all.
' They are the C-runtime case converters, and the correct rows are
'     0x004A7410  _bbStringToUpper
'     0x004A74E0  _bbStringToLower
' Four independent lines of evidence, none of them the oracle:
'  1. The instruction that does the work.
'       0x004A74E0: lea eax,[edi-0x41] / cmp eax,0x19 / or  edi,0x20    -> LOWERCASES
'       0x004A7410: lea eax,[edi-0x61] / cmp eax,0x19 / and edi,0xFFDF  -> UPPERCASES
'  2. blitz_string.c. bbStringToLower gates its ASCII path on `c<192` and bbStringToUpper
'     on `c<181`; the two bodies compare edi against 0xBF and 0xB4 respectively, matching
'     0x004A74E0 = ToLower and 0x004A7410 = ToUpper.
'  3. NSS5.exe names them itself. The brl.retro wrappers survive in the original at
'     0x0059C8E8 Trim / 0x0059C8FD Lower / 0x0059C912 Upper -- 21 bytes each, in the same
'     Mid/Instr/Left/Right/LSet/RSet/Replace/Trim/Lower/Upper/Hex order and with the same
'     byte sizes as our own build of retro.mod, with Replace at 0x0059C8CB and Hex at
'     0x0059C927 already named in extracted/brl_functions.tsv. Each wrapper is one call:
'       0x0059C8E8 (Trim)  -> 0x004A7740, independently named _bbStringTrim in the table
'       0x0059C8FD (Lower) -> 0x004A74E0
'       0x0059C912 (Upper) -> 0x004A7410
'     A wrapper cannot be the function it calls, so 0x004A74E0 is what Lower() calls, i.e.
'     bbStringToLower. This body therefore calls the String method .ToLower(), not the
'     brl.retro Function Lower() -- the original really does distinguish the two: it calls
'     0x0059C8FD from ReadSettingFloat and ReadSettingString and nowhere else, and calls
'     0x0059C912 from nowhere at all.
'  4. Semantics elsewhere in the corpus. With the old rows, RGBToHex returned LOWERCASE hex
'     while every colour literal in the game is uppercase ("FFFFFF", "00FF00"), and
'     TCompetition.IsCupFinal tested `Lower(c.tla) = "SUPER CUP"`, which can never be true.
'
' WHY THIS BODY WAS EVER MARKED VERIFIED, AND WHY IT STOPPED BEING. Offset +224 is the
' OPERAND of `E8` at 0x005104A2, target 0x004A74E0. scripts/localise_diff.py reported
' "CLEAN -- byte-identical modulo the oracle's masks" throughout, because its own mask set
' covers the call operand; only harness.try_method's by-name check saw it.
'
' The original verification almost certainly ran with LEARNING ON. In that mode a body whose
' only defect is one unnamed original-side call operand teaches the table its OWN symbol for
' that address, then re-compares clean inside the same try_method() call -- the exact
' self-fulfilling masking scripts/harness.py's NSS5_NO_LEARN note describes, and the failure
' mode codegen-patterns.md 15.5 records as "a WRONG name in the table blesses WRONG source".
'
' DO NOT 'FIX' A DIFF AT THIS OFFSET BY FLIPPING THE CASE. Writing Upper(s.name) produced
' MATCH 381/381 against the OLD wrong row and breaks the game: all 33 help_* rows in
' GameMedia/Languages/Languages.csv are lowercase, as is every screen-name literal, so
' uppercasing the key makes every lookup miss and every screen falls back to help_nohelp.
' Measured 3x4 matrix (worker 380, NSS5_NO_LEARN=1), showing the oracle alone cannot pick
' between the two namings and only the binary can:
'     table 7410=retro_Lower,74E0=retro_Upper (old) : Upper(s.name)     MATCH  381/381
'     table 7410=retro_Upper,74E0=retro_Lower       : Lower(s.name)     MATCH  381/381
'     table 7410=bbToUpper,  74E0=bbToLower  (now)  : s.name.ToLower()  MATCH  381/381
'     every other cell of the 12                    :                   MISMATCH at 224
'
' Lesson for the corpus, not just this file: a MATCH obtained under learning is only as good
' as the table it wrote. This is the argument for NSS5_NO_LEARN=1 on every audit.
'
' GLOBAL NAMES ARE OURS. 0x00C61714 TImage (fallback background), 0x00C61700 TScreen
' (the current screen -- if none is set yet this one becomes active),
' 0x00C6EFDC / 0x00C6EFE0 Int (screen width / height).
'
' The help text is looked up as "help_" + name.ToLower(); GetText returns "@"+key when the
' key is missing (see TLocale.GetLocaleText), which is exactly what .Contains("@") tests.
'!Global g_defaultbg:TImage
'!Global g_curscreen:TScreen
' g_screenwidth/g_screenheight are the screen width/height (0x00C6EFDC=800,
' 0x00C6EFE0=600, the game's fixed 800x600 resolution -- codegen-patterns 21.1/21.3).
' The SAME two addresses are also declared under two other names elsewhere in the corpus
' (g_screen_int21/g_screen_int22 in TScreen.UpdateOffset.bmx and others, g_screenw/g_screenh
' in TScreen.Draw.bmx); merge_globals dedups by name, not address, so each name family
' needs its own initialiser or it stays a separate, zero-defaulted Global in the assembled
' build. This is the dominant name -- ~30 files use it.
'!Global g_screenwidth:Int = 800
'!Global g_screenheight:Int = 600
' The predicate is .Contains, not .StartsWith. extracted/runtime_helpers.tsv names
'   0x004A6BF0 _bbStringStartsWith; it is _bbStringContains, and the wrong row MASKED
'   BY NAME and blessed the wrong predicate here (codegen-patterns 3b). 0x004A6BF0 is
'   44 bytes and is exactly `return bbStringFind(x,y,0)!=-1` -- blitz_string.c:265 --
'   while bbStringStartsWith/EndsWith are call-free loops and cannot call anything.
'   With the row right, this body is MISMATCH as .StartsWith and MATCH as .Contains.
'
' The case call is .ToLower(), not Lower() and not any form of Upper. Full derivation is
' in the block at the top of this file; the short version is that 0x004A74E0 is the
' C-runtime bbStringToLower, reached here directly by the String method, while the
' brl.retro Function Lower() is a separate 21-byte wrapper at 0x0059C8FD that calls it.
' Confirmed against data: every one of the 33 `help_*` rows in
' GameMedia/Languages/Languages.csv (help_newplayer, help_matchprep, help_mycontract,
' ...) has its screen-name suffix in lowercase, matching every screen-name literal passed
' to TScreen.CreateScreen (also all lowercase, e.g. "newplayer"). Lowercasing the name is
' a no-op on those and the built key matches the CSV tag exactly; uppercasing it matches
' none of them, so h.Contains("@") would always be true and every screen's help would fall
' back to help_nohelp ("Sorry but there is no help for this screen!"). TMap keys strings
' via bbStringCompare (blitz_string.c:238), a plain case-sensitive byte compare, so this
' is not a false alarm from a case-insensitive lookup elsewhere.
' CASE DIRECTION CORRECTED 2026-08-22: 1 call site -> .ToLower().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function CreateScreen:TScreen(a0:String, a1:TImage, a2:Int(), a3:Int())
		LogLine("Create Screen:" + a0)
		Local s:TScreen = New TScreen
		s.name = a0
		s.bg = a1
		If s.bg = Null
			s.bg = g_defaultbg
		EndIf
		s.fDraw = a2
		s.fUpdate = a3
		s.gadgetlist = CreateList()
		If Not g_curscreen
			TScreen.SetActive(a0, "")
		EndIf
		Local h:String = GetText("help_" + s.name.ToLower())
		If h.Contains("@")
			h = GetText("help_nohelp")
		EndIf
		s.lHelp.AddLast(THelpBox.Create(Null, g_screenwidth / 2 - 240, g_screenheight / 2 - 130, 480, 260, h, 0, 3))
		Return s
	End Function
