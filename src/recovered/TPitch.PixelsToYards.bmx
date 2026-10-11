' TPitch.PixelsToYards
' VA 0x004e9fb1   18 bytes   vtable slot 0x64   sig (f)f
' byte-identical vs NSS5.exe (18/18, original length from Ghidra's inventory)
' VA 0x004E9FB1, 18 bytes
' byte-identical vs NSS5.exe
' The divisor/factor is the Global g_pitchscale (0x00C5D628), NOT a 10.0 literal: the
' original operand is [0x00C5D628], the address TPitch.SetUp writes from Engine.ini's
' "pitchscale". A literal assembles to the same opcode with its own constant-pool
' address, which the relocation mask hides, so the probe matched either way.
'!Global g_pitchscale:Float = 10.0

	Function PixelsToYards:Float(p:Float)
		Return p / g_pitchscale
	End Function
