' TScreen_ContractOffer.ShowCurrentContract
' VA 0x005540D9   278 bytes
' byte-identical vs NSS5.exe (278/278, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_co_panelA:TPanel
'!Global g_co_panelB:TPanel
' 0x00C6EFDC, the 800-wide DESIGN canvas, read twice by the original at 0x00554105
' (`sar eax,1`, /2) and 0x00554138 (/4); the function never touches 0x00C6EFE4.
' g_screen_w is fifteen other bodies' name for 0x00C6EFE4, the runtime window width, so
' above 800 wide the panel slid a quarter of the WINDOW instead of a quarter of the
' canvas and left the visible area.
'!Global g_screen_int21:Int
g_co_panelA.Show()
g_co_panelB.Show()
If g_co_panelB.x < g_screen_int21/2
	g_co_panelB.x = g_co_panelB.x + g_screen_int21/4
End If
For Local g:TGadget = EachIn g_co_panelB.children
	If g.x < g_screen_int21/2
		g.x = g.x + g_screen_int21/4
	End If
Next
