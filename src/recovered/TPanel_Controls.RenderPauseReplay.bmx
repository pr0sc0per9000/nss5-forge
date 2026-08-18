' TPanel_Controls.RenderPauseReplay
' VA 0x00585F5E   743 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (i,i)i, slot 0x3C   (static -- no implicit Self)
' ASSUMPTIONS
'  * Globals (names ours; declared types are load-bearing):
'      0x00C6DD60 g_panel_controls_btn:TButton[]   0x00C5D1F4 g_options_arr10:Int[]
'      0x00C5D1FC g_options_arr11:Int[]            0x00C5D1A8 g_options_int01:Int
'    globals_final.tsv types all three arrays Object[]; TButton comes from the slots
'    used through them -- 0x64 TGadget.SetText, 0x8C TButton.SetImage, 0x44 TButton.Draw
'    -- plus fields +0x60 image / +0x68 icon which only TButton has.
'  * `ystep` is a real Int Local: the original stores 0x22 into [ebp-4] before the loop
'    and closes each iteration with `add esi,[ebp-4]`. Inlining the 34 costs 7 bytes.
'  * The g_options_int01 dispatch is a Select -- subject loaded once into eax, both
'    `cmp eax,N / je` back to back, then the fallthrough jmp (guide 10.2).
'  * `.length` on the txt String reads the BBString length field at +8.
	'!Global g_panel_controls_btn:TButton[]
	'!Global g_options_arr10:Int[]
	'!Global g_options_arr11:Int[]
	'!Global g_options_int01:Int
	Local ystep:Int = 34
	For Local i:Int = 0 To 4
		g_panel_controls_btn[i].x = a0
		g_panel_controls_btn[i].y = a1
		g_panel_controls_btn[i].SetText("", "", -1, -1)
		g_panel_controls_btn[i].SetImage(Null)
		g_panel_controls_btn[i + 5].x = a0 + 52
		g_panel_controls_btn[i + 5].y = a1
		g_panel_controls_btn[i + 5].SetText("", "", -1, -1)
		a1 = a1 + ystep
	Next
	g_panel_controls_btn[0].SetText(TOptions.GetButtonLabel(g_options_arr10[0]), "", -1, -1)
	g_panel_controls_btn[0].SetImage(TOptions.GetButtonIcon(g_options_arr10[1], 0))
	g_panel_controls_btn[5].SetText(GetText("Pause"), "", -1, -1)
	g_panel_controls_btn[1].SetText(TOptions.GetButtonLabel(g_options_arr11[0]), "", -1, -1)
	g_panel_controls_btn[1].SetImage(TOptions.GetButtonIcon(g_options_arr11[1], 0))
	g_panel_controls_btn[6].SetText(GetText("Replay"), "", -1, -1)
	For Local i:Int = 0 To 4
		Select g_options_int01
			Case 0
				g_panel_controls_btn[i].icon = Null
			Case 1
				g_panel_controls_btn[i].txt = ""
		End Select
		If g_panel_controls_btn[i].icon Or g_panel_controls_btn[i].txt.length
			g_panel_controls_btn[i].Draw()
		EndIf
		If g_panel_controls_btn[i + 5].txt.length <> 0
			g_panel_controls_btn[i + 5].Draw()
		EndIf
	Next
