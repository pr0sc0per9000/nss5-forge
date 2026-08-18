' TScreen_Casino.HideTitleButtons
' VA 0x00574542   76 bytes   vtable slot 0x54   sig ()i
' byte-identical vs NSS5.exe (76/76, original length from Ghidra's inventory)
' assumes module global:  Global g_Object348:TButton
' assumes module global:  Global g_Object349:TButton
' globals 0x00c66770 / 0x00c66774

	Function HideTitleButtons:Int()
		'!Global g_Object348:TButton
		'!Global g_Object349:TButton
		g_Object348.alive = 0
		g_Object348.SetAlph(0.5)
		g_Object349.alive = 0
		g_Object349.SetAlph(0.5)
	End Function
