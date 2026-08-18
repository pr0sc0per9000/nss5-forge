' TScreen_Leagues.SetUpLeagueFixtures
' VA 0x00545C5D   1420 bytes   KIND=Function (static, no Self)   SIG=(i)i   class-table slot 0x50
' byte-identical vs NSS5.exe (1420/1420)
' a0 = the round/page number to display (stored into g_leagues_page immediately).
'
' RECONSTRUCTION NOTES (verified against raw disassembly at 0x00545C5D, not just Ghidra's
' pseudo-C, because this body is thick with the merged-argument trap):
'   * The two FUN_005b9690 (_bbFloatToInt) chains feeding each TGadget.SetPosition (slot
'     0x84) each truly take ONE argument; the extra push shown by Ghidra on the first call
'     of each pair is really the LAST-pushed SetPosition arg (the "1" / "y" value) sitting
'     on the stack early. Confirmed by walking `add esp,N` after every call.
'   * FUN_004a7ac0/004c5549/004a7c20 in the non-cup branch are the well known
'     _bbStringFromInt / GetText / _bbStringConcat trio (runtime_helpers.tsv); GetText only
'     ever consumes ONE pushed string ("Round"), the surrounding pushes belong to the two
'     _bbStringConcat calls that follow. Source: GetText("Round") + " " + g_leagues_page.
'   * FUN_004a8f60 is the object-downcast helper; the classtable arg (0x00C5A2A0 = TFixture,
'     class_tables.tsv) is pushed BEFORE the preceding TListEnumerator.NextObject() call and
'     consumed only by the downcast, per the merged-argument trap.
'   * FUN_004a63d0 = _bbArrayNew1D (already named, src/recovered/TFormation.New.bmx); here
'     `_bbArrayNew1D("$", 2)` (0x00C59058 = the C string "$", globals_corrections.tsv row for
'     0x00C63990) building a 2-element String[] is just the array-literal
'     ["", fdate.GetString("WWWW")] passed straight into TTable.AddItem.
'   * DAT_00C5D288 is NOT a Global counter -- it is literally the refcount word of the ""
'     string literal at 0x00C5D284 (confirmed for
'     the sibling TFixture.GetStringArrayForLeague). The `+= 1` is just the retain half of
'     storing "" into the array literal and needs no source-level representation.
'   * &DAT_005C9C80 compares are ordinary `<> Null` (confirmed against
'     TScreen_Leagues.ButtonFixturesFirst's decompile, which compiles `g_leagues_comp <>
'     Null` to the identical `cmp ..., 0x5C9C80`), not just downcast-failure sentinels.
'   * Slot arithmetic used below, all from vtable_map.tsv / object_model.json: TGadget 0x54
'     Hide, 0x58 Show, 0x64 SetText($,$,i,i), 0x84 SetPosition(i,i,i); TTable 0x94 AddItem
'     ([]$,$,$), 0x9c ClearItems, 0xa0 SetColumnHeading(i,$), 0xdc SelectItemByRow(i);
'     TCompetition 0xc0 GetFixtureDate(i):TMyDate, 0xc4 GetNoofRounds, 0xd4
'     AllFixturesPopulated, name@+0xc, comptype@+0x24, level@+0x1c, lfixturelist@+0x60;
'     TMyDate 0x38 SetDate(i,i,i), 0x5c GetString($), sdate@+8; TFixture 0x48
'     GetStringArrayForLeague, 0x70 GetHomeTeamId, 0x74 GetAwayTeamId, sdate@+8, round@+0x10,
'     leg@+0x18, result@+0x24; TProfile date@+0x10, nationid@+0x1c, clubid@+0x20.
'   * g_screen_int21 (0x00C6EFDC) is the canonical name for this address (see
'     src/recovered/TScreen.UpdateOffset.bmx and the many CreateScreen bodies citing "the
'     established convention"); explain_global.py's address index still shows the older
'     names (g_screen_height/g_screen_y) because global_address_map.tsv predates that rename.
'   * g_leagues_comp (not g_screen_leagues_comp) is the adjudicated winner for 0x00C66F5C
'     per extracted/unify_work/verdicts.json (g_league_comp merge-into decision).
'   * g_lg_table2/g_lg_table3 (not g_screen_leagues_tplayer02/03) are the CERTAIN-tier names
'     for 0x00C66F24/0x00C66F28 (2 unanimous bodies each, vs 1 STRONG-tier body each).
'   * The EachIn loop over lfixturelist relies entirely on EachIn's own implicit null-skip
'     (`cmp edi,0x5C9C80 / je LOOP_BOTTOM`) on the downcast result; the very next instruction
'     reads `f.round` directly with no second cmp/sete/movzx/cmp/je sequence, so the loop body
'     is not wrapped in its own explicit `If f <> Null Then ... EndIf`.
'   * The comptype guard is a solo-relational If/Else with distinct branches, so it carries
'     the negate-and-swap shape (guide 21): `cmp [comptype],1 / je HIDE_BLOCK` reads as
'     `If comptype <> 1 Then <Show/"Round N"> Else <Hide/comp-name> EndIf`, with the Show/
'     "Round N" body placed fall-through and the Hide/comp-name body placed behind the jump.
'   * `f.leg > lastleg` is one term of a compound Or, which is excluded from the negate/swap
'     shape (guide 21): `mov eax,[edi+0x18] / cmp eax,esi / setg` puts f.leg (the freshly
'     loaded field) first and lastleg (already resident in esi across loop iterations) second,
'     direct operand order per guide 10.1, no negation.
'   * `Select g_leagues_comp.level` (Case 0 / Case 1, no Default), not `If/ElseIf`: the level
'     field is loaded once (`mov eax,[g_leagues_comp] / mov eax,[eax+0x1c]`) and both Case
'     tests cascade off that one load with no re-fetch, the guide 10.2 Select shape.
'   * The todayrow/unplayedrow/lastplayedrow cascade at the end is three solo-relational
'     If/Else levels, each carrying the same negate-and-swap shape as the comptype guard:
'     `cmp [todayrow],0 / jle NESTED` puts the direct `SelectItemByRow(x)` call fall-through
'     and the next nested level behind the jump, i.e. `If x > 0 Then SelectItemByRow(x) Else
'     <next level> EndIf` at every level, terminating in `If lastplayedrow > 0 Then
'     SelectItemByRow(lastplayedrow) Else SelectItemByRow(0) EndIf`.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_object468:TButton
'!Global g_object469:TButton
'!Global g_object470:TButton
'!Global g_object471:TButton
'!Global g_object472:TButton
'!Global g_lg_table3:TTable
'!Global g_lg_table2:TTable
'!Global g_object462:TPanel
'!Global g_leagues_page:Int
'!Global g_leagues_comp:TCompetition
'!Global g_shared_panel1:TPanel
'!Global g_screen_int21:Int
'!Global g_profile:TProfile
g_object468.Show()
g_object469.Show()
g_object470.Show()
g_object471.Show()
g_object472.Show()
g_lg_table3.Hide()
g_lg_table2.Show()
g_lg_table2.ClearItems()
g_object462.SetText("", "", -1, -1)
g_leagues_page = a0
ClampInt(Varptr g_leagues_page, 1, g_leagues_comp.GetNoofRounds())
If g_leagues_comp.comptype <> 1 Then
	g_shared_panel1.Show()
	g_object462.SetPosition(Int(g_screen_int21 - g_object462.w - 10.0), Int(g_object462.y), 1)
	g_object470.SetText(GetText("Round") + " " + g_leagues_page, "", -1, -1)
