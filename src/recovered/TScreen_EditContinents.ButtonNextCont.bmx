' TScreen_EditContinents.ButtonNextCont
' VA 0x00528fbe   45 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (45/45, original length from Ghidra's inventory)
' assumes module global:  Global g_Object169:TContinent
' global 0x00c64ec4 typed TContinent

	Function ButtonNextCont:Int()
		'!Global g_Object169:TContinent
		Local c:Int = g_Object169.id + 1
		If c > 6 Then c = 6
		SetUpScreen(c)
	End Function
