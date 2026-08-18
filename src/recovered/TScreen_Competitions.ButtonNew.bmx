' TScreen_Competitions.ButtonNew
' VA 0x0052fe6a   42 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (42/42, original length from Ghidra's inventory)
' Class-table pointers resolved: 0x00c615f8 = TCompetition+0x38 (NewCompetition),
' 0x00c658d8 = TScreen_EditCompetition+0x34 (SetUpScreen). 0x00c5d284 is the empty
' string constant (len 0).
	Function ButtonNew:Int()
		Local c:TCompetition = TCompetition.NewCompetition(0)
		TScreen_EditCompetition.SetUpScreen(c.id,"")
	End Function
