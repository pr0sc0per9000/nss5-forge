' TScreen_Options.ButtonCorners
' VA 0x00521652   125 bytes   vtable slot 0x88   sig ()i
' byte-identical vs NSS5.exe (125/125, original length from Ghidra's inventory, mode=reloc)
' assumptions:
'   0x00C621CC = TGadget class table + 0x7C -> TGadget.GetActiveGadgetName()$
'   0x00C64064 = TScreen_Options class table + 0x38 -> TScreen_Options.RefreshButtons()
'   0x00C5D27C is a module Global Int (name ours; the corner-request option, 1/0/-1)
' Shape is load-bearing: all three bbStringCompare tests are emitted up front followed by
' a jump table of bodies -- that is Select/Case, not an If/ElseIf cascade (which is 121).
' The Select scrutinee is the call itself; no Local is materialised.
	Function ButtonCorners:Int()
		'!Global g_options_corners:Int
		Select TGadget.GetActiveGadgetName()
			Case "options_reqcornersalways"
				g_options_corners = 1
			Case "options_reqcornerssometimes"
				g_options_corners = 0
			Case "options_reqcornersnever"
				g_options_corners = -1
		End Select
		TScreen_Options.RefreshButtons()
	End Function
