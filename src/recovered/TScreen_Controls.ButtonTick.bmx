' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_Controls.ButtonTick
' VA 0x00523899   39 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory)
' 0x00c5d560=TOptions+0x48 (SaveOptions), 0x00c61c88=TScreen+0x5c (SetActive($,$):TScreen)
' Both SetActive arguments are string constants.
	Function ButtonTick:Int()
		TOptions.SaveOptions()
		TScreen.SetActive("options","")
	End Function
