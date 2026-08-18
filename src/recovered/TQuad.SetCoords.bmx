' TQuad.SetCoords
' VA 0x005AF615   455 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG (f,f,f,f,f,f,f,f)i, slot 0x30
' ASSUMPTIONS
'  * Field names come from TQuad's own reflection record (object_model.json):
'    +0x18 minx:Float, +0x1c miny:Float, +0x20 maxx:Float, +0x24 maxy:Float,
'    +0x28 xyuv:Float[]. The decompiler's `*(int*)(Self+0x28) + 0x18 + 4*i` is the
'    BBArray data pointer, so every store is an ordinary constant array index.
'  * FUN_004A8050 / FUN_004A8070 (two Double args each, six call sites each) are the
'    Double overloads of Min / Max. The min group feeds minx/miny and the max group
'    feeds maxx/maxy, which fixes which is which. Both nest left-associatively:
'    Min(Min(Min(a,b),c),d) -- Ghidra flattens the nest into one four-argument call.
'  * No module Globals are touched.
	Self.xyuv[0] = a0
	Self.xyuv[1] = a1
	Self.xyuv[2] = 0
	Self.xyuv[3] = 0
	Self.xyuv[4] = a2
	Self.xyuv[5] = a3
	Self.xyuv[6] = 1
	Self.xyuv[7] = 0
	Self.xyuv[8] = a4
	Self.xyuv[9] = a5
	Self.xyuv[10] = 1
	Self.xyuv[11] = 1
	Self.xyuv[12] = a6
	Self.xyuv[13] = a7
	Self.xyuv[14] = 0
	Self.xyuv[15] = 1
	Self.minx = Min(Min(Min(a0,a2),a4),a6)
	Self.miny = Min(Min(Min(a1,a3),a5),a7)
	Self.maxx = Max(Max(Max(a0,a2),a4),a6)
	Self.maxy = Max(Max(Max(a1,a3),a5),a7)
