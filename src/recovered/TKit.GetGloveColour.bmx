' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TKit.GetGloveColour
' VA 0x004dc1d7   67 bytes   vtable slot 0x60   sig (i)$
' byte-identical vs NSS5.exe (67/67, original length from Ghidra's inventory)
' Select WITHOUT a Default plus a trailing Return.

	Function GetGloveColour:String(a0:Int)
		Select a0
			Case 1
				Return "404040"
			Case 2
				Return "FFFFFF"
			Case 3
				Return "2D00EA"
			Case 4
				Return "EA0005"
		End Select
		Return ""
	End Function
