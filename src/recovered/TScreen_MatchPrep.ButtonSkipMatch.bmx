' TScreen_MatchPrep.ButtonSkipMatch
' VA 0x0055f1f7   82 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (82/82, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C6F028 declared TProfile (globals_final: construction, high).
'   PTR_FUN_00C61CC0 = TScreen classtable + 0x94 = TScreen.DoMessage($,i,i)i.
'   PTR_FUN_00C687C0 = TScreen_MatchPrep classtable + 0x54 = sibling Function NextFixture(i).
'   GetText is the recovered module Function at 0x004C5549; the literal text is a
'   .rdata address and is masked, so the string content is not byte-observable.
	Function ButtonSkipMatch:Int()
		'!Global g_profile:TProfile
		If g_profile.selectedformatch < 1 Or TScreen.DoMessage(GetText("CMESSAGE_SKIPMATCH"),1,0) Then NextFixture(1)
	End Function
