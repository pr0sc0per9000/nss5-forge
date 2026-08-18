' TScreen_TestTournaments.CheckRounds
' VA 0x005390DC   248 bytes
' byte-identical vs NSS5.exe (248/248, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_tt_comp:TCompetition
'!Global g_tt_int02:Int
'!Global g_tt_button:TButton
If Not g_tt_comp
	g_tt_int02 = 1
Else
	Local maxround:Int = 1
	If g_tt_comp.lfixturelist <> Null
		For Local f:TFixture = EachIn g_tt_comp.lfixturelist
			If f.round > maxround Then maxround = f.round
		Next
	End If
	ClampInt(Varptr g_tt_int02, 1, maxround)
End If
g_tt_button.SetText(GetText("Round") + " " + g_tt_int02, "", -1, -1)
