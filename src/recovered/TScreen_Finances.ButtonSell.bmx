' TScreen_Finances.ButtonSell
' VA 0x00558bfa   60 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (60/60, original length from Ghidra's inventory)
' 0x00C6F028 : TProfile (globals_final, construction, high) -- slot 0xEC = SellItemByName($)
' 0x00C68168 : TTable  (globals_final, construction) -- slot 0xD8 = GetSelectedText(i)$
' PTR_FUN_00c68224 = TScreen_Finances slot 0x34 = SetUpScreen() (sibling Function)
' Global: Global g_profile:TProfile
' Global: Global g_finances_table:TTable
	Function ButtonSell:Int()
		'!Global g_profile:TProfile
		'!Global g_finances_table:TTable
		g_profile.SellItemByName(g_finances_table.GetSelectedText(0))
		SetUpScreen()
	End Function
