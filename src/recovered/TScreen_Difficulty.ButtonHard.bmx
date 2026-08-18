' TScreen_Difficulty.ButtonHard
' VA 0x00525DA4   50 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (50/50, original length from Ghidra's inventory, mode=reloc)
'
' Slots resolved from the class tables: 0x00C5D560 = TOptions + 0x48 (SaveOptions),
' 0x00C61C88 = TScreen + 0x5C (SetActive($,$):TScreen). The second SetActive argument is
' the empty-string literal at 0x00C5D284.
' The screen-name String Global at 0x00C64504 is typed Int in globals_final.tsv; it is a
' String here (it is passed to SetActive($,$)).
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_difficulty:Int
'   Global g_screen_difficulty_name:String
	Function ButtonHard:Int()
		'!Global g_difficulty:Int
		'!Global g_screen_difficulty_name:String
		g_difficulty = 3
		TOptions.SaveOptions()
		TScreen.SetActive(g_screen_difficulty_name, "")
	End Function
