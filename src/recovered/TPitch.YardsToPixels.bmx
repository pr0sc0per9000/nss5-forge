' TPitch.YardsToPixels
' VA 0x004e9fdb   18 bytes   vtable slot 0x6c   sig (f)f
' byte-identical vs NSS5.exe (18/18, original length from Ghidra's inventory)
' VA 0x004E9FDB, 18 bytes
' byte-identical vs NSS5.exe
' The divisor/factor is the Global g_pitchscale (0x00C5D628), NOT a 10.0 literal: the
' original operand is [0x00C5D628], the address TPitch.SetUp writes from Engine.ini's
' "pitchscale". A literal assembles to the same opcode with its own constant-pool
' address, which the relocation mask hides, so the probe matched either way.
'!Global g_pitchscale:Float = 10.0

	Function YardsToPixels:Float(y:Float)
		Return y * g_pitchscale
	End Function
