' TScreen_MatchPaused.SetUpScreen
' VA 0x0054ABFC   541 bytes  mode=reloc  byte-identical vs NSS5.exe (541/541, original
' length from Ghidra's inventory, reloc_masked=40)
' KIND=Function (static method on TScreen_MatchPaused), SIG (:TImage)i, slot 0x34
'
' ASSUMPTIONS (names of Globals are ours; the declared TYPE is load-bearing)
'  0x00C6764C g_scr_matchpaused : TScreen  -- globals_final "TScreen (construction)". The
'             store is to +0x10 = TScreen.bg:TImage, with full retain/release traffic.
'  0x00C67650 g_mp_btn1 : TButton  -- slot 0x70 = TButton.SetAlph(f); +0x38 = TGadget.alive
'  0x00C67654 g_mp_btn2 : TButton
'  0x00C67658 g_mp_btn3 : TButton  -- slot 0x64 = TGadget.SetText($,$,i,i),
'                                     slot 0x80 = TGadget.CreateToolTip($)
'  0x00C5B218 g_team_home : TTeam  -- globals_final types this TKit, which is WRONG: TKit
'             has no field at +0x3c (its fields stop at +0x10). +0x3c is TTeam.newstarselno.
'  0x00C5B21C g_team_away : TTeam  -- globals_final agrees (TTeam, construction).
'  0x00C6CF90 g_trainingmode : Int -- bare dword compare, no refcount traffic.
'  Class-table slots resolved: TScreen+0x5c = SetActive($,$):TScreen (static),
'  TPlayer+0x164 = GetHumanPlayer():TPlayer (static).
'  Direct call 0x004C5549 -> GetText (src/recovered_module/GetText.bmx).
'  All six string literals read out of NSS5.exe with harness.read_string.
'
' NOTES ON FORM
'  The guard is `If g_trainingmode > 0` with the training arm FIRST: the original emits
'  `cmp [g],0 / jle else`. Writing it as `If g < 1` with the arms swapped is the same
'  length but diverges at byte 73.
'  `p.selectionno >= 0` emits cmp eax,0 / setge; `> -1` emits cmp eax,-1 / setg and
'  diverges at byte 431 (guide 10.1).
	Function SetUpScreen:Int(a0:TImage)
		'!Global g_scr_matchpaused:TScreen
		'!Global g_mp_btn1:TButton
		'!Global g_mp_btn2:TButton
		'!Global g_mp_btn3:TButton
		'!Global g_team_home:TTeam
		'!Global g_team_away:TTeam
		'!Global g_trainingmode:Int
		TScreen.SetActive("matchpaused", "")
		If a0 <> Null Then g_scr_matchpaused.bg = a0
		If g_trainingmode > 0
			g_mp_btn1.SetAlph(0.5)
			g_mp_btn1.alive = 0
			g_mp_btn2.SetAlph(0.5)
			g_mp_btn2.alive = 0
			g_mp_btn3.SetText(GetText("Quit"), "", -1, -1)
			g_mp_btn3.CreateToolTip(GetText("skiptime_EndTraining"))
		Else
			g_mp_btn1.SetAlph(1.0)
			g_mp_btn1.alive = 1
			g_mp_btn2.SetAlph(1.0)
			g_mp_btn2.alive = 1
			g_mp_btn3.SetText(GetText("Skip Time"), "", -1, -1)
			If g_team_home.newstarselno = 11 Or g_team_away.newstarselno = 11
				g_mp_btn3.CreateToolTip(GetText("skiptime_SubstitutionOn"))
			Else
				Local p:TPlayer = TPlayer.GetHumanPlayer()
				If p <> Null And p.selectionno >= 0 And p.selectionno < 11
					g_mp_btn3.CreateToolTip(GetText("skiptime_SubstitutionOff"))
				Else
					g_mp_btn3.CreateToolTip(GetText("skiptime_EndMatch"))
				EndIf
			EndIf
		EndIf
	End Function
