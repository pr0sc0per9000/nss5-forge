' TTeam.GetShootoutPositions
' VA 0x004e0954   135 bytes   vtable slot 0x78   sig ()i
' byte-identical vs NSS5.exe (135/135, original length from Ghidra's inventory, mode=reloc)
' assumptions: TTeam field +0x1c = squad:TList; downcast class table 0x00c5f94c = TPlayer;
'              TPlayer +0x188 = matchstats:TStats_Match, TStats_Match +0x10 = reds:Int,
'              TPlayer +0xbc = selectionno:Int, TPlayer slot 0x14c = GetShootOutPosition().
'
' The body is `If <cond> Then Continue`, not `If Not (<cond>) Then <call>`. The original
' emits `74 02 EB 0C` -- je over a jmp back to the enumerator test -- which is what
' Continue produces. Folding it into a single inverted branch is 2 bytes shorter (133).
	Method GetShootoutPositions:Int()
		For Local p:TPlayer = EachIn Self.squad
			If p.matchstats.reds Or p.selectionno > 10 Then Continue
			p.GetShootOutPosition()
		Next
	End Method
