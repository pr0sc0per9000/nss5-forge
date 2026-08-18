' TScreen_Formation.SetUpScreen  -- KIND=Function (static), slot 0x34, sig (i)i
' VA 0x0054BA26   635 bytes
' byte-identical vs NSS5.exe (635/635, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=64)
'
' ASSUMPTIONS
'  * Globals (names ours; only the FIELD OFFSETS a declared type produces are byte-visible,
'    so a type is load-bearing exactly as far as the offsets it supplies):
'      0x00C6F028 -> g_profile:TProfile  (+0x2C newstarselno, +0x38 internationalselno,
'                                         +0x1C8 helppages:Int[], +0x1E4 formationchanged)
'      0x00C5B22C -> g_fixture:TFixture  -- only field +0x3C is read (TFixture.level).
'        globals_final.tsv says TPlayer on the "only TPlayer has them all" heuristic that
'        guide 11.2 flags as unsafe; TFixture.level fits the use (international ->
'        internationalselno). UNSURE about the identity; the OFFSET is what is verified.
'      0x00C677B0 -> g_formteam:TTeam    0x00C5B218/0x00C5B21C -> g_team1/g_team2:TTeam
'        (+0x18 controller, +0x0C name, +0x2C kitplayer:TKit, TKit +0x10 newcol:String[])
'      0x00C677A0 -> g_formscreen:TScreen (slot 0x90 GetGadgetByName($), slot 0x60
'                                          SetActiveGadget($))
'      0x00C677A4 -> g_formbtn:TButton    (slot 0x90 SetIcon(:TImage))
'      0x00C6F274/0x00C6F194 -> TImage globals passed to SetIcon
'      0x00C677D8 -> g_formmode:Int   0x00C677D4 -> g_formselno:Int
'      0x00C677DC -> g_formsel:Int
'  * 0x0059CC21 = _brl_standardio_Print -- this function opens with `Print`, not LogLine.
'  * 0x004C5549 = GetText (src/recovered_module/), a ONE-argument function; the two extra
'    pushes Ghidra shows belong to the following TScreen.DoMessage($,i,i) call
'    (`add esp,4` then `add esp,0xC` proves the split).
'  * Class-table calls: 0x00C61C88 TScreen+0x5C SetActive($,$), 0x00C61CE0 TScreen+0xB4
'    Tutorial, 0x00C61CC0 TScreen+0x94 DoMessage($,i,i), 0x00C67980 TScreen_Formation+0x3C
'    RefreshButtons, 0x00C67988 TScreen_Formation+0x44 CheckPosition (own type -> written
'    unprefixed, guide 3d).
'  * TGadget slots 0x64 SetText($,$,i,i) and 0x6C SetColour($,$), inherited by TButton.
'  * `g_formteam = Null` is the `mov ebx,0x5C9C80 / inc [ebx+4]` retain-of-bbNullObject
'    plus release-of-old idiom, i.e. one assignment statement.
'  * The mode dispatch is a Select (two Case compares back to back, then a jmp past both).
'  * helppages index 19: `[eax+0x64]` = BBArray data (+0x18) + 19*4.
	Function SetUpScreen:Int(a0:Int)
		'!Global g_profile:TProfile
		'!Global g_fixture:TFixture
		'!Global g_formmode:Int
		'!Global g_formselno:Int
		'!Global g_formteam:TTeam
		'!Global g_team1:TTeam
		'!Global g_team2:TTeam
		'!Global g_formscreen:TScreen
		'!Global g_formbtn:TButton
		'!Global g_imgteam1:TImage
		'!Global g_imgteam2:TImage
		'!Global g_formsel:Int
		Print "TScreen_Formation.SetUpScreen"
		g_formmode = a0
		g_formselno = g_profile.newstarselno
		If g_fixture.level = 1
			g_formselno = g_profile.internationalselno
		End If
		g_formteam = Null
		Select g_formmode
			Case 0
				g_formbtn.SetIcon(g_imgteam1)
				If g_team1.controller = 1
					g_formteam = g_team1
				ElseIf g_team2.controller = 1
					g_formteam = g_team2
				End If
			Case 1
				g_formsel = 0
				g_formbtn.SetIcon(g_imgteam2)
				If g_team1.controller = 1
					g_formteam = g_team2
				ElseIf g_team2.controller = 1
					g_formteam = g_team1
				End If
		End Select
		If g_formteam <> Null
			Local b:TButton = TButton(g_formscreen.GetGadgetByName("btn_team"))
			b.SetText(g_formteam.name, "", -1, -1)
			b.SetColour(g_formteam.kitplayer.newcol[4], "FFFFFF")
			TScreen.SetActive("formation", "")
			g_formscreen.SetActiveGadget("btn_play")
			RefreshButtons()
			If g_formmode = 0
				CheckPosition()
			End If
		End If
		If g_profile.helppages[19] = 0
			TScreen.Tutorial()
			g_profile.helppages[19] = 1
		End If
		If g_profile.formationchanged = 1
			TScreen.DoMessage(GetText("CMESSAGE_BOSSCHANGINGFORMATION"), 0, 0)
			g_profile.formationchanged = 2
		End If
	End Function
