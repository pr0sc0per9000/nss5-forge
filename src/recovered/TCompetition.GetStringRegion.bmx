' TCompetition.GetStringRegion
' VA 0x0050CAAD   107 bytes   vtable slot 0x98   sig (i)$
' byte-identical vs NSS5.exe (107/107, original length from Ghidra's inventory, mode=reloc)
' assumptions: FUN_004C5549 is the recovered module Function GetText (locale lookup).
' Literals read out of .rdata at 0x00C7CF88/CFA0/CFB4/CFCC/CF74. Shape is Select/Case with
' NO Default -- the "None" arm is a plain statement after End Select (same as GetStringLocale).
	Function GetStringRegion:String(a0:Int)
		Select a0
			Case 1
				Return GetText("North")
			Case 2
				Return GetText("East")
			Case 3
				Return GetText("South")
			Case 4
				Return GetText("West")
		End Select
		Return GetText("None")
	End Function
