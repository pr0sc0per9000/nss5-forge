' TPanel_Controls.RenderTraining
' VA 0x005849F2   4218 bytes   mode=reloc   byte-identical vs NSS5.exe
' (4218/4218, original length from Ghidra's inventory, reloc_masked=336; re-verified with
'  NSS5_NO_LEARN=1 so no call operand was masked by a name this run taught the table)
' KIND=Function (static, no implicit Self), SIG (f,f)i, class-table slot 0x34
'
' ASSUMPTIONS
'   Module Globals -- the ADDRESSES are fact, the NAMES are ours (module Globals have no
'   debug record). Every declared TYPE below is load-bearing: it picks the vtable slot.
'     0x00C6DD50 g_ctl_panel:TPanel     (globals_final: construction site; slot 0x84 =
'                                        TGadget.SetPosition(i,i,i), 0x44 = TPanel.Draw)
'     0x00C6DD60 g_ctl_lbl:TLabel[]     (elements take slot 0x64 = TGadget.SetText($,$,i,i)
'                                        and slot 0x8C = TLabel.SetIcon(:TImage) -- 0x8C on
'                                        TButton is SetImage, so TLabel is the load-bearing
'                                        choice; fields +0x10 txt:$ and +0x68 icon:TImage
'                                        are TGadget/TLabel and confirm it)
'     0x00C5D1B4 g_key_a:Int[]   0x00C5D1BC g_key_b:Int[]   0x00C5D1C4 g_key_c:Int[]
'     0x00C5D1CC g_key_d:Int[]   0x00C5D1D4 g_key_e:Int[]   0x00C5D1DC g_key_f:Int[]
'     0x00C5D1E4 g_key_g:Int[]   0x00C5D1F4 g_key_i:Int[]
'        globals_final types these Object[]; they are Int[]. Element [0] is passed to
'        TOptions.GetButtonLabel(i)$ and element [1] to TOptions.GetButtonIcon(i,i):TImage,
'        both plain dword loads with no refcount traffic (sec 10.7 / 11.2).
'        Semantically each is a {keycode, joybutton} pair for one action:
'        a/b/c/d = the four direction keys (tested against 37..40 = the cursor-key range),
'        e = primary action, f/g = the two-button variants, i = pause.
'     0x00C5D218 g_icon_none:TImage  (globals_final "Object, low"; passed to TLabel.SetIcon)
'     0x00C5D1A8 g_options_int01:Int (icon-vs-text control style; Select 0/1)
'     0x00C5D1AC g_player_int14:Int  (control scheme: 0 = one button, 1 = two buttons)
'     0x00C6CF90 g_training_int03:Int (training drill id)  0x00C6CF98 g_training_int05:Int
'   Cross-Type static calls, resolved through the class tables, not guessed:
'     [0x00C5D54C] = TOptions+0x34 GetButtonLabel(i)$      [0x00C5D550] = TOptions+0x38
'     GetButtonIcon(i,i):TImage    [0x00C5AEDC] = TBall+0x44 GetActiveBall():TBall
'   TBall +0x70 controlledby:TPlayer, TPlayer +0x08 newstar:Int (object_model.json).
'   GetText is the recovered module Function at 0x004C5549; all 18 literals below were
'   read out of the exe with harness.read_string, not invented.
'   `Local yspace:Int = 34` is the source form behind `mov esi,0x22` at the prologue: the
'   in-loop `a1 :+ yspace` emits mov [ebp-4],esi / fild, whereas the pre-loop `a1 :+ 34.0`
'   uses the Float constant at 0x00C92E18. Two different 34s, and the bytes distinguish them.
'   Every `Case 0 / Case 1` on g_player_int14 is a Select, not If/ElseIf (sec 10.2): the
'   subject is loaded once and both compares are emitted back to back.
'
'!Global g_ctl_panel:TPanel
'!Global g_ctl_lbl:TLabel[]
'!Global g_key_a:Int[]
'!Global g_key_b:Int[]
'!Global g_key_c:Int[]
'!Global g_key_d:Int[]
'!Global g_key_e:Int[]
'!Global g_key_f:Int[]
'!Global g_key_g:Int[]
'!Global g_key_i:Int[]
'!Global g_icon_none:TImage
'!Global g_options_int01:Int
'!Global g_player_int14:Int
'!Global g_training_int03:Int
'!Global g_training_int05:Int
Local yspace:Int = 34
g_ctl_panel.SetPosition(Int(a0), Int(a1), 1)
g_ctl_panel.Draw()
a0 :+ 6.0
a1 :+ 34.0
For Local i:Int = 0 To 4
	g_ctl_lbl[i].x = a0
	g_ctl_lbl[i].y = a1
	g_ctl_lbl[i].SetText("", "", -1, -1)
	g_ctl_lbl[i].SetIcon(Null)
	g_ctl_lbl[i + 5].x = a0 + 52.0
	g_ctl_lbl[i + 5].y = a1
	g_ctl_lbl[i + 5].SetText("", "", -1, -1)
	a1 :+ yspace
