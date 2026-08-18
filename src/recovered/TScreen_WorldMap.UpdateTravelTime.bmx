' TScreen_WorldMap.UpdateTravelTime   (KIND=Function -- static, no Self)
' VA 0x0055BB02   1385 bytes   (Ghidra-authoritative)
' byte-identical vs NSS5.exe (1385/1385, original length from Ghidra's inventory)
' ORACLE: mode=reloc  matched=1385/1385  reloc_masked=114  STATUS=MATCH
'
' ASSUMPTIONS / RESOLUTIONS
'   0x00C6F028 g_profile:TProfile; 0x00C6842C g_wm_comp:TCompetition (both typed from
'     their construction sites in globals_final).
'   0x00C68414 TPanel, 0x00C68418 TProgressBar, 0x00C6841C/20/24 TButton -- the music,
'     game and film upgrade buttons in THAT address order (0x20 is the game button:
'     it pairs with profile.boughtgame and items[1]).
'   0x00C68428 g_wm_int01:Int is the travel time in days; 0x00C68440/44 the map cursor
'     lat/long; 0x00C8C0C8 g_wm_float07:Float the fixed international distance.
'   TProfile: mynation +0x1CC, myclub +0x1D0, selectedformatch +0x1D8, energy +0x15C,
'     injury +0x16C, boughtmusic +0x17C, boughtgame +0x180, boughtfilm +0x184,
'     items:Int[] +0xF0 (element k at +0x18+4k, so [eax+0x1C] is items[1]).
'   TCompetition: locale +0x18, level +0x1C, compstatus +0x50.
'   TGadget slots: Hide 0x54, Show 0x58, SetText 0x64, SetColour 0x6C, SetAlph 0x70;
'     TProgressBar SetPercent 0x8C, SetOldPercent 0x90.  alive is TGadget +0x38.
'   ClampInt/ClampFloat take a POINTER (src/recovered_module), hence Varptr.
'   Literals read out of the exe: the six time_* locale keys, "Travel Time",
'     "Energy After Travelling", "Distance:", ": ", "%", "00FF00".
'   0x00C8C0C4 is the float constant 0.0 -- an explicit "d = 0.0" loads it from .rdata
'     rather than emitting fldz (which is what a bare Local declaration emits).

'!Global g_profile:TProfile
'!Global g_wm_comp:TCompetition
'!Global g_wm_int01:Int
'!Global g_wm_float01:Float
'!Global g_wm_float02:Float
'!Global g_wm_float07:Float
'!Global g_wm_panel:TPanel
'!Global g_wm_bar:TProgressBar
'!Global g_wm_btn_music:TButton
'!Global g_wm_btn_game:TButton
'!Global g_wm_btn_film:TButton

	Function UpdateTravelTime()
		Local d:Float = Dist2D(g_profile.myclub.stadiumlongitude, g_profile.myclub.stadiumlatitude, g_wm_float02, g_wm_float01)
		If g_wm_comp.level = 1
			d = Dist2D(g_profile.mynation.stadiumlongitude, g_profile.mynation.stadiumlatitude, g_wm_float02, g_wm_float01)
			If g_profile.selectedformatch < 0
				d = 0.0
			End If
			If g_wm_comp.locale = 2 Or g_wm_comp.compstatus = 1
				d = g_wm_float07
			End If
		End If
		g_wm_int01 = Int(d * 3.5)
		If g_profile.injury
			g_wm_int01 = 0
		End If
		LogLine("Distance:" + String(d))
		Local s:String = GetText("Travel Time") + ": "
		If g_wm_int01 > 40
			g_wm_int01 = 40
			s :+ GetText("time_VeryLong")
		ElseIf g_wm_int01 > 30
			s :+ GetText("time_Long")
		ElseIf g_wm_int01 > 20
			s :+ GetText("time_Medium")
		ElseIf g_wm_int01 > 10
			s :+ GetText("time_Short")
		ElseIf g_wm_int01 > 5
			s :+ GetText("time_VeryShort")
		Else
			g_wm_int01 = 0
			s :+ GetText("time_None")
		End If
		If g_profile.boughtgame
			g_wm_int01 :- 5
		End If
		If g_profile.boughtmusic
			g_wm_int01 :- 10
		End If
		If g_profile.boughtfilm
			g_wm_int01 :- 15
		End If
		ClampInt(Varptr g_wm_int01, 0, 50)
		g_wm_panel.SetText(s, "", -1, -1)
		Local e:Float = g_profile.energy - g_wm_int01
		ClampFloat(Varptr e, 0, 100.0)
		If g_wm_int01 > 0 Or g_profile.boughtfilm Or g_profile.boughtgame Or g_profile.boughtmusic
			g_wm_panel.Show()
			g_wm_bar.SetPercent(e, 1)
			g_wm_bar.SetOldPercent(g_profile.energy, 0)
			g_wm_bar.SetText(GetText("Energy After Travelling") + ": " + Int(e) + "%", "", -1, -1)
		Else
			g_wm_panel.Hide()
		End If
		g_wm_bar.SetColour("", "00FF00")
		g_wm_btn_game.SetAlph(1.0)
		g_wm_btn_game.alive = 1
		If g_profile.items[1] = 0
			g_wm_btn_game.SetAlph(0.5)
		End If
		If g_wm_int01 = 0 Or g_profile.boughtgame
			g_wm_btn_game.SetAlph(0.5)
			g_wm_btn_game.alive = 0
		End If
		g_wm_btn_music.SetAlph(1.0)
		g_wm_btn_music.alive = 1
		If g_profile.items[2] = 0
			g_wm_btn_music.SetAlph(0.5)
		End If
		If g_wm_int01 = 0 Or g_profile.boughtmusic
			g_wm_btn_music.SetAlph(0.5)
			g_wm_btn_music.alive = 0
		End If
		g_wm_btn_film.SetAlph(1.0)
		g_wm_btn_film.alive = 1
		If g_profile.items[3] = 0
			g_wm_btn_film.SetAlph(0.5)
		End If
		If g_wm_int01 = 0 Or g_profile.boughtfilm
			g_wm_btn_film.SetAlph(0.5)
			g_wm_btn_film.alive = 0
		End If
	End Function
