' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TCompetition.GetStringBased
' VA 0x0050c9c0   90 bytes   vtable slot 0x90   sig (i,i)$
' byte-identical vs NSS5.exe (90/90, original length from Ghidra's inventory)
' Select with NO Default -- the default text is the statement after End Select (that is the 2-byte EB jmp at 0x0050C9D8)
	Function GetStringBased:String(a0:Int,a1:Int)
		Select a0
			Case 0
				Return TNation.SelectById(a1).labelshortname
			Case 1
				Return TContinent.SelectById(a1).name
			Case 2
				Return GetText("World")
		End Select
		Return GetText("None")
	End Function
