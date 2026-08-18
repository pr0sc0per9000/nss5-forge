' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TKit.GetStringSkinCol
' VA 0x004dc310   97 bytes   vtable slot 0x6c   sig (i)$
' byte-identical vs NSS5.exe (97/97, original length from Ghidra's inventory)
' The fallback is genuinely a literal + Int concat (bbStringFromInt then bbStringConcat)
	Function GetStringSkinCol:String(a0:Int)
		Select a0
			Case 1
				Return "CSKIN_LIGHT"
			Case 2
				Return "CSKIN_MEDIUM"
			Case 3
				Return "CSKIN_DARK"
			Case 4
				Return "CSKIN_BLACK"
			Case 5
				Return "CSKIN_ASIAN"
		End Select
		Return "CSKIN_UNKNOWN:" + a0
	End Function
