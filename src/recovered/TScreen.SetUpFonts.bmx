' TScreen.SetUpFonts  -- KIND=Function (static, no Self), sig ($)i, slot 0x34
' VA 0x00510285   318 bytes
' byte-identical vs NSS5.exe (318/318, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=2)
'
' ASSUMPTIONS
'   Global 0x00C61710 g_fonts:TImageFont[] (already established by TGadget.CreateToolTip /
'   TBossMessage.DrawAll / TScreenMessage.CreateAlert / TStats_Match.DrawPitch). Array
'   elements 0..3 are the four loaded point-size fonts; element 1 (14pt) is made current.
'   Calls the module Function LoadFontChecked (src/recovered_module/LoadFontChecked.bmx,
'   ours; original VA 0x004bc773), a LoadImageChecked-shaped wrapper around
'   _brl_max2d_LoadImageFont with a FileType/LogLine guard. Path prefix literal
'   "incbin::Inc/" (0x00C7D984) is prepended to the font filename before the call.
'   String literals: "TCCEB.TTF" (default), "ru" (language-code compare target),
'   "RUSSIAN.TTF" (Russian-locale font file).
'
' CODEGEN NOTE (cost 3 probe rounds): the font-file selection is
'   Local fontfile:String = "TCCEB.TTF" ; If a0 = "ru" Then fontfile = "RUSSIAN.TTF"
'   in EVERY plain-If phrasing tried (single-line Then, block If/EndIf, If/Else with the
'   default re-assigned in Else) -- all of those compile the branch as a single 2-byte
'   `jne +5` (314 bytes, 4 short). The original's branch is `74 02 EB 07 ... EB 00`: je to
'   a LATER block, an unconditional jmp past it for the untaken case, and a trailing
'   zero-displacement jmp closing that block back to the join point -- the per-arm
'   unconditional-jump shape a `Select`/`Case` emits even for a single Case. Wrapping the
'   same single comparison in `Select a0 / Case "ru" ... End Select` (no Default arm; the
'   pre-set Local IS the default) reproduces it exactly.
	Function SetUpFonts(a0:String)
		'!Global g_fonts:TImageFont[]
		Local fontfile:String = "TCCEB.TTF"
		Select a0
			Case "ru"
				fontfile = "RUSSIAN.TTF"
		End Select
		g_fonts[0] = LoadFontChecked("incbin::Inc/" + fontfile, 10, 4)
		g_fonts[1] = LoadFontChecked("incbin::Inc/" + fontfile, 14, 4)
		g_fonts[2] = LoadFontChecked("incbin::Inc/" + fontfile, 22, 4)
		g_fonts[3] = LoadFontChecked("incbin::Inc/" + fontfile, 32, 4)
		SetImageFont(g_fonts[1])
		Return 0
	End Function
