' TScreen_Options.ButtonDifficulty
' VA 0x00520d2d   125 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (125/125, original length from Ghidra's inventory)
' assumes: Select (not If/ElseIf) - 125 vs 121; difficulty Global Int; RefreshButtons is TScreen_Options' own slot 0x38
	Function ButtonDifficulty:Int()
		'!Global g_difficulty:Int
		Select TGadget.GetActiveGadgetName()
		Case "options_difficultyeasy"
			g_difficulty = 1
		Case "options_difficultynormal"
			g_difficulty = 2
		Case "options_difficultyhard"
			g_difficulty = 3
		End Select
		RefreshButtons()
	End Function
