' TBlackJack.Hold
' VA 0x0057731a   52 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (52/52, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Globals 0x00C6C174:Int (blackjack state machine), 0x00C6C020:TButton,
' 0x00C6C024:TButton (both from globals_final.tsv, construction-typed). Slot 0x54 on
' TButton is INHERITED from TGadget = Hide().
	Function Hold:Int()
		'!Global g_blackjack_state:Int
		'!Global g_bj_btn1:TButton
		'!Global g_bj_btn2:TButton
		g_blackjack_state = 2
		g_bj_btn1.Hide()
		g_bj_btn2.Hide()
	End Function
