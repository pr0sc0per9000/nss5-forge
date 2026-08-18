' TPlayer.GetHuddlePosition
' VA 0x004FA208   155 bytes   vtable slot 0x148   sig (*i,*i)i
' byte-identical vs NSS5.exe (155/155, original length from Ghidra's inventory, mode=reloc)
'
' 0x00C5D998 = TPitch + 0x6C (YardsToPixels(f)f); the pushed constant is 0x40F00000 = 7.5.
' 0x00C5D634 is an Int Global. TPlayer + 0x160 = GetShootingDirection()i.
' Both Float Locals are written, then updated with `:+` / `:*` -- three statements each, which
' is what the two fstp/fld round trips through [ebp-4] and [ebp-8] show.
' The `(*i,*i)` parameters were almost certainly `Var` in the original; scalar Var and Ptr
' compile identically (same finding as ClampInt/ClampFloat).
' Module Globals declared by this body (names are ours; the TYPES are load-bearing):
'   Global g_huddleoffset:Int
	Method GetHuddlePosition:Int(a0:Int Ptr, a1:Int Ptr)
		'!Global g_huddleoffset:Int
		Local f:Float = -g_huddleoffset
		f :+ TPitch.YardsToPixels(7.5)
		a0[0] = Int(f)
		Local g:Float = -Self.GetShootingDirection()
		g :* TPitch.YardsToPixels(7.5)
		a1[0] = Int(g)
	End Method
