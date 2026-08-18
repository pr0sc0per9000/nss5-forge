' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TKit.GetHexHairCol
' VA 0x004dbed8   103 bytes   vtable slot 0x48   sig (i)$
' byte-identical vs NSS5.exe (103/103, original length from Ghidra's inventory)
' Case 1 and the fallback share one literal address in the original, so their text is deliberately identical
	Function GetHexHairCol:String(a0:Int)
		Select a0
			Case 1
				Return "404040"
			Case 2
				Return "5B2603"
			Case 3
				Return "E5E60E"
			Case 4
				Return "EA3C00"
			Case 5
				Return "999999"
			Case 6
				Return "AC541A"
			Case 7
				Return "D7A303"
		End Select
		Return "404040"
	End Function
