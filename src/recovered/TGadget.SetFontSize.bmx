' TGadget.SetFontSize
' VA 0x005140d1   66 bytes   vtable slot 0x5c   sig (i)i
' byte-identical vs NSS5.exe (66/66, original length from Ghidra's inventory)
' assumes: font array Global is TImageFont[]; SetImageFont/TextWidth from brl.max2d
'
' GLOBAL RENAMED (2026-08-15): g_gadget_fonts -> g_fonts. Same slot, 0x00C61710.
' This file was the ONLY one in the corpus spelling it g_gadget_fonts; five others
' (TGadget.CreateToolTip, TScreen.SetUpFonts, TBossMessage.DrawAll,
' TScreenMessage.CreateAlert, TStats_Match.DrawPitch) all call it g_fonts, and
' TGadget.CreateToolTip.bmx's header pins the address explicitly.
'
' Why it mattered: TScreen.SetUpFonts is the only writer -- it fills four sizes
' (10/14/22/32pt) from the Incbin'd TTF into g_fonts[0..3]. Under the old spelling this
' method read a DIFFERENT, empty Global, so the very first CreateLabel -> SetText ->
' SetFontSize on the language screen indexed a zero-length array and threw. Per-body
' verification cannot catch this: a Global appears in the compiled code only as an absolute
' address and the byte oracle masks those, so both spellings verify at 66/66.
' Renaming is byte-neutral -- confirm with scripts/reverify.py, do not take it on trust.
' scripts/unify_globals.py reports the rest of this defect class corpus-wide.
	Method SetFontSize:Int(a0:Int)
		'!Global g_fonts:TImageFont[]
		SetImageFont(g_fonts[a0-1])
		Self.txtw = TextWidth(Self.txt)
	End Method
