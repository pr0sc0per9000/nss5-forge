' TPhotographer.RenderAll
' VA 0x004EB0DE   93 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (93/93, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00C5DB1C declared :TList.
' harness mode=reloc.

	Function RenderAll:Int()
		'!Global g_photographers:TList
		For Local p:TPhotographer = EachIn g_photographers
			p.Render()
		Next
	End Function
