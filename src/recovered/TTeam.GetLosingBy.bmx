' TTeam.GetLosingBy
' VA 0x004E1EB2   110 bytes   vtable slot 0x98   sig ()i
' byte-identical vs NSS5.exe (110/110, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C5B22C is a TFixture (it is called at slot 0x50 = GetFirstLegScore(*i,*i)i and read at
' +0x2C/+0x30 = score1/score2). globals_final types it TPlayer from usage -- that is wrong.
' 0x00C5B218 is a TTeam (compared for identity against Self); globals_final flags a
' TKit/TTeam construction conflict on it, and TTeam is the member that fits here.
' `theirs`/`mine` are register-allocated Int Locals -- writing back into s1 instead costs 9 bytes.
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_hometeam:TTeam
'   Global g_fixture:TFixture
	Method GetLosingBy:Int()
		'!Global g_fixture:TFixture
		'!Global g_hometeam:TTeam
		Local s1:Int = 0
		Local s2:Int = 0
		g_fixture.GetFirstLegScore(Varptr s1, Varptr s2)
		Local theirs:Int
		Local mine:Int
		If g_hometeam = Self Then
			theirs = g_fixture.score1 + s2
			mine = g_fixture.score2 + s1
		Else
			theirs = g_fixture.score2 + s1
			mine = g_fixture.score1 + s2
		End If
		Return mine - theirs
	End Method
