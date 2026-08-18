' TCameraMan.Render
' VA 0x004EB97E   794 bytes  mode=reloc  byte-identical vs NSS5.exe (794/794)
' KIND=Method, SIG ()i, slot 0x48
' ASSUMPTIONS
'   0x00C5DCAC g_cameraman_imgs:TImage[] -- the two uses are [eax+0x18] and [eax+0x1C],
'     i.e. elements 0 and 1 of a BBArray (data starts at +0x18), and both feed
'     TDrawOb.AddDrawOb's first parameter, declared :TImage.
'   The dwords at 0x00C78A98..0x00C78AD0 are bcc-emitted Float literals, not Globals.
'   `ElseIf Not (rot >= 135.0)` / `ElseIf Not (rot >= 225.0)`: the setcc emitted is the
'     POSITIVE test (setae) and the branch is inverted (jne).  Compare the first condition,
'     where `rot < 45.0` as an Or operand emits setb directly -- the two spellings are
'     distinguishable in the bytes.
'   `sc * 1.0` in the second AddDrawOb is a real fmul against a 1.0 literal in the original,
'     not a redundancy to be tidied away.
	Method Render:Int()
		'!Global g_cameraman_imgs:TImage[]
		Local sc:Float = 0.25
		Local f:Int
		Local d:Int
		If Self.rot > 315.0 Or Self.rot < 45.0
			f = 4
			d = 0
		ElseIf Not (Self.rot >= 135.0)
			f = 2
			d = 2
		ElseIf Not (Self.rot >= 225.0)
			f = 3
			d = 0
			sc = -sc
		Else
			f = 1
			d = 1
		End If
		TDrawOb.AddDrawOb(g_cameraman_imgs[0], Self.x, Self.y, 0, d, 3, 1.0, 0, "FFFFFF", sc, 0.25, 3, 0, "", 0, 0)
		TDrawOb.AddDrawOb(g_cameraman_imgs[0], Self.x, Self.y, 0, d, 2, 0.3, 20, "000000", sc * 1.0, 0.2, 3, 0, "", 0, 0)
		Select f
			Case 3
				TDrawOb.AddDrawOb(g_cameraman_imgs[1], Self.x + 3.0, Self.y - 10.0, 0, d, 4, 1.0, Int(Self.rot + 180.0), "FFFFFF", sc, 0.25, 3, 0, "", 0, 0)
			Case 4
				TDrawOb.AddDrawOb(g_cameraman_imgs[1], Self.x - 3.0, Self.y - 10.0, 0, d, 4, 1.0, Int(Self.rot), "FFFFFF", sc, 0.25, 3, 0, "", 0, 0)
			Case 2
				TDrawOb.AddDrawOb(g_cameraman_imgs[1], Self.x - 4.0, Self.y - 12.0, 0, d, 4, 1.0, Int(Self.rot), "FFFFFF", sc, 0.25, 3, 0, "", 0, 0)
			Case 1
				TDrawOb.AddDrawOb(g_cameraman_imgs[1], Self.x - 4.0, Self.y - 8.0, 0, d, 3, 1.0, Int(Self.rot), "FFFFFF", sc, 0.25, 3, 0, "", 0, 0)
		End Select
	End Method
