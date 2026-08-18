' TCompetition.GetStringLocale
' VA 0x0050C926   87 bytes   vtable slot 0x88   sig (i)$
' byte-identical vs NSS5.exe (87/87, original length from Ghidra's inventory, mode=reloc)
' assumptions: FUN_004C5549 is the recovered module Function GetText (locale lookup).
' Shape is load-bearing: the original tests every case up front and then jumps to the
' bodies, i.e. Select/Case with NO Default -- the "None" arm is a plain statement after
' End Select. An If/ElseIf cascade is 85 bytes and a Select with Default is also 85.
	Function GetStringLocale:String(a0:Int)
		Select a0
			Case 0
				Return GetText("Nation")
			Case 1
				Return GetText("Continent")
			Case 2
				Return GetText("World")
		End Select
		Return GetText("None")
	End Function
