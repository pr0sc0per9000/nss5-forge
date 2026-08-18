' TScreen_Roulette.ClearBets
' VA 0x005750d6   48 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (48/48, original length from Ghidra's inventory)
' assumes module global:  Global g_screen_roulette_arr:Int[]
' UpdateBetLabels is TScreen_Roulette slot 0x48

	Function ClearBets:Int()
		'!Global g_screen_roulette_arr:Int[]
		For Local i:Int = 0 To 5
			g_screen_roulette_arr[i] = 0
		Next
		UpdateBetLabels()
	End Function
