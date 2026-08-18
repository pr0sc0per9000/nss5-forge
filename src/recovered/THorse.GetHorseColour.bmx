' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' THorse.GetHorseColour
' VA 0x0058b918   91 bytes   vtable slot 0x74   sig (i)$
' byte-identical vs NSS5.exe (91/91, original length from Ghidra's inventory)
' The fallback must be a Return AFTER End Select, not a 'Default' clause (Default is 2 bytes short - bcc lays the default block before the case bodies)
	Function GetHorseColour:String(a0:Int)
		Select a0
			Case 1
				Return "FF0000"
			Case 2
				Return "FFFF00"
			Case 3
				Return "00FF00"
			Case 4
				Return "0000FF"
			Case 5
				Return "FF00FF"
			Case 6
				Return "00FFFF"
		End Select
		Return "000000"
	End Function
