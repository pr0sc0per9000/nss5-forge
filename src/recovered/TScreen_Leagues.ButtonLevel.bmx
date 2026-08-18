' TScreen_Leagues.ButtonLevel
' VA 0x0054642e   29 bytes   vtable slot 0x68   sig ()i
' byte-identical vs NSS5.exe (29/29, original length from Ghidra's inventory)
' PTR_FUN_00c67468 resolved via class_tables.tsv to TScreen_Continents + slot 0x34 = SetUpScreen(i,i,i)
	Function ButtonLevel()
		TScreen_Continents.SetUpScreen(0,0,0)
	End Function
