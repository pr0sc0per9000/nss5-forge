' TContinent.SaveMaster
' VA 0x00508DF4   315 bytes
' byte-identical vs NSS5.exe (315/315, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_datapath:String
Local f:String = g_datapath + "GameMedia/Data/Continents.csv"
If a1
	CreateDir(g_datapath + "GameMedia/Data/Mobile", 0)
	f = g_datapath + "GameMedia/Data/Mobile/Continents.txt"
EndIf
If a0 And FileType(f) = 1 And TScreen.DoMessage(GetText("CMESSAGE_OVERWRITEFILE").Replace("$filename", StripDir(f)), 1, 0) = 0 Then Return 0
Local s:TStream = WriteFile("utf8::" + f)
If Not s
	TScreen.DoMessage(GetText("CMESSAGE_FILENOTCREATED").Replace("$filename", StripDir(f)), 0, 0)
	Return 0
EndIf
WriteData(s)
