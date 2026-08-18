' TScreen_Stats.ButtonMyHistory
' VA 0x00552224   42 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (42/42, original length from Ghidra's inventory)
' assumes module globals:  Global g_Object523:TGadget (0x00c679b0), Global g_Object526:TGadget (0x00c679bc)
' the TGadget type is load-bearing: slot 0x58 = Show, slot 0x54 = Hide
	Function ButtonMyHistory:Int()
		'!Global g_Object523:TGadget
		'!Global g_Object526:TGadget
		g_Object523.Show()
		g_Object526.Hide()
	End Function
