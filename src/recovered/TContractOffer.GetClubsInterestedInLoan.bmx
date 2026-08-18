' TContractOffer.GetClubsInterestedInLoan
' VA 0x00572A53   509 bytes   vtable slot 0x60   sig ():TList   KIND=Function
' byte-identical vs NSS5.exe (509/509, original length from Ghidra's inventory)
' Builds the shortlist of clubs that would take the player on loan, stopping at 5.
'
' ASSUMPTIONS
'  Direct calls resolved:
'    0x00505B91 LogLine; literal at 0x00C8FAE4 read with harness.read_string =
'      "GetClubsInterestedInLoan" (function-entry trace, codegen-patterns 3g)
'    0x005B40BF alias set -> CreateList()  (confirmed by the following AddLast at slot 0x44,
'      codegen-patterns 10.8)
'    0x004A8F60 _bbObjectDowncast (the EachIn downcast)
'  Class-table slot calls:
'    0x00C59E40 TClub+0x94        SortListBy(i,i)i
'    0x00C6B81C TContractOffer+0x64 GetPlayerValueStatus()i -- this Type's own table, so
'                                    written unqualified as a sibling Function
'    0x00C6160C TCompetition+0x4C SelectById(i):TCompetition
'    0x00C59A20 TNation+0x58      SelectById(i):TNation
'    TProfile slot 0xA0 = GetAge()i -- called for effect, result discarded
'    TClub slot 0x80 = CountFixturesRemaining()i
'    TList slots 0x44 AddLast / 0x70 Count / 0x8C ObjectEnumerator / 0x30,0x34 the enum
'  Module Globals (names ours, types load-bearing):
'    0x00C6F028 g_profile:TProfile  (globals_final, typed from its construction site)
'    0x00C59A44 g_clubs:TList       (globals_final says bare Object; slot 0x8C
'                                    ObjectEnumerator is used on it -> TList)
'  Field offsets: TClub id 0x0C / strength 0x24 are inherited from TBase_Team;
'    leagueid 0x68. TCompetition id 0x08, based 0x20, duration 0x30. TNation id 0x0C
'    (TBase_Team), continent 0x64. TProfile clubid 0x20, myclub 0x1D0,
'    desiredcontinentid 0x138, desirednationid 0x13C, desiredleagueid 0x140,
'    desiredclubid 0x144.
' SHAPE NOTES (byte-observable)
'  * The four "desired" filters NEST -- each `If g_profile.desiredX > 0` jle-jumps to the
'    SAME label (the CountFixturesRemaining test), and each inner mismatch is a `Continue`.
'  * `If Not comp Or comp.duration < 10 Then Continue` -- the double negation
'    (setne/movzx then sete/movzx) is `Not comp` used as an Or operand, not `comp = Null`.
'  * The 5-club cap is `Exit`, not `Return l`: both paths converge on one `mov eax,[ebp-4]`.
'  * sub esp,0xC = three slots (l, the enumerator, status); c/comp/n live in esi/ebx/eax.
	Function GetClubsInterestedInLoan:TList()
		'!Global g_profile:TProfile
		'!Global g_clubs:TList
		LogLine("GetClubsInterestedInLoan")
		TClub.SortListBy(11, 0)
		Local l:TList = CreateList()
		g_profile.GetAge()
		Local status:Int = GetPlayerValueStatus()
		For Local c:TClub = EachIn g_clubs
			If c.id <> g_profile.clubid And c.strength <= g_profile.myclub.strength And c.strength <= status - 5
				Local comp:TCompetition = TCompetition.SelectById(c.leagueid)
				If Not comp Or comp.duration < 10 Then Continue
				If g_profile.desiredcontinentid > 0
					Local n:TNation = TNation.SelectById(comp.based)
					If n.continent <> g_profile.desiredcontinentid Then Continue
					If g_profile.desirednationid > 0
						If n.id <> g_profile.desirednationid Then Continue
						If g_profile.desiredleagueid > 0
							If comp.id <> g_profile.desiredleagueid Then Continue
							If g_profile.desiredclubid > 0
								If c.id <> g_profile.desiredclubid Then Continue
							EndIf
						EndIf
					EndIf
				EndIf
				If c.CountFixturesRemaining() > 4
					l.AddLast(c)
				EndIf
			EndIf
			If l.Count() >= 5 Then Exit
		Next
		Return l
	End Function