Next
Local s:String
If g_key_c[0] >= 37 And g_key_a[0] <= 40
	s = GetText("controls_CursorKeys")
Else
	s = TOptions.GetButtonLabel(g_key_a[0]) + "," + TOptions.GetButtonLabel(g_key_c[0]) + "," + TOptions.GetButtonLabel(g_key_b[0]) + "," + TOptions.GetButtonLabel(g_key_d[0])
EndIf
g_ctl_lbl[0].SetText(s, "", -1, -1)
g_ctl_lbl[0].SetIcon(g_icon_none)
If g_training_int03 = 3 Or g_training_int03 = 6 Or g_training_int03 = 10
	g_ctl_lbl[5].SetText(GetText("controls_Aim"), "", -1, -1)
Else
	g_ctl_lbl[5].SetText(GetText("controls_Run"), "", -1, -1)
EndIf
If g_training_int03 = 1 Or g_training_int03 = 2
	g_ctl_lbl[1].SetText(TOptions.GetButtonLabel(g_key_i[0]), "", -1, -1)
	g_ctl_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_i[1], 0))
	g_ctl_lbl[6].SetText(GetText("controls_Pause"), "", -1, -1)
	If g_training_int05 = 0
		g_ctl_lbl[2].SetText(TOptions.GetButtonLabel(g_key_e[0]), "", -1, -1)
		g_ctl_lbl[2].SetIcon(TOptions.GetButtonIcon(g_key_e[1], 0))
		g_ctl_lbl[7].SetText(GetText("controls_Kick"), "", -1, -1)
	EndIf
ElseIf g_training_int03 = 4 Or g_training_int03 = 5
	Select g_player_int14
	Case 0
		g_ctl_lbl[1].SetText(TOptions.GetButtonLabel(g_key_e[0]), "", -1, -1)
		g_ctl_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_e[1], 0))
		g_ctl_lbl[6].SetText(GetText("controls_Tackle"), "", -1, -1)
	Case 1
		g_ctl_lbl[1].SetText(TOptions.GetButtonLabel(g_key_g[0]), "", -1, -1)
		g_ctl_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_g[1], 0))
		g_ctl_lbl[6].SetText(GetText("controls_Tackle"), "", -1, -1)
	End Select
ElseIf g_training_int03 = 3 Or g_training_int03 = 6 Or g_training_int03 = 10
	Select g_player_int14
	Case 0
		g_ctl_lbl[1].SetText(TOptions.GetButtonLabel(g_key_e[0]), "", -1, -1)
		g_ctl_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_e[1], 0))
		g_ctl_lbl[6].SetText(GetText("controls_Kick"), "", -1, -1)
	Case 1
		g_ctl_lbl[1].SetText(TOptions.GetButtonLabel(g_key_f[0]), "", -1, -1)
		g_ctl_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_f[1], 0))
		g_ctl_lbl[6].SetText(GetText("controls_Pass"), "", -1, -1)
		g_ctl_lbl[2].SetText(TOptions.GetButtonLabel(g_key_g[0]), "", -1, -1)
		g_ctl_lbl[2].SetIcon(TOptions.GetButtonIcon(g_key_g[1], 0))
		g_ctl_lbl[7].SetText(GetText("controls_Lob"), "", -1, -1)
		g_ctl_lbl[3].SetText(TOptions.GetButtonLabel(g_key_e[0]), "", -1, -1)
		g_ctl_lbl[3].SetIcon(TOptions.GetButtonIcon(g_key_e[1], 0))
		g_ctl_lbl[8].SetText(GetText("controls_Shoot"), "", -1, -1)
	End Select
ElseIf g_training_int03 = 7 Or g_training_int03 = 8
	Select g_player_int14
	Case 0
		g_ctl_lbl[1].SetText(TOptions.GetButtonLabel(g_key_e[0]), "", -1, -1)
		g_ctl_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_e[1], 0))
		g_ctl_lbl[6].SetText(GetText("controls_Head"), "", -1, -1)
	Case 1
		g_ctl_lbl[1].SetText(TOptions.GetButtonLabel(g_key_f[0]), "", -1, -1)
		g_ctl_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_f[1], 0))
		g_ctl_lbl[6].SetText(GetText("controls_HeadLow"), "", -1, -1)
		g_ctl_lbl[2].SetText(TOptions.GetButtonLabel(g_key_g[0]), "", -1, -1)
		g_ctl_lbl[2].SetIcon(TOptions.GetButtonIcon(g_key_g[1], 0))
		g_ctl_lbl[7].SetText(GetText("controls_HeadHigh"), "", -1, -1)
		g_ctl_lbl[3].SetText(TOptions.GetButtonLabel(g_key_e[0]), "", -1, -1)
		g_ctl_lbl[3].SetIcon(TOptions.GetButtonIcon(g_key_e[1], 0))
		g_ctl_lbl[8].SetText(GetText("controls_HeadHard"), "", -1, -1)
	End Select
