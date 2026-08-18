' TScreen_EditMenu.SetUpScreen
' VA 0x0052812a   33 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (33/33, original length from Ghidra's inventory)
' Class table 0x00C61C88 = TScreen + 0x5c = SetActive($,$):TScreen.
' String constants read out of NSS5.exe at 0x00C823A8 ("editmenu") and 0x00C82748.
	Function SetUpScreen:Int()
		TScreen.SetActive("editmenu","mainmenu_continents")
	End Function
