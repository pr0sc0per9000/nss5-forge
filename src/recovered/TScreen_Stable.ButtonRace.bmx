' TScreen_Stable.ButtonRace
' VA 0x0058853e   54 bytes   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (54/54, original length from Ghidra's inventory)
' assumes module global:  Global g_screen_stable_int05:Int
' global 0x00c6df70; the EMPTY Case 2 is real -- an If/ElseIf cascade is 8 bytes short

	Function ButtonRace:Int()
		'!Global g_screen_stable_int05:Int
		Select g_screen_stable_int05
			Case 0
				SetUpNextRace()
			Case 1
				DoRace()
			Case 2
		End Select
	End Function
