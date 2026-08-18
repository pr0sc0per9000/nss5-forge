' TDrawOb.ClearAll
' VA 0x004CD3F2   145 bytes   vtable slot 0x30   sig ()i
' byte-identical vs NSS5.exe (145/145, original length from Ghidra's inventory)
' ASSUMPTION: Global 0x00c5af6c declared :TList; element type TDrawOb from class table 0x00c5b180
	Function ClearAll:Int()
		'!Global g_drawobs:TList
		For Local d:TDrawOb = EachIn g_drawobs
			d.img = Null
		Next
		g_drawobs.Clear()
	End Function
