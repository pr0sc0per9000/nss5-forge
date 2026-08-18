' TPitchMark.RenderReplay
' VA 0x004EA35D   194 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (194/194, original length from Ghidra's inventory, mode=reloc)
' Assumes three module Globals (original names unrecoverable):
'   g_pitchmarks:TList  (0x00C5D9AC)  g_replayframe:Int (0x00C5B2C8)
'   g_pmimage:TImage    (0x00C5D9B0)
' 0x00C5B1B4 = TDrawOb class table slot =
'   TDrawOb.AddDrawOb(:TImage,f,f,f,i,i,f,i,$,f,f,i,f,$,i,i)
' Comparison operand order is load-bearing: the original is
'   `mov edx,[pm+0x1c] / cmp [g_replayframe],edx / jle`, i.e. g_replayframe > pm.frametime.
' Ghidra prints it the other way round; writing `pm.frametime < g_replayframe` gives
' `cmp [pm+0x1c],edx / jge` and misses at byte 64.
	Function RenderReplay:Int()
		'!Global g_pitchmarks:TList
		'!Global g_replayframe:Int
		'!Global g_pmimage:TImage
		For Local pm:TPitchMark = EachIn g_pitchmarks
			If g_replayframe > pm.frametime
				TDrawOb.AddDrawOb(g_pmimage, Float(pm.x), Float(pm.y), 1.0, pm.frm, 0, pm.a, pm.rot, "FFFFFF", 0.5, 0.5, 3, 0, Null, 0, 0)
			EndIf
		Next
	End Function
