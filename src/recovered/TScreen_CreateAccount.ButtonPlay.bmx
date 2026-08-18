' TScreen_CreateAccount.ButtonPlay
' VA 0x005256d5   26 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (26/26, original length from Ghidra's inventory)
' No assumptions: both callees resolved via class_tables.tsv + vtable_map.tsv.
	Function ButtonPlay()
		TScreen_NewPlayer.SetUpScreen()
		TScreen_NewPlayer.DoClubTrial()
	End Function
