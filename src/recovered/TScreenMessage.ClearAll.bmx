' TScreenMessage.ClearAll
' VA 0x005704ab   232 bytes   vtable slot 0x40   sig (i)i
' byte-identical vs NSS5.exe (232/232, original length from Ghidra's inventory)
' assumes: 0x00C6AFDC is a TList of TScreenMessage. Guard is 'If Not g' (setne/movzx form) + early return; the a0 branch is an early return too; 'If m.lbl <> Null Then Continue' (12-byte cmp form + 74 02 EB xx).
	Function ClearAll:Int(a0:Int)
		'!Global g_screenmessages:TList
		If Not g_screenmessages Then Return 0
		LogLine("TScreenMessage.ClearAll")
		If a0
			g_screenmessages.Clear()
			Return 0
		EndIf
		For Local m:TScreenMessage = EachIn g_screenmessages
			If m.lbl <> Null Then Continue
			m.finishtime = 0
			m.starttime = 0
			m.message = ""
		Next
	End Function
