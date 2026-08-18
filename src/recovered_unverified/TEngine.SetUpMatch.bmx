' TEngine.SetUpMatch -- VA 0x004CE7BE, 1776 bytes, vtable slot 0x3c, KIND=Function
' sig (:TFixture,:TTeam,:TTeam,()i)i
' Refined this pass after finding a byte-verified sibling.
'
' ============================================================================================
' THIS PASS -- a byte-perfect sibling for this EXACT method already exists
' ============================================================================================
' src/recovered/TEngine.SetUpMatch.bmx verifies MATCH 1776/1776 (mode=reloc) for
' this identical (Type, Method). That resolves every open question the previous header left
' unsolved. Statement shape and Global TYPES were brought in line with it (names kept as
' this file's own -- names are cosmetic, only declared TYPE affects codegen, and every Global
' below already carried the matching type). Concretely, four changes:
'
'  1. THE TAIL (the one open issue): replaces the nested
'     `If Rand(5,1)<>1 Then...Else...EndIf` wrapped in `If A ... Else EndIf` with
'         If g_profile.selectedformatch > 1 Then
'             Select Rand(5, 1)
'                 Case 1     : g_engine_int22 = Rand(10, 65)
'                 Default    : g_engine_int22 = Rand(55, 65)
'             End Select
'         End If
'     A Select with one Case and a Default compiles to the SAME `cmp/je` shape as an
'     If/Else, but -- confirmed by disassembling the sibling's OWN compiled output in
'     src/assembled/.bmx/*.s -- its two exit jumps (`jmp` from the Case-1 arm and the
'     `jmp` from the Default arm) both land on ONE unified label placed directly at the
'     call to MatchLoop(), reproducing the original's `EB 13`/`EB 00`-both-reach-0x4CEE9A
'     shape exactly. None of the three If/Else-based shapes tried in the previous pass
'     produced that; the Select does, for free, because bcc lowers "one Case + Default"
'     as a single two-way branch with a shared join point, not as two nested If/EndIf
'     closes. This is why the previous header's whole "OPEN ISSUE" investigation is
'     retired rather than extended.
'  2. Added the explicit `String(...)` cast on the ">>> MemAlloced = " concat --
'     the decompiled call chain is a bare int-to-string convert (FUN_004a7ac0) followed
'     by a separate Concat (FUN_004a7c20), i.e. `String(g_engine_memstart)`, not an
'     implicit numeric concat.
'  3. Block-formed a handful of single-line `If X Then Y` / `If X <> Null ... EndIf`
'     sites to match the sibling's exact text (belt-and-braces; single-line and block
'     form are not known to differ in codegen here, but there is no reason to leave a
'     needless textual difference against a proven-byte-exact reference).
'  4. Added the explicit trailing `Return 0` the decompiled source has (`return 0;`),
'     which the body would otherwise leave implicit.
'
' NOT copied from the sibling: it logs via `DebugLog(...)`; this file keeps `LogLine(...)`
' (already what this file had). Direct disassembly of the ORIGINAL at 0x00505B91 --
' `cmp [g_logstream],Null / je +skip / g_logstream.WriteLine(a0) / Print a0 / skip: mov eax,0`
' -- is exactly this project's own reconstructed `Function LogLine:Int(a0:String)` body
' (src/assembled/nss5_assembled.bmx), not the bare BRL.Blitz DebugLog. The sibling's
' harness.try_method run "learned" 0x00505b91=_brl_blitz_DebugLog only via the oracle's
' case-(c) fallback ("our side is named, original's address not yet in the table, but
' everything ELSE in the function agrees, so trust the alignment") -- and a `push a0 /
' call X / add esp,4` call site is the same length and shape for ANY single-String-arg
' Int-returning callee, so that corroboration cannot actually distinguish LogLine from
' DebugLog. Direct disassembly is stronger evidence than that heuristic and it says
' LogLine, matching every OTHER file in this tree that names 0x00505B91 (TBall.HitNet,
' TCombo.SelectItem, TCompetition.CreateTeamPool/PopulateTeamPool/ValidatePromotionPlaces,
' TEngine.DoYourSubstitutionOn, TNation.SelectRandomNation, TOptions.WaitForJoyRelease).
' This is left as a note, not a fix to the sibling -- rule 1 forbids touching other files.
'
' ============================================================================================
' Fields / Globals used (all confirmed via object_model.json / vtable_map.tsv / cross-reference
' against already-VERIFIED sibling files, not guessed)
' ============================================================================================
'  TFixture: matchtype +0xc, leg +0x18, level +0x3c, compid +0x40.
'  TTeam: id +8, tla +0x10, kitplayer:TKit +0x2c.  TKit: newcol:[]$ +0x10.
'  TBase_Team (super of TClub/TNation): stadiumcapacity +0x38, imgFlag:TImage +0x58.
'  TClub/TNation: SelectById(i):T slot 0x60 / 0x58 respectively (Functions on their own class
'    table, called unqualified through the class-table pointer, no receiver).
'  TCompetition: locale +0x18, level +0x1c, based +0x20, comptype +0x24, compstatus +0x50.
'    SelectById(i):TCompetition slot 0x4c. IsCupFinal()i slot 0xf8.
'  TFixture.GetFirstLegScore(*i,*i)i slot 0x50 -- BOTH params are `Int Var` (reflection `*i`),
'    call with `Varptr` (see src/recovered/TTeam.GetLosingBy.bmx for the same pattern).
'  Module Globals (names OURS, types load-bearing; cross-checked against already-VERIFIED
'    TEngine.EndMatch.bmx / TEngine.DrawScores.bmx / TEngine.RenderScoreboard.bmx /
'    TEngine.SetUpReplay.bmx / TEngine.CreateReplayFrames.bmx / src/recovered/TEngine.SetUpMatch.bmx,
'    which reference many of the SAME addresses and independently confirm both address and type):
'      0x00C5B378 g_engine_memstart:Int        (TEngine.EndMatch reads it as "memstart",
'                                                writes the matching 0x00C5B37C as "memend")
'      0x00C5B1C0 g_engine_fnend:Int()          (TEngine.EndMatch, TEngine.SetUpReplay)
'      0x00C5B22C g_engine_fixture:TFixture     (TEngine.DrawScores, TEngine.EndMatch)
'      0x00C5B234 g_engine_agg1:Int  0x00C5B230 g_engine_agg2:Int   (TEngine.DrawScores)
'      0x00C5B218 g_hometeam:TTeam  0x00C5B21C g_awayteam:TTeam     (TEngine.RenderScoreboard,
'                                                TEngine.SetUpReplay; TEngine.EndMatch calls the
'                                                same two addresses g_playerteam/g_opponentteam
'                                                -- names are ours either way, addresses agree)
'      0x00C5D24C g_opt_playercam:Int           (TOptions.LoadOptions/SaveOptions)
'      0x00C5B1D4 g_engine_zoom:Float  0x00C5D238 g_engine_zoomdefault:Float = 2.0
'                                                (TEngine.SetUpReplay; float read directly from
'                                                 the exe at 0x00C73B34 via struct.unpack)
'      0x00C5B238 g_kickcount:Int  0x00C5B240 g_kickresults:Int[]  (TEngine.RenderScoreboard)
'      0x00C5B208 g_engine_half:Int  0x00C5B210 g_engine_clock:Int (TEngine.SkipMatchTime,
'                                                TEngine.RenderScoreboard)
'      0x00C5B1FC g_matchstate:Int              (TEngine.EndMatch)
'      0x00C5B1CC g_engine_int13:Int  0x00C5B2BC g_engine_int49:Int (TEngine.EndMatch,
'                                                TEngine.Update; semantics not identified,
'                                                names are placeholders, TYPE Int is confirmed
'                                                by bare `mov` with no refcount traffic)
'      0x00C5B2D4 g_homebadge:TImage  0x00C5B2D8 g_awaybadge:TImage (TEngine.RenderScoreboard --
'                                                globals_final.tsv wrongly typed these TClub;
'                                                the field actually read/stored is TBase_Team's
'                                                +0x58 = imgFlag, a TImage, not a TClub)
'      0x00C5B32C g_engine_labels:TLabel[4]  0x00C5B330 g_lbl_time:TLabel
'      0x00C5B334 g_lbl_agg:TLabel           (all three: TEngine.DrawScores)
'      0x00C6CF90 g_training_int03:Int       (TEngine.EndMatch; also TTraining module)
'      0x00C5B228 g_engine_int22:Int         (usage only, this function)
'      0x00C6F028 g_profile:TProfile         (TEngine.EndMatch; +0x1D8 = selectedformatch, per
'                                                TProfile.UpdateSelectedForMatch.bmx)
'      0x00C5B2B0 g_replayframes:TList       (TEngine.CreateReplayFrames.bmx types it TList
'                                                from the SAME `If Not g Then g=CreateList()
'                                                Else g.Clear()` shape seen here -- slot 0x34 on
'                                                the Else branch is TList.Clear(), and the
'                                                Then branch constructs via CreateList(), which
'                                                DISAMBIGUATES it from TEngine.EndMatch's own
'                                                unresolved "GUESS: 30 Types qualify" note for
'                                                the very same address -- CreateList() can only
'                                                return a TList)
'
' Literals (all read directly from NSS5.exe via harness.read_string / struct.unpack, not
'   guessed): "SetUpMatch", ">>> MemAlloced = ", "FixtureType:", "tla_CupMatch", " 1", "tla_Leg",
'   "tla_Aggregate", "666666", "FFFFFF", "" (empty), " " (single space), float 2.0 at 0xC73B34.
'
' ============================================================================================

	Function SetUpMatch:Int(a0:TFixture, a1:TTeam, a2:TTeam, a3:Int())
		'!Global g_engine_memstart:Int
		'!Global g_engine_fnend:Int()
		'!Global g_engine_fixture:TFixture
		'!Global g_engine_agg1:Int
		'!Global g_engine_agg2:Int
		'!Global g_hometeam:TTeam
		'!Global g_awayteam:TTeam
		'!Global g_opt_playercam:Int
		'!Global g_engine_zoom:Float
		'!Global g_engine_zoomdefault:Float = 2.0
		'!Global g_kickcount:Int
		'!Global g_kickresults:Int[]
		'!Global g_engine_half:Int
		'!Global g_engine_clock:Int
		'!Global g_matchstate:Int
		'!Global g_engine_int13:Int
		'!Global g_engine_int49:Int
		'!Global g_homebadge:TImage
		'!Global g_awaybadge:TImage
		'!Global g_engine_labels:TLabel[]
		'!Global g_lbl_time:TLabel
		'!Global g_lbl_agg:TLabel
		'!Global g_training_int03:Int
		'!Global g_engine_int22:Int
		'!Global g_profile:TProfile
		'!Global g_replayframes:TList

		LogLine("SetUpMatch")
		GCCollect()
		g_engine_memstart = GCMemAlloced()
		LogLine(">>> MemAlloced = " + String(g_engine_memstart))
		TEngine.SetUpChannels()
		g_engine_int13 = 2
		If Not g_replayframes Then
			g_replayframes = CreateList()
		Else
			g_replayframes.Clear()
		End If
		g_engine_fnend = a3
		g_engine_fixture = a0
		a0.GetFirstLegScore(Varptr g_engine_agg2, Varptr g_engine_agg1)
		LogLine("FixtureType:" + String(g_engine_fixture.matchtype))
		g_hometeam = a1
		g_awayteam = a2
		If g_opt_playercam > 1 Then g_engine_zoomdefault = 2.0
		g_engine_zoom = g_engine_zoomdefault
		g_kickcount = 0
		For Local i:Int = 0 To 98
			g_kickresults[i] = 0
		Next
		g_engine_half = 1
		If g_engine_clock >= 45 Then g_engine_half = 2
		If g_engine_clock >= 90 Then g_engine_half = 3
		If g_engine_clock >= 105 Then g_engine_half = 4
		g_matchstate = 0
		g_engine_int49 = 0
		TEngine.SetUpRadarColours()
		TEngine.SetUpWeatherConditions()
		TEngine.ResumeSounds()
		g_homebadge = Null
		g_awaybadge = Null
		TPitch.SetStadiumSize(60000, 0)
		Select g_engine_fixture.level
			Case 0
				Local homeclub:TClub = TClub.SelectById(g_hometeam.id)
				Local awayclub:TClub = TClub.SelectById(g_awayteam.id)
				If homeclub <> Null Then
					g_homebadge = homeclub.imgFlag
					TPitch.SetStadiumSize(homeclub.stadiumcapacity, 0)
				End If
				If awayclub <> Null Then
					g_awaybadge = awayclub.imgFlag
				End If
				g_engine_labels[0].SetColour("666666", "FFFFFF")
				g_engine_labels[2].SetColour("666666", "FFFFFF")
				g_lbl_time.SetColour("666666", "FFFFFF")
				g_lbl_agg.SetColour("666666", "FFFFFF")
			Case 1
				Local homenation:TNation = TNation.SelectById(g_hometeam.id)
				Local awaynation:TNation = TNation.SelectById(g_awayteam.id)
				If homenation <> Null Then
					g_homebadge = homenation.imgFlag
				End If
				If awaynation <> Null Then
					g_awaybadge = awaynation.imgFlag
				End If
				g_engine_labels[0].SetColour("FFFFFF", "FFFFFF")
				g_engine_labels[2].SetColour("FFFFFF", "FFFFFF")
				g_lbl_time.SetColour("FFFFFF", "FFFFFF")
				g_lbl_agg.SetColour("FFFFFF", "FFFFFF")
		End Select
		Local comp:TCompetition = TCompetition.SelectById(a0.compid)
		g_lbl_agg.Hide()
		If comp <> Null And comp.comptype = 1 Then
			g_lbl_agg.Show()
			g_lbl_agg.SetText(GetText("tla_CupMatch"), "", -1, -1)
			If g_engine_fixture.leg = 1 Then g_lbl_agg.SetText(GetText("tla_Leg") + " 1", "", -1, -1)
			If g_engine_fixture.leg = 2 Then g_lbl_agg.SetText(GetText("tla_Aggregate") + " " + String(g_engine_agg1) + " " + String(g_engine_agg2), "", -1, -1)
			If comp.IsCupFinal() Then
				TPitch.SetStadiumSize(60000, 1)
			ElseIf comp.level = 1 And (comp.locale = 2 Or comp.compstatus = 1) Then
				TPitch.SetStadiumSize(60000, 1)
			End If
		End If
		If g_training_int03 = 0 Then
			TPitch.SetUpFans(a1, a2, g_engine_fixture.level)
		End If
		g_engine_labels[1].SetText(Left(g_hometeam.tla, 8), "", -1, -1)
		g_engine_labels[1].SetColour(g_hometeam.kitplayer.newcol[1], "FFFFFF")
		g_engine_labels[3].SetText(Left(g_awayteam.tla, 8), "", -1, -1)
		g_engine_labels[3].SetColour(g_awayteam.kitplayer.newcol[1], "FFFFFF")
		g_engine_int22 = -1
		If g_profile.selectedformatch > 1 Then
			Select Rand(5, 1)
				Case 1
					g_engine_int22 = Rand(10, 65)
				Default
					g_engine_int22 = Rand(55, 65)
			End Select
		End If
		TEngine.MatchLoop()
		Return 0
	End Function
