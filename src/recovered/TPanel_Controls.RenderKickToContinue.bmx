' TPanel_Controls.RenderKickToContinue
' VA 0x00586509   365 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x44
' ASSUMPTIONS
'   0x00C6DD6C g_panel_controls_lbl:TLabel[]  -- globals_final says Object[]; TLabel fits
'     every use: .x/.y/.w are TGadget fields +0x20/+0x24/+0x2c, slot 0x64 = TGadget.SetText,
'     slot 0x8c = TLabel.SetIcon(:TImage), slot 0x44 = TLabel.Draw. Elements are read at
'     array-data +0x18 / +0x1c, i.e. indices 0 and 1.
'   0x00C6EFE4 g_engine_screenw:Int, 0x00C6EFE8 g_engine_screenh:Int
'   0x00C5D1A8 g_options_controlmode:Int
'   0x00C5D1D4 g_options_buttons:Int[]  -- globals_final says Object[], but the elements are
'     passed straight to TOptions.GetButtonLabel(i)$ / GetButtonIcon(i,i), so they are Ints.
'   Global names are ours; the originals are unrecoverable.
'   0x00C93120 is this function's float literal 2.0, not a Global.
'   The `cmp 0 / je / cmp 1 / je / jmp` run with both targets past the last compare is a
'   Select with no Default (codegen-patterns 10.2), not If/ElseIf.
	Function RenderKickToContinue:Int()
		'!Global g_engine_screenw:Int
		'!Global g_engine_screenh:Int
		'!Global g_panel_controls_lbl:TLabel[]
		'!Global g_options_controlmode:Int
		'!Global g_options_buttons:Int[]
		Local x:Int = Int(g_engine_screenw / 2 - (g_panel_controls_lbl[0].w + g_panel_controls_lbl[1].w) / 2.0)
		Local y:Int = g_engine_screenh - 42
		g_panel_controls_lbl[0].x = x
		g_panel_controls_lbl[0].y = y
		g_panel_controls_lbl[1].x = x + 256
		g_panel_controls_lbl[1].y = y
		Select g_options_controlmode
			Case 0
				g_panel_controls_lbl[1].SetText(TOptions.GetButtonLabel(g_options_buttons[0]), "", -1, -1)
				g_panel_controls_lbl[1].SetIcon(Null)
			Case 1
				g_panel_controls_lbl[1].SetText("", "", -1, -1)
				g_panel_controls_lbl[1].SetIcon(TOptions.GetButtonIcon(g_options_buttons[1], 1))
		End Select
		g_panel_controls_lbl[0].Draw()
		g_panel_controls_lbl[1].Draw()
	End Function
