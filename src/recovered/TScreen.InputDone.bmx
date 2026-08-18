' TScreen.InputDone
' VA 0x00512d65   83 bytes   vtable slot 0xa4   sig ()i
' byte-identical vs NSS5.exe (83/83, original length from Ghidra's inventory)
' two module Globals assumed: 0x00c61700:TScreen (this declared type IS pinned - GetGadgetByName is slot 0x90) and 0x00c61734:String. Downcast target 0x00c62558 = TInputBox per class_tables.tsv
' VERIFIED: the gadget-name literal was flagged as a placeholder; harness.read_string(0x00C7DCE8) confirms "msgscreen_input" exactly. No change needed.
	Function InputDone:Int()
		'!Global g_screen:TScreen
		'!Global g_inputtext:String
		g_inputtext = TInputBox(g_screen.GetGadgetByName("msgscreen_input")).txt
	End Function
