' TNation.SelectByTLA
' VA 0x004bec88   146 bytes   vtable slot 0x5c   sig ($):TNation
' byte-identical vs NSS5.exe (146/146, original length from Ghidra's inventory)
' assumes module global at 0x00C596F0 typed TList; downcast class table 0x00C599C8
' is TNation + 0x00. Field [6] = +0x18 = tla (inherited from TBase_Team).
' FUN_004A6A30 is the string-compare runtime helper.
	Function SelectByTLA:TNation(a0:String)
		'!Global g_nations:TList
		If Not g_nations Then Return Null
		For Local n:TNation = EachIn g_nations
			If n.tla = a0 Then Return n
		Next
		Return Null
	End Function
