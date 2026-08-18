' TScreen_Pairs.EnableAll
' VA 0x0057962b   45 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (45/45, original length from Ghidra's inventory)
' assumes module global:  Global g_screen_pairs_arr:TButton[]
' global 0x00c6c81c; element type guessed TButton

	Function EnableAll:Int()
		'!Global g_screen_pairs_arr:TButton[]
		For Local i:Int = 0 To 15
			g_screen_pairs_arr[i].alive = 1
		Next
	End Function
