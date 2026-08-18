' TScreen_Controls.RefreshButtons
' VA 0x005230AC   1990 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x40
' MATCH 1990/1990 (orig length from Ghidra's inventory), reloc_masked=126.
' Re-verified with NSS5_NO_LEARN=1 (no in-run helper-name learning): still 1990/1990.
'
' ASSUMPTIONS -- GLOBAL NAMES ARE OURS; every declared TYPE below is load-bearing, it picks
' the vtable slot at every call site.
'   0x00C5D1AC g_player_int14:Int    (0=Simple scheme, 1=Advanced -- same Global as
'                                     ButtonSimple/ButtonAdvanced in this Type)
'   0x00C640D4 g_pan_simple:TPanel   0x00C640D8 g_pan_advanced:TPanel   (CreateScreen)
'   0x00C61700 g_activescreen:TScreen (same Global as TScreen_Options.RefreshButtons;
'                                      .gadgetlist is TScreen field +0x0C :TList)
'   0x00C5D1A8 g_options_int01:Int   (current input device: 0=keyboard,1=joy1,2=joy2 --
'                                     same Global TPanel_Controls.RenderTraining calls
'                                     "icon-vs-text control style")
'   0x00C640D0 g_img_keys:TImage   0x00C640C8 g_img_joy1:TImage   0x00C640CC g_img_joy2:TImage
'   0x00C6E91C g_col_key:String      (CreateScreen's highlight colour for the kick rows)
'   0x00C5D1B4 g_options_arr02:Int[]   0x00C5D1BC g_options_arr03:Int[]
'   0x00C5D1C4 g_options_arr04:Int[]   0x00C5D1CC g_options_arr05:Int[]
'   0x00C5D1D4 g_options_arr06:Int[]   0x00C5D1DC g_options_arr07:Int[]
'   0x00C5D1E4 g_options_arr08:Int[]   0x00C5D1F4 g_options_arr10:Int[]
'   0x00C5D1FC g_options_arr11:Int[]
'      globals_final types all nine "Object[]"; they are Int[] -- each read is a plain
'      dword load with no refcount traffic (sec 10.7/11.2), indexed by g_options_int01 and
'      passed straight into TOptions.GetButtonLabel(i)$ / GetButtonIcon(i,i):TImage. One
'      array per control action (up/down/left/right/kick/kick2/kick3/pause/replay -- arr09
'      is not touched here, presumably TOptions.NewButtonKick4's array, unused on this
'      screen since it only has three kick rows).
'   Cross-Type static calls, resolved through class_tables.tsv, not guessed:
'      [0x00C5D54C] = TOptions+0x34 GetButtonLabel(i)$
'      [0x00C5D550] = TOptions+0x38 GetButtonIcon(i,i):TImage
'   GetText is the recovered module Function at 0x004C5549 (22 bytes).
'   TGadget slots used: 0x54 Hide()i, 0x58 Show()i, 0x64 SetText($,$,i,i)i, 0x6C
'   SetColour($,$)i; field +0x0C name:$ (the EachIn loop var's Select subject), field +0x38
'   alive:Int (raw store, not a method -- kick2/kick3 flip it 1/0 with the scheme).
'   TButton's own slots: 0x70 SetAlph(f)i, 0x90 SetIcon(:TImage)i.
'   The EachIn loop downcasts each TScreen.gadgetlist member to TButton via class table
'   0x00C62344 (= TButton+0x88 CreateButton's own table, confirmed against CreateScreen.bmx).
'   All 15 Case-subject strings and the four Text literals were read out of the exe with
'   harness.read_string, not invented: btn_joy, btn_scheme1, btn_scheme2, btn_up, btn_down,
'   btn_left, btn_right, btn_kick, btn_kick2, btn_kick3, btn_pause, btn_replay, lbl_kick,
'   lbl_kick2, lbl_kick3; GetText keys controls_Shoot/controls_Kick/controls_Pass/
'   controls_Lob. 0x00C5D284 is a zero-length BBString, i.e. "".
'
' NOTES ON SHAPE
'   * ALL THREE multi-way branches (the scheme-panel show/hide on g_player_int14, "btn_joy"
'     on g_options_int01, "btn_scheme1"/"btn_scheme2" on g_player_int14) are `Select`, not
'     `If/ElseIf` (sec 10.2): each loads its subject into eax ONCE and both/all three
'     compares run back to back with no interleaved body, closed by the Select-with-no-
'     -Default trailing `jmp`. The If/ElseIf form for these three came out 1 byte long.
'   * `Local d:Int = g_options_int01` is declared ONCE, immediately after the panel Select
'     and before the loop, and is what every "arrNN[d]" lookup uses; it lives in edi for the
'     rest of the function (`8B 3D A8 D1 C5 00`), i.e. a genuine cross-call-surviving Local,
'     not a decompiler artefact. "btn_joy"'s own icon Select still reads g_options_int01
'     fresh (a separate `mov eax,[DAT_00c5d1a8]`) rather than reusing `d` -- reproduced as
'     written, not tidied (law 3).
'   * `TOptions.GetButtonLabel(idx)` and `.GetButtonIcon(idx, 0)` each look like a 4-arg and
'     2-arg call respectively in the raw decompilation; the label call's extra 3 operands are
'     Ghidra folding SetText's own trailing pushes ("", -1, -1) into the indirect call it
'     cannot prototype (same artefact as CreateScreen's GetText, sec 7) -- confirmed against
'     the already-verified TPanel_Controls.RenderTraining/RenderKickToContinue, which use the
'     identical `b.SetText(TOptions.GetButtonLabel(x), "", -1, -1)` source form.
'!Global g_player_int14:Int
'!Global g_pan_simple:TPanel
'!Global g_pan_advanced:TPanel
'!Global g_activescreen:TScreen
'!Global g_options_int01:Int
'!Global g_img_keys:TImage
'!Global g_img_joy1:TImage
'!Global g_img_joy2:TImage
'!Global g_col_key:String
'!Global g_options_arr02:Int[]
'!Global g_options_arr03:Int[]
'!Global g_options_arr04:Int[]
'!Global g_options_arr05:Int[]
'!Global g_options_arr06:Int[]
'!Global g_options_arr07:Int[]
'!Global g_options_arr08:Int[]
'!Global g_options_arr10:Int[]
'!Global g_options_arr11:Int[]
	Function RefreshButtons:Int()
		Select g_player_int14
		Case 0
			g_pan_simple.Show()
			g_pan_advanced.Hide()
		Case 1
			g_pan_simple.Hide()
			g_pan_advanced.Show()
		End Select
		Local d:Int = g_options_int01
		For Local b:TButton = EachIn g_activescreen.gadgetlist
			Select b.name
			Case "btn_joy"
				Select g_options_int01
				Case 0
					b.SetIcon(g_img_keys)
				Case 1
					b.SetIcon(g_img_joy1)
				Case 2
					b.SetIcon(g_img_joy2)
				End Select
			Case "btn_scheme1"
				Select g_player_int14
				Case 0
					b.SetColour(g_col_key, "FFFFFF")
				Case 1
					b.SetColour("FFFFFF", "FFFFFF")
				End Select
			Case "btn_scheme2"
				Select g_player_int14
				Case 0
					b.SetColour("FFFFFF", "FFFFFF")
				Case 1
					b.SetColour(g_col_key, "FFFFFF")
				End Select
			Case "btn_up"
				b.SetText(TOptions.GetButtonLabel(g_options_arr02[d]), "", -1, -1)
				b.SetIcon(TOptions.GetButtonIcon(g_options_arr02[d], 0))
			Case "btn_down"
				b.SetText(TOptions.GetButtonLabel(g_options_arr03[d]), "", -1, -1)
				b.SetIcon(TOptions.GetButtonIcon(g_options_arr03[d], 0))
			Case "btn_left"
				b.SetText(TOptions.GetButtonLabel(g_options_arr04[d]), "", -1, -1)
				b.SetIcon(TOptions.GetButtonIcon(g_options_arr04[d], 0))
			Case "btn_right"
				b.SetText(TOptions.GetButtonLabel(g_options_arr05[d]), "", -1, -1)
				b.SetIcon(TOptions.GetButtonIcon(g_options_arr05[d], 0))
			Case "btn_kick"
				b.SetText(TOptions.GetButtonLabel(g_options_arr06[d]), "", -1, -1)
				b.SetIcon(TOptions.GetButtonIcon(g_options_arr06[d], 0))
			Case "btn_kick2"
				If g_player_int14 = 1
					b.SetAlph(1.0)
					b.alive = 1
					b.SetText(TOptions.GetButtonLabel(g_options_arr07[d]), "", -1, -1)
					b.SetIcon(TOptions.GetButtonIcon(g_options_arr07[d], 0))
				Else
					b.SetAlph(0.5)
					b.alive = 0
					b.SetText("", "", -1, -1)
					b.SetIcon(Null)
				EndIf
			Case "btn_kick3"
				If g_player_int14 = 1
					b.SetAlph(1.0)
					b.alive = 1
					b.SetText(TOptions.GetButtonLabel(g_options_arr08[d]), "", -1, -1)
					b.SetIcon(TOptions.GetButtonIcon(g_options_arr08[d], 0))
				Else
					b.SetAlph(0.5)
					b.alive = 0
					b.SetText("", "", -1, -1)
					b.SetIcon(Null)
				EndIf
			Case "btn_pause"
				b.SetText(TOptions.GetButtonLabel(g_options_arr10[d]), "", -1, -1)
				b.SetIcon(TOptions.GetButtonIcon(g_options_arr10[d], 0))
			Case "btn_replay"
				b.SetText(TOptions.GetButtonLabel(g_options_arr11[d]), "", -1, -1)
				b.SetIcon(TOptions.GetButtonIcon(g_options_arr11[d], 0))
			Case "lbl_kick"
				If g_player_int14 = 1
					b.SetText(GetText("controls_Shoot"), "", -1, -1)
				Else
					b.SetText(GetText("controls_Kick"), "", -1, -1)
				EndIf
			Case "lbl_kick2"
				If g_player_int14 = 1
					b.SetAlph(1.0)
					b.SetText(GetText("controls_Pass"), "", -1, -1)
				Else
					b.SetAlph(0.5)
					b.SetText("", "", -1, -1)
				EndIf
			Case "lbl_kick3"
				If g_player_int14 = 1
					b.SetAlph(1.0)
					b.SetText(GetText("controls_Lob"), "", -1, -1)
				Else
					b.SetAlph(0.5)
					b.SetText("", "", -1, -1)
				EndIf
			End Select
		Next
	End Function
