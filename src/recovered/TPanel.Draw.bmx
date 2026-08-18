' TPanel.Draw
' VA 0x005196C1   214 bytes
' byte-identical vs NSS5.exe (214/214, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
If Self.hidden Then Return 0
SetColourHex(Self.colour)
If Not Self.bodyimage
	SetAlpha(Self.alph)
	DrawImage(Self.image, Self.x, Self.y, 0)
	If Self.txt.Length <> 0
		Self.DrawGadgetText(Self.txtcolour, 0)
	End If
Else
	SetAlpha(1.0)
	DrawImage(Self.image, Self.x, Self.y, 0)
	If Self.txt.Length <> 0
		Self.DrawGadgetText(Self.txtcolour, 0)
	End If
	SetAlpha(Self.alph)
	DrawImage(Self.bodyimage, Self.x, Self.y + Self.h, 0)
End If
