' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH never
' certifies the text -- see docs/reference/codegen-patterns.md 13.2.
' TBall.GetStringKickType
' VA 0x004cc5e2   98 bytes   vtable slot 0xc8   sig (i)$
' byte-identical vs NSS5.exe (98/98, original length from Ghidra's inventory)
' The empty 'Case 0' is load-bearing - it is what produces the leading test against 0
	Function GetStringKickType:String(a0:Int)
		Select a0
			Case 0
			Case 1
				Return "PASS"
			Case 2
				Return "SHOOT"
			Case 3
				Return "LOB"
			Case 4
				Return "HEAD PASS"
			Case 5
				Return "HEAD SHOOT"
			Case 6
				Return "HEAD LOB"
		End Select
		Return "NONE"
	End Function
