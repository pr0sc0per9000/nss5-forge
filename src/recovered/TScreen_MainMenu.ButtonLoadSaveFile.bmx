' TScreen_MainMenu.ButtonLoadSaveFile
' VA 0x0051d54f   91 bytes   vtable slot 0x50   sig ()i
' byte-identical vs NSS5.exe (91/91, original length from Ghidra's inventory)
' assumption: module Global at 0x00c639dc declared as g_tblSaves:TTable
'             (the call is slot 0xd8 = TTable.GetSelectedText(i)$)
' string literal ".sav" read directly out of NSS5.exe's data section
	Function ButtonLoadSaveFile:Int()
		'!Global g_tblSaves:TTable
		TScreenMessage.ClearAll(1)
		Local s:String=g_tblSaves.GetSelectedText(0)
		If s<>"" Then TProfile.LoadSavedGame(s+".sav")
	End Function
