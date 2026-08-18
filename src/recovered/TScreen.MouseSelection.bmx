' TScreen.MouseSelection
' VA 0x00512374   205 bytes   vtable slot 0x88   sig ()i
' byte-identical vs NSS5.exe (205/205, original length from Ghidra's inventory)
' assumes: 'If g.hidden Then Continue' (74 02 EB xx) not an enclosing If-block - 205 vs 203
' this wrote the Global it called g_selectedgadget, and TScreen_Options.ButtonCam
' read a Global it called g_selectedgadget:Object. Disassembly says BOTH are 0x00C61CF8 --
' the SAME slot the rest of the corpus calls g_activegadget (stores at 0x005123F5 and
' 0x0051242D here; read at 0x005211C6 there). There is no separate selected-gadget Global.
' Renamed to g_activegadget:TGadget so the corpus declares one slot once.
	Method MouseSelection:Int()
		'!Global g_activegadget:TGadget
		For Local g:TGadget = EachIn Self.GetGadgetList()
			If g.hidden Then Continue
			If g.alive And g.MouseOver()
				g_activegadget = g
				Return 0
			EndIf
		Next
		g_activegadget = Null
	End Method
