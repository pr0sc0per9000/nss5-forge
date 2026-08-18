' TScreen_EditKits.SetUpScreen
' VA 0x0053524B   289 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_editkits_team:TBase_Team      ' 0x00C65C70
'!Global g_editkits_skin1:Int            ' 0x00C65C74
'!Global g_editkits_skin2:Int            ' 0x00C65C78
'!Global g_editkits_screen:TScreen       ' 0x00C65C6C
TScreen.SetActive("editkits", "")
g_editkits_team = a0
If TNation(g_editkits_team) <> Null
	g_editkits_skin1 = TNation(g_editkits_team).primaryskin + 1
	g_editkits_skin2 = TNation(g_editkits_team).secondaryskin + 1
ElseIf TClub(g_editkits_team) <> Null
	Local n:TNation = TNation.SelectById(TClub(g_editkits_team).leagueid)
	If n <> Null
		g_editkits_skin1 = n.primaryskin + 1
		g_editkits_skin2 = n.secondaryskin + 1
	End If
End If
g_editkits_screen.SetActiveGadget("cmb_Shirt1" + a1)
RefreshKits()
