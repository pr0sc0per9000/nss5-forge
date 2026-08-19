' TPanel_Controls.RenderReplay
' VA 0x00585A6C   1266 bytes   mode=reloc   byte-identical vs NSS5.exe (matched 1266/1266)
' KIND=Function (static, no implicit Self), SIG (i,i)i, class-table slot 0x38
'
' ASSUMPTIONS
'   Module Globals -- ADDRESSES are fact, declared TYPES are load-bearing (they pick the
'   vtable slot), NAMES are ours except where an established name already exists elsewhere
'   in the corpus (reused verbatim from TPanel_Controls.SetUp.bmx / RenderTraining.bmx):
'     0x00C6DD54 g_ctl_panel:TPanel        (= g_panel_controls_panreplay in SetUp.bmx/
'                                           CreateScreen-style callers; slot 0x84 =
'                                           TGadget.SetPosition(i,i,i)i, 0x44 = TPanel.Draw)
'     0x00C6DD60 g_ctl_lbl:TLabel[]        (SAME array TPanel_Controls.SetUp.bmx populates
'                                           with TLabel.CreateLabel -- NOT TButton as an
'                                           earlier sibling file (RenderPauseReplay.bmx)
'                                           guessed. TLabel.icon sits at +0x68, the same
'                                           offset TButton.icon happens to occupy, and slot
'                                           0x8C is TLabel.SetIcon(:TImage)i -- signature-
'                                           identical to TButton.SetImage at the same slot --
'                                           so both declarations compile to the same bytes;
'                                           TLabel is the choice corroborated by SetUp.bmx and
'                                           by TPanel_Controls.RenderTraining.bmx (4218/4218).
'     0x00C5D1B4 g_key_a:Int[]   0x00C5D1C4 g_key_c:Int[]   0x00C5D1CC g_key_d:Int[]
'     0x00C5D1D4 g_key_e:Int[]    -- globals_final.tsv types these Object[]; they are Int[]:
'                                    element [0]/[1] are plain dword loads (no refcount
'                                    traffic, rule 11.2) passed straight into
'                                    TOptions.GetButtonLabel(i)$ / GetButtonIcon(i,i):TImage.
'                                    Established in RenderTraining.bmx as {keycode,joybutton}
'                                    pairs for the four movement-key bindings.
'     0x00C5D218 g_icon_none:TImage   (RenderTraining.bmx; passed to TLabel.SetIcon)
'     0x00C5D1A8 g_options_int01:Int  (icon-vs-text control style; Select 0/1)
'     0x00C5D240 g_options_int05:Int  (show/hide player names toggle)
'     0x00C5B2CC g_engine_int53:Int   (replay slow-mo flag)
'   Cross-Type static calls resolved through the class tables:
'     0x00C5D54C = TOptions+0x34 GetButtonLabel(i)$    0x00C5D550 = TOptions+0x38
'     GetButtonIcon(i,i):TImage
'   GetText is the recovered module Function at 0x004C5549 (($)$). All 15 literals were
'   read out of the exe with harness.read_string, not invented: "controls_CursorKeys",
'   ",", "replay_RwdFwd", "replay_SlowMo", "replay_Pause", "key_F2", "replay_ShowNames",
'   "replay_HideNames", "key_F3", "replay_Save", "key_F9", " - ", "key_F10", "replay_Zoom",
'   plus the two empty-string forms (both the pooled literal at 0x00C5D284).
'
'   `Local yspace:Int = 34` is a real Local, referenced ONLY inside the setup loop
'   (`a1 = a1 + yspace`, `add esi,[ebp-4]`); the equal-valued PRE-loop bump
'   (`a1 = a1 + 34`) is a separate literal 34 (`add esi,0x22` immediate) -- two textually
'   different additions, exactly as in RenderTraining.bmx's yspace/34.0 pair.
'
'   `g_options_int05` is the solo-relational If/Else branch-swap (codegen-
'   patterns.md sec 21): the ORIGINAL's `cmp [g],0 / je` tests the
'   NEGATION of the semantic condition with the two branches swapped. Semantically
'   "options_int05 = 0 -> ShowNames, else -> HideNames", but the source that reproduces the
'   `je` byte-for-byte is `If g_options_int05 <> 0 Then HideNames Else ShowNames`.
'
'   `g_key_c[0] >= 37 And g_key_a[0] <= 40` and the final loop's icon/txt Select + the two
'   short-circuit Or/truthy Draw guards are copied verbatim from RenderTraining.bmx's
'   already-verified (4218/4218) shape for the identical idiom on the same array.
	Function RenderReplay:Int(a0:Int, a1:Int)
		'!Global g_panel_controls_panreplay:TPanel
		'!Global g_panel_controls_lbl:TLabel[]
		'!Global g_key_a:Int[]
		'!Global g_key_c:Int[]
		'!Global g_key_d:Int[]
		'!Global g_key_e:Int[]
		'!Global g_icon_none:TImage
		'!Global g_options_int01:Int
		'!Global g_options_int05:Int
		'!Global g_engine_int53:Int
		Local yspace:Int = 34
		g_panel_controls_panreplay.SetPosition(a0, a1, 1)
		g_panel_controls_panreplay.Draw()
		a0 = a0 + 6
		a1 = a1 + 34
		For Local i:Int = 0 To 4
			g_panel_controls_lbl[i].x = a0
			g_panel_controls_lbl[i].y = a1
			g_panel_controls_lbl[i].SetText("", "", -1, -1)
			g_panel_controls_lbl[i].SetIcon(Null)
			g_panel_controls_lbl[i + 5].x = a0 + 52
			g_panel_controls_lbl[i + 5].y = a1
			g_panel_controls_lbl[i + 5].SetText("", "", -1, -1)
			a1 = a1 + yspace
		Next
		Local s:String
		If g_key_c[0] >= 37 And g_key_a[0] <= 40
			s = GetText("controls_CursorKeys")
		Else
			s = TOptions.GetButtonLabel(g_key_c[0]) + "," + TOptions.GetButtonLabel(g_key_d[0])
		EndIf
		g_panel_controls_lbl[0].SetText(s, "", -1, -1)
		g_panel_controls_lbl[0].SetIcon(g_icon_none)
		g_panel_controls_lbl[5].SetText(GetText("replay_RwdFwd"), "", -1, -1)
		If g_engine_int53
			g_panel_controls_lbl[5].SetText(GetText("replay_SlowMo"), "", -1, -1)
		EndIf
		g_panel_controls_lbl[1].SetText(TOptions.GetButtonLabel(g_key_e[0]), "", -1, -1)
		g_panel_controls_lbl[1].SetIcon(TOptions.GetButtonIcon(g_key_e[1], 0))
		g_panel_controls_lbl[6].SetText(GetText("replay_Pause"), "", -1, -1)
		g_panel_controls_lbl[2].SetText(GetText("key_F2"), "", -1, -1)
		If g_options_int05 <> 0
			g_panel_controls_lbl[7].SetText(GetText("replay_HideNames"), "", -1, -1)
		Else
			g_panel_controls_lbl[7].SetText(GetText("replay_ShowNames"), "", -1, -1)
		EndIf
		g_panel_controls_lbl[3].SetText(GetText("key_F3"), "", -1, -1)
		g_panel_controls_lbl[8].SetText(GetText("replay_Save"), "", -1, -1)
		g_panel_controls_lbl[4].SetText(GetText("key_F9") + " - " + GetText("key_F10"), "", -1, -1)
		g_panel_controls_lbl[9].SetText(GetText("replay_Zoom"), "", -1, -1)
		For Local i:Int = 0 To 4
			Select g_options_int01
			Case 0
				g_panel_controls_lbl[i].icon = Null
			Case 1
				If g_panel_controls_lbl[i].icon <> Null
					g_panel_controls_lbl[i].txt = ""
				EndIf
			End Select
			If g_panel_controls_lbl[i].icon <> Null Or g_panel_controls_lbl[i].txt.Length
				g_panel_controls_lbl[i].Draw()
			EndIf
			If g_panel_controls_lbl[i + 5].txt.Length
				g_panel_controls_lbl[i + 5].Draw()
			EndIf
		Next
	End Function
