' TFormation.Create
' VA 0x004d8397   53 bytes   vtable slot 0x34   sig (i):TFormation
' byte-identical vs NSS5.exe (53/53, original length from Ghidra's inventory)

	Function Create:TFormation(a0:Int)
		Local f:TFormation = New TFormation
		f.LoadTactics(GetStringTacticName(a0))
		Return f
	End Function
