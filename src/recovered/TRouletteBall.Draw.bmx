' TRouletteBall.Draw
' byte-identical vs NSS5.exe
' VA 0x00576254   175 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
' g_roulette_arr (0x00C6BCBC) carries an INITIALISER, not just a size. It is one of the two
' array module Globals module_globals_decoded.tsv leaves as SCALAR_OR_COMPLEX (the other was
' g_pitch_arr05), so no table carries its length and it was emitted unsized -- length 0, and
' every index throws in a -d build (TScreen_Roulette.GetResult indexes it UNGUARDED the moment
' the wheel stops). Recovered from the module body at 0x004BAFF5: _bbArrayNew1D("i", 0x26) --
' 38 Ints -- immediately followed by 38 constant stores at [eax+0x18 .. eax+0xac], transcribed
' verbatim below. It is the American double-zero wheel's pocket->number map, 37 standing for
' "00"; the read below is bounds-checked `n > -1 And n < 38` in the original too. A bare size
' would have compiled but made every spin land on 0, so the values are carried, which is also
' exactly what the original emits.
'!Global g_rouletteball_img:TImage
'!Global g_roulette_arr:Int[] = [0,1,13,36,24,3,15,34,22,5,17,32,20,7,11,30,26,9,28,37,2,14,35,23,4,16,33,21,6,18,31,19,8,12,29,25,10,27]
Local fx:Float = Self.fX*a0 + Self.oldfX*(1.0-a0)
Local fy:Float = Self.fY*a0 + Self.oldfY*(1.0-a0)
DrawImage(g_rouletteball_img, fx, fy, 0)
Local n:Int = Int(Self.fPocket)
If n > -1 And n < 38
	Local s:String = String(g_roulette_arr[n])
	If s = "37"
	End If
End If
Return 0
