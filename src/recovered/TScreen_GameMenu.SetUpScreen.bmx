' TScreen_GameMenu.SetUpScreen
' VA 0x0053aaa7   51 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (51/51, original length from Ghidra's inventory)
' assumptions: 0x00c61c88 = TScreen classtable+0x5c -> TScreen.SetActive($,$):TScreen (explicit
' TScreen. qualification, not the sibling table); 0x00c66914/0x00c66918 are this Type's own
' classtable+0x38/+0x3c so they are unqualified sibling calls; 0x00c66a60 = TScreen_Home+0x34.
' 0x00c855d4 = "gamemenu"; &PTR_PTR_00c5d284 is the empty string.
	Function SetUpScreen:Int()
		TScreen.SetActive("gamemenu", "")
		UpdateTitlePanel()
		UpdateNavPanel()
		TScreen_Home.SetUpScreen()
	End Function
