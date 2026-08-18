' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_ContinentalComps.ButtonEditComp
' VA 0x00534245   48 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (48/48, original length from Ghidra's inventory)
' assumes module global:  Global g_Object293:TCompetition   (0x00c65a24; the declared type is
' load-bearing -- it selects the +0x8 'id' field)
' 0x00c658d8 = class table TScreen_EditCompetition + 0x34 = SetUpScreen(i,$)i
	Function ButtonEditComp:Int()
		'!Global g_Object293:TCompetition
		If g_Object293 <> Null Then TScreen_EditCompetition.SetUpScreen(g_Object293.id, "continentalcomps")
	End Function
