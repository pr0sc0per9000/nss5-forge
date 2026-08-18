' TScreen_WorldMap.SetUpScreen
' VA 0x0055A4ED   3251 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static), SIG ()i, class-table slot 0x34
' MATCH 3251/3251, reloc_masked=241, original length from Ghidra's inventory,
' re-verified under NSS5_NO_LEARN=1 (codegen-patterns 13.1).
'
' ASSUMPTIONS -- module Global NAMES are ours; the DECLARED TYPES are load-bearing.
'   0x00C683CC g_wm_bg           TImage        ImageHeight/MidHandleImage/LoadImageChecked
'   0x00C683E8 g_wm_lbl_comp     TLabel        construction site; slot 0x64 = TGadget.SetText
'   0x00C683EC g_wm_lbl_money    TLabel        construction site
'   0x00C683F4 g_wm_lbl_versus   TLabel        construction site; also slot 0x54 TGadget.Hide
'   0x00C683FC g_wm_lbl_team1    TLabel        construction site
'   0x00C68400 g_wm_lbl_stadname TLabel        construction site
'   0x00C68408 g_wm_lbl_capacity TLabel        construction site
'   0x00C6840C g_wm_pnl_year     TPanel        construction site
'   0x00C68410 g_wm_table        TTable        slots 0x94 AddItem, 0x9C ClearItems,
'                                              0xB0 SetHighlightColour, 0xDC SelectItemByRow,
'                                              0xEC CountItems -- all TTable-only
'   0x00C6842C g_wm_comp         TCompetition  slots 0x9C/0xF4/0xF8, fields 0x14/0x18/0x1C/0x50/0x60
'   0x00C68430 g_wm_team1        TBase_Team    assigned from BOTH TClub.SelectById and
'   0x00C68434 g_wm_team2        TBase_Team    TNation.SelectById, so it is their common base
'   0x00C68438 g_wm_stadiumname  String        full retain/release traffic -- codegen-patterns 11.2.
'                                              globals_final.tsv says Int; the code says String.
'   0x00C6843C g_wm_stadiumcap   Int           bare mov, no refcounting. globals_final says TNation.
'   0x00C68440 g_wm_lat1         Float         copied from TBase_Team.stadiumlatitude /
'   0x00C68444 g_wm_long1        Float         .stadiumlongitude with fld/fstp
'   0x00C68448 g_wm_lat2         Float
'   0x00C6844C g_wm_long2        Float
'   0x00C68450 g_wm_zoom         Float         set to 1.0 -- fld1/fstp
'   0x00C6EFE8 g_screenheight    Int
'   0x00C6E950 g_mediapath       String        already typed String elsewhere
'   0x00C6F028 g_profile         TProfile      construction site
'   0x00C59A48 g_club_sortby     Int           TClub sort-key selector, set to 33 before TList.Sort
'
' NOTES
'   * The self-comparison f.sdate = f.sdate at 0x0055AE07 is VERBATIM: the original
'     compares the same field to itself (8B 43 08 / 3B 43 08, both [ebx+8]). Almost
'     certainly a typo for fix.sdate in the original source. Reproduced as written --
'     it is byte-load-bearing.
'   * g_profile.helppages is []i; the constant index folds to [eax+0x68] = index 20,
'     BBArray data starting at +0x18 (codegen-patterns 11.1).
'   * The TNation local in the Case 1 arm MUST be ONE variable declared before the
'     If/Else. A separate Local in each arm is 3 instructions off -- bcc gives the
'     second one ebx where the original keeps esi (89 C6 vs 89 C3 at 0x0055AC12, plus
'     its two [esi+..] operands). Same length, so only first_diff localises it.
'   * The second TNation.SelectById in the level=0 arm is genuinely DEAD in the
'     original: the call is emitted, the result is stored nowhere. Written as an
'     unused Local, which is what reproduces it.
'   * String literals were read out of NSS5.exe with harness.read_string, not guessed:
'     "worldmap", "GameMedia/Images/Backgrounds/WorldMap2.jpg", ".../WorldMap4.jpg",
'     "Team1:", "Team2:", "tla_versus", " ", "WWWW".

	Function SetUpScreen:Int()

		'!Global g_wm_bg:TImage
		'!Global g_wm_lbl_comp:TLabel
		'!Global g_wm_lbl_money:TLabel
		'!Global g_wm_lbl_versus:TLabel
		'!Global g_wm_lbl_team1:TLabel
		'!Global g_wm_lbl_stadname:TLabel
		'!Global g_wm_lbl_capacity:TLabel
		'!Global g_wm_pnl_year:TPanel
		'!Global g_wm_table:TTable
		'!Global g_wm_comp:TCompetition
		'!Global g_wm_team1:TBase_Team
		'!Global g_wm_team2:TBase_Team
		'!Global g_wm_stadiumname:String
		'!Global g_wm_stadiumcap:Int
		'!Global g_wm_lat1:Float
		'!Global g_wm_long1:Float
		'!Global g_wm_lat2:Float
		'!Global g_wm_long2:Float
		'!Global g_wm_zoom:Float
		'!Global g_screenheight:Int
		'!Global g_mediapath:String
		'!Global g_profile:TProfile
		'!Global g_club_sortby:Int

		TScreen.SetActive("worldmap", "")
		g_profile.UpdateSelectedForMatch(g_profile.energy)
		g_wm_lbl_money.SetText(FormatMoney(g_profile.bank, 0), "", -1, -1)
		If g_screenheight = 600
			If Not g_wm_bg Or ImageHeight(g_wm_bg) > 640
				g_wm_bg = LoadImageChecked(g_mediapath + "GameMedia/Images/Backgrounds/WorldMap2.jpg", -1)
				MidHandleImage(g_wm_bg)
			EndIf
		Else
			If Not g_wm_bg Or ImageHeight(g_wm_bg) = 640
				g_wm_bg = LoadImageChecked(g_mediapath + "GameMedia/Images/Backgrounds/WorldMap4.jpg", -1)
				MidHandleImage(g_wm_bg)
			EndIf
		EndIf
		Local fix:TFixture = g_profile.GetNextFixture(0)
		Select fix.level
		Case 0
			g_wm_team1 = TClub.SelectById(fix.GetHomeTeamId())
			g_wm_team2 = TClub.SelectById(fix.GetAwayTeamId())
		Case 1
			g_wm_team1 = TNation.SelectById(fix.GetHomeTeamId())
			g_wm_team2 = TNation.SelectById(fix.GetAwayTeamId())
		End Select
		LogLine("Team1:" + g_wm_team1.strength)
		LogLine("Team2:" + g_wm_team2.strength)
		g_wm_comp = TCompetition.SelectById(fix.compid)
		g_wm_stadiumname = g_wm_team1.stadiumname
		g_wm_stadiumcap = g_wm_team1.stadiumcapacity
		g_wm_long1 = g_wm_team1.stadiumlongitude
		g_wm_lat1 = g_wm_team1.stadiumlatitude
		g_wm_long2 = g_wm_team2.stadiumlongitude
		g_wm_lat2 = g_wm_team2.stadiumlatitude
		g_wm_lbl_team1.SetText(g_wm_team1.labelname, "", -1, -1)
		g_wm_lbl_comp.SetText(g_wm_comp.labelname, "", -1, -1)
		g_wm_lbl_versus.SetText(g_wm_team1.labelname + " " + GetText("tla_versus") + " " + g_wm_team2.labelname, "", -1, -1)
		g_wm_lbl_versus.Hide()
		Select g_wm_comp.level
		Case 0
			Local c1:TClub = TClub.SelectById(g_wm_team1.id)
			Local c2:TClub = TClub.SelectById(g_wm_team2.id)
			Local n1:TNation = TNation.SelectById(c1.nationid)
			Local n2:TNation = TNation.SelectById(c2.nationid)
			If g_wm_team1.stadiumname = ""
				g_wm_lbl_team1.SetText(n1.labelname, "", -1, -1)
				g_wm_stadiumname = n1.stadiumname
				g_wm_stadiumcap = n1.stadiumcapacity
				g_wm_long1 = n1.stadiumlongitude
				g_wm_lat1 = n1.stadiumlatitude
			EndIf
			If g_wm_comp.IsCupFinal()
				Select g_wm_comp.locale
				Case 0
					g_wm_lbl_team1.SetText(n1.labelname, "", -1, -1)
					g_wm_stadiumname = n1.stadiumname
					g_wm_stadiumcap = n1.stadiumcapacity
					g_wm_long1 = n1.stadiumlongitude
					g_wm_lat1 = n1.stadiumlatitude
					g_wm_long2 = n1.stadiumlongitude
					g_wm_lat2 = n1.stadiumlatitude
				Case 1
					Local n3:TNation = TNation.SelectById(g_wm_comp.GetBasedNationId(g_profile.date.GetYear()))
					g_wm_lbl_team1.SetText(n3.labelname, "", -1, -1)
					g_wm_stadiumname = n3.stadiumname
					g_wm_stadiumcap = n3.stadiumcapacity
					g_wm_long1 = n3.stadiumlongitude
					g_wm_lat1 = n3.stadiumlatitude
					g_wm_long2 = n3.stadiumlongitude
					g_wm_lat2 = n3.stadiumlatitude
				End Select
			EndIf
		Case 1
			If g_wm_comp.locale = 2 Or g_wm_comp.compstatus = 1
				Local nn:TNation
				If g_wm_comp.IsCupFinal()
					nn = TNation.SelectById(g_wm_comp.GetBasedNationId(g_profile.date.GetYear()))
					g_wm_lbl_team1.SetText(nn.labelname, "", -1, -1)
					g_wm_stadiumname = nn.stadiumname
					g_wm_stadiumcap = nn.stadiumcapacity
					g_wm_long1 = nn.stadiumlongitude
					g_wm_lat1 = nn.stadiumlatitude
					g_wm_long2 = nn.stadiumlongitude
					g_wm_lat2 = nn.stadiumlatitude
				Else
					nn = TNation.SelectById(g_wm_comp.GetBasedNationId(g_profile.date.GetYear()))
					g_wm_lbl_team1.SetText(nn.labelname, "", -1, -1)
					Local lst:TList = TClub.SelectListByNationId(nn.id)
					g_club_sortby = 33
					lst.Sort(0)
					Local n:Int = 0
					For Local c:TClub = EachIn lst
						If n = g_profile.date.sdate Mod 6
							g_wm_stadiumname = c.stadiumname
							g_wm_stadiumcap = c.stadiumcapacity
							g_wm_long1 = c.stadiumlongitude
							g_wm_lat1 = c.stadiumlatitude
							g_wm_long2 = c.stadiumlongitude
							g_wm_lat2 = c.stadiumlatitude
							Exit
						EndIf
						n = n + 1
					Next
				EndIf
			EndIf
		End Select
		g_wm_lbl_stadname.SetText(g_wm_stadiumname, "", -1, -1)
		g_wm_lbl_capacity.SetText(GroupDigits(g_wm_stadiumcap), "", -1, -1)
		g_wm_table.ClearItems()
		g_wm_pnl_year.SetText(TMyDate.Create(fix.sdate, 1, 1).GetString("WWWW"), "", -1, -1)
		For Local f:TFixture = EachIn g_wm_comp.lfixturelist
			If f.round = fix.round And f.sdate = f.sdate And f.leg = fix.leg
				Select g_wm_comp.level
				Case 0
					Local h1:TClub = TClub.SelectById(f.GetHomeTeamId())
					Local a1:TClub = TClub.SelectById(f.GetAwayTeamId())
					If h1 And a1
						g_wm_table.AddItem([g_wm_comp.GetStringTeamPosition(h1.id), h1.tla, a1.tla, g_wm_comp.GetStringTeamPosition(a1.id)], "", "")
						If h1.tla = g_profile.myclub.tla Or a1.tla = g_profile.myclub.tla
							g_wm_table.SelectItemByRow(g_wm_table.CountItems())
							g_wm_table.SetHighlightColour(h1.GetPrimaryColour())
						EndIf
					EndIf
				Case 1
					Local h2:TNation = TNation.SelectById(f.GetHomeTeamId())
					Local a2:TNation = TNation.SelectById(f.GetAwayTeamId())
					If h2 And a2
						g_wm_table.AddItem([g_wm_comp.GetStringTeamPosition(h2.id), h2.tla, a2.tla, g_wm_comp.GetStringTeamPosition(a2.id)], "", "")
						If h2.tla = g_profile.mynation.tla Or a2.tla = g_profile.mynation.tla
							g_wm_table.SelectItemByRow(g_wm_table.CountItems())
							g_wm_table.SetHighlightColour(h2.GetPrimaryColour())
						EndIf
					EndIf
				End Select
			EndIf
		Next
		g_wm_zoom = 1.0
		TScreen_WorldMap.UpdateTravelTime()
		If g_profile.helppages[20] = 0
			TScreen.Tutorial()
			g_profile.helppages[20] = 1
		EndIf
		If g_profile.prematchsaved = 0
			g_profile.SaveGame("")
			g_profile.prematchsaved = 1
		EndIf
	End Function
