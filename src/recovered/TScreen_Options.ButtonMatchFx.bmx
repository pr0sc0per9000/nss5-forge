' TScreen_Options.ButtonMatchFx
' VA 0x005212d0   108 bytes   vtable slot 0x68   sig ()i
' byte-identical vs NSS5.exe (108/108, original length from Ghidra's inventory)
' three module Globals assumed (active gadget:Object, the flag:Int, and a refresh function pointer Int())
' VERIFIED: the two gadget-name literals were flagged as placeholders; harness.read_string
' confirms "options_matchfxon"/"options_matchfxoff" exactly. No change needed.
' The active-gadget Global 0x00C61CF8 is TGadget, not Object -- it is only
' DOWNCAST here so both spellings emit the same bytes, but TScreen.SetActive reads
' .alive/.hidden off it and 0x005114C7 calls its +0x40 function-pointer field, which
' Object cannot have. See extracted/globals_corrections.tsv.
	Function ButtonMatchFx:Int()
		'!Global g_activegadget:TGadget
		'!Global g_opt_matchfx:Int
		'!Global g_opt_refresh:Int()
		Select TButton(g_activegadget).name
			Case "options_matchfxon"
				g_opt_matchfx = 1
			Case "options_matchfxoff"
				g_opt_matchfx = 0
		End Select
		g_opt_refresh()
	End Function
