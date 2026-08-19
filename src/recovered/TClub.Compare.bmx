' TClub.Compare
' VA 0x004C2578   1319 bytes   vtable slot 0x1c   sig (:Object)i
' byte-identical vs NSS5.exe (1319/1319, original length from Ghidra's inventory, mode=reloc)
'
' g_club_int01:Int at 0x00C59A48 selects the sort key, same pattern as
' TBase_Team.Compare's g_screen_continents_int01. Falls through to an id
' compare + Super.Compare(a0) after the Select regardless of which Case ran
' (or none), matching TBase_Team.Compare's shape.
'
' Two ORIGINAL BUGS reproduced faithfully:
'  - Case 20 (nationid) compares Self.name against TClub(a0).labelname, not
'    TClub(a0).name -- different fields on the two sides.
'  - Case 34's trailing strength tie-break is REVERSED relative to every
'    other numeric field in this function: "If strength < other.strength
'    Then Return 1" (lower strength sorts first), confirmed from the actual
'    cmp/jge bytes, not from Ghidra's decompiled sense (Ghidra's comparison
'    direction is not reliable -- codegen-patterns.md 10.1).
'
' Case 5 (randno) and Case 34's compstatus/strength tie-breaks needed the
' downcast-side operand written FIRST to match the compiler's operand order
' (same phenomenon as codegen-patterns.md 10.1); every other Case keeps
' Self as the first operand, matching TBase_Team.Compare's house style.
'
' TCompetition.SelectById(id) returning Null is tested with "If Not c",
' which is codegen-patterns.md 10.3's LONG inverted-sense form (confirmed
' by the extra fxch/setne/movzx/cmp/jne bytes) -- not "If c = Null".
'
' Case 35's home-nation strength bonus is written as short-circuit And
' chains (no intermediate Boolean locals) -- the original computes each
' term inline and branches immediately; the decompiled bVar5/bVar6 locals
' are Ghidra's rendering of BlitzMax's short-circuit And, not real Locals.
	Method Compare:Int(a0:Object)
		'!Global g_club_int01:Int
		'!Global g_profile:TProfile
		Select g_club_int01
			Case 1
				If id > TClub(a0).id Then Return 1
				If id < TClub(a0).id Then Return -1
			Case 2
				If labelname > TClub(a0).labelname Then Return 1
				If labelname < TClub(a0).labelname Then Return -1
			Case 11
				If strength > TClub(a0).strength Then Return 1
				If strength < TClub(a0).strength Then Return -1
			Case 5
				If TClub(a0).randno < randno Then Return 1
				If TClub(a0).randno > randno Then Return -1
			Case 20
				If nationid > TClub(a0).nationid Then Return 1
				If nationid < TClub(a0).nationid Then Return -1
				If name > TClub(a0).labelname Then Return 1
				If name < TClub(a0).labelname Then Return -1
			Case 21
				If leagueid > TClub(a0).leagueid Then Return 1
				If leagueid < TClub(a0).leagueid Then Return -1
			Case 33
				If stadiumcapacity > TClub(a0).stadiumcapacity Then Return 1
				If stadiumcapacity < TClub(a0).stadiumcapacity Then Return -1
			Case 34
				Local c0:TCompetition = TCompetition.SelectById(leagueid)
				Local c1:TCompetition = TCompetition.SelectById(TClub(a0).leagueid)
				If Not c0 Then Return -1
				If Not c1 Then Return 1
				If c0.compstatus = 0 Then Return 1
				If c1.compstatus = 0 Then Return -1
				If c0.compstatus > c1.compstatus Then Return 1
				If c0.compstatus < c1.compstatus Then Return -1
				If strength < TClub(a0).strength Then Return 1
				If strength > TClub(a0).strength Then Return -1
			Case 35
				Local v0:Float = strength
				Local v1:Float = TClub(a0).strength
				If strength < 80 And nationid = g_profile.myclub.nationid And TClub(a0).nationid <> g_profile.myclub.nationid
					v0 = v0 + 1.0
				Else If TClub(a0).strength < 80 And TClub(a0).nationid = g_profile.myclub.nationid And nationid <> g_profile.myclub.nationid
					v1 = v1 + 1.0
				EndIf
				If v0 > v1 Then Return 1
				If v0 < v1 Then Return -1
		End Select
		If id > TClub(a0).id Then Return 1
		If id < TClub(a0).id Then Return -1
		Return Super.Compare(a0)
	End Method
