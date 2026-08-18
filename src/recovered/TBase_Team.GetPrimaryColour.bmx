' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TBase_Team.GetPrimaryColour
' VA 0x004bd25d   73 bytes   vtable slot 0x3c   sig ()$
' byte-identical vs NSS5.exe (73/73, original length from Ghidra's inventory)

	Method GetPrimaryColour:String()
		Local c:String = kitcolsHome.shirt1
		If c = "FFFFFF" Then c = kitcolsHome.shirt2
		If c = "000000" Then c = "666666"
		Return c
	End Method
