' TPole.Render
' VA 0x00583bad   173 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (173/173, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c5de44 declared Float (the pitch/draw scale, passed
' twice as AddDrawOb's two Float scale arguments). The two string literals are relocatable
' data addresses and are masked, so their VALUES are not proven by the match. Shadow pass
' first, then the pole itself.
' CONSTANTS CORRECTED: the shadow-offset triple was written x+2.5, y-1.5,
'   alph*0.5 as placeholders (the oracle masks the .rdata ADDRESS of a Float constant, so
'   any value of the right width matched equally). scripts/check_floats.py plus direct
'   disassembly (code offsets +42/+64/+79) show the exe holds x+1.5, y-1.0, alph*0.3 --
'   the same triple as the sibling TDummy.Render except the y term. Re-verified MATCH
'   173/173.
	Method Render:Int()
		'!Global g_pscale:Float
		TDrawOb.AddDrawOb(img, x + 1.5, y - 1.0, 0, frame, 2, alph * 0.3, 24, "000000", g_pscale, g_pscale, 3, 0, "", 0, 0)
		TDrawOb.AddDrawOb(img, x, y, 0, frame, 3, alph, 0, colour, g_pscale, g_pscale, 3, 0, "", 0, 0)
	End Method
