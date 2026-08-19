' TScreen_GameMenu.ButtonPlay
' VA 0x0053B3F1   1527 bytes   vtable slot 0x4c   sig ()i   KIND=Function
' byte-identical vs NSS5.exe
' Reconstructed from extracted/decomp_annotated/TScreen_GameMenu.ButtonPlay@0053b3f1.c,
' which resolves every SYM/CALL in this body.
'
' Register/stack placement of Locals inside Case 4 follows directly from source order and
' shape and is not incidental: `newseason` is declared before `fx` (its implicit zero-init
' sits at the top of the Case, ahead of the `GetNextFixture` call); `fx = Null` is tested as
' `fx <> Null Then <fxyr comparison> Else newseason = True End If` (the Then branch is the
' comparison, not the assignment) so that the trivial `newseason = True` block is the Else
' side of the test, matching how bcc lays out branch targets for a simple-vs-compound If/Else
' pair; and inside the fixture loop, `bestcomp = c` is assigned before `bestdate = f.sdate`.
'
' GLOBALS (name/type per scripts/explain_global.py; all also load-bearing for the vtable
' slot each is dispatched through):
'   0x00C6EF50 g_engine_int161:Int   -- CERTAIN (explain_global.py). The debug-overlay flag;
'                                        ==2 is required to even test the leagues-cheat key.
'   0x00C61700 g_curscreen:TScreen   -- CERTAIN (explain_global.py, 16 bodies); decomp_annotated
'                                        carries the stale g_Object101 spelling. .name at +8.
'   0x00C66F28 g_lg_table3:TTable    -- CERTAIN (explain_global.py, 2 bodies unanimous; beats
'                                        the STRONG g_screen_leagues_tplayer03 alias at the
'                                        same address). Slot 0xD8 = TTable.GetSelectedText(i)$.
'   0x00C6F028 g_profile:TProfile    -- explain_global.py's CERTAIN pick for this address is
'                                        actually g_contractoffer_tplayer (20 bodies), with
'                                        g_profile only STRONG (142 bodies, 102/104 agree).
'                                        Overridden here: every OTHER TScreen_GameMenu body
'                                        already in src/recovered (ButtonQuit, ButtonCompetitions,
'                                        UpdateTitlePanel, UpdateMatchRefresh) declares this
'                                        exact address g_profile:TProfile, and TScreen_TestFixtures
'                                        /TestTournaments.ButtonPlay (verified siblings) do too --
'                                        within-Type/within-feature consistency wins over the
'                                        raw unanimity count.
'   0x00C6099C g_competitions:TList  -- CERTAIN (explain_global.py, 28 bodies).
'
' FIELD / SLOT RESOLUTION (object_model.json, vtable_map.tsv):
'   TProfile      +0x10 date:TMyDate   +0x3C retired   +0x130 playbuttontype   +0x164 booze
'                 +0x1CC mynation:TNation   +0x1D0 myclub:TClub
'                 slot 0x54 Play(i)i, 0x58 GetNextFixture(i):TFixture, 0x60 PlayNextFixture(i)i,
'                 0x74 RandomIncident()i, 0x13C CheckLoanEnd()i
'   TMyDate       +0x08 sdate:Int ; Function 0x30 Create(i,i,i):TMyDate, Method 0x54 GetYear()i
'   TCompetition  +0x08 id  +0x18 locale  +0x1C level  +0x20 based  +0x24 comptype
'                 +0x60 lfixturelist:TList
'   TFixture      +0x08 sdate  +0x24 result  +0x3C level
'                 slot 0x70 GetHomeTeamId()i, 0x74 GetAwayTeamId()i
'   TClub         +0x64 nationid  +0x68 leagueid ; Function slot 0x60 SelectById(i):TClub
'   TNation       +0x64 continent ; Function slot 0x58 SelectById(i):TNation
'   KeyDown(162) = KEY_LCONTROL, same idiom as TScreen_TestFixtures/TestTournaments.ButtonPlay
'     and TTable.UpdateActivated (0x005B4721 is the KeyDown|MouseDown alias set; KeyDown fits).
'
' STRUCTURE (all four multi-way dispatches in this body are Selects, not If/ElseIf):
'   - `g_profile.playbuttontype`: Case order in the machine code is 1, 2, 3, 5, 4 (5 before
'     4) -- that non-monotonic order is the tell for a `Select` over an If/ElseIf
'     cascade (codegen-patterns.md 10.2), so it is written as one Select in that exact order.
'   - `bestcomp.locale` (0, 1, 2) and `fx.level` (0, 1) are Selects for the same reason: every
'     case-body address sits after the last compare in the cmp/je run.
'   - The eligibility test for each competition, and the "best fixture so far" test inside
'     it, are each a staged short-circuit boolean (bVarN = false; if(cond) bVarN=...) repeated
'     across several terms, written back as the equivalent compound And/Or expression rather
'     than reproducing the staging by hand.
	Function ButtonPlay:Int()
		'!Global g_engine_int161:Int
		'!Global g_curscreen:TScreen
		'!Global g_lg_table3:TTable
		'!Global g_profile:TProfile
		'!Global g_competitions:TList
		LogLine("Play")
		If g_engine_int161 = 2 And KeyDown(162) And g_curscreen.name = "leagues"
			Local wk:String = g_lg_table3.GetSelectedText(0)
			LogLine("week:" + wk)
			Local d:TMyDate = TMyDate.Create(1, Int(wk), g_profile.date.GetYear())
			g_profile.Play(d.sdate)
			TScreen_Leagues.SetUpScreen(0)
			Return 0
		Else
			PlayTrack(2)
			LogLine(String(g_profile.playbuttontype))
			If g_profile.retired <> 0
				TScreen.DoMessage(GetText("CMESSAGE_RETIREMENT"), 0, 0)
				Return 0
			Else
				Select g_profile.playbuttontype
					Case 1
						TScreen_ReportPhysio.SetUpScreen()
					Case 2
						TScreen_WebPage.SetUpScreen("", "")
					Case 3
						g_profile.RandomIncident()
						g_profile.booze = 0
					Case 5
						TScreen_Newspaper.SetUpScreen()
					Case 4
						g_profile.CheckLoanEnd()
						Local newseason:Int
						Local fx:TFixture = g_profile.GetNextFixture(0)
						Local seasonstart:TMyDate = TMyDate.Create(1, 1, g_profile.date.GetYear() + 1)
						If fx <> Null
							If TMyDate.Create(fx.sdate, 1, 1).GetYear() > g_profile.date.GetYear()
								newseason = True
							End If
						Else
							newseason = True
						End If
						If newseason
							LogLine("SeasonReview")
							Local mycontinent:Int = g_profile.mynation.continent
							Local clubcontinent:Int = TNation.SelectById(g_profile.myclub.nationid).continent
							Local bestcomp:TCompetition = Null
							Local bestdate:Int = 0
							For Local c:TCompetition = EachIn g_competitions
								If (c.comptype = 1 And c.id = g_profile.myclub.leagueid) Or (c.locale = 1 And c.level = 1 And c.based = mycontinent) Or (c.locale = 1 And c.level = 0 And c.based = clubcontinent) Or (c.locale = 2)
									For Local f:TFixture = EachIn c.lfixturelist
										If (f.result = 0 And f.sdate < seasonstart.sdate) And (bestdate = 0 Or f.sdate < bestdate)
											bestcomp = c
											bestdate = f.sdate
										End If
									Next
								End If
							Next
							LogLine("SeasonStart:" + String(seasonstart.sdate))
							LogLine("compfixdate:" + String(bestdate))
							If bestdate > 0
								g_profile.Play(bestdate)
								Select bestcomp.locale
									Case 0
										TScreen_Leagues.SetUpScreen(bestcomp.id)
									Case 1
										TScreen_Continents.SetUpScreen(0, bestcomp.level, bestcomp.id)
									Case 2
										TScreen_Continents.SetUpScreen(0, bestcomp.level, bestcomp.id)
								End Select
							Else
								g_profile.Play(seasonstart.sdate)
								TScreen_SeasonReview.SetUpScreen()
							End If
						Else
							Local a:Object = Null
							Local b:Object = Null
							Select fx.level
								Case 0
									a = TClub.SelectById(fx.GetHomeTeamId())
									b = TClub.SelectById(fx.GetAwayTeamId())
								Case 1
									a = TNation.SelectById(fx.GetHomeTeamId())
									b = TNation.SelectById(fx.GetAwayTeamId())
							End Select
							If Not a Or Not b
								g_profile.PlayNextFixture(1)
							Else
								TScreen_WorldMap.SetUpScreen()
							End If
						End If
				End Select
			End If
		End If
	End Function
