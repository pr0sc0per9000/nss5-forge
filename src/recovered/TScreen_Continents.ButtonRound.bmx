' TScreen_Continents.ButtonRound
' VA 0x00548816   108 bytes   vtable slot 0x58   sig ()i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory)
' assumptions: module Global at 0x00c67220 declared as g_comp:TCompetition
'              module Global at 0x00c67204 declared as g_roundmode:Int
' the empty Case 1 is load-bearing: it produces the EB 00 at 0x00548875
	Function ButtonRound:Int()
		'!Global g_comp:TCompetition
		'!Global g_roundmode:Int
		If g_comp<>Null Then
			Select g_comp.comptype
				Case 1
				Default
					If g_roundmode<>0 Then
						TScreen_Continents.SetUpFixturesTable(g_comp.GetPrevRound())
					Else
						TScreen_Continents.SetUpFixturesTable(g_comp.GetNextRound())
					EndIf
			End Select
		EndIf
	End Function
