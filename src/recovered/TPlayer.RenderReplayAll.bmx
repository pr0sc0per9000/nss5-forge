' TPlayer.RenderReplayAll
' VA 0x004FE6DE   127 bytes   vtable slot 0x210   sig (f)i
' byte-identical vs NSS5.exe (127/127, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C5DE10 is the replay-player TList; the EachIn downcast class table is TPlayer (0x00C5F94C).
' TPlayer + 0x214 = RenderReplay(f).
' MEASURED: `For ... EachIn` already emits its own `cmp eax,nullobj / je next` skip. Adding an
' explicit `If p <> Null` costs 7 extra bytes. Do not write one.
' The guard is the early-return shape: `If Not g` (object->Int cast: setne/movzx/cmp 0), which
' is 6 bytes longer than the fused `If g = Null` -- the original uses the cast form here.
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_replayplayers:TList
	Function RenderReplayAll:Int(a0:Float)
		'!Global g_replayplayers:TList
		If Not g_replayplayers Then Return 0
		For Local p:TPlayer = EachIn g_replayplayers
			p.RenderReplay(a0)
		Next
	End Function
