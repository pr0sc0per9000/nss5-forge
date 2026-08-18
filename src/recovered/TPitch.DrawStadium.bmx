' TPitch.DrawStadium
' VA 0x004E6FE1   5255 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (f,f,f)i, class-table slot 0x48
' ASSUMPTIONS
'   0x00C5D664 declared g_pitch_int13:Int   -- half stadium width in tiles (fild + fmul a0)
'   0x00C5D668 declared g_pitch_int14:Int   -- half stadium height; +/-90 gives the two ends
'   0x00C5D66C declared g_pitch_int15:Int   -- stand-segment width step
'   0x00C5D670 declared g_pitch_int16:Int   -- stand-segment height step
'   0x00C5D69C declared g_stadiumsize:Int   -- same slot TPitch.SetStadiumSize writes (0..3)
'   0x00C5D5F4 declared g_pitch_arr02:TImage[]  -- 16 stand images, filled by TPitch.SetUp
'   0x00C5D600 declared g_pitch_arr03:TImage[]  -- 16 matching crowd/colour-tint overlays
'   0x00C5D698 declared g_pitch_wallcolour:String -- load-time value is the literal "FFFFFF"
'   DrawFans is the sibling Function at TPitch class-table slot 0x4C (i,f,f,f,i)i
'   SetColourHex is the verified module Function at 0x00505CEA
' NOTES
'   Every float constant in the function is 0.5, 2.0 or 3.0 (read from .data at
'   0x00C78640..0x00C78750); there are NO string literals in the body.
'   Both size gates are >= 2, not < 2: the original emits cmp [g],2 / jl <else>, so the
'   >= 2 arm is the Then branch. The order of the float constants in .data confirms it.
'   h is REUSED for the far end (h = (g_pitch_int14 - 90) * a0) rather than a 5th Local;
'   the frame is sub esp,0x14 = four Float slots plus one fild scratch.
	Function DrawStadium:Int(a0:Float, a1:Float, a2:Float)
		'!Global g_pitch_int13:Int
		'!Global g_pitch_int14:Int
		'!Global g_pitch_int15:Int
		'!Global g_pitch_int16:Int
		'!Global g_stadiumsize:Int
		'!Global g_pitch_arr02:TImage[]
		'!Global g_pitch_arr03:TImage[]
		'!Global g_pitch_wallcolour:String
		Local w:Float = g_pitch_int13 * a0
		Local h:Float = (g_pitch_int14 + 90) * a0
		Local d:Float = g_pitch_int15 * a0
		Local e:Float = g_pitch_int16 * a0
		If g_stadiumsize >= 2
			SetScale a0 * 0.5, a0 * 0.5
			SetRotation 0
			SetColor 255, 255, 255
			DrawImage g_pitch_arr02[0], -w - a1, -h - a2, 0
			DrawImage g_pitch_arr02[0], -w + d - a1, -h - a2, 0
			DrawImage g_pitch_arr02[0], -w + d * 2.0 - a1, -h - a2, 0
			DrawImage g_pitch_arr02[0], -w + d * 3.0 - a1, -h - a2, 0
			SetColourHex(g_pitch_wallcolour)
			DrawImage g_pitch_arr03[0], -w - a1, -h - a2, 0
			DrawImage g_pitch_arr03[0], -w + d - a1, -h - a2, 0
			DrawImage g_pitch_arr03[0], -w + d * 2.0 - a1, -h - a2, 0
			DrawImage g_pitch_arr03[0], -w + d * 3.0 - a1, -h - a2, 0
			SetColor 255, 255, 255
			DrawFans(1, a0, -w - a1, -h - a2, 0)
			DrawFans(1, a0, -w + d - a1, -h - a2, 0)
			DrawFans(1, a0, -w + d * 2.0 - a1, -h - a2, 0)
			DrawFans(1, a0, -w + d * 3.0 - a1, -h - a2, 0)
		Else
			SetScale a0 * 0.5, a0 * 0.5
			SetRotation 0
			SetColor 255, 255, 255
			DrawImage g_pitch_arr02[11], -w - a1, -h - a2, 0
			DrawImage g_pitch_arr02[11], -w + d - a1, -h - a2, 0
			DrawImage g_pitch_arr02[11], -w + d * 2.0 - a1, -h - a2, 0
			DrawImage g_pitch_arr02[11], -w + d * 3.0 - a1, -h - a2, 0
		EndIf
		If g_stadiumsize = 3
			SetScale a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[4], -w - a1, -h - a2, 0
			SetColourHex(g_pitch_wallcolour)
			DrawImage g_pitch_arr03[4], -w - a1, -h - a2, 0
			SetColor 255, 255, 255
			DrawFans(5, a0, -w - a1, -h - a2, 0)
			SetScale a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[6], -w - a1, -h - a2, 0
			SetScale -a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[4], w - a1, -h - a2, 0
			SetColourHex(g_pitch_wallcolour)
			DrawImage g_pitch_arr03[4], w - a1, -h - a2, 0
			SetColor 255, 255, 255
			DrawFans(6, a0, w - a1, -h - a2, 0)
			SetScale -a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[6], w - a1, -h - a2, 0
		Else
			SetScale a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[9], -w - a1, -h - a2, 0
			If g_stadiumsize = 0
				SetScale -a0 * 0.5, a0 * 0.5
				DrawImage g_pitch_arr02[13], w - a1, -h - a2, 0
			Else
				SetScale -a0 * 0.5, a0 * 0.5
				DrawImage g_pitch_arr02[9], w - a1, -h - a2, 0
			EndIf
		EndIf
		SetScale a0 * 0.5, a0 * 0.5
		DrawImage g_pitch_arr02[2], -w - a1, -h - a2, 0
		DrawImage g_pitch_arr02[3], -w - a1, -h + e - a2, 0
		DrawImage g_pitch_arr02[2], -w - a1, -h + e * 2.0 - a2, 0
		SetColourHex(g_pitch_wallcolour)
		DrawImage g_pitch_arr03[2], -w - a1, -h - a2, 0
		DrawImage g_pitch_arr03[3], -w - a1, -h + e - a2, 0
		DrawImage g_pitch_arr03[2], -w - a1, -h + e * 2.0 - a2, 0
		SetColor 255, 255, 255
		DrawFans(3, a0, -w - a1, -h - a2, 0)
		DrawFans(3, a0, -w - a1, -h + e - a2, 1)
		DrawFans(3, a0, -w - a1, -h + e * 2.0 - a2, 0)
		SetScale a0 * 0.5, a0 * 0.5
		DrawImage g_pitch_arr02[8], -w - a1, -h + e - a2, 0
		If g_stadiumsize = 0
			SetScale -a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[14], w - a1, -h - a2, 0
			DrawImage g_pitch_arr02[14], w - a1, -h + e - a2, 0
			DrawImage g_pitch_arr02[14], w - a1, -h + e * 2.0 - a2, 0
		Else
			SetScale -a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[2], w - a1, -h - a2, 0
			DrawImage g_pitch_arr02[2], w - a1, -h + e - a2, 0
			DrawImage g_pitch_arr02[2], w - a1, -h + e * 2.0 - a2, 0
			SetColourHex(g_pitch_wallcolour)
			DrawImage g_pitch_arr03[2], w - a1, -h - a2, 0
			DrawImage g_pitch_arr03[2], w - a1, -h + e - a2, 0
			DrawImage g_pitch_arr03[2], w - a1, -h + e * 2.0 - a2, 0
			SetColor 255, 255, 255
			DrawFans(4, a0, w - a1, -h - a2, 0)
			DrawFans(4, a0, w - a1, -h + e - a2, 0)
			DrawFans(4, a0, w - a1, -h + e * 2.0 - a2, 0)
		EndIf
		h = (g_pitch_int14 - 90) * a0
		If g_stadiumsize >= 2
			SetScale a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[1], -w - a1, h - a2, 0
			DrawImage g_pitch_arr02[1], -w + d - a1, h - a2, 0
			DrawImage g_pitch_arr02[1], -w + d * 2.0 - a1, h - a2, 0
			DrawImage g_pitch_arr02[1], -w + d * 3.0 - a1, h - a2, 0
			SetColourHex(g_pitch_wallcolour)
			DrawImage g_pitch_arr03[1], -w - a1, h - a2, 0
			DrawImage g_pitch_arr03[1], -w + d - a1, h - a2, 0
			DrawImage g_pitch_arr03[1], -w + d * 2.0 - a1, h - a2, 0
			DrawImage g_pitch_arr03[1], -w + d * 3.0 - a1, h - a2, 0
			SetColor 255, 255, 255
			DrawFans(2, a0, w - a1, h - a2, 0)
			DrawFans(2, a0, w - d - a1, h - a2, 0)
			DrawFans(2, a0, w - d * 2.0 - a1, h - a2, 0)
			DrawFans(2, a0, w - d * 3.0 - a1, h - a2, 0)
		Else
			SetScale a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[12], -w - a1, h - a2, 0
			DrawImage g_pitch_arr02[12], -w + d - a1, h - a2, 0
			DrawImage g_pitch_arr02[12], -w + d * 2.0 - a1, h - a2, 0
			DrawImage g_pitch_arr02[12], -w + d * 3.0 - a1, h - a2, 0
		EndIf
		SetScale a0 * 0.5, a0 * 0.5
		DrawImage g_pitch_arr02[5], -w - a1, h - a2, 0
		SetColourHex(g_pitch_wallcolour)
		DrawImage g_pitch_arr03[5], -w - a1, h - a2, 0
		SetColor 255, 255, 255
		DrawFans(7, a0, -w - a1, h - a2, 0)
		DrawFans(9, a0, -w - a1, h - a2, 0)
		SetScale a0 * 0.5, a0 * 0.5
		DrawImage g_pitch_arr02[7], -w - a1, h - a2, 0
		If g_stadiumsize = 0
			SetScale a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[10], -w - a1, h - a2, 0
			SetScale -a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[15], w - a1, h - a2, 0
		Else
			SetScale -a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[5], w - a1, h - a2, 0
			SetColourHex(g_pitch_wallcolour)
			DrawImage g_pitch_arr03[5], w - a1, h - a2, 0
			SetColor 255, 255, 255
			DrawFans(8, a0, w - a1, h - a2, 0)
			DrawFans(10, a0, w - a1, h - a2, 0)
			SetScale -a0 * 0.5, a0 * 0.5
			DrawImage g_pitch_arr02[7], w - a1, h - a2, 0
			If g_stadiumsize <> 3
				SetScale a0 * 0.5, a0 * 0.5
				DrawImage g_pitch_arr02[10], -w - a1, h - a2, 0
				SetScale -a0 * 0.5, a0 * 0.5
				DrawImage g_pitch_arr02[10], w - a1, h - a2, 0
			EndIf
		EndIf
	End Function
