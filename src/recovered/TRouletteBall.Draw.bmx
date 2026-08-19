' TRouletteBall.Draw
' byte-identical vs NSS5.exe
' VA 0x00576254   175 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_rouletteball_img:TImage
'!Global g_roulette_arr:Int[]
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
