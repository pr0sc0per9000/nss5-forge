' Every string literal in this file was read out of NSS5.exe with
' harness.read_string and checked against the address the ORIGINAL pushes at the
' same code offset. The oracle masks a literal's ADDRESS, so a MATCH on its own does
' not certify the text -- see docs/reference/codegen-patterns.md 13.2.
' TScreen_Options.ButtonShowEnergy
' VA 0x005214ec   108 bytes   vtable slot 0x7c   sig ()i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory)
' same three-global shape as ButtonMatchFx
' VERIFIED: harness.read_string confirms "options_showenergyon"/"options_showenergyoff" exactly. No change needed.
' The active-gadget Global 0x00C61CF8 is TGadget, not Object -- it is only
' DOWNCAST here so both spellings emit the same bytes, but TScreen.SetActive reads
' .alive/.hidden off it and 0x005114C7 calls its +0x40 function-pointer field, which
' Object cannot have. See extracted/globals_corrections.tsv.
	Function ButtonShowEnergy:Int()
		'!Global g_activegadget:TGadget
		'!Global g_opt_showenergy:Int
		'!Global g_opt_refresh:Int()
		Select TButton(g_activegadget).name
			Case "options_showenergyon"
				g_opt_showenergy = 1
			Case "options_showenergyoff"
				g_opt_showenergy = 0
		End Select
		g_opt_refresh()
	End Function
