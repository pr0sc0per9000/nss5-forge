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
		g_train_msg1 = Lower(GetText("Fail!"))
		g_train_msg2 = GetText("CMESSAGE_TRAININGFAIL")
	End Function
