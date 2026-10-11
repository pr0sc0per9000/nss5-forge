' TPitch.MetresToPixels
' VA 0x004e9fed   24 bytes   vtable slot 0x70   sig (f)f
' byte-identical vs NSS5.exe (24/24, original length from Ghidra's inventory)
' VA 0x004E9FED, 24 bytes
' byte-identical vs NSS5.exe
' The divisor/factor is the Global g_pitchscale (0x00C5D628), NOT a 10.0 literal: the
' original operand is [0x00C5D628], the address TPitch.SetUp writes from Engine.ini's
' "pitchscale". A literal assembles to the same opcode with its own constant-pool
' address, which the relocation mask hides, so the probe matched either way.
'!Global g_pitchscale:Float = 10.0

	Function MetresToPixels:Float(m:Float)
		Return m * 1.0936133 * g_pitchscale
	End Function
