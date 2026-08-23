' TScreen.InputDone
' VA 0x00512d65   83 bytes   vtable slot 0xa4   sig ()i
' byte-identical vs NSS5.exe (83/83, original length from Ghidra's inventory)
' two module Globals: 0x00c61700 g_curscreen:TScreen (this declared type IS pinned -
' GetGadgetByName is slot 0x90) and 0x00c61734 g_inputtext:String. Downcast target
' 0x00c62558 = TInputBox per class_tables.tsv
'
' The screen slot is spelled g_curscreen because that is the name 0x00C61700 resolves to:
' CERTAIN in global_address_map.tsv, forced in nine bodies and unanimous across nineteen.
' g_screen is AMBIGUOUS and lands on a different slot, so under that spelling assemble.py
' emits a second Global holding some other live TScreen. The body still byte-matches either
' way, because a Global reference is a relocation the oracle masks. What changes is which
' screen is searched: GetGadgetByName("msgscreen_input") misses on the wrong one and
' returns Null, and the .txt read through that Null ends the process when a save name is
' confirmed. TScreen.TextEntered reads the same slot and already spells it g_curscreen.
' VERIFIED: the gadget-name literal was flagged as a placeholder; harness.read_string(0x00C7DCE8) confirms "msgscreen_input" exactly. No change needed.
	Function InputDone:Int()
		'!Global g_curscreen:TScreen
		'!Global g_inputtext:String
		g_inputtext = TInputBox(g_curscreen.GetGadgetByName("msgscreen_input")).txt
	End Function
