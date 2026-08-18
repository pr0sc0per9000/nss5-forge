' TScreen_GameMenu.ButtonRelationships
' VA 0x0053B9E8   25 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (25/25, original length from Ghidra's inventory)
' harness mode=reloc: call target resolved to TScreen_Relationships+0x34 on both sides.

	Function ButtonRelationships:Int()
		TScreen_Relationships.SetUpScreen(1)
	End Function
