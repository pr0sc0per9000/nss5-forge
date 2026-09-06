' TEngine.DrawMyText
' VA 0x004D7D6B   391 bytes   mode=reloc
' byte-identical vs NSS5.exe
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_font_match_m:TBitmapFont
'!Global g_font2:TBitmapFont
' THE RUNTIME WINDOW SIZE IS 0x00C6EFE4/0x00C6EFE8, NOT 0x00C6EFDC/0x00C6EFE0.
' The lower pair are the 800x600 DESIGN canvas: they are static initialisers in the PE
' image and no instruction anywhere in the program stores to them. The upper pair are
' written from the chosen TGraphicsMode in FUN_00506A5D (0x00506AF6
' `mov [0xc6efe4],eax`, fallback 0x00506B3A `mov [0xc6efe4],0x320`).
' TScreen.UpdateOffset settles which is which: 0x00510825 `mov eax,[0xc6efe4]` /
' `sub eax,[0xc6efdc]` halved into the borderX float, and 0x00510844 the same for
' 0x00C6EFE8 minus 0x00C6EFE0 into borderY.
' Measured here: 0x004D7DBE `a1e4efc600 mov eax,[0xc6efe4]` then `sar eax,1`, and
' 0x004D7DD4 the same for [0xc6efe8]. g_screenW and g_screenH are three other bodies'
' names for the LOWER pair, so every centred match message was placed at (400,300)
' instead of the centre of the window.
'!Global g_screen_w:Int
'!Global g_screen_h:Int
Local f:TBitmapFont = g_font_match_m
If a8 = 1 Then f = g_font2
If a1 = 0.0 And a2 = 0.0
	a1 = g_screen_w / 2
	a2 = g_screen_h / 2
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
