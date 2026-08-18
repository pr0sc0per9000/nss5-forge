' TPlayer.ResetOffsideAll
' VA 0x004fee5c   104 bytes   vtable slot 0x220   sig ()i
' byte-identical vs NSS5.exe (104/104, original length from Ghidra's inventory)
' assumes module global:  Global g_Object79:TList   (0x00c5de10, the all-players list)
	Function ResetOffsideAll:Int()
		'!Global g_Object79:TList
		For Local p:TPlayer = EachIn g_Object79
			p.offsidewhenkicked = 0
			p.offside = 0
		Next
	End Function
