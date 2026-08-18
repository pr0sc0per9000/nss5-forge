' TNation.LoadData
' VA 0x004BE1F3   285 bytes   mode=reloc
' Verified through the oracle from scratch with helper_map.record stubbed; MATCH over
' the full Ghidra-authoritative length, every byte.
' Body-only format: statements only, parameters are a0, a1, ...
'!Global g_nations:TList
'!Global g_datapath:String
If g_nations <> Null Then g_nations.Clear()
If Not a0
	a0 = ReadFile("utf8::" + g_datapath + "GameMedia/Data/Nations.csv")
EndIf
If Not a0
	Notify("Could not load GameMedia/Data/Nations.csv", 0)
	End
EndIf
LogLine("TNation.LoadData")
ReadLine(a0)
While Eof(a0) = 0
	Local line:String = ReadLine(a0)
	If line = "//"
		LogLine("Nations:" + g_nations.Count())
		Return 0
	EndIf
	CreateNation(line)
Wend
CloseFile(a0)
Return 0
