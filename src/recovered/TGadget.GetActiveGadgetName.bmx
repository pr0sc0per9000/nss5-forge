' TGadget.GetActiveGadgetName
' VA 0x00514c5d   36 bytes   vtable slot 0x7c   sig ()$
' byte-identical vs NSS5.exe (36/36, original length from Ghidra's inventory)
' assumes module global:  Global g_Object108:TGadget
' global 0x00c61cf8 (the active gadget); the non-null case must come first

	Function GetActiveGadgetName:String()
		'!Global g_Object108:TGadget
		If g_Object108 <> Null Then Return g_Object108.name
		Return ""
	End Function
