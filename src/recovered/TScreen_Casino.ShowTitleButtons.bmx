' TScreen_Casino.ShowTitleButtons
' VA 0x005744f6   76 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (76/76, original length from Ghidra's inventory)
' assumes module global:  Global g_Object348:TButton
' assumes module global:  Global g_Object349:TButton
' globals 0x00c66770 / 0x00c66774; TButton chosen for alive@0x38 + SetAlph@0x70

	Function ShowTitleButtons:Int()
		'!Global g_Object348:TButton
		'!Global g_Object349:TButton
		g_Object348.alive = 1
		g_Object348.SetAlph(1.0)
		g_Object349.alive = 1
		g_Object349.SetAlph(1.0)
	End Function
