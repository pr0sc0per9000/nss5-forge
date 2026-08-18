' TBall.RenderReplay
' VA 0x004cc30c   346 bytes   vtable slot 0xbc   sig (f)i
' byte-identical vs NSS5.exe (346/346, original length from Ghidra's inventory, mode=reloc)
'
' GLOBAL NAMES ARE OURS. 0x00C5A4B4 TImage (shadow), 0x00C5A4B0 TImage (ball),
' 0x00C5DE44 Float (draw scale).
'
' a0 is the replay interpolation fraction and is held on the x87 stack for the whole body.
' The three `1.0` literals occupy three DISTINCT constant slots (0x00C72A88/8C/90), which is
' what a literal repeated three times in source produces.
' The two identical GetHeightScale expressions really are computed twice -- bcc does no CSE.
'!Global g_img_ballshadow:TImage
'!Global g_img_ball:TImage
'!Global g_drawscale:Float
	Method RenderReplay:Int(a0:Float)
		If Self.hideball = 1 Then Return 0
		Local px:Float = Self.x * a0 + Self.oldx * (1.0 - a0)
		Local py:Float = Self.y * a0 + Self.oldy * (1.0 - a0)
		Local pz:Float = Self.z * a0 + Self.oldz * (1.0 - a0)
		TDrawOb.AddDrawOb(g_img_ballshadow, px, py, 0, 0, 2, Self.alph * 0.35, 0, "FFFFFF", g_drawscale, g_drawscale, 3, 0, "", 0, 0)
		TDrawOb.AddDrawOb(g_img_ball, px, py, pz, Self.frame, 3, Self.alph, 0, Self.colour, g_drawscale * Self.GetHeightScale(Int(Self.z)), g_drawscale * Self.GetHeightScale(Int(Self.z)), 3, 0, "", 0, 0)
	End Method
