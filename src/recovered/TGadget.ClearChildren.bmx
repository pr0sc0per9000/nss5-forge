' TGadget.ClearChildren
' VA 0x00513B36   195 bytes
' byte-identical vs NSS5.exe (195/195, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_allgadgets:TList
If Not Self.children Then Return 0
If Self.children.IsEmpty() Then Return 0
For Local g:TGadget = EachIn Self.children
	g.ClearChildren()
	g_allgadgets.Remove(g)
Next
Self.children.Clear()
