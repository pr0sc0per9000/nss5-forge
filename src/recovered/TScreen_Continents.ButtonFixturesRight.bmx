' TScreen_Continents.ButtonFixturesRight
' VA 0x00548882   121 bytes   vtable slot 0x5c   sig ()i
' byte-identical vs NSS5.exe (121/121, original length from Ghidra's inventory)
' assumptions: module Global at 0x00c67220 declared as g_comp:TCompetition
'              module Global at 0x00c67208 declared as g_round:Int
	Function ButtonFixturesRight:Int()
		'!Global g_comp:TCompetition
		'!Global g_round:Int
		If g_comp<>Null Then
			Select g_comp.comptype
				Case 1
					g_comp=g_comp.GetCupNextRound()
					TScreen_Continents.SetUpFixturesTable(1)
				Default
					TScreen_Continents.SetUpFixturesTable(g_round+1)
			End Select
		EndIf
	End Function
