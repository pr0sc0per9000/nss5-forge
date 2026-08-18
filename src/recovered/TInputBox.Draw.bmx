' TInputBox.Draw   (KIND=Method, SIG=()i)
' VA 0x00515B92   877 bytes   (Ghidra-authoritative)
' ORACLE: mode=reloc  matched=877/877  reloc_masked=40  STATUS=MATCH
'
' ASSUMPTIONS / RESOLUTIONS
'   0x00C6EFD4 g_player_int50:Int -- the free-running millisecond counter; `Mod 1000 < 500`
'     is the caret blink. (globals_final types it TScreen; codegen-patterns 10.7 already
'     records that row as an Int -- confirmed again here, bare dword into idiv.)
'   Fields are TGadget's: x +0x20, y +0x24, h +0x28, w +0x2C, colour +0x30,
'     txtcolour +0x34, hidden +0x3C, alph +0x44, txt +0x10; TInputBox adds
'     gettinginput +0x60, image +0x68, hideinput +0x6C.
'   Literal 0x00C6FC58 = "000000" (read out of the exe).  Alpha constant 0x3EB33333
'     is 0.35, not 0.7 -- reading the dword rather than eyeballing it is what fixed
'     the only divergence (offset 279).
'   Every /2.0 site is its own .rdata dword (0x00C7E054/58/6C/70/74/78/7C/80), all 2.0;
'     the caret offset 0x00C7E084 is 4.0.
'   `If Self.txt.length` is the bare truth form -- `<> 0` would add setne/movzx.
'   Frame is `sub esp,0x14`: tw/th/cx/cy spill to [ebp-4..-0x10] in declaration order,
'     [ebp-0x14] is the fild scratch; xx/yy/s/i/limit all colour into esi/ebx/edi.

'!Global g_player_int50:Int

	Method Draw()
		If Self.hidden Then Return 0
		SetScale(1.0, 1.0)
		SetAlpha(Self.alph)
		Local xx:Int = Int(Self.x)
		Local yy:Int = Int(Self.y)
		SetColourHex("000000")
		DrawRect(xx, yy, Self.w, Self.h)
		SetColourHex(Self.colour)
		DrawRect(xx + 1, yy + 1, Self.w - 2.0, Self.h - 2.0)
		SetColor(255, 255, 255)
		SetAlpha(0.35)
		DrawImage(Self.image, xx, yy, 0)
		SetAlpha(1.0)
		SetColourHex(Self.txtcolour)
		Local tw:Float = TextWidth(Self.txt)
		Local th:Float = TextHeight(Self.txt)
		Local cx:Int = Int(Self.x + Self.w / 2.0)
		Local cy:Int = Int(Self.y + Self.h / 2.0)
		If Self.txt.length
			If Self.hideinput
				Local s:String = ""
				For Local i:Int = 1 To Self.txt.length
					s :+ "*"
				Next
				tw = TextWidth(s)
				DrawText(s, cx - tw / 2.0, cy - th / 2.0)
			Else
				DrawText(Self.txt, cx - tw / 2.0, cy - th / 2.0)
			End If
		End If
		If Self.gettinginput And g_player_int50 Mod 1000 < 500
			SetColor(0, 0, 0)
			DrawRect(cx + tw / 2.0 + 4.0, cy - th / 2.0, 4.0, th)
		End If
		SetScale(1.0, 1.0)
		SetColor(255, 255, 255)
	End Method
