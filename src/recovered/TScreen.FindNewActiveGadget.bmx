' TScreen.FindNewActiveGadget
' VA 0x00510CAC   281 bytes
' byte-identical vs NSS5.exe (281/281, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_curscreen:TScreen
'!Global g_activegadget:TGadget
For Local g:TGadget = EachIn g_curscreen.gadgetlist
	If g.hidden Then Continue
	If g.alive <> 0
		g_activegadget = g
		Return 0
	Else
		For Local c:TGadget = EachIn g.children
			If c.alive <> 0
				g_activegadget = c
				Return 0
			EndIf
		Next
	EndIf
Next
