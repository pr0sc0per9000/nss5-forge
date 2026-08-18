' TScreen_Leagues.RefreshComboColours
' VA 0x0054644B   284 bytes
' byte-identical vs NSS5.exe (284/284, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_lg_combo1:TCombo
'!Global g_lg_combo2:TCombo
'!Global g_lg_combo3:TCombo
'!Global g_lg_combo4:TCombo
g_lg_combo1.SetColour("888888", "FFFFFF")
g_lg_combo2.SetColour("888888", "FFFFFF")
g_lg_combo3.SetColour("888888", "FFFFFF")
g_lg_combo4.SetColour("888888", "FFFFFF")
If Not TClub.SelectById(g_lg_combo4.GetSelectedItemId())
End If
Local col:String = "FFFFFF"
If g_lg_combo1.selecteditem > 0
	g_lg_combo1.SetColour(col, "FFFFFF")
End If
If g_lg_combo2.selecteditem > 0
	g_lg_combo2.SetColour(col, "FFFFFF")
End If
If g_lg_combo3.selecteditem > 0
	g_lg_combo3.SetColour(col, "FFFFFF")
End If
If g_lg_combo4.selecteditem > 0
	g_lg_combo4.SetColour(col, "FFFFFF")
End If
