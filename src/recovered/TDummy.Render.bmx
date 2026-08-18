' TDummy.Render
' VA 0x0058360a   175 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (175/175, original length from Ghidra's inventory)
' ASSUMPTIONS: img/frame/x/y/alph inherited from TTrainingObject. Module Global at
' 0x00c5de44 declared Float (the shared draw-scale, same as TPole.Render).
' The two String literals are relocatable data addresses and are masked, so their VALUES
' are not proven. Shadow pass first (frame 2, layer 24), then the dummy itself (frame 3).
' harness mode=reloc, 13 addresses masked.
' CONSTANTS CORRECTED: the shadow-offset triple was written x+2.5, y-1.5,
'   alph*0.5 as placeholders (the oracle masks the .rdata ADDRESS of an Float constant, so
'   any value of the right width matched equally). scripts/check_floats.py plus direct
'   disassembly (code offsets +42/+64/+79) show the exe holds x+1.5, y-0.5, alph*0.3.
'   Re-verified MATCH 175/175.
	Method Render:Int()
		'!Global g_pscale:Float
		TDrawOb.AddDrawOb(img, x + 1.5, y - 0.5, 0, frame, 2, alph * 0.3, 24, "000000", g_pscale, g_pscale, 3, 0, "", 0, 0)
		TDrawOb.AddDrawOb(img, x, y, 0, frame, 3, alph, 0, "FFFFFF", g_pscale, g_pscale, 3, 0, "", 0, 0)
	End Method
