' TSnowFlake.Update
' VA 0x0050584E   295 bytes
' byte-identical vs NSS5.exe (295/295, original length from Ghidra's inventory, mode=reloc)
' Driven through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_screen_w:Int
'!Global g_screen_h:Int
If Self.d = 0
	Self.x = Self.x - Self.iner
	Self.iner = Self.iner - 0.01
	If Self.iner <= Self.inerD
		Self.d = 1
		Self.iner = 1.0
	End If
Else
	Self.x = Self.x + Self.iner
	Self.iner = Self.iner - 0.01
	If Self.iner <= Self.inerD
		Self.d = 0
		Self.iner = 1.0
	End If
End If
Self.rot = Int(Self.rot + Self.s)
Self.y = Self.y + Self.g
Self.scl = Self.scl - 0.001
If Self.y >= g_screen_h
	Self.y = -5.0
	Self.x = Rand(0, g_screen_w)
	Self.scl = Rnd(0.25, 0.5)
End If
