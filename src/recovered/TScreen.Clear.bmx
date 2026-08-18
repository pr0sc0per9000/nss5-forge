' TScreen.Clear
' VA 0x005105ed   91 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (91/91, original length from Ghidra's inventory)
' module Global at 0x00c61cf8 assumed declared type Object (no vtable call is made on it here, so its declared type is not pinned by this match)
' the active-gadget Global 0x00C61CF8 is TGadget, not Object -- it is only
' DOWNCAST here so both spellings emit the same bytes, but TScreen.SetActive reads
' .alive/.hidden off it and 0x005114C7 calls its +0x40 function-pointer field, which
' Object cannot have. See extracted/globals_corrections.tsv.
	Method Clear:Int()
		'!Global g_activegadget:TGadget
		g_activegadget = Null
		bg = Null
		ClearGadgetList()
	End Method
