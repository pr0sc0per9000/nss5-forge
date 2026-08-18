' TScreen_ContractOffer.ShowCurrentContract
' VA 0x005540D9   278 bytes
' byte-identical vs NSS5.exe (278/278, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_co_panelA:TPanel
'!Global g_co_panelB:TPanel
'!Global g_screen_w:Int
g_co_panelA.Show()
g_co_panelB.Show()
If g_co_panelB.x < g_screen_w/2
	g_co_panelB.x = g_co_panelB.x + g_screen_w/4
End If
For Local g:TGadget = EachIn g_co_panelB.children
	If g.x < g_screen_w/2
		g.x = g.x + g_screen_w/4
	End If
Next
