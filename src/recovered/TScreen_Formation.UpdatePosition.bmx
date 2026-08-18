' TScreen_Formation.UpdatePosition
' VA 0x0054d0aa   232 bytes   vtable slot 0x54   sig (i)i
' byte-identical vs NSS5.exe (232/232, original length from Ghidra's inventory, mode=reloc)
' Globals: 0x00C677D8 g_fmt_lock:Int, 0x00C677D4 g_fmt_sel:Int, 0x00C5B22C g_fixture:TFixture
'          (globals_final says TPlayer from slots 0x58/0x68/0x70/0x74; the FIELDS decide it --
'          +0x2c/+0x30 are score1/score2 and +0x34/+0x38 penscore1/penscore2 in TEngine.DrawScores
'          and TEngine.CheckShootOutComplete, so it is a TFixture and +0x3c is level),
'          0x00C6F028 g_profile:TProfile, 0x00C677B0 g_team:TTeam (its +0x24 is formation:TFormation,
'          whose slots 0x5c/0x60 are GetPosFromSelectionNo/GetSideFromSelectionNo).
' PTR_FUN_00C67990 is this Type's own slot 0x4c = CancelRequest, so no Type prefix.
' Two shape facts: the entry guard is an early return (If-block gives 207), and every use after
' `g_fmt_sel = a0` reads the GLOBAL back rather than the parameter still sitting in eax
' (guide 10.6) -- using a0 gives 213.
	Function UpdatePosition:Int(a0:Int)
		'!Global g_fmt_lock:Int
		'!Global g_fmt_sel:Int
		'!Global g_fixture:TFixture
		'!Global g_profile:TProfile
		'!Global g_team:TTeam
		If g_fmt_lock Then Return 0
		g_fmt_sel = a0
		If g_fixture.level = 1
			If g_profile.internationalselno <> g_fmt_sel
				g_profile.internationalselno = g_fmt_sel
				g_team.UpdateNewStarPosition(g_profile.internationalselno)
			End If
		ElseIf g_profile.newstarselno <> g_fmt_sel
			g_profile.newstarselno = g_fmt_sel
			g_profile.side = g_team.formation.GetSideFromSelectionNo(g_fmt_sel)
			g_profile.position = g_team.formation.GetPosFromSelectionNo(g_fmt_sel)
			g_team.UpdateNewStarPosition(g_profile.newstarselno)
		End If
		CancelRequest()
	End Function
