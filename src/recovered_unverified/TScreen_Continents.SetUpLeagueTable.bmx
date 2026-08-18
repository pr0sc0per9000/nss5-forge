' TScreen_Continents.SetUpLeagueTable
' VA 0x00548970   1433 bytes   sig ()i   KIND=Function (static)   class-table slot 0x64
'
' Own-Type callback: called bare as `SetUpLeagueTable()` from TScreen_Continents.ButtonGroup
' (src/recovered/TScreen_Continents.ButtonGroup.bmx). Near-twin of the already-recovered
' TScreen_Leagues.SetUpLeagueTable (VA 0x005459FF) -- same table-population idiom, same
' merged-call shapes -- used as the primary style/field template below.
'
' GLOBALS (address is load-bearing; names taken from the SAME-Type siblings already in
' src/recovered/ -- TScreen_Continents.CreateScreen.bmx and .SetUpScreen.bmx -- in
' preference to explain_global.py's solver output where the two disagree; see NOTE below).
'   0x00C671C8 g_continents_panTable:TPanel      (TScreen_Continents.CreateScreen.bmx)
'   0x00C671CC g_table_league:TTable  -- CORRECTED this pass. The prior name here,
'     g_continents_tblTable (taken from CreateScreen.bmx's own comment), is contradicted
'     by hard evidence: the score report's first-difference byte (offset 10, right after
'     the prologue) showed our compiled `mov eax,[addr]` for THIS call loading 0x00CA6C50
'     instead of the original's 0x00C671CC -- i.e. that name is not the one this project's
'     current global table resolves to this slot, so it silently created a second, wrong
'     Global instead of aliasing the real one (exactly the defect the task brief warns
'     about). `python scripts/explain_global.py 0x00C671CC` resolves this address to
'     g_table_league:TTable at STRONG tier, sourced from TScreen_Continents.ComboContinent
'     (src/recovered/, byte-identical, PAIRED with a real original at VA 0x00547A20) --
'     `g_table_league.ClearItems()` is that body's own line 2. That is strictly stronger
'     evidence than CreateScreen.bmx's un-paired prose comment, so g_table_league wins
'     here per this task's explicit global-naming rule; CreateScreen.bmx's own use of the
'     other name is a pre-existing inconsistency in the corpus, out of scope for this file.
'   0x00C671D0 g_continents_panFixtures:TPanel   (TScreen_Continents.CreateScreen.bmx)
'   0x00C671E8 g_continents_cmbTeam:TCombo       (TScreen_Continents.CreateScreen.bmx/.SetUpScreen.bmx)
'   0x00C671F0 g_continents_btnGroupsFirst:TButton
'   0x00C671F4 g_continents_btnGroupsLeft:TButton
'   0x00C671F8 g_continents_btnGroup:TButton
'   0x00C671FC g_continents_btnGroupsRight:TButton
'   0x00C67200 g_continents_btnGroupsLast:TButton
'   0x00C671EC g_grouppage:Int   -- explain_global.py: tier=CERTAIN, 2 unanimous bodies
'     (TScreen_Continents.ButtonGroupsFirst/Left), exactly this "clamp then use as a
'     teampool[] index" role; the other 3 names resolved at this address are for
'     unrelated Continents Functions (ButtonGroup/ButtonGroupsLast/ComboCompetition).
'   0x00C67220 g_continents_comp:TCompetition    (TScreen_Continents.SetUpScreen.bmx,
'     .ButtonGroup.bmx -- both same-Type, both already recovered)
'   0x00C6F028 g_profile:TProfile                (TScreen_Continents.SetUpScreen.bmx,
'     .ButtonGroup.bmx)
'   0x00C6EFDC g_screenwidth:Int                 (TScreen_Continents.CreateScreen.bmx,
'     pushed as CreatePanel's `w`; this body's own usage -- halved and subtracted from a
'     panel width to horizontally CENTRE a panel -- is only sensible as a width, confirming
'     the name over explain_global's g_screen_height/g_screen_y, which come from unrelated
'     Types (TScreen_Kits/TScreen_Pairs/TScreen_Newspaper/TSlotMachine) and, per those
'     bodies' own PROSE comments, are themselves disputed between width and height at this
'     address.)
' NOTE on the two explain_global.py disagreements above (g_grouppage's siblings are
' unanimous so there is no real dispute there; the g_screenwidth one is the only place this
' body picks a name explain_global.py did not surface for THIS address) -- both choices
' favour the same-Type, already-recovered sibling per the task's own source ranking
' (recovered siblings of the same Type outrank the solver's cross-Type sample).
'
' FIELDS (object_model.json byte offsets):
'   TGadget(TButton/TPanel) .y+0x24 .w+0x2c (both Float); 0x54=Hide()i 0x58=Show()i
'     0x84=SetPosition(i,i,i)i (inherited by TButton/TPanel)
'   TCompetition .comptype+0x24 .level+0x1c .teampool+0x6c ([]:TTeamPool); 0xec=
'     PaintPromotionPlaces(:TTable)i
'   TTeamPool .list+0x8 ([]:TTeamPool element, TList); 0x5c=SortTableBy(i)i
'   TTableData 0x3c=GetStringArray(i,i)[]$
'   TTable .selecteditem+0x70; 0x9c=ClearItems()i 0x94=AddItem([]$,$,$)i
'     0xe0=SelectItemByText($,i)i
'   TCombo 0xc0=GetSelectedItemId()i
'   TProfile .myclub+0x1d0(:TClub) .mynation+0x1cc(:TNation)
'   TBase_Team (inherited by TClub/TNation) .tla+0x18 .labelname+0x1c .labelshortname+0x20
'   TList 0x8c=ObjectEnumerator() 0x30=HasNext()i 0x34=NextObject():Object
'   TClub/TNation Functions SelectById(i):<Type> via class-table cells 0x00C59E0C/0x00C59A20
'
' MERGED CALLS (Ghidra folds a helper's real args together with the pushes for the call
' that follows it -- guide's "call arguments reversed/merged" trap, resolved the same way
' TScreen_Leagues.SetUpLeagueTable.bmx and TPanel_Controls.RenderTraining.bmx were):
'   * FUN_005B9690 = _bbFloatToInt (`Int(x)`, true arity 1). Two back-to-back calls whose
'     visible 2nd argument is really the FOLLOWING TGadget.SetPosition(i,i,i)i call's other
'     arguments: `SetPosition(Int(<2nd FUN_005B9690's arg>), Int(<1st FUN_005B9690's arg>),
'     <1st call's literal 2nd arg>)` -- confirmed against TPanel_Controls.RenderTraining's
'     identical shape, already recovered as `SetPosition(Int(a0), Int(a1), 1)`.
'   * FUN_004A7AC0 = _bbStringFromInt (arity 1), FUN_004C5549 = GetText (arity 1),
'     FUN_004A7C20 = _bbStringConcat (arity 2) x2, feeding TGadget.SetText($,$,i,i)i (slot
'     0x64=100=0x64 decimal). Literal reads (harness.read_string): 0x00C70EBC="Group",
'     0x00C6EF28=" ", 0x00C5D284="" (bbEmptyString/pooled empty literal). Reassembled:
'     `SetText(GetText("Group") + " " + String(g_grouppage + 1), "", -1, -1)`.
'   * FUN_004A8F60 = _bbObjectDowncast (arity 2, classtable 0x00C64B80 = TTableData) merged
'     with the preceding TList+0x34 NextObject()() call -- this triple (ObjectEnumerator/
'     HasNext/NextObject+downcast, with the "downcast failed -> skip body" Null guard) is
'     exactly `For Local td:TTableData = EachIn <TList>` (matches TScreen_Leagues's
'     identical loop, byte-identical there).
'
' CONTROL FLOW.
'   * The outer `comptype<>0 And comptype<>4` / `ElseIf teampool` test reads
'     g_continents_comp.comptype from memory TWICE (two independent `*(int*)(...+0x24)`
'     dereferences) -- the natural codegen for a literal `If A<>0 And A<>4` (bcc has no CSE,
'     confirmed independently by TTraining.ResetTraining.bmx's header note). No Null guard
'     on g_continents_comp anywhere in this body -- it relies on release-build
'     null-deref-returns-0 (guide 18.26) for safety when there is no current competition;
'     preserved as found.
'   * The `comptype<>1,2,3,5` dispatch is the OPPOSITE shape: ONE read into a register,
'     reused across all four compares -- exactly the Select/Case codegen (codegen-patterns
'     10.2: subject read once, every Case compare back to back, then a jmp for the no-match
'     path, then all the bodies) the sibling TScreen_Leagues.SetUpLeagueTable.bmx documents
'     for its own comptype dispatch (a Select WITH a Default). Written here as `Select ...
'     Case 1 / Case 2 / Case 3 / Case 5 / Default <body>`, four SEPARATE empty Case labels
'     rather than one comma-joined `Case 1,2,3,5` -- every other place in this corpus that
'     had to choose between the two forms (TTraining.ResetTraining, TScreen_MyContract.
'     ButtonRequestTransfer/.UpdateDesiredCombos, TProfile.FixturePlayed) found the ORIGINAL
'     used separate Case labels, each with its own trailing jmp, not the comma form. The
'     `Default` arm holds ONLY the `SortTableBy(4)` call -- `End Select` follows immediately
'     -- exactly mirroring the sibling, where each Case/Default arm is a single SortTableBy
'     call and the row-population loop sits OUTSIDE the Select as shared code. Compiled this
'     way, the no-match jmp lands right after the compare chain (falling into Default), a
'     second jmp inside Default's own tail skips over the four `Return 0` case bodies to
'     reach that shared code, and those trivial case bodies (`mov eax,0`, jump to the
'     function epilogue) end up close enough to their own `je` that all four encode short
'     (`74 xx`, 2 bytes). A wider Default arm pushes the case targets far enough away that
'     the four `je` need the near `0F 84` encoding (6 bytes each) instead, which is the
'     length tell that pins the Default arm's true extent.
'   * `If club <> Null And club <> g_profile.myclub` (and the nation equivalent) is the same
'     two-step short-circuit shape as TScreen_Leagues.SetUpLeagueTable's `If c <> Null And
'     c <> g_contractoffer_tprofile.myclub`.
'   * The level dispatch (`comptype<>1,2,3,5`'s sibling test on `.level`) is ALSO a Select,
'     not an If/ElseIf: `.level` is read into a register once and reused across two back-to-
'     back compares (`cmp eax,0`/`je`, `cmp eax,1`/`je`), with a single trailing `jmp` for
'     the no-match path landing on the statement after End Select (`PaintPromotionPlaces`) --
'     codegen-patterns 10.2's own example of a Select with NO Default, where the fallback is
'     whatever follows `End Select`. Written as `Select g_continents_comp.level / Case 0
'     <club body> / Case 1 <nation body> / End Select`.
'   * SelectItemByText fallback order here is labelname, labelshortname, tla (offsets 0x1c,
'     0x20, 0x18 in that order) for BOTH the level-0 and level-1 branches -- NOTE this is
'     the opposite order from TScreen_Leagues.SetUpLeagueTable (labelshortname, labelname,
'     tla); reproduced exactly as this body's own decompilation shows it, not copied from
'     the sibling's order.
'
' Body-only format: statements only; this Function takes no parameters.
'!Global g_continents_panTable:TPanel
'!Global g_table_league:TTable
'!Global g_continents_panFixtures:TPanel
'!Global g_continents_cmbTeam:TCombo
'!Global g_continents_btnGroupsFirst:TButton
'!Global g_continents_btnGroupsLeft:TButton
'!Global g_continents_btnGroup:TButton
'!Global g_continents_btnGroupsRight:TButton
'!Global g_continents_btnGroupsLast:TButton
'!Global g_grouppage:Int
'!Global g_continents_comp:TCompetition
'!Global g_profile:TProfile
'!Global g_screenwidth:Int
g_table_league.ClearItems()
g_continents_btnGroupsFirst.Hide()
g_continents_btnGroupsLeft.Hide()
g_continents_btnGroup.Hide()
g_continents_btnGroupsRight.Hide()
g_continents_btnGroupsLast.Hide()
If g_continents_comp.comptype <> 0 And g_continents_comp.comptype <> 4 Then
	g_continents_panTable.Hide()
	g_continents_panFixtures.SetPosition(Int(g_screenwidth / 2 - g_continents_panFixtures.w / 2), Int(g_continents_panFixtures.y), 1)
