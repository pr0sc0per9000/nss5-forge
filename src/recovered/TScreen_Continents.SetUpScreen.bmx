' TScreen_Continents.SetUpScreen  (KIND=Function -- static, a0/a1/a2 are NOT Self)
' VA 0x005471D1   1866 bytes   sig (i,i,i)i   class-table slot 0x34
' byte-identical vs NSS5.exe (1866/1866, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=118).  Verified with NSS5_NO_LEARN=1 so no call operand was masked by a name
' this run itself taught.
'
' PARAMETERS.  Confirmed against callers (TScreen_Continents.ButtonLevel, both
' TScreen_GameMenu.ButtonCompetitions/ButtonPlay call sites, TProfile.FixturePlayed):
'   a0 = id override -- a club id (level 0) or nation id (level 1); 0 means "use the
'        current profile's own club/nation".
'   a1 = level to select, forwarded straight into TScreen_Continents.SelectLevel(a1)
'        (0 = domestic/continent view via TClub, 1 = international view via TNation).
'   a2 = competition id override, stored into g_continents_compid; 0 means "search for one".
'
' GLOBALS DECLARED (names are ours; the ADDRESS and TYPE are load-bearing).
'   0x00C67204 g_continents_compid:Int          -- bare dword store/load, no refcount (11.2)
'   0x00C67220 g_continents_comp:TCompetition   -- full retain/release traffic throughout
'   0x00C67224 g_continents_level:Int           -- same Global TScreen_Continents.SelectLevel
'                                                  writes as g_continents_level there
'   0x00C671DC g_continents_btnLevel:TButton    -- same address CreateScreen.bmx names it
'   0x00C671E0 g_continents_cmbContinent:TCombo
'   0x00C671E4 g_continents_cmbCompetition:TCombo
'   0x00C671E8 g_continents_cmbTeam:TCombo
'   0x00C66F04 g_iconWorld:TImage    -- loads "World.png"   (TScreen_Leagues.CreateScreen.bmx)
'   0x00C66F08 g_iconCountry:TImage  -- loads "Country.png"  (same file, same addresses)
'   0x00C6F028 g_profile:TProfile    -- same Global TScreen_Leagues.SetUpScreen calls g_profile
'   0x00C6099C g_competitions:TList  -- confirmed via slot 0x8C (ObjectEnumerator) and the
'                                       existing TCompetition.ChangeId.bmx naming
'
' FIELDS (object_model.json byte offsets, all confirmed by the field NAME the decompiler's
' offset resolves to, never guessed from usage alone):
'   TProfile.clubid(+0x20) / .nationid(+0x1C)
'   TClub.nationid(+0x64) (TBase_Team.id at +0xC, inherited, used for club.id/nation.id)
'   TNation.continent(+0x64)
'   TContinent.id(+8)
'   TCompetition.id(+8) .locale(+0x18) .level(+0x1C) .based(+0x20) .lfixturelist(+0x60)
'   TFixture.sdate(+8) .compid(+0x40) .result(+0x24)
'
' CALL TARGETS RESOLVED (class-table slots via class_tables.tsv + vtable_map.tsv):
'   TScreen+0x5C SetActive($,$):TScreen   TClub+0x94/TCompetition+0x11C/TNation+0x78
'     SortListBy(i,i)i   TScreen_Continents+0x3C SelectLevel(i)i (own-Type, EXPLICIT prefix --
'     matches the TScreen_Leagues.SetUpScreen precedent, not CreateScreen's bare-name-as-
'     function-pointer-value convention)
'   TGadget+0x64 SetText($,$,i,i)i (inherited by TButton) -- GetText's single-arg call is
'     merged by Ghidra with SetText's following pushes; disassembly shows GetText takes 1
'     argument and SetText takes 4 (guide 3d/8)
'   TButton+0x90 SetIcon(:TImage)i
'   TBase_Team+0x30 GetFixtureList(i,i):TList (inherited by TClub and TNation)
'   TClub+0x60/TNation+0x58/TCompetition+0x4C/TContinent+0x40 SelectById(i):<Type>
'   TCompetition+0xD8 IsThisCurrentCupRound()i
'   TList+0x8C ObjectEnumerator()  +0x30/+0x34 TListEnum HasNext/NextObject
'   TList+0x44 AddLast(:Object):TLink   +0x38 IsEmpty()i
'   TCombo+0xB0 SelectItemById(i)i
'   TScreen_Continents+0x40/0x44/0x48/0x80 ComboContinent/ComboCompetition/ComboTeam/
'     RefreshComboColours (own-Type, EXPLICIT prefix, actual calls not callback values)
'
' CONTROL-FLOW FINDINGS worth keeping for the next large body:
'   * The level dispatch is a Select with NO Default (guide 10.2): both Case compares are
'     emitted back-to-back before either body, and with no match the fallthrough (compid=0;
'     RefreshComboColours()) is what emits the trailing jmp. As If/ElseIf this body is 11
'     bytes longer per branch of the dispatch.
'   * A test of a JUST-STORED object Global against Null takes the LONG "If Not x" / bare
'     truthy form (21 bytes, setne+movzx materialised) whenever the guard controls a whole
'     multi-statement block (guide 10.3's "If Not x" row); an "x <> Null"/"x = Null" spelled
'     explicitly against a value that is not about to be reused compiles to the SHORT form
'     (12-14 bytes) instead. Getting this backwards costs 7-9 bytes per site and there are
'     five such tests in this body.
'   * "Module Globals are re-read from memory" (guide 10.6) extends past parameter shadowing:
'     inside the club/nation fixture-search loops, EVERY subsequent test after
'     `g_continents_comp = TCompetition.SelectById(...)` (the Null check, `.locale`, the
'     IsThisCurrentCupRound call) re-reads g_continents_comp from its address rather than
'     using a Local. Introducing a `Local comp:TCompetition` to hold the same value is
'     semantically identical but costs a register/stack slot the original never spends,
'     and cascades into wrong stack offsets for everything declared afterward.
'   * The compound guard `If g_continents_comp <> Null And g_continents_comp.locale = 1
'     And g_continents_comp.IsThisCurrentCupRound() Then Exit` must be ONE expression -- an
'     `isCont`/`found` pair of intermediate Locals recreates the same truth table but bcc
'     spends two extra `mov edx,eax` register shuffles materialising them (+9 bytes).
'   * Boolean operand ORDER inside an `Or` is byte-observable, exactly like guide 10.1's
'     comparison-operand-order rule: the two date-search loops read
'     `fx.sdate <= bestDate Or bestDate = -1` / `fx.sdate >= bestDate Or bestDate = -1`
'     (the fixture comparison FIRST, the sentinel check SECOND) -- written the other way
'     round the sub-expressions evaluate in the opposite order and the body comes out wrong
'     by exactly the size of one `setcc` chain (9 bytes) without changing its own length.
'   * The "keep A, or swap to B if B is non-empty" fallback-list pattern used building the
'     continent-competition search space is a real THREE-variable shape, not a two-variable
'     rename: `allComps` accumulates every eligible competition inside the EachIn loop,
'     `contComps` accumulates the continent-matching subset, and only AFTER the loop does a
'     THIRD Local `comps = allComps` get initialised and conditionally overwritten with
'     `contComps`. Merging allComps/comps into one variable removes a genuine 6-byte
'     unconditional store the original always executes.
'
' STRING LITERALS read out of NSS5.exe with harness.read_string (a MATCH never certifies
' literal content, only the masked address): "continents", "Continent", "International".
' The empty-string arguments read back None (the pooled 0-length literal at 0x00C5D284);
' see TScreen_Continents.CreateScreen.bmx for the two-empty-string-forms finding -- not
' investigated further here since both spellings give the same byte count in this body.
Function SetUpScreen(a0:Int, a1:Int, a2:Int)
	'!Global g_continents_compid:Int
	'!Global g_continents_comp:TCompetition
	'!Global g_continents_level:Int
	'!Global g_continents_btnLevel:TButton
	'!Global g_continents_cmbContinent:TCombo
	'!Global g_continents_cmbCompetition:TCombo
	'!Global g_continents_cmbTeam:TCombo
	'!Global g_iconWorld:TImage
	'!Global g_iconCountry:TImage
	'!Global g_profile:TProfile
	'!Global g_competitions:TList
	TScreen.SetActive("continents", "")
	g_continents_compid = a2
	TClub.SortListBy(2, 1)
	TCompetition.SortListBy(1, 1)
	TNation.SortListBy(2, 1)
	TScreen_Continents.SelectLevel(a1)
	Select g_continents_level
	Case 0
		g_continents_btnLevel.SetText(GetText("Continent"), "", -1, -1)
		g_continents_btnLevel.SetIcon(g_iconCountry)
		If a0 = 0 Then a0 = g_profile.clubid
		Local club:TClub = TClub.SelectById(a0)
		g_continents_comp = TCompetition.SelectById(g_continents_compid)
		If Not g_continents_comp
			For Local fx:TFixture = EachIn club.GetFixtureList(-1, 0)
				g_continents_comp = TCompetition.SelectById(fx.compid)
				If g_continents_comp <> Null And g_continents_comp.locale = 1 And g_continents_comp.IsThisCurrentCupRound() Then Exit
				g_continents_comp = Null
			Next
		EndIf
		If Not g_continents_comp
			Local cont:TContinent = TContinent.SelectById(TNation.SelectById(club.nationid).continent)
			Local allComps:TList = CreateList()
			Local contComps:TList = CreateList()
			For Local c:TCompetition = EachIn g_competitions
				If c.level = 0 And c.locale = 1
					allComps.AddLast(c)
					If c.based = cont.id Then contComps.AddLast(c)
				EndIf
			Next
			Local comps:TList = allComps
			If Not contComps.IsEmpty() Then comps = contComps
			Local bestDate:Int = -1
			For Local comp2:TCompetition = EachIn comps
				For Local fx:TFixture = EachIn comp2.lfixturelist
					If fx.result = 0 And (fx.sdate <= bestDate Or bestDate = -1)
						g_continents_comp = comp2
						bestDate = fx.sdate
						Exit
					EndIf
				Next
			Next
			If Not g_continents_comp
				For Local comp2:TCompetition = EachIn comps
					For Local fx:TFixture = EachIn comp2.lfixturelist
						If fx.sdate >= bestDate Or bestDate = -1
							g_continents_comp = comp2
							bestDate = fx.sdate
							Exit
						EndIf
					Next
				Next
			EndIf
		EndIf
		If g_continents_comp <> Null
			g_continents_cmbContinent.SelectItemById(g_continents_comp.based)
			TScreen_Continents.ComboContinent()
			g_continents_cmbCompetition.SelectItemById(g_continents_comp.id)
			TScreen_Continents.ComboCompetition()
			If g_continents_compid = 0
				g_continents_cmbTeam.SelectItemById(club.id)
				TScreen_Continents.ComboTeam()
			EndIf
		EndIf
	Case 1
		LogLine("International")
		g_continents_btnLevel.SetText(GetText("International"), "", -1, -1)
		g_continents_btnLevel.SetIcon(g_iconWorld)
		If a0 = 0 Then a0 = g_profile.nationid
		Local nation:TNation = TNation.SelectById(a0)
		g_continents_comp = TCompetition.SelectById(g_continents_compid)
		If Not g_continents_comp
			For Local fx:TFixture = EachIn nation.GetFixtureList(-1, 0)
				g_continents_comp = TCompetition.SelectById(fx.compid)
				If g_continents_comp Then Exit
			Next
		EndIf
		If g_continents_comp <> Null
			g_continents_cmbContinent.SelectItemById(nation.continent)
			TScreen_Continents.ComboContinent()
			g_continents_cmbCompetition.SelectItemById(g_continents_comp.id)
			TScreen_Continents.ComboCompetition()
			If g_continents_compid = 0
				g_continents_cmbTeam.SelectItemById(nation.id)
				TScreen_Continents.ComboTeam()
			EndIf
		EndIf
	End Select
	g_continents_compid = 0
	TScreen_Continents.RefreshComboColours()
End Function
