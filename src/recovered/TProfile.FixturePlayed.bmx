' TProfile.FixturePlayed
' VA 0x005667FF   2669 bytes   vtable slot 0x64   KIND=Function SIG=()i
' byte-identical vs NSS5.exe (2669/2669, MATCH, mode=reloc, 175 relocations masked)
'
' g_profile (0x00C6F028) is a TProfile* -- the current career profile the whole game
'   operates on; this Function reads/writes it throughout via direct field offsets,
'   never Self (KIND=Function, no receiver). g_Object329 (0x00C66724) is a TScreen*
'   (construction site TScreen_Casino) -- the tail call is an INSTANCE-mediated
'   `g_Object329.SetActiveGadget("btn_play")` (load Global, deref its class table, call
'   slot 0x60 on that), not a static Type.Function call -- those compile to a different,
'   shorter indirect-call shape and would cost 4 bytes here.
'
' Two outer discriminants (g_profile.mylastfixture.level, and comp.level for the
'   cup-final split) and one apparently-binary one (comp.locale, 0 vs non-zero, in the
'   promotion/relegation branch) ALL compile as `Select`, never `If/ElseIf`/`If/Else` --
'   the original loads the discriminant into a register once (mov+cmp/je), which an
'   If-chain re-evaluating the field access on every test does not reproduce byte-for-
'   byte. This holds even for the 2-case comp.locale test, which has no ElseIf chain
'   nearby to make it "look like" a Select -- confirmed empirically, not assumed.
'
' `Select comp.locale ... Case 1, 2 ...` (comma-joined) is WRONG for the screen-dispatch
'   Select near the end -- the original genuinely duplicates the
'   TScreen_Continents.SetUpScreen(0, comp.level, comp.id) call body for Case 1 and
'   Case 2 separately (confirmed by raw disassembly, byte-identical duplicated blocks).
'
' The three "tournament exit" history-text sites evaluate `comp.name`/`comp.labelname`
'   in second position -- `comp.name + " " + GetText("tournament_exit")`, name/label
'   FIRST -- opposite of the two "win" sites, which use a preceding `Local wintxt:String
'   = GetText("Winners") + " " + comp.<name|labelname>` (GetText first). Both orderings
'   were confirmed by tracing the actual concat call-argument push order in the original
'   disassembly (Ghidra's decompiled C merges these into misleading single calls --
'   trust raw bytes, not the parenthesization, per codegen-patterns 16.6).
'
' THistory.Create(year, x2, x3, text, compid, flag) argument order for the (0, id) pair
'   is NOT fixed to "id-then-0" or "0-then-id" corpuswide -- it follows the actual
'   source argument order at each site and was confirmed per-site from push order
'   (rightmost arg pushed first): win sites use (clubid, 0)/(0, nationid); the
'   club-lost "tournament_exit" site uses (0, clubid) -- note this is DIFFERENT from
'   the sibling club-win site's (clubid, 0) despite reading similarly in prose.
'
' Field offsets: TProfile mylastfixture:TFixture@0x1D4 clubid@0x20 nationid@0x1C
'   date:TMyDate@0x10 history:TList@0x1C0 webheadline:String@0x50 banclub@0x198
'   bancontinent@0x19C baninternational@0x1A0 selectedformatch@0x1D8 myclub:TClub@0x1D0
'   interviewchance@0x1E0 prematchsaved@0x21C. TCompetition id@8 name@0xC locale@0x18
'   level@0x1C based@0x20 comptype@0x24 lpromotionplaces:TList@0x64
'   teampool:[]TTeamPool@0x6C. TFixture sdate@8 matchtype@0xC level@0x3C compid@0x40.
'   TBase_Team.labelname@0x1C (used by both TClub and TNation via the "$clubname"
'   template token). TTeamPool.list:TList@8. TTableData.teamid@0xC.
'   TPromotionPlace.place@0xC promotiontoid@0x10.
Function FixturePlayed:Int()
	'!Global g_profile:TProfile
	'!Global g_Object329:TScreen
	LogLine("FixturePlayed:" + TCompetition.SelectById(g_profile.mylastfixture.compid).name)
	g_profile.Play(g_profile.mylastfixture.sdate)
	TScreen_GameMenu.UpdateTitlePanel()
	TScreen_GameMenu.UpdateNavPanel()
	Select g_profile.mylastfixture.level
		Case 0
			Local loc0:Int = TCompetition.SelectById(g_profile.mylastfixture.compid).locale
			Select loc0
				Case 0
					If g_profile.banclub > 0 Then g_profile.banclub = g_profile.banclub - 1
				Case 1
					If g_profile.bancontinent > 0 Then g_profile.bancontinent = g_profile.bancontinent - 1
			End Select
		Case 1
			If g_profile.baninternational > 0 Then g_profile.baninternational = g_profile.baninternational - 1
	End Select
	TScreen_GameMenu.SetUpScreen()
	g_profile.NextPlayButton()
	g_profile.UpdateHealth()
	g_profile.SaveGame("")
	g_profile.prematchsaved = 0

	Local comp:TCompetition = TCompetition.SelectById(g_profile.mylastfixture.compid)
	Local won:Int = g_profile.mylastfixture.GetWinningTeamId()

	If comp.comptype = 1 And won <> 0 And g_profile.mylastfixture.matchtype <> 4
		Local isCupFinal:Int = comp.IsCupFinal()
		Select comp.level
		Case 0
			If won = g_profile.clubid
				If isCupFinal
					Local wintxt:String = GetText("Winners") + " " + comp.name
					g_profile.history.AddLast(THistory.Create(g_profile.date.GetYear(), g_profile.clubid, 0, wintxt, comp.id, 1))
					g_profile.webheadline = GetText("CNEWS_CUPWINNER")
					g_profile.webheadline = g_profile.webheadline.Replace("$clubname", TClub.SelectById(won).labelname)
					g_profile.webheadline = g_profile.webheadline.Replace("$competition", comp.labelname)
				EndIf
			Else
				g_profile.history.AddLast(THistory.Create(g_profile.date.GetYear(), g_profile.clubid, 0, comp.name + " " + GetText("tournament_exit"), comp.id, 0))
				If isCupFinal
					g_profile.webheadline = GetText("CNEWS_CUPWINNER")
					g_profile.webheadline = g_profile.webheadline.Replace("$clubname", TClub.SelectById(won).labelname)
					g_profile.webheadline = g_profile.webheadline.Replace("$competition", comp.labelname)
				EndIf
			EndIf
		Case 1
			If isCupFinal
				If won = g_profile.nationid And (g_profile.selectedformatch > 0 Or g_profile.GetStat(12, 4, 0, g_profile.date.GetYear()) > 0)
					Local wintxt:String = GetText("Winners") + " " + comp.labelname
					g_profile.history.AddLast(THistory.Create(g_profile.date.GetYear(), 0, g_profile.nationid, wintxt, comp.id, 1))
				EndIf
				g_profile.webheadline = GetText("CNEWS_CUPWINNER")
				g_profile.webheadline = g_profile.webheadline.Replace("$clubname", TNation.SelectById(won).labelname)
				g_profile.webheadline = g_profile.webheadline.Replace("$competition", comp.labelname)
			EndIf
		End Select
	Else
		If comp.level = 0 And comp.comptype = 0 And comp.locale <> 0 And comp.AllFixturesPlayed()
			Local promoteid:Int = 0
			For Local pp:TPromotionPlace = EachIn comp.lpromotionplaces
				If pp.place = 1
					promoteid = pp.promotiontoid
					Exit
				EndIf
			Next
			Local found:Int = 0
			For Local fx:TFixture = EachIn g_profile.myclub.GetFixtureList(-1, 0)
				If fx.compid = promoteid
					found = 1
				EndIf
			Next
			If found = 0
				Select comp.locale
				Case 0
					g_profile.history.AddLast(THistory.Create(g_profile.date.GetYear(), 0, g_profile.clubid, comp.labelname + " " + GetText("tournament_exit"), comp.id, 1))
				Default
					g_profile.history.AddLast(THistory.Create(g_profile.date.GetYear(), 0, g_profile.nationid, comp.labelname + " " + GetText("tournament_exit"), comp.id, 1))
				End Select
			EndIf
		ElseIf comp.comptype = 0 And comp.locale = 0 And comp.AllFixturesPlayed()
			comp.teampool[0].SortTableBy(4)
			Local winnerid:Int = 0
			For Local td:TTableData = EachIn comp.teampool[0].list
				winnerid = td.teamid
				Exit
			Next
			g_profile.webheadline = GetText("CNEWS_LEAGUEWINNER")
			g_profile.webheadline = g_profile.webheadline.Replace("$clubname", TClub.SelectById(winnerid).labelname)
			g_profile.webheadline = g_profile.webheadline.Replace("$competition", comp.labelname)
		EndIf
	EndIf

	Select comp.locale
		Case 0
			TScreen_Leagues.SetUpScreen(comp.id)
		Case 1
			TScreen_Continents.SetUpScreen(0, comp.level, comp.id)
		Case 2
			TScreen_Continents.SetUpScreen(0, comp.level, comp.id)
	End Select

	g_Object329.SetActiveGadget("btn_play")

	If g_profile.interviewchance And Rand(10) = 1
		If TScreen.DoMessage(GetText("CMESSAGE_DOINTERVIEW"), 1, 0) <> 0
			TScreen_Interview.SetUpScreen()
		EndIf
	EndIf
	g_profile.interviewchance = 0
	Return 0
End Function
