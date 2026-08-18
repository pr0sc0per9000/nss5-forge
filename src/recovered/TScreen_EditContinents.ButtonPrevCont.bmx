' TScreen_EditContinents.ButtonPrevCont
' VA 0x00528f91   45 bytes   vtable slot 0x3c   sig ()i
' byte-identical vs NSS5.exe (45/45, original length from Ghidra's inventory)
' assumes module global:  Global g_Object169:TContinent
' global 0x00c64ec4 typed TContinent (Int id at +8); SetUpScreen is slot 0x34

	Function ButtonPrevCont:Int()
		'!Global g_Object169:TContinent
		Local c:Int = g_Object169.id - 1
		If c < 1 Then c = 1
		SetUpScreen(c)
	End Function
