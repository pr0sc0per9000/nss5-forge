' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TTraining.TimeUp
' VA 0x00581844   131 bytes   vtable slot 0x90   sig ()i
' byte-identical vs NSS5.exe (131/131, original length from Ghidra's inventory, mode=reloc)
' Assumptions: four module Globals, names ours. 0x00C6CF98 and 0x00C5B1FC are Ints
' (plain dword stores, no refcount traffic -- globals_final.tsv types 0x00C5B1FC as
' TPlayer, which the code contradicts). 0x00C6CFA4 and 0x00C6CFAC carry full retain/
' release traffic around the store, so they are Strings, not the Ints the table lists.
' FUN_004A7410 is _brl_retro_Lower; FUN_004C5549 is the verified module GetText.
' String literal contents are placeholders (their .rdata addresses relocate).
' CASE DIRECTION CORRECTED 2026-08-22: 1 call site -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function TimeUp:Int()
		'!Global g_training_a:Int
		'!Global g_player_b:Int
		'!Global g_training_s1:String
		'!Global g_training_s2:String
		g_training_a = 2
		g_player_b = 11
		g_training_s1 = GetText("Time Up!").ToUpper()
		g_training_s2 = GetText("CMESSAGE_TRAININGFAIL")
	End Function
