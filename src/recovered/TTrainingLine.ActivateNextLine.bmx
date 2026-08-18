' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TTrainingLine.ActivateNextLine
' VA 0x005842BA   196 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (196/196, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00C6D568 declared :TList.
' The `If found = 0 ... Else ...` polarity is load-bearing (jne, not je); the inverted spelling mismatches at byte 138.
' The two colour literals have addresses masked by mode=reloc, so the byte match alone does not certify their text. String equality goes through _bbStringCompare (0x004A6A30).
' harness mode=reloc.

	Function ActivateNextLine:Int()
		'!Global g_trainingobjects:TList
		Local found:Int = 0
		For Local l:TTrainingLine = EachIn g_trainingobjects
			If l.colour = "00FF00" Or l.colour = "00FFFF" Then
				If found = 0 Then
					l.alive = 1
					found = 1
				Else
					l.alive = 0
				EndIf
			EndIf
		Next
	End Function
