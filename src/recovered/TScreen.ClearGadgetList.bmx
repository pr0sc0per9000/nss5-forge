' TScreen.ClearGadgetList
' VA 0x00510648   153 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (153/153, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00C61CF0 declared :TList (the global gadget registry).
' harness mode=reloc.

	Method ClearGadgetList:Int()
		'!Global g_allgadgets:TList
		For Local g:TGadget = EachIn gadgetlist
			If Not g.children.IsEmpty() Then g.ClearChildren()
			g_allgadgets.Remove(g)
		Next
		gadgetlist.Clear()
	End Method
