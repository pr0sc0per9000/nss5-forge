' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_Difficulty.ButtonEasy
' VA 0x00525D40   50 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (50/50, original length from Ghidra's inventory)
' ASSUMPTION: Global 0x00c5d228 declared :Int, Global 0x00c64504 declared :String (it is pushed by value as SetActive's first argument)
' The second SetActive argument is a string constant.
	Function ButtonEasy:Int()
		'!Global g_difficulty:Int
		'!Global g_diffname:String
		g_difficulty = 1
		TOptions.SaveOptions()
		TScreen.SetActive(g_diffname,"")
	End Function
