' TScreen_Continents.ButtonFixturesLeft
' VA 0x0054879D   121 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (121/121, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Global 0x00C67220:TCompetition (globals_final flags a construction-site
' CONFLICT TClub=1/TCompetition=9/TNation=1; TCompetition is the majority and is the only
' one carrying comptype at +0x24 and GetCupPreviousRound at slot 0xE0). Global
' 0x00C67208:Int. 0x00C67480 = TScreen_Continents class table + 0x4C =
' SetUpFixturesTable(i)i, a sibling Function so it is unqualified.
' The comptype test is a SELECT: the value is loaded into eax and compared with `je` to
' the case body, with the Default body emitted first. An If/Else is 117 bytes.
	Function ButtonFixturesLeft:Int()
		'!Global g_continents_comp:TCompetition
		' g_screen_continents_int05's original data-section value is 1 (read from
		' NSS5.exe at 0x00C67208 -- codegen-patterns 21.1/21.3).
		'!Global g_screen_continents_int05:Int = 1
		If g_continents_comp <> Null
			Select g_continents_comp.comptype
				Case 1
					g_continents_comp = g_continents_comp.GetCupPreviousRound()
					SetUpFixturesTable(1)
				Default
					SetUpFixturesTable(g_screen_continents_int05 - 1)
			End Select
		EndIf
	End Function
