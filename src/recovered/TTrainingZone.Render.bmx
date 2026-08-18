' TTrainingZone.Render
' VA 0x00583e88   173 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (173/173, original length from Ghidra's inventory, mode=reloc)
' Global: 0x00C5DE44 g_zoom:Float.
' PTR_FUN_00C5B1B4 is TDrawOb's class table + slot 0x34 = TDrawOb.AddDrawOb, a 16-arg
' Function, so the call is written with the Type prefix (we are inside TTrainingZone).
' Literals: 0x005C7D40 is "" and 0x00C5D680 is "FFFFFF", both read out of NSS5.exe.
	Method Render:Int()
		'!Global g_zoom:Float
		TDrawOb.AddDrawOb(img, x, y, 0, 0, 2, alph, 0, colour, g_zoom * scl, g_zoom * scl, 3, 0, "", 0, 0)
		TDrawOb.AddDrawOb(Null, x, y, 0, 0, 3, 1.0, 0, "FFFFFF", g_zoom * scl, g_zoom * scl, 4, 0, txt, 0, 0)
	End Method
