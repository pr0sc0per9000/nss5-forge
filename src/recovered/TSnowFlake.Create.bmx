' TSnowFlake.Create
' VA 0x00505551   302 bytes   mode=reloc
' Driven through the oracle from scratch with helper_map.record stubbed; MATCH over the
' full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_scr_w:Int
'!Global g_scr_h:Int
'!Global g_snowcount:Int
Local s:TSnowFlake = New TSnowFlake
s.x = Rand(0, g_scr_w)
s.y = Rand(0, -g_scr_h)
s.rot = 0
s.a = Rnd(0.2, 1.0)
s.g = Rnd(1.5, 4.0)
s.s = Rnd(0.5, 2.0)
s.t = 0
s.w = Rand(2, 5)
s.d = Rand(0, 1)
s.inerD = Rnd(-0.5, -1.0)
s.scl = Rnd(0.25, 0.5)
g_snowcount :+ 1
Return s
