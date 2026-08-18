' TScreen_Continents.ButtonGroupsLast
' VA 0x00549206   126 bytes   vtable slot 0x78   sig ()i
' byte-identical vs NSS5.exe (126/126, original length from Ghidra's inventory, mode=reloc)
' Assumes four module Globals (original names unrecoverable):
'   g_cont_selected:Int   (0x00C671EC)
'   g_cont_combo:TCombo   (0x00C671E4) -- type from construction site; slot 0xC0 = GetSelectedItemId
'   g_cont_comp:TCompetition (0x00C67220)
'   g_cont_fixid:Int      (0x00C67208)
' 0x00C6160C = TCompetition class table + 0x4C = TCompetition.SelectById(i):TCompetition
' 0x00C67498 / 0x00C67480 = TScreen_Continents own class table + 0x64 / +0x4C
' The combo's GetSelectedItemId() is called twice -- bcc does no CSE, so the source does too.
	Function ButtonGroupsLast:Int()
		'!Global g_cont_selected:Int
		'!Global g_cont_combo:TCombo
		'!Global g_cont_comp:TCompetition
		'!Global g_cont_fixid:Int
		g_cont_selected = 99999
		If g_cont_combo.GetSelectedItemId() > 0
			g_cont_comp = TCompetition.SelectById(g_cont_combo.GetSelectedItemId())
		EndIf
		TScreen_Continents.SetUpLeagueTable()
		TScreen_Continents.SetUpFixturesTable(g_cont_fixid)
	End Function
