' TCompetition.GetStringCompType
' VA 0x0050ca1a   147 bytes   vtable slot 0x94   sig (i)$
' byte-identical vs NSS5.exe (147/147, original length from Ghidra's inventory, mode=reloc)
' 0x004C5549 is the recovered module Function GetText; every literal was read out of NSS5.exe.
' Shape: a Select with NO Default -- the six compares run back to back, then a 2-byte jmp to
' the fallback statement that sits AFTER End Select (guide 10.2). If/ElseIf gives 145 and a
' Select WITH Default also gives 145.
	Function GetStringCompType:String(a0:Int)
		Select a0
			Case 0
				Return GetText("comptype_League")
			Case 1
				Return GetText("comptype_KO")
			Case 2
				Return GetText("comptype_BestPlaced")
			Case 3
				Return GetText("comptype_Pool")
			Case 4
				Return GetText("comptype_LeagueCont")
			Case 5
				Return GetText("comptype_RegionalSort")
		End Select
		Return GetText("None")
	End Function
