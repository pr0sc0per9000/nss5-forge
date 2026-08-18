' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_Language.SetUpScreen
' VA 0x0051BF6C   93 bytes   vtable slot 0x34   sig (i)i
' byte-identical vs NSS5.exe (93/93, original length from Ghidra's inventory)
' ASSUMPTION: Global 0x00c638c4 :Int, Global 0x00c5d290 :String
' the <> form (not =) is required: the original emits je, not jne, after the _bbStringCompare result test
	Function SetUpScreen:Int(a0:Int)
		'!Global g_langsel:Int
		'!Global g_optlang:String
		g_langsel = a0
		If g_optlang <> "0" Then
			TScreen.SetActive("language",g_optlang)
			TScreen_Language.ButtonLanguage()
		Else
			TScreen.SetActive("language","en")
		EndIf
	End Function
