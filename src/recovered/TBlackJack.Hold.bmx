' TBlackJack.Hold
' VA 0x0057731a   52 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (52/52, original length from Ghidra's inventory, mode=reloc)
' Assumptions: Globals 0x00C6C174:Int (blackjack state machine), 0x00C6C020:TButton,
' 0x00C6C024:TButton (both from globals_final.tsv, construction-typed). Slot 0x54 on
' TButton is INHERITED from TGadget = Hide().
	Function Hold:Int()
		'!Global g_blackjack_state:Int
		' 0x00C6C020 and 0x00C6C024, the hold and twist buttons. This body's ordered pairing is
' exact -- three names, three touched addresses, 0x00C6C174 0x00C6C020 0x00C6C024 --
' and TScreen_BlackJack.CreateScreen.bmx:104 records the same pairing outright:
' `0x00C6C01C/20/24/28 TButton g_object753/754/755/756 -- NOT g_bj_btn1..4`.
' g_bj_btn1 and g_bj_btn2 are TScreen_BlackJack.SetUpScreen's names for 0x00C6C01C and
' 0x00C6C028, so these two Hide calls were made on the quit and play buttons, and on a
' variable nothing writes at that.
		'!Global g_object754:TButton
		'!Global g_object755:TButton
		g_blackjack_state = 2
		g_object754.Hide()
		g_object755.Hide()
	End Function
