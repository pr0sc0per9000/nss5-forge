' TTraining.Fail
' VA 0x005818c7   162 bytes   vtable slot 0x94   sig ()i
' byte-identical vs NSS5.exe (162/162, original length from Ghidra's inventory)
' ASSUMPTIONS: module Globals 0x00c5df40 declared TSound and 0x00c6f090 declared TChannel
' (both are "Object, no call-site typing" in globals_final.tsv; the types are fixed by
' PlaySound's signature). 0x00c5b1fc is an Int, not the TPlayer globals_final.tsv claims --
' it takes a plain "mov dword, 11" with no refcount traffic.
' 0x004a7410 = _brl_retro_Lower per runtime_helpers.tsv, so the first message is lowercased.
' The tail is two String Global assignments; the inc/dec pairs around them in the
' decompilation are inlined retain/release, not source. TScreenMessage slot 0x40 = ClearAll.
' The two GetText keys are masked addresses; their VALUES are not proven.
' harness mode=reloc, 17 addresses masked.
' CASE DIRECTION CORRECTED 2026-08-22: 1 call site -> .ToUpper().
' extracted/runtime_helpers.tsv named 0x004A7410 `_brl_retro_Lower` and 0x004A74E0
' `_brl_retro_Upper`. Both were wrong and neither address is a brl.retro wrapper:
' 0x004A7410 is `_bbStringToUpper` and 0x004A74E0 is `_bbStringToLower`. NSS5.exe's
' own 21-byte retro wrappers at 0x0059C8FD (Lower) and 0x0059C912 (Upper) CALL those
' two addresses, and a wrapper cannot be the function it calls. The wrong row masked
' by name, so this body certified with the case conversion running backwards. Full
' derivation and the discriminating 3x4 matrix: docs/reference/codegen-patterns.md
' 15.6. Re-verified under NSS5_NO_LEARN=1 on worker trees 380 and 380b.
	Function Fail:Int()
		'!Global g_snd_fail:TSound
		'!Global g_object859:TChannel
		'!Global g_train_int05:Int
		'!Global g_player_int01:Int
		'!Global g_train_msg1:String
		'!Global g_train_msg2:String
		PlaySound(g_snd_fail, g_object859)
		TScreenMessage.ClearAll(0)
		g_train_int05 = 2
		g_player_int01 = 11
		g_train_msg1 = GetText("Fail!").ToUpper()
		g_train_msg2 = GetText("CMESSAGE_TRAININGFAIL")
	End Function