Else
	g_shared_panel1.Hide()
	g_object462.SetPosition(Int(g_screen_int21 / 2 - g_object462.w / 2.0), Int(g_object462.y), 1)
	g_object470.SetText(g_leagues_comp.name, "", -1, -1)
EndIf
Local fdate:TMyDate = g_leagues_comp.GetFixtureDate(g_leagues_page)
If fdate <> Null Then
	g_lg_table2.SetColumnHeading(1, fdate.GetString("WWWW"))
EndIf
Local todayrow:Int = 0
Local lastplayedrow:Int = 0
Local unplayedrow:Int = 0
Local rowcount:Int = 0
Local lastleg:Int = 0
If g_leagues_comp.comptype <> 1 Or g_leagues_comp.AllFixturesPopulated() Then
	For Local f:TFixture = EachIn g_leagues_comp.lfixturelist
		If f.round = g_leagues_page Or g_leagues_comp.comptype = 1 Then
			If (f.leg > lastleg And f.leg = 2) Or f.sdate > fdate.sdate Then
				fdate.SetDate(f.sdate, 1, 1)
				g_lg_table2.AddItem(["", fdate.GetString("WWWW")], "", "")
				rowcount :+ 1
			EndIf
			g_lg_table2.AddItem(f.GetStringArrayForLeague(), "", "")
			rowcount :+ 1
			lastleg = f.leg
			Local hometeam:Int = f.GetHomeTeamId()
			Local awayteam:Int = f.GetAwayTeamId()
			Select g_leagues_comp.level
				Case 0
					If hometeam = g_profile.clubid Or awayteam = g_profile.clubid Then
						If f.sdate = g_profile.date.sdate Then todayrow = rowcount
						If f.result = 0 And unplayedrow = 0 Then unplayedrow = rowcount
						If f.result = 1 Then lastplayedrow = rowcount
					EndIf
				Case 1
					If hometeam = g_profile.nationid Or awayteam = g_profile.nationid Then
						If f.sdate = g_profile.date.sdate Then todayrow = rowcount
						If f.result = 0 And unplayedrow = 0 Then unplayedrow = rowcount
						If f.result = 1 Then lastplayedrow = rowcount
					EndIf
			End Select
		EndIf
	Next
	If todayrow > 0 Then
		g_lg_table2.SelectItemByRow(todayrow)
	Else
		If unplayedrow > 0 Then
			g_lg_table2.SelectItemByRow(unplayedrow)
		Else
			If lastplayedrow > 0 Then
				g_lg_table2.SelectItemByRow(lastplayedrow)
			Else
				g_lg_table2.SelectItemByRow(0)
			EndIf
		EndIf
	EndIf
EndIf
Return 0
