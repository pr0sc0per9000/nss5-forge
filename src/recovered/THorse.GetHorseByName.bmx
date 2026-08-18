' THorse.GetHorseByName
' VA 0x0058A8C7   118 bytes   vtable slot 0x34   sig ($):THorse
' byte-identical vs NSS5.exe (118/118, original length from Ghidra's inventory)
' ASSUMPTION: module Global at 0x00C6E294 declared :TList.
' harness mode=reloc.

	Function GetHorseByName:THorse(a0:String)
		'!Global g_horses:TList
		For Local h:THorse = EachIn g_horses
			If h.name = a0 Then Return h
		Next
		Return Null
	End Function
