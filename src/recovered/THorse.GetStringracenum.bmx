' THorse.GetStringracenum
' VA 0x0058ab31   62 bytes   vtable slot 0x4c   sig ()$
' byte-identical vs NSS5.exe (62/62, original length from Ghidra's inventory)
' assumptions: field at +0x60 is THorse.racenum:Int (object_model.json). FUN_004c5549 is the
' recovered module Function GetText. Shape is a Select with NO Default plus a trailing
' Return "" -- the 2-byte `jmp` past the case bodies at +19 is what a Default clause would
' have removed (Default form measured at 60 bytes, so it is excluded).
	Method GetStringracenum:String()
		Select racenum
			Case 0
				Return GetText("stable_racenumWin")
			Case 1
				Return GetText("stable_racenumPlace")
		End Select
		Return ""
	End Method
