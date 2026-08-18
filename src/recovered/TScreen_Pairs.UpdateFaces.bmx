' TScreen_Pairs.UpdateFaces
' VA 0x00579354   197 bytes   mode=reloc
' Driven through the oracle from scratch with helper_map.record stubbed; MATCH over the
' full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_pairs_icons:TList
'!Global g_pairs_int03:Int
'!Global g_pairs_buttons:TButton[]
LogLine("UpdateFaces")
Local n:Int = 0
For Local p:TPair_Icon = EachIn g_pairs_icons
	If p.picked Or g_pairs_int03 = -2
		g_pairs_buttons[n].SetIcon(p.front)
	Else
		g_pairs_buttons[n].SetIcon(p.back)
	EndIf
	n = n + 1
Next
