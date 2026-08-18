' TRoulette.Spin
' VA 0x00575636   116 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (116/116, original length from Ghidra's inventory)
' Globals: 0x00C6BBC4 Int, 0x00C6BA50 TPanel, 0x00C6BA58 TButton, 0x00C6BA54 TButton,
' 0x00C6BBBC TRouletteWheel, 0x00C6BBC0 TRouletteBall. Hide() is TGadget slot 0x54,
' inherited by TPanel/TButton. The guard is an early return, not an If block.
	Function Spin:Int()
		'!Global g_roul_spinning:Int
		'!Global g_roul_panel:TPanel
		'!Global g_roul_btn1:TButton
		'!Global g_roul_btn2:TButton
		'!Global g_roul_wheel:TRouletteWheel
		'!Global g_roul_ball:TRouletteBall
		If g_roul_spinning = 0 Then Return 0
		g_roul_panel.Hide()
		g_roul_btn2.Hide()
		g_roul_btn1.Hide()
		g_roul_spinning = 0
		g_roul_wheel.Reset()
		g_roul_ball.Reset(g_roul_wheel)
	End Function
