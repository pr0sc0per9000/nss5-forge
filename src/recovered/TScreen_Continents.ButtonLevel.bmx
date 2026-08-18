' TScreen_Continents.ButtonLevel
' VA 0x00549284   61 bytes   vtable slot 0x7c   sig ()i
' byte-identical vs NSS5.exe (61/61, original length from Ghidra's inventory)
' assumes module global:  Global g_screen_continents_int06:Int  (0x00c67224)
' Select/Case is load-bearing here: the original loads the global once and compares twice,
' which an If/ElseIf chain does not reproduce (it re-reads the global).
	Function ButtonLevel:Int()
		'!Global g_screen_continents_int06:Int
		Select g_screen_continents_int06
			Case 0
				SetUpScreen(0, 1, 0)
			Case 1
				TScreen_Leagues.SetUpScreen(0)
		End Select
	End Function
