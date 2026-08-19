' TScreen_Continents.SetUpFixturesTable
' VA 0x00548244   1255 bytes   sig (i)i   KIND=Function (static)   class-table slot 0x4c
' byte-identical vs NSS5.exe
'
' a0 is a round id: called as `SetUpFixturesTable(g_contid)` (ButtonGroupsFirst/Left, both
' already in src/recovered), `SetUpFixturesTable(g_continents_comp.GetPrevRound())` /
' `.GetNextRound()` (ButtonRound), and with the Cup-round-navigation results of
' GetCupFirstRound/GetCupLastRound/GetCupPreviousRound/GetCupNextRound (ButtonFixtures*).
' Populates the two-column ("Home Team"/""/"Away Team") league-style fixtures table for
' round a0 of the current continents competition and group page, then re-selects whichever
' row is most relevant (today's fixture, else the first unplayed one, else the last played
' one, else row 0).
'
' GLOBALS (address is load-bearing; names taken from the SAME-Type siblings already in
' src/recovered/ and src/recovered_pending/ in preference to raw solver output where they
' disagree -- see NOTE below).
'   0x00C6720C g_continents_btnFixturesFirst:TButton  (TScreen_Continents.CreateScreen.bmx)
'   0x00C67210 g_continents_btnFixturesLeft:TButton   (CreateScreen.bmx)
'   0x00C67214 g_continents_btnRound:TButton          (CreateScreen.bmx)
'   0x00C67218 g_continents_btnFixturesRight:TButton  (CreateScreen.bmx)
'   0x00C6721C g_continents_btnFixturesLast:TButton   (CreateScreen.bmx)
'   0x00C671D0 g_continents_panFixtures:TPanel        (CreateScreen.bmx)
'   0x00C671D4 g_continents_tblFixturesLeague:TTable  (CreateScreen.bmx; adjudicated in
'     extracted/global_alias_adjudicated.tsv)
'   0x00C671D8 g_continents_tblFixturesClub:TTable    (CreateScreen.bmx; adjudicated)
'   0x00C67208 g_contid:Int       -- explain_global.py: tier=CERTAIN, 2 unanimous bodies
'     (ButtonGroupsFirst/Left, both `TScreen_Continents.SetUpFixturesTable(g_contid)` --
'     i.e. this is literally a0 at the call sites that pass the round-page global through).
'   0x00C671EC g_grouppage:Int    -- explain_global.py: tier=CERTAIN, 2 unanimous bodies;
'     same address/name TScreen_Continents.SetUpLeagueTable.bmx (recovered_pending) uses.
'   0x00C67220 g_continents_comp:TCompetition -- FOUR names are attested at this address
'     (g_comp/g_cont_comp/g_continents_comp/g_curcomp across different already-recovered
'     Continents bodies); following TScreen_Continents.SetUpLeagueTable.bmx's precedent
'     (recovered_pending, same Type, same address, explicitly reasoned there) and
'     TScreen_Continents.SetUpScreen.bmx / .ButtonGroup.bmx, both already byte-verified in
'     src/recovered, which also use g_continents_comp.
'   0x00C6F028 g_profile:TProfile -- solver: forced in 142 bodies (103/106 agree), by far
'     the dominant name corpus-wide; confirmed canonical in extracted/global_alias_adjudicated.tsv
'     ("g_profile is forced in 142 bodies ... " overriding g_contractoffer_tplayer etc).
'
' FIELDS (object_model.json byte offsets):
'   TCompetition .comptype+0x24 .name+0xc(:String) .level+0x1c .lfixturelist+0x60(:TList);
'     0xc0=GetFixtureDate(i):TMyDate  0xc4=GetNoofRounds()i
'   TFixture .sdate+8 .round+0x10 .groupno+0x14 .leg+0x18 .result+0x24;
'     0x48=GetStringArrayForLeague()[]$  0x70=GetHomeTeamId()i  0x74=GetAwayTeamId()i
'   TProfile .date+0x10(:TMyDate) .nationid+0x1c .clubid+0x20
'   TMyDate .sdate+8 (raw absolute day count, same representation TFixture.sdate uses);
'     0x38=SetDate(day,week,year)i  0x54=GetYear()i  0x5c=GetString($)$
'   TGadget (inherited by TButton/TPanel/TTable) 0x54=Hide()i 0x58=Show()i
'     0x64(100 decimal)=SetText($,$,i,i)i
'   TTable 0x9c=ClearItems()i 0x94=AddItem([]$,$,$)i 0xa0=SetColumnHeading(i,$)i
'     0xdc=SelectItemByRow(i)i
'   TList 0x8c=ObjectEnumerator() 0x30=HasNext()i 0x34=NextObject():Object
'
' MERGED CALLS (Ghidra folds a helper's real args together with the pushes for the call
' that follows it):
'   * FUN_00505B91 = LogLine (arity 1) -- matches src/recovered/TBossMessage.ClearAll.bmx.
'   * FUN_00505F6D = ClampInt(Varptr x, min, max) -- matches src/recovered/TPlayer.
'     AddPlayerRating.bmx's own header note ("FUN_00505B91 = LogLine; FUN_00505F6D =
'     ClampInt").
'   * FUN_004A7AC0 = String(Int) (arity 1), FUN_004C5549 = GetText (arity 1),
'     FUN_004A7C20 = _bbStringConcat (arity 2) x2, feeding TGadget.SetText($,$,i,i)i.
'     Literal reads (harness.read_string): 0x00C88748="SetUpFixturesTable" (the LogLine
'     call), 0x00C85448="Round", 0x00C6EF28=" ", 0x00C5D284="" (bbEmptyString/pooled empty
'     literal), 0x00C85010="WWWW", 0x00C88778="YY-WW". Reassembled:
'     `SetText(GetText("Round") + " " + String(g_contid), "", -1, -1)` -- the identical
'     shape TScreen_Continents.SetUpLeagueTable.bmx documents for its own
'     `SetText(GetText("Group") + " " + String(g_grouppage + 1), "", -1, -1)`.
'   * FUN_004A63D0(&DAT_00C59058, 2) = `New String[2]` -- the same String[]-array allocator
'     TDate.GetStringMonth/GetStringWeekday call with the classinfo constant at the same
'     address; the element stores at +0x18/+0x1c that follow are the array-literal element
'     writes (retain but no release of the old value, matching src/recovered_pending/
'     TScreen_Continents.SetUpLeagueTable.bmx and src/recovered/TScreen_Achievements.
'     SetUpScreen.bmx's `AddItem(["", a.txt, ...], ...)` idiom) -- written here as the
'     array literal `["", fxDate.GetString("WWWW")]`.
'   * FUN_004A8F60 = downcast, merged with the preceding TList+0x34 NextObject() call --
'     the standard `For Local fx:TFixture = EachIn g_continents_comp.lfixturelist` shape
'     (same idiom as TScreen_Continents.SetUpScreen.bmx's fixture loops).
'   * Both TTable.AddItem calls inside the loop pass Null,Null for the tag/icon args (the
'     decompiled operand is &PTR_PTR_005C7D40 both times, the runtime's shared
'     bbEmptyString -- the Null-lowered form, NOT the "" pooled-literal form at 0xC5D284
'     that the panel/column-heading calls above use).
'
' CONTROL FLOW.
'   * `fxDate.SetDate(fx.sdate, 1, 1)` reuses the SAME TMyDate g_continents_comp.
'     GetFixtureDate(g_contid) already returned (Method slot 0x38, not the Function
'     Create() at slot 0x30) -- it does not allocate a second TMyDate. Passing week=1,
'     year=1 zeroes both those terms of SetDate's `(year-1)*364+(week-1)*7+day` so the call
'     just copies fx.sdate into fxDate's raw day field, matching TMyDate.Create(day,1,1)'s
'     use for the exact same purpose in TScreen_Achievements.SetUpScreen.bmx.
'   * The round/group match test `fx.round = g_contid And fx.groupno = g_grouppage + 1`
'     and the leg-separator test `prevLeg < fx.leg And fx.leg = 2` are both the standard
'     bcc short-circuit-And codegen (a `bVar9 = false; if (cond1) bVar9 = cond2;` shape),
'     not independent nested Ifs.
'   * `homeId`/`awayId` (fx.GetHomeTeamId()/GetAwayTeamId()) are each called EXACTLY ONCE
'     per fixture, before the level branch, and reused inside whichever of the two branches
'     runs -- the decompiled call sites for both methods sit once, above the level dispatch,
'     not duplicated inside each branch.
'   * `Select g_continents_comp.level / Case 0 ... Case 1 ... End Select` (no Default): the
'     disasm loads the field into eax ONCE and emits both Case compares back to back (`cmp
'     eax,0/je Case0; cmp eax,1/je Case1; jmp EndSelect`) before either body runs, matching
'     codegen-patterns.md 10.2's Select signature exactly (a plain If/ElseIf interleaves
'     test and body and comes out shorter). Each Case body ends with its own `jmp
'     EndSelect`, including Case 1 (the last one), where that jump's target is the very next
'     instruction -- an explicit zero-offset `jmp` byte pair that a hand-written If/ElseIf's
'     final branch would never need, since Select always emits the jump regardless of case
'     position.
'   * Two more solo-relational If/Else sites here have two genuinely different bodies, so
'     codegen-patterns.md #21's negation-swap rule applies to both (confirmed against the
'     probe exe's disasm, not inferred): `g_continents_comp.comptype = 1` is actually written
'     `<> 1` with the Round-label/name branches swapped, and the fixture-date year match is
'     actually written `<>` with the WWWW/YY-WW branches swapped.
'   * The final row-selection tests are plain `selRow > 0` / `unplayedRow > 0` / `lastRow >
'     0` (`cmp reg,0 / jle`), not `>= 1` (`cmp reg,1 / jl`) -- same truth table, different
'     immediate and different jcc, and codegen-patterns.md 10.1 says match the jcc and its
'     immediate, not the meaning. Today's row still wins over first-unplayed, which still
'     wins over last-played, which still wins over row 0.
' Body-only format: statements only; this Function takes one parameter (a0:Int, the round id).
'!Global g_continents_btnFixturesFirst:TButton
'!Global g_continents_btnFixturesLeft:TButton
'!Global g_continents_btnRound:TButton
'!Global g_continents_btnFixturesRight:TButton
'!Global g_continents_btnFixturesLast:TButton
'!Global g_continents_panFixtures:TPanel
'!Global g_continents_tblFixturesClub:TTable
'!Global g_continents_tblFixturesLeague:TTable
'!Global g_contid:Int
'!Global g_continents_comp:TCompetition
'!Global g_profile:TProfile
'!Global g_grouppage:Int
LogLine("SetUpFixturesTable")
g_continents_btnFixturesFirst.Show()
g_continents_btnFixturesLeft.Show()
g_continents_btnRound.Show()
g_continents_btnFixturesRight.Show()
g_continents_btnFixturesLast.Show()
g_continents_panFixtures.SetText("", "", -1, -1)
g_continents_tblFixturesClub.Hide()
g_continents_tblFixturesLeague.Show()
g_continents_tblFixturesLeague.ClearItems()
g_contid = a0
ClampInt(Varptr g_contid, 1, g_continents_comp.GetNoofRounds())
If g_continents_comp.comptype <> 1 Then
	g_continents_btnRound.SetText(GetText("Round") + " " + String(g_contid), "", -1, -1)
Else
	g_continents_btnRound.SetText(g_continents_comp.name, "", -1, -1)
End If
g_continents_tblFixturesLeague.SetColumnHeading(1, "")
Local fxDate:TMyDate = g_continents_comp.GetFixtureDate(g_contid)
If fxDate <> Null Then
	If fxDate.GetYear() <> g_profile.date.GetYear() Then
		g_continents_tblFixturesLeague.SetColumnHeading(1, fxDate.GetString("YY-WW"))
	Else
		g_continents_tblFixturesLeague.SetColumnHeading(1, fxDate.GetString("WWWW"))
	End If
End If
Local selRow:Int = 0
Local lastRow:Int = 0
Local unplayedRow:Int = 0
Local row:Int = 0
Local prevLeg:Int = 0
For Local fx:TFixture = EachIn g_continents_comp.lfixturelist
	If fx.round = g_contid And fx.groupno = g_grouppage + 1 Then
		If fx.leg > prevLeg And fx.leg = 2 Then
			fxDate.SetDate(fx.sdate, 1, 1)
			g_continents_tblFixturesLeague.AddItem(["", fxDate.GetString("WWWW")], Null, Null)
			row = row + 1
		End If
		g_continents_tblFixturesLeague.AddItem(fx.GetStringArrayForLeague(), Null, Null)
		row = row + 1
		prevLeg = fx.leg
		Local homeId:Int = fx.GetHomeTeamId()
		Local awayId:Int = fx.GetAwayTeamId()
		Select g_continents_comp.level
			Case 0
				If homeId = g_profile.clubid Or awayId = g_profile.clubid Then
					If fx.sdate = g_profile.date.sdate Then selRow = row
					If fx.result = 0 And unplayedRow = 0 Then unplayedRow = row
					If fx.result = 1 Then lastRow = row
				End If
			Case 1
				If homeId = g_profile.nationid Or awayId = g_profile.nationid Then
					If fx.sdate = g_profile.date.sdate Then selRow = row
					If fx.result = 0 And unplayedRow = 0 Then unplayedRow = row
					If fx.result = 1 Then lastRow = row
				End If
		End Select
	End If
Next
If selRow > 0 Then
	g_continents_tblFixturesLeague.SelectItemByRow(selRow)
Else
	If unplayedRow > 0 Then
		g_continents_tblFixturesLeague.SelectItemByRow(unplayedRow)
	Else
		If lastRow > 0 Then
			g_continents_tblFixturesLeague.SelectItemByRow(lastRow)
		Else
			g_continents_tblFixturesLeague.SelectItemByRow(0)
		End If
	End If
End If
Return 0
