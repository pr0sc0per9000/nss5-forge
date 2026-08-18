' TScreen_Continents.ButtonFixturesFirst
' VA 0x0054872B   114 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (114/114, original length from Ghidra's inventory)
' Assumption: module Global at 0x00c67220 declared g_cont_comp:TCompetition
' (globals_named guessed TPlayer; slot 0xdc = TCompetition.GetCupFirstRound and
'  field 0x24 = TCompetition.comptype both confirm TCompetition).
' Class-table pointer 0x00c67480 = TScreen_Continents.SetUpFixturesTable.
' The Select/Default form is load-bearing: an If/Then chain compiles 17 bytes short,
' because Select loads the tested field into a register once (mov eax,[eax+0x24]).
	Function ButtonFixturesFirst()
		'!Global g_cont_comp:TCompetition
		If g_cont_comp <> Null
			Select g_cont_comp.comptype
				Case 1
					g_cont_comp = g_cont_comp.GetCupFirstRound()
					TScreen_Continents.SetUpFixturesTable(1)
				Default
					TScreen_Continents.SetUpFixturesTable(1)
			End Select
		EndIf
	End Function
