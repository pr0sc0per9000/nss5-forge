' TScreen_Pairs.DisableAll
' VA 0x005795fe   45 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (45/45, original length from Ghidra's inventory)
' assumes module global:  Global g_screen_pairs_arr:TButton[]
' global 0x00c6c81c; element type guessed TButton (any TGadget subclass has alive at +0x38)

	Function DisableAll:Int()
		'!Global g_screen_pairs_arr:TButton[]
		For Local i:Int = 0 To 15
			g_screen_pairs_arr[i].alive = 0
		Next
	End Function
