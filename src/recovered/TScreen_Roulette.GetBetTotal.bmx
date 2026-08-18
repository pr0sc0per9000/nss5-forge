' TScreen_Roulette.GetBetTotal
' VA 0x005754ba   39 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (39/39, original length from Ghidra's inventory)
' assumes module global:  Global g_screen_roulette_arr:Int[]
' global 0x00c6ba60 inferred Int[] (4-byte elements summed directly); loop is 'To 5' (jle)

	Function GetBetTotal:Int()
		'!Global g_screen_roulette_arr:Int[]
		Local t:Int = 0
		For Local i:Int = 0 To 5
			t = t + g_screen_roulette_arr[i]
		Next
		Return t
	End Function
