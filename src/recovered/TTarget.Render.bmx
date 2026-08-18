' TTarget.Render
' VA 0x0058466a   76 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (76/76, original length from Ghidra's inventory)
' ASSUMPTIONS: fields img/x/y/alph are inherited from TTrainingObject (+8/+0x10/+0x14/+0x1c).
' Module Global at 0x00c5de44 declared Float (same draw-scale Global as TPole.Render).
' The two String literals are relocatable data addresses and are masked, so their VALUES
' are not proven -- only that a String constant sits in each position.
' harness mode=reloc, 5 addresses masked.
	Method Render:Int()
		'!Global g_pscale:Float
		TDrawOb.AddDrawOb(img, x, y, 0, 0, 2, alph, 0, "FFFFFF", g_pscale, g_pscale, 3, 0, "", 0, 0)
	End Method
