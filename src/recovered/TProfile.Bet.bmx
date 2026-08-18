' TProfile.Bet
' VA 0x0056B780   99 bytes   vtable slot 0x104   sig (i)i
' byte-identical vs NSS5.exe (99/99, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C61CC0 = TScreen.DoMessage($,i,i)i, 0x00C66914 =
' TScreen_GameMenu.UpdateTitlePanel(). FUN_004C5549 = GetText.
	Method Bet:Int(a0:Int)
		If bank < a0
			TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"), 0, 0)
			Return 0
		Else
			bank = bank - a0
			If a0 > 0
				gambling = gambling + 2
			EndIf
			If gambling > 100
				gambling = 100
			EndIf
			TScreen_GameMenu.UpdateTitlePanel()
			Return 1
		EndIf
	End Method