ElseIf g_training_int03 = 9
	Local b:TBall = TBall.GetActiveBall()
	If b <> Null And b.controlledby <> Null And b.controlledby.newstar
		Select g_player_int14
		Case 0
			g_ctl_lbl[1].SetText(TOptions.GetButtonLabel(g_key_e[0]), "", -1, -1)
			g_ctl_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_e[1], 0))
			g_ctl_lbl[6].SetText(GetText("controls_Kick"), "", -1, -1)
		Case 1
			g_ctl_lbl[1].SetText(TOptions.GetButtonLabel(g_key_f[0]), "", -1, -1)
			g_ctl_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_f[1], 0))
			g_ctl_lbl[6].SetText(GetText("controls_Pass"), "", -1, -1)
			g_ctl_lbl[2].SetText(TOptions.GetButtonLabel(g_key_g[0]), "", -1, -1)
			g_ctl_lbl[2].SetIcon(TOptions.GetButtonIcon(g_key_g[1], 0))
			g_ctl_lbl[7].SetText(GetText("controls_Lob"), "", -1, -1)
			g_ctl_lbl[3].SetText(TOptions.GetButtonLabel(g_key_e[0]), "", -1, -1)
			g_ctl_lbl[3].SetIcon(TOptions.GetButtonIcon(g_key_e[1], 0))
			g_ctl_lbl[8].SetText(GetText("controls_Shoot"), "", -1, -1)
		End Select
	Else
		Select g_player_int14
		Case 0
			g_ctl_lbl[1].SetText(TOptions.GetButtonLabel(g_key_e[0]), "", -1, -1)
			g_ctl_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_e[1], 0))
			g_ctl_lbl[6].SetText(GetText("controls_Call"), "", -1, -1)
		Case 1
			g_ctl_lbl[1].SetText(TOptions.GetButtonLabel(g_key_f[0]), "", -1, -1)
			g_ctl_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_f[1], 0))
			g_ctl_lbl[6].SetText(GetText("controls_CallLow"), "", -1, -1)
			g_ctl_lbl[2].SetText(TOptions.GetButtonLabel(g_key_g[0]), "", -1, -1)
			g_ctl_lbl[2].SetIcon(TOptions.GetButtonIcon(g_key_g[1], 0))
			g_ctl_lbl[7].SetText(GetText("controls_CallHigh"), "", -1, -1)
			g_ctl_lbl[3].SetText(TOptions.GetButtonLabel(g_key_e[0]), "", -1, -1)
			g_ctl_lbl[3].SetIcon(TOptions.GetButtonIcon(g_key_e[1], 0))
			g_ctl_lbl[8].SetText(GetText("controls_CallHard"), "", -1, -1)
		End Select
	EndIf
EndIf
If g_player_int14 = 0
	If g_training_int03 = 1 Or g_training_int03 = 2
		g_ctl_lbl[1].SetText(TOptions.GetButtonLabel(g_key_i[0]), "", -1, -1)
		g_ctl_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_i[1], 0))
		g_ctl_lbl[6].SetText(GetText("controls_Pause"), "", -1, -1)
	Else
		g_ctl_lbl[2].SetText(TOptions.GetButtonLabel(g_key_i[0]), "", -1, -1)
		g_ctl_lbl[2].SetIcon(TOptions.GetButtonIcon(g_key_i[1], 0))
		g_ctl_lbl[7].SetText(GetText("controls_Pause"), "", -1, -1)
	EndIf
EndIf
For Local i:Int = 0 To 4
	Select g_options_int01
	Case 0
		g_ctl_lbl[i].icon = Null
	Case 1
		If g_ctl_lbl[i].icon <> Null
			g_ctl_lbl[i].txt = ""
		EndIf
	End Select
	If g_ctl_lbl[i].icon <> Null Or g_ctl_lbl[i].txt.Length
		g_ctl_lbl[i].Draw()
	EndIf
	If g_ctl_lbl[i + 5].txt.Length
		g_ctl_lbl[i + 5].Draw()
	EndIf
Next
