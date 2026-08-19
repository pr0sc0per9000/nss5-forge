' TPanel_Controls.RenderPauseSkipTime
' VA 0x00586245   708 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (i,i)i, class-table slot 0x40
' ASSUMPTIONS
'   0x00C6DD60 g_panel_controls_arr01:TButton[] -- elements take slot 0x64 SetText($,$,i,i),
'     0x8c SetImage(:TImage), 0x44 Draw(), and fields TGadget.x/+0x20, y/+0x24, txt/+0x10
'     plus TButton.icon/+0x68, so the element type is TButton (table says Object[]).
'   0x00C5D1F4 g_options_arr10:Int[] -- indices feed TOptions.GetButtonLabel(i)$ and
'     GetButtonIcon(i,i):TImage (table says Object[]).
'   0x00C5D1A8 g_options_int01:Int.
'   `Local gap:Int = 34` is real, not a folded constant: the original stores 0x22 into
'     [ebp-4] before the loop and the step is `add esi,[ebp-4]` (sub esp,8 = two slots,
'     the other being the Int->Float fild temp).
'   Both loops are `To 4`, not `Until 5` -- the guard is `cmp ebx,4 / jle`.
'   The g_options_int01 dispatch is a Select (two cmp/je back to back), not If/ElseIf.
'   `txt.Length` reads the BBString length at +8; the Or is short-circuit.
'   Literals "Pause", "Skip Time", "F5" read with harness.read_string.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_panel_controls_lbl:TLabel[]
'!Global g_options_arr10:Int[]
'!Global g_options_int01:Int
Local gap:Int = 34
For Local i:Int = 0 To 4
	g_panel_controls_lbl[i].x = a0
	g_panel_controls_lbl[i].y = a1
	g_panel_controls_lbl[i].SetText("", "", -1, -1)
	g_panel_controls_lbl[i].SetIcon(Null)
	g_panel_controls_lbl[i + 5].x = a0 + 52
	g_panel_controls_lbl[i + 5].y = a1
	g_panel_controls_lbl[i + 5].SetText("", "", -1, -1)
	a1 = a1 + gap
Next
g_panel_controls_lbl[0].SetText(TOptions.GetButtonLabel(g_options_arr10[0]), "", -1, -1)
g_panel_controls_lbl[0].SetIcon(TOptions.GetButtonIcon(g_options_arr10[1], 0))
g_panel_controls_lbl[5].SetText(GetText("Pause"), "", -1, -1)
g_panel_controls_lbl[1].SetText("F5", "", -1, -1)
g_panel_controls_lbl[6].SetText(GetText("Skip Time"), "", -1, -1)
For Local j:Int = 0 To 4
	Select g_options_int01
		Case 0
			g_panel_controls_lbl[j].icon = Null
		Case 1
			If g_panel_controls_lbl[j].icon <> Null Then
				g_panel_controls_lbl[j].txt = ""
			End If
	End Select
	If g_panel_controls_lbl[j].icon <> Null Or g_panel_controls_lbl[j].txt.Length Then
		g_panel_controls_lbl[j].Draw()
	End If
	If g_panel_controls_lbl[j + 5].txt.Length Then
		g_panel_controls_lbl[j + 5].Draw()
	End If
Next
Return 0
