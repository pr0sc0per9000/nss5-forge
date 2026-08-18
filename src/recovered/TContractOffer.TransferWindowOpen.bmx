' TContractOffer.TransferWindowOpen
' VA 0x00571DF9   152 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (152/152, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTION: module Global at 0x00c6f028 declared TProfile (+0x10 = TProfile.date:TMyDate).
' TMyDate slot 0x54 = GetYear, slot 0x50 = GetWeek.
' The >= / <= forms are load-bearing: '> 0' and '< 11' give cmp 0/setg and cmp 0xb/setl.

	Function TransferWindowOpen:Int()
		'!Global g_profile:TProfile
		If g_profile.date.GetYear() >= 1 And g_profile.date.GetWeek() <= 10
			Return 1
		ElseIf g_profile.date.GetWeek() >= 26 And g_profile.date.GetWeek() <= 32
			Return 1
		Else
			Return 0
		EndIf
	End Function
