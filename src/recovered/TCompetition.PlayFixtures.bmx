' TCompetition.PlayFixtures
' VA 0x0050EED4   508 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, slot 0x120
' ASSUMPTIONS
'  * Globals (names ours; only the declared TYPE is load-bearing):
'      0x00C6099C g_competitions:TList   (globals_final says Object; slot 0x8c
'                                         ObjectEnumerator is used on it -> TList)
'      0x00C6F028 g_profile:TProfile     (typed from its construction site)
'  * TScreen_TestFixtures.CheckShowFixtures is reached through the class-table
'    slot call `FF 15 [0x00C66714]` = TScreen_TestFixtures+0x38, resolved on both sides.
'  * `If c.lfixturelist.IsEmpty() Then Continue` is the `74 05 / E9` shape at 0x0050EF51.
'  * The myclub test is the `If Not x` spelling (setne al / movzx / cmp / jne at
'    0x0050F050), not `= Null` -- guide 10.3.
'  * Both date comparisons put the fixture on the LEFT (`cmp [eax+8], edx`), so the
'    source is `f.sdate > ...` / `f.sdate <= ...`, and the pair really is emitted twice.
'  * Matched first attempt, reloc_masked=15.

'!Global g_competitions:TList
'!Global g_profile:TProfile

Function PlayFixtures:Int()
	LogLine("PlayFixtures")
	Local ret:Int = 0
	For Local c:TCompetition = EachIn g_competitions
		Local played:Int = 0
		If c.lfixturelist.IsEmpty() Then Continue
		Local allplayed:Int = 1
		For Local f:TFixture = EachIn c.lfixturelist
			If f.sdate > g_profile.date.sdate
				allplayed = 0
				Exit
			End If
			If f.sdate <= g_profile.date.sdate
				If f.result = -1
					played = 1
					f.result = 1
				End If
				If f.result = 0
					f.PlayFixture()
					played = 1
				End If
			End If
		Next
		If played
			c.SortFixtureList()
			If allplayed Then c.DoPromotionPlaces()
		End If
		If played
			If c.level = 1
				ret = 1
			ElseIf Not g_profile.myclub
				If TScreen_TestFixtures.CheckShowFixtures(c) Then ret = 1
			Else
				If c.locale = 1 Or c.based = g_profile.myclub.nationid Then ret = 1
			End If
		End If
	Next
	Return ret
End Function
