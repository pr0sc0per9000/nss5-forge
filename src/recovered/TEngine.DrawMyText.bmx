' TEngine.DrawMyText
' VA 0x004D7D6B   391 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_font1:TBitmapFont
'!Global g_font2:TBitmapFont
'!Global g_screenW:Int
'!Global g_screenH:Int
Local f:TBitmapFont = g_font1
If a8 = 1 Then f = g_font2
If a1 = 0.0 And a2 = 0.0
	a1 = g_screenW / 2
	a2 = g_screenH / 2
End If
SetDrawStateHex(a7, a5, a6, 0, 3)
Select a3
	Case 0
	Case 1
		a1 = a1 - (f.GetTxtWidth(a0) / 2) * a5
	Case 2
		a1 = a1 - f.GetTxtWidth(a0) * a5
End Select
Select a4
	Case 0
	Case 1
		a2 = a2 - (f.GetFontHeight() / 2) * a5
	Case 2
		a2 = a2 - f.GetFontHeight() * a5
End Select
f.DrawText(a0, a1, a2, 1)
SetDrawStateHex("FFFFFF", 1.0, 1.0, 0, 3)
