' TPlayer.UpdateMatchRatingAll
' VA 0x004ff56d   271 bytes   vtable slot 0x22c   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (271/271, original length from Ghidra's inventory)
'
' GLOBAL NAMES ARE OURS; the DECLARED TYPES are load-bearing (they pick the vtable slot).
' g_fixture is typed TFixture from the pair of Int fields at +0x2c/+0x30 that get swapped
' on the home/away test -- score1/score2. globals_final.tsv types 0x00C5B22C as TPlayer
' with an explicitly UNSOUND uniqueness note; TPlayer +0x2c is a String, so that row is
' wrong and the code decides it (codegen-patterns 11.2).
' GetMyTeam() is called twice on purpose -- bcc does no CSE and the original calls it twice.
'!Global g_allplayers:TList
'!Global g_fixture:TFixture
'!Global g_awayteam:TTeam
'!Global g_matchminute:Int
	Function UpdateMatchRatingAll:Int()
		For Local p:TPlayer = EachIn g_allplayers
			Local t:TTeam = p.GetMyTeam()
			Local pos:Int = t.formation.GetPosFromSelectionNo(p.selectionno)
			Local g1:Int = g_fixture.score1
			Local g2:Int = g_fixture.score2
			If t = g_awayteam
				g1 = g_fixture.score2
				g2 = g_fixture.score1
			EndIf
			p.matchstats.UpdateRating(pos, g1, g2, g_matchminute, p.GetMyTeam().rating, p.GetOppTeam().rating)
		Next
	End Function
