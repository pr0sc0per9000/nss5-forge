' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_Options.ButtonDistance
' VA 0x005213a8   108 bytes   vtable slot 0x70   sig ()i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory)
' note this one sets 0 on the first case and 1 on the second
' VERIFIED: harness.read_string confirms "options_distyards"/"options_distmetres" exactly. No change needed.
' The active-gadget Global 0x00C61CF8 is TGadget, not Object -- it is only
' DOWNCAST here so both spellings emit the same bytes, but TScreen.SetActive reads
' .alive/.hidden off it and 0x005114C7 calls its +0x40 function-pointer field, which
' Object cannot have. See extracted/globals_corrections.tsv.
	Function ButtonDistance:Int()
		'!Global g_activegadget:TGadget
		'!Global g_opt_distance:Int
		'!Global g_opt_refresh:Int()
		Select TButton(g_activegadget).name
			Case "options_distyards"
				g_opt_distance = 0
			Case "options_distmetres"
				g_opt_distance = 1
		End Select
		g_opt_refresh()
	End Function
