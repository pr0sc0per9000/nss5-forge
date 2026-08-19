' TScreen_MainMenu.ButtonDeleteSaveFile
' VA 0x0051D5AA   228 bytes   mode=reloc
' Driven through the oracle from scratch with helper_map.record stubbed; MATCH over the
' full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
' byte-identical vs NSS5.exe
'!Global g_loadtable:TTable
'!Global g_savedir:String
Local f:String = g_loadtable.GetSelectedText(0)
If f <> ""
	TScreenMessage.ClearAll(1)
	If TScreen.DoMessage(GetText("CMESSAGE_FILECONFIRMDELETE").Replace("$filename", f), 1, 0)
		DeleteFile(g_savedir + "Save/" + f + ".sav")
		DeleteFile(g_savedir + "Save/" + f + ".bak")
	EndIf
EndIf
UpdateLoadTable()
Return 0
