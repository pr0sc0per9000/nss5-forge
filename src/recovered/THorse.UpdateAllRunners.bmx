' THorse.UpdateAllRunners
' VA 0x0058ab6f   93 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (93/93, original length from Ghidra's inventory)
' assumes module global:  Global g_Object851:TList   (0x00c6e298, the runners list)
	Function UpdateAllRunners:Int()
		'!Global g_Object851:TList
		For Local h:THorse = EachIn g_Object851
			h.Update()
		Next
	End Function
