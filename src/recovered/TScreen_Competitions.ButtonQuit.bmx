' TScreen_Competitions.ButtonQuit
' VA 0x0052fd37   26 bytes   vtable slot 0x38   sig ()i
' byte-identical vs NSS5.exe (26/26, original length from Ghidra's inventory)
' No assumptions: both callees resolved via class_tables.tsv + vtable_map.tsv.
	Function ButtonQuit()
		TScreen_EditMenu.SetUpScreen()
		TCompetition.ValidatePromotionPlacesAll()
	End Function
