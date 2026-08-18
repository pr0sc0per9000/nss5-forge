' TProgressBar.Draw   (KIND=Method, SIG=()i)
' VA 0x0051A6F3   1079 bytes   (Ghidra-authoritative)
' ORACLE: mode=reloc  matched=1079/1079  reloc_masked=63  STATUS=MATCH
'
' ASSUMPTIONS / RESOLUTIONS
'   0x00C6EFE4/E8 g_engine_int162/163:Int -- the backbuffer width and height, restored
'     into SetViewport after the icon-clipping pass.
'   TProgressBar fields: image +0x5C, fillimage +0x60, fillicon +0x64, fillcolour +0x68,
'     percent +0x6C, livepercent +0x70, oldpercent +0x74, oldfillcolour +0x78,
'     oldfillalpha +0x7C, boosticon +0x84, numboost +0x88; x/y/h/w/colour/txtcolour/
'     hidden/txt from TGadget.  DrawGadgetText is slot 0x68.
'   Every literal offset is its own .rdata dword (0x00C7E280..0x00C7E2E4): 4.0/8.0 for
'     the outer plate, 6.0/12.0 for the inner fill, 100.0 for the percentage divide and
'     10.0 for the ten icon cells.  Literal 0x00C7E268 = "AAAAAA".
'   `Local ox:Float` / `Local oy:Float` are BARE declarations -- bcc default-initialises
'     them with fldz/fstp, and adding `ox = 0.0` statements costs 10 extra bytes.  This
'     is the mirror image of codegen-patterns 16.3, which recorded the elision of
'     `Local x:Float = 0.0`: the zero store comes from the declaration, not the
'     initialiser.
'   `If Not Self.fillicon` (setne/movzx/cmp/jne, 21 bytes) rather than `= Null`
'     (cmp/je, 12 bytes) -- codegen-patterns 10.3.

'!Global g_engine_int162:Int
'!Global g_engine_int163:Int

	Method Draw()
		If Self.hidden Then Return 0
		Local ox:Float
		Local oy:Float
		GetOrigin(ox, oy)
		SetColourHex(Self.colour)
		SetAlpha(1.0)
		DrawImage(Self.image, Self.x, Self.y, 0)
		SetColourHex("AAAAAA")
		DrawImageRect(Self.fillimage, Self.x + 4.0, Self.y + 4.0, Self.w - 8.0, Self.h - 8.0, 0)
		If Self.oldpercent <> 0.0
			Local ow:Int = Int((Self.w - 12.0) / 100.0 * Self.oldpercent)
			SetColourHex(Self.oldfillcolour)
			SetAlpha(Self.oldfillalpha)
			DrawImageRect(Self.fillimage, Self.x + 6.0, Self.y + 6.0, ow, Self.h - 12.0, 0)
			SetAlpha(1.0)
		End If
		If Not Self.fillicon
			Local fw:Int = Int((Self.w - 12.0) / 100.0 * Self.livepercent)
			SetColourHex(Self.fillcolour)
			DrawImageRect(Self.fillimage, Self.x + 6.0, Self.y + 6.0, fw, Self.h - 12.0, 0)
		Else
			Local pw:Int = Int((Self.w - 12.0) / 100.0 * Self.percent)
			SetViewport(Int(ox + Self.x + 6.0), Int(oy + Self.y + 6.0), pw, Int(Self.h - 12.0))
			Local iw:Float = (Self.w - 12.0) / 10.0
			Local ih:Float = Self.h - 12.0
			SetColourHex(Self.fillcolour)
			For Local i:Int = 1 To 10
				DrawImageRect(Self.fillicon, Self.x + 6.0 + (i - 1) * iw, Self.y + 6.0, iw, ih, 0)
			Next
			If Self.boosticon And Self.numboost
				SetColor(255, 255, 255)
				For Local j:Int = 1 To Self.numboost
					DrawImageRect(Self.boosticon, Self.x + 6.0 + pw - j * iw, Self.y + 6.0, iw, ih, 0)
				Next
			End If
			SetViewport(0, 0, g_engine_int162, g_engine_int163)
		End If
		If Self.txt.length
			Self.DrawGadgetText(Self.txtcolour, 0)
		Else
			If Not Self.fillicon
				Self.txt = Int(Self.livepercent) + "%"
				Self.DrawGadgetText(Self.txtcolour, 0)
				Self.txt = ""
			End If
		End If
	End Method
