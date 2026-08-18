' TPanel_Controls.SetUp
' VA 0x00584706   748 bytes   vtable slot 0x30   sig ()i   KIND=Function
' byte-identical vs NSS5.exe (748/748, original length from Ghidra's inventory, mode=reloc)
' assumptions:
'   0x00C6DD50 :TPanel  (the controls panel)      0x00C6DD54 :TPanel  (the replay panel)
'   0x00C6DD60 :TLabel[] indexed 0..9             0x00C6DD6C :TLabel[] indexed 0..1
'   globals_final types the two arrays Object[]; TLabel[] is what the CreateLabel return
'   feeding every element proves.
'   Class-table slots: 0x00C63294 = TPanel+0x88 CreatePanel, 0x00C634C0 = TLabel+0x88
'   CreateLabel.
' Note: the trailing "" argument of CreateLabel is pushed as 0x005C7D40 (bbEmptyString,
' i.e. the DEFAULT value of that parameter) rather than the "" literal at 0x00C5D284 the
' second argument uses. Both are in-image absolute addresses, so the oracle masks them
' either way -- the original almost certainly omitted the last two defaulted arguments.
	Function SetUp:Int()
		'!Global g_panel_controls_pan:TPanel
		'!Global g_panel_controls_panreplay:TPanel
		'!Global g_panel_controls_lbl:TLabel[]
		'!Global g_panel_controls_kick:TLabel[]
		g_panel_controls_pan = TPanel.CreatePanel("pan_Controls", GetText("Controls"), 0, 0, 144, 28, "666666", "FFFFFF", 3, 0.8, 1, 146, 0)
		g_panel_controls_panreplay = TPanel.CreatePanel("pan_Replay", GetText("Controls") + " (F4)", 0, 0, 144, 28, "666666", "FFFFFF", 3, 0.8, 1, 176, 0)
		For Local i:Int = 0 To 4
			g_panel_controls_lbl[i] = TLabel.CreateLabel("lbl_Controls" + i, "", 0, 0, 52, 28, 2, "FFFFFF", "FFFFFF", 0.75, 4, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		Next
		For Local i:Int = 5 To 9
			g_panel_controls_lbl[i] = TLabel.CreateLabel("lbl_Controls" + i, "", 0, 0, 80, 28, 2, "666666", "FFFFFF", 0.75, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		Next
		g_panel_controls_kick[0] = TLabel.CreateLabel("lbl_KickToContinue0", GetText("CMESSAGE_SKIPTOCONTINUE"), 0, 0, 256, 32, 3, "666666", "FFFFFF", 0.75, 4, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
		g_panel_controls_kick[1] = TLabel.CreateLabel("lbl_KickToContinue1", "", 0, 0, 64, 32, 3, "FFFFFF", "FFFFFF", 0.75, 5, 0, 1, 1, Null, 1, 0, 0, 0, "", 0)
	End Function
