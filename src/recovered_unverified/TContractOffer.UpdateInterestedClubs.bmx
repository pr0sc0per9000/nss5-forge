' TContractOffer.UpdateInterestedClubs
' VA 0x00572643   1040 bytes   vtable slot 0x5c   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe
'
' ASSUMPTIONS
'   Module Globals (names ours, resolved via explain_global.py / globals_final):
'     0x00C6F028 g_profile:TProfile   -- same slot as every other TContractOffer body,
'       confirmed via TContractOffer.EraseInterestedClubs.bmx / GetClubsInterestedInLoan.bmx
'     0x00C59A44 g_clubs:TList        -- same slot GetClubsInterestedInLoan.bmx iterates
'     0x00C6B428 g_contractoffers:TList -- same slot TContractOffer.GetOffer.bmx uses
'   Direct calls resolved (matches sibling GetClubsInterestedInLoan.bmx's own table):
'     0x00505B91 LogLine; literal at 0x00C8FA8C read with harness.read_string =
'       "UpdateInterestedClubs" (function-entry trace). A second literal at 0x00C8FAC4
'       reads "mystatus:", the prefix for `LogLine("mystatus:" + status)`.
'     0x005B40BF CreateList()
'     0x004A8F60 _bbObjectDowncast (every EachIn / RemoveFirst downcast below)
'     0x004A7AC0 / 0x004A7C20 int->string + string-concat -- the runtime pair behind the
'       plain `"prefix" + intValue` operator (same pair GetPlayerValueStatus.bmx's own
'       LogLine calls compile to; no explicit String() needed in source)
'   Class-table slot calls (vtable_map.tsv / class_tables.tsv):
'     0x00C59E0C TClub+0x60      SelectById(i):TClub
'     0x00C59E40 TClub+0x94      SortListBy(i,i)i
'     0x00C6160C TCompetition+0x4C SelectById(i):TCompetition
'     0x00C59A20 TNation+0x58    SelectById(i):TNation
'     TProfile slot 0x148 = TooSoonSinceLastContract()i (own byte-verified body)
'     TProfile slot 0xA0  = GetAge()i -- called for effect, result discarded (same idiom
'       as GetClubsInterestedInLoan.bmx's own `g_profile.GetAge()`)
'     TContractOffer slot 0x64 = GetPlayerValueStatus()i -- this Type's own table, so
'       written unqualified as a sibling Function (GetClubsInterestedInLoan.bmx does the
'       same)
'     TList slots 0x8C ObjectEnumerator / 0x30 HasNext / 0x34 NextObject (the EachIn
'       downcasts, twice: TClub over g_clubs, TContractOffer over g_contractoffers -- the
'       TContractOffer class-table pointer is 0x00C6B7B8, confirmed against GetOffer.bmx's
'       own `New TContractOffer` / EachIn use of the identical address) / 0x44 AddLast /
'       0x70 Count / 0x38 IsEmpty / 0x50 RemoveFirst.
'   Field offsets (object_model.json): TProfile interestedclubs[]i @0x1A4, myclub:TClub
'     @0x1D0, transferlisted @0x134, onloanfrom @0x148, mynation:TNation @0x1CC,
'     desiredcontinentid @0x138, desirednationid @0x13C, desiredleagueid @0x140,
'     desiredclubid @0x144. TClub/TBase_Team id @0xC, strength @0x24, nationid @0x64,
'     leagueid @0x68. TCompetition id @0x8, based @0x20, duration @0x30. TNation id @0xC
'     (TBase_Team), continent @0x64. TContractOffer club:TClub @0x8, newbossrel @0x24.
'
' SHAPE NOTES (byte-observable, cross-checked against GetClubsInterestedInLoan.bmx)
'   * The five-slot reset loop is INLINE (a plain store loop over interestedclubs[i]=0),
'     not a call to the sibling EraseInterestedClubs() -- there is no call instruction to
'     0x00571DC9 anywhere in this function.
'   * `TNation.SelectById(c.nationid)` is called separately for the id-check and the
'     continent-check (two distinct call sites in the original) -- bcc does no CSE, so no
'     Local caches the nation between them (same rule GetPlayerValueStatus.bmx documents
'     for GetSkillRating()/GetFame()).
'   * The `desiredcontinentid/desirednationid/desiredleagueid/desiredclubid` cascade is
'     copied verbatim from GetClubsInterestedInLoan.bmx -- same nesting, same `Continue`
'     targets, same `n:TNation = TNation.SelectById(comp.based)` Local.
'   * The 5-club cap on `l` is `Exit`, same idiom as GetClubsInterestedInLoan.bmx's own
'     `If l.Count() >= 5 Then Exit` -- EXCEPT here bcc also guards it (and the whole
'     redistribution loop below) with an `l <> Null And` / `If l <> Null` check that the
'     sibling function's decompile does not have (`if (piVar3 != &DAT_005c9c80)` wraps
'     both the Count() test at 0x005729xx and the final `for` at LAB_005729e8) -- `l` is
'     always non-Null in practice (fresh off CreateList()) so this is dead defensive code
'     in the original, reproduced verbatim rather than dropped.
'   * Likewise the `g_contractoffers` EachIn is gated `g_contractoffers <> Null And Not
'     g_contractoffers.IsEmpty()`, not just `Not IsEmpty()` -- the decompile's
'     `if (PTR_DAT_00c6b428 != &DAT_005c9c80) { bVar10 = IsEmpty()==0 }` is the standard
'     `bVar=false; if(guard){bVar=rhs}` shape for a two-term short-circuit `And` (same shape
'     as TPlayer.UpdateKeeperPosition's `ball.jumpx <> 0.0 And ...`), not the double-negation
'     `Not X` shape (10.3) -- so `<> Null`, not `Not g_contractoffers`, is the right form.
'   * No CountFixturesRemaining() gate here (unlike GetClubsInterestedInLoan) -- a
'     candidate club is skipped only if an existing g_contractoffers entry for that same
'     club with newbossrel = 0 is already pending.
'!Global g_profile:TProfile
'!Global g_clubs:TList
'!Global g_contractoffers:TList
	LogLine("UpdateInterestedClubs")
	For Local i:Int = 0 To 4
		g_profile.interestedclubs[i] = 0
	Next
	If g_profile.TooSoonSinceLastContract() Then Return 0
	Local club:TClub = g_profile.myclub
	If g_profile.transferlisted = 4
		club = TClub.SelectById(g_profile.onloanfrom)
	EndIf
	g_profile.GetAge()
	Local status:Int = GetPlayerValueStatus()
	LogLine("mystatus:" + status)
	TClub.SortListBy(35, 0)
	Local l:TList = CreateList()
	For Local c:TClub = EachIn g_clubs
		If c.id <> club.id And c.strength <= status
			Local comp:TCompetition = TCompetition.SelectById(c.leagueid)
			If Not comp Or comp.duration < 10 Then Continue
			If status < 50 And TNation.SelectById(c.nationid).id <> club.nationid Then Continue
			If status < 60 And TNation.SelectById(c.nationid).continent <> g_profile.mynation.continent Then Continue
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
			Local found:Int = False
			If g_contractoffers <> Null And Not g_contractoffers.IsEmpty()
				For Local o:TContractOffer = EachIn g_contractoffers
					If c.id = o.club.id And o.newbossrel = 0
						found = True
						Exit
					EndIf
				Next
			EndIf
			If Not found Then l.AddLast(c)
		EndIf
		If l <> Null And l.Count() >= 5 Then Exit
	Next
	If l <> Null
		For Local i:Int = 0 To 4
			If Not l.IsEmpty()
				Local c:TClub = TClub(l.RemoveFirst())
				If c <> Null
					g_profile.interestedclubs[i] = c.id
				EndIf
			EndIf
		Next
	EndIf
	Return 0