ElseIf g_continents_comp.teampool Then
	g_continents_panTable.Show()
	g_continents_panFixtures.SetPosition(Int(g_screenwidth - g_continents_panFixtures.w - 10.0), Int(g_continents_panFixtures.y), 1)
	ClampInt(Varptr g_grouppage, 0, g_continents_comp.teampool.Length - 1)
	If g_continents_comp.teampool.Length > 1 Then
		g_continents_btnGroupsFirst.Show()
		g_continents_btnGroupsLeft.Show()
		g_continents_btnGroup.Show()
		g_continents_btnGroupsRight.Show()
		g_continents_btnGroupsLast.Show()
		g_continents_btnGroup.SetText(GetText("Group") + " " + String(g_grouppage + 1), "", -1, -1)
	End If
	Select g_continents_comp.comptype
		Case 1
			Return 0
		Case 2
			Return 0
		Case 3
			Return 0
		Case 5
			Return 0
		Default
			g_continents_comp.teampool[g_grouppage].SortTableBy(4)
	End Select
	Local row:Int = 1
	For Local td:TTableData = EachIn g_continents_comp.teampool[g_grouppage].list
		g_table_league.AddItem(td.GetStringArray(row, 0), "", "")
		row = row + 1
	Next
	Select g_continents_comp.level
		Case 0
			g_table_league.SelectItemByText(g_profile.myclub.labelname, 1)
			If g_table_league.selecteditem = -1 Then
				g_table_league.SelectItemByText(g_profile.myclub.labelshortname, 1)
			End If
			If g_table_league.selecteditem = -1 Then
				g_table_league.SelectItemByText(g_profile.myclub.tla, 1)
			End If
			Local club:TClub = TClub.SelectById(g_continents_cmbTeam.GetSelectedItemId())
			If club <> Null And club <> g_profile.myclub Then
				g_table_league.SelectItemByText(club.labelname, 1)
				If g_table_league.selecteditem = -1 Then
					g_table_league.SelectItemByText(club.labelshortname, 1)
				End If
				If g_table_league.selecteditem = -1 Then
					g_table_league.SelectItemByText(club.tla, 1)
				End If
			End If
		Case 1
			g_table_league.SelectItemByText(g_profile.mynation.labelname, 1)
			If g_table_league.selecteditem = -1 Then
				g_table_league.SelectItemByText(g_profile.mynation.labelshortname, 1)
			End If
			If g_table_league.selecteditem = -1 Then
				g_table_league.SelectItemByText(g_profile.mynation.tla, 1)
			End If
			Local nation:TNation = TNation.SelectById(g_continents_cmbTeam.GetSelectedItemId())
			If nation <> Null And nation <> g_profile.mynation Then
				g_table_league.SelectItemByText(nation.labelname, 1)
				If g_table_league.selecteditem = -1 Then
					g_table_league.SelectItemByText(nation.labelshortname, 1)
				End If
				If g_table_league.selecteditem = -1 Then
					g_table_league.SelectItemByText(nation.tla, 1)
				End If
			End If
	End Select
	g_continents_comp.PaintPromotionPlaces(g_table_league)
End If
Return 0
