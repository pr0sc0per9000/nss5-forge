' TRouletteWheel.Draw
' VA 0x00575C36   115 bytes   vtable slot 0x3c   sig (f)i
' byte-identical vs NSS5.exe (115/115, original length from Ghidra's inventory)
' assumptions: Globals 0x00C6BCB4 / 0x00C6BCB8 declared TImage (DrawImage arg 1);
' float constants 1.0 (0x00C90B10) and 280.0 (0x00C90B14) read from .rdata.
	Method Draw:Int(a0:Float)
		'!Global g_roulettewheelimage:TImage
		'!Global g_roulettewheelimage2:TImage
		Local rot:Float = Self.fRot * a0 + Self.oldfRot * (1.0 - a0)
		DrawImage(g_roulettewheelimage, Self.fX, Self.fY, 0)
		SetRotation(rot + 280.0)
		DrawImage(g_roulettewheelimage2, Self.fX, Self.fY, 0)
	End Method
