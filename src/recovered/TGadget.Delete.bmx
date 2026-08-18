' TGadget.Delete
' VA 0x005136df   174 bytes   vtable slot 0x14   sig ()i
' byte-identical vs NSS5.exe (174/174, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00c61cf0 declared :TList (selects slot 0x74 = TList.Remove).
' The seven trailing field decrefs (desx.. children) are compiler-generated destructor code.
	Method Delete()
		'!Global g_gadgets:TList
		ClearChildren()
		txtlines.Clear()
		g_gadgets.Remove(Self)
	End Method
