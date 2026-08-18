' TScreen_ReportPhysio.Draw
' VA 0x005618AA   86 bytes   vtable slot 0x3c
' byte-identical vs NSS5.exe (86/86, original length from Ghidra's inventory, mode=reloc)
'
' g_physio_img:TImage is the module Global at 0x00C68A04 (globals_final says TScreen from a
' single construction site; it is passed straight to DrawImageRect, so it is a TImage).
' SetDrawStateHex is the already-verified module Function at 0x00506456.
	Function Draw:Int()
		'!Global g_physio_img:TImage
		SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
		If g_physio_img <> Null Then DrawImageRect(g_physio_img, 0, 60, 400, 480, 0)
	End Function
