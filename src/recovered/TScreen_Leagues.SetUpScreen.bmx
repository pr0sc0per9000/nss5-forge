' TScreen_Leagues.SetUpScreen
' VA 0x00545038   446 bytes   vtable slot 0x34   sig (i)i
' byte-identical vs NSS5.exe (446/446, original length from Ghidra's inventory)
' VA        0x00545038   slot 0x34   KIND=Function (static)   SIG=(i)i
' ORACLE    MATCH mode=reloc  446/446 bytes  reloc_masked=33
'
' GLOBALS DECLARED (names are ours; the TYPES are load-bearing)
'   g_combo_continent:TCombo   = 0x00C66F30
'   g_combo_nation:TCombo      = 0x00C66F34
'   g_combo_league:TCombo      = 0x00C66F38
'   g_combo_club:TCombo        = 0x00C66F3C
'       All four typed TCombo by globals_final (construction, 1 site each) AND confirmed
'       by their slots here: 0xB8 = TCombo.CountItems(), 0x90 = TCombo.AddItem($,$,$,i),
'       0xB0 = TCombo.SelectItemById(i).  All three exist on TCombo itself.
'   g_leagues_setupid:Int      = 0x00C66F40   (bare dword mov, no refcount traffic)
'   g_continents:TList         = 0x00C6080C
'       globals_final says Object/low.  It is a TList: the loop opens with slot 0x8C
'       (TList.ObjectEnumerator) and drives 0x30/0x34 on the result (guide 5, 10.7).
'       Elements are downcast to the TContinent class table at 0x00C60958.
'   g_profile:TProfile         = 0x00C6F028   (same Global as ButtonPainKillers)
'
' CALL TARGETS RESOLVED
'   0x00C61C88 -> TScreen + 0x5C   = TScreen.SetActive($,$):TScreen
'   0x00C59E40 -> TClub + 0x94     = TClub.SortListBy(i,i)
'   0x00C616DC -> TCompetition+0x11C = TCompetition.SortListBy(i,i)
'   0x00C59A40 -> TNation + 0x78   = TNation.SortListBy(i,i)
'   0x00C59E0C -> TClub + 0x60     = TClub.SelectById(i):TClub
'   0x00C59A20 -> TNation + 0x58   = TNation.SelectById(i):TNation
'   0x00C67190/94/98/9C -> TScreen_Leagues + 0x3C/0x40/0x44/0x48
'                        = ComboContinent / ComboNation / ComboLeague / ComboClub
'   0x00C671C0 -> TScreen_Leagues + 0x6C = RefreshComboColours()
'   0x00C61CE0 -> TScreen + 0xB4   = TScreen.Tutorial()
'   TClub slot 0x68 = TClub.GetActualLeagueId()i
'
' FIELDS
'   TContinent.id(+8) / .name(+0xC);  TClub.nationid(+0x64);  TNation.continent(+0x64);
'   TProfile.clubid(+0x20);  TProfile.helppages:Int[](+0x1C8) -- `[eax+0x20]` is data(+0x18)
'   plus 8, i.e. element index 2.
'
' STRING LITERALS read out of NSS5.exe's BBString pool: "leagues", "", "BBBBBB", "FFFFFF".
'
' NOTE
'   `If lid = 0` tests the LOCAL (`cmp ebx,0`), while the later `If g_leagues_setupid = 0`
'   re-reads the Global (`cmp dword [0x00C66F40],0`) -- guide 10.6.  Getting those the
'   wrong way round changes the bytes.

Function SetUpScreen(a0:Int)
	'!Global g_leagues_setupid:Int
	'!Global g_combo_continent:TCombo
	'!Global g_continents:TList
	'!Global g_profile:TProfile
	'!Global g_combo_nation:TCombo
	'!Global g_combo_league:TCombo
	'!Global g_combo_club:TCombo
	TScreen.SetActive("leagues", "")
	g_leagues_setupid = a0
	TClub.SortListBy(2, 1)
	TCompetition.SortListBy(1, 1)
	TNation.SortListBy(2, 1)
	If g_combo_continent.CountItems() = 0
		For Local c:TContinent = EachIn g_continents
			g_combo_continent.AddItem(c.name, "BBBBBB", "FFFFFF", c.id)
		Next
	EndIf
	Local clubid:Int = g_profile.clubid
	Local club:TClub = TClub.SelectById(clubid)
	Local nid:Int = club.nationid
	Local cont:Int = TNation.SelectById(nid).continent
	Local lid:Int = g_leagues_setupid
	If lid = 0 Then lid = club.GetActualLeagueId()
	g_combo_continent.SelectItemById(cont)
	TScreen_Leagues.ComboContinent()
	g_combo_nation.SelectItemById(nid)
	TScreen_Leagues.ComboNation()
	g_combo_league.SelectItemById(lid)
	TScreen_Leagues.ComboLeague()
	If g_leagues_setupid = 0
		g_combo_club.SelectItemById(clubid)
		TScreen_Leagues.ComboClub()
	EndIf
	g_leagues_setupid = 0
	TScreen_Leagues.RefreshComboColours()
	If g_profile.helppages[2] = 0
		TScreen.Tutorial()
		g_profile.helppages[2] = 1
	EndIf
End Function
