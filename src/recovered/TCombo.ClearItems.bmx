' TCombo.ClearItems
' VA 0x0051819D   166 bytes   vtable slot 0x8c   sig ()i
' byte-identical vs NSS5.exe (166/166, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00C61CF0 declared :TList (same registry as TScreen.ClearGadgetList).
' harness mode=reloc.

	Method ClearItems:Int()
		'!Global g_allgadgets:TList
		For Local b:TButton = EachIn buttons
			g_allgadgets.Remove(b)
			buttons.Remove(b)
		Next
		selecteditem = 0
		btn_head.SetText(txt, "", -1, -1)
	End Method
