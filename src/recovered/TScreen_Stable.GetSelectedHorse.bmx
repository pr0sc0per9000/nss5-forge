' TScreen_Stable.GetSelectedHorse
' VA 0x00589BF8   118 bytes   vtable slot 0x7c   sig ($):THorse
' byte-identical vs NSS5.exe (118/118, original length from Ghidra's inventory)
' ASSUMPTION: Global 0x00c6e294 declared :TList (same list as THorse.CountHorsesOwned)
	Function GetSelectedHorse:THorse(a0:String)
		'!Global g_horses:TList
		For Local h:THorse = EachIn g_horses
			If h.name = a0 Then Return h
		Next
		Return Null
	End Function
