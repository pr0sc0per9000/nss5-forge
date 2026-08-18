' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_Controls.SetUpScreen
' VA 0x00523049   39 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory)
' 0x00c61c88 = class table TScreen + 0x5c = SetActive($,$):TScreen; 0x00c64204 = TScreen_Controls + 0x40 = RefreshButtons()i
	Function SetUpScreen:Int()
		TScreen.SetActive("controls", "tick")
		RefreshButtons()
	End Function
